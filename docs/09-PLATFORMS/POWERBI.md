# Power BI Deployment Guide

Deploy Power BI reports (PBIX and RDL) via Azure DevOps pipelines with environment-specific data source rebinding.

---

## Overview

| Feature | Support |
|---------|---------|
| PBIX (Standard Reports) | ✅ |
| RDL (Paginated Reports) | ✅ |
| Data Source Rebinding | ✅ |
| Dataset Refresh | ✅ |
| Service Principal Auth | ✅ |

---

## Quick Start

```yaml
# azure-pipelines.yml
stages:
  - stage: Deploy
    jobs:
      - template: /.azure-pipelines/jobs/deploy-powerbi.yml
        parameters:
          environment: production
          workspaceId: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
          azureSubscription: 'my-azure-connection'
          reportPath: 'reports'
          dataSourceConfigFile: 'datasource-config.json'
```

---

## Prerequisites

### 1. Azure AD App Registration

Create an app registration for Service Principal authentication:

```
Azure Portal → Azure Active Directory → App Registrations → New Registration
```

**Required API Permissions:**
- Power BI Service → Delegated:
  - `Report.ReadWrite.All`
  - `Dataset.ReadWrite.All`
  - `Workspace.ReadWrite.All`

**Create Client Secret:**
- Certificates & secrets → New client secret
- Save the secret value (won't be shown again)

### 2. Power BI Admin Portal

Enable Service Principal access:

```
Power BI Admin Portal → Tenant Settings → Developer Settings
```

- Enable "Service principals can use Fabric APIs"
- Add a security group containing your Service Principal

### 3. Workspace Access

Add Service Principal to target workspaces:

```
Power BI Workspace → Access → Add → [Service Principal Name] → Admin or Member
```

### 4. Azure DevOps Configuration

**Variable Group** (`powerbi-credentials`):
| Variable | Value |
|----------|-------|
| `POWERBI_TENANT_ID` | Azure AD Tenant ID |
| `POWERBI_CLIENT_ID` | App Registration Client ID |
| `POWERBI_CLIENT_SECRET` | Client Secret (mark as secret) |
| `POWERBI_WORKSPACE_DEV` | Development workspace GUID |
| `POWERBI_WORKSPACE_STAGING` | Staging workspace GUID |
| `POWERBI_WORKSPACE_PROD` | Production workspace GUID |

---

## Job Parameters

### Required

| Parameter | Description |
|-----------|-------------|
| `environment` | `development`, `staging`, `production` |
| `workspaceId` | Target Power BI workspace GUID |
| `azureSubscription` | Azure DevOps service connection |

### Report Source

| Parameter | Default | Description |
|-----------|---------|-------------|
| `reportPath` | `reports` | Path to reports folder/file |

### Data Source Rebinding

| Parameter | Default | Description |
|-----------|---------|-------------|
| `dataSourceConfigFile` | - | Path to JSON config |
| `rebindDataSource` | `true` | Enable rebinding |
| `takeOwnership` | `true` | Take ownership (required for RDL) |

### Refresh Options

| Parameter | Default | Description |
|-----------|---------|-------------|
| `refreshDataset` | `true` | Trigger refresh after deploy |
| `waitForRefresh` | `true` | Wait for completion |
| `refreshTimeout` | `30` | Timeout in minutes |

### Import Options

| Parameter | Default | Description |
|-----------|---------|-------------|
| `conflictAction` | `CreateOrOverwrite` | `CreateOrOverwrite`, `Abort`, `Ignore` |

---

## Data Source Configuration

Create `datasource-config.json`:

```json
{
  "development": {
    "server": "dev-sql.database.windows.net",
    "database": "ReportsDB_Dev"
  },
  "staging": {
    "server": "staging-sql.database.windows.net",
    "database": "ReportsDB_Staging"
  },
  "production": {
    "server": "prod-sql.database.windows.net",
    "database": "ReportsDB_Prod"
  }
}
```

### With Credentials

```json
{
  "development": {
    "server": "dev-sql.database.windows.net",
    "database": "ReportsDB_Dev",
    "credentialType": "Basic",
    "username": "report_user",
    "password": "$(DEV_DB_PASSWORD)"
  }
}
```

**Credential Types:**
- `OAuth2` - Azure AD authentication (recommended)
- `Basic` - Username/password
- `Key` - API key

---

## Scripts Reference

### deploy-report.ps1

Imports PBIX/RDL files to workspace.

```powershell
./deploy-report.ps1 `
  -WorkspaceId "guid" `
  -ReportPath "reports/*.pbix" `
  -ConflictAction "CreateOrOverwrite"
```

### rebind-datasource.ps1

Updates data source connections.

```powershell
./rebind-datasource.ps1 `
  -WorkspaceId "guid" `
  -DatasetId "guid" `
  -ConfigFile "datasource-config.json" `
  -Environment "production" `
  -TakeOver
```

### refresh-dataset.ps1

Triggers and monitors dataset refresh.

```powershell
./refresh-dataset.ps1 `
  -WorkspaceId "guid" `
  -DatasetId "guid" `
  -Wait $true `
  -TimeoutMinutes 30
```

---

## Pipeline Examples

### Basic Deployment

```yaml
- template: /.azure-pipelines/jobs/deploy-powerbi.yml
  parameters:
    environment: production
    workspaceId: $(WORKSPACE_ID)
    azureSubscription: 'azure-connection'
    reportPath: 'reports'
```

### With Data Source Rebinding

```yaml
- template: /.azure-pipelines/jobs/deploy-powerbi.yml
  parameters:
    environment: production
    workspaceId: $(WORKSPACE_ID)
    azureSubscription: 'azure-connection'
    reportPath: 'reports'
    dataSourceConfigFile: 'config/datasources.json'
    rebindDataSource: true
    refreshDataset: true
```

### RDL Only (No Refresh)

```yaml
- template: /.azure-pipelines/jobs/deploy-powerbi.yml
  parameters:
    environment: production
    workspaceId: $(WORKSPACE_ID)
    azureSubscription: 'azure-connection'
    reportPath: 'reports/*.rdl'
    refreshDataset: false
    takeOwnership: true
```

---

## Troubleshooting

### "Unauthorized" Error

- Verify Service Principal has workspace access (Admin or Member)
- Check tenant settings allow Service Principals
- Ensure API permissions are granted

### "TakeOver Failed"

- Report may already be owned by the Service Principal
- Check if another user has exclusive ownership

### "Refresh Failed"

- Verify data source credentials are configured
- Check gateway connection if using on-premises data
- Review refresh history in Power BI Service

### RDL Data Source Not Rebinding

- RDL paginated reports require `TakeOver` before modifying
- Some RDL reports use embedded data (no rebind needed)

---

## Best Practices

1. **Version Control**
   - Store PBIX files in Git (binary, but trackable)
   - RDL files diff well (XML format)
   - Use meaningful commit messages

2. **Security**
   - Use variable groups for secrets
   - Mark client secrets as secret variables
   - Use separate Service Principals per environment

3. **Testing**
   - Deploy to dev workspace first
   - Validate data source connections
   - Test refresh before production

4. **Monitoring**
   - Enable refresh failure notifications
   - Monitor dataset refresh history
   - Set appropriate timeouts

---

## Related Resources

- [Microsoft Fabric Git Integration](https://learn.microsoft.com/en-us/fabric/cicd/git-integration/intro-to-git-integration)
- [Power BI REST API Reference](https://learn.microsoft.com/en-us/rest/api/power-bi/)
- [Deployment Pipelines Automation](https://learn.microsoft.com/en-us/power-bi/create-reports/deployment-pipelines-automation)
