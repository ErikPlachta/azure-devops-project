# Power BI Report Deployment Pipeline - Plan

## Requirements
- **Report types:** Both RDL (paginated) and PBIX (standard)
- **Capacity:** Premium/Fabric ✓
- **Data sources:** Environment-specific rebinding (Dev/Test/Prod)

---

## Implementation Plan

### 1. Create PowerShell Scripts

**`.azure-pipelines/scripts/powerbi/deploy-report.ps1`**
- Authenticate via Service Principal
- Import PBIX or RDL via REST API
- Handle conflict resolution (overwrite vs abort)
- Support both report types with single script

**`.azure-pipelines/scripts/powerbi/rebind-datasource.ps1`**
- Get datasources from deployed report
- Update connection strings per environment
- Set credentials from Key Vault
- Handle gateway bindings if needed

**`.azure-pipelines/scripts/powerbi/refresh-dataset.ps1`**
- Trigger dataset refresh post-deployment
- Wait for completion or run async
- Report refresh status

### 2. Create Job Template

**`.azure-pipelines/jobs/deploy-powerbi.yml`**

Parameters:
```yaml
parameters:
  - name: environment        # development | staging | production
  - name: workspaceId        # Target Power BI workspace GUID
  - name: reportPath         # Path to reports (supports glob)
  - name: reportType         # pbix | rdl | auto (detect by extension)
  - name: dataSourceConfig   # JSON config for rebinding
  - name: refreshDataset     # boolean - trigger refresh after deploy
  - name: azureSubscription  # Service connection
```

Steps:
1. Checkout repo (sparse: scripts + reports)
2. Install Az.Accounts, MicrosoftPowerBIMgmt modules
3. Authenticate with Service Principal
4. Deploy reports (loop through files)
5. Rebind data sources per environment
6. Refresh datasets (if enabled)
7. Output deployment summary

### 3. Create Example Pipeline

**`examples/powerbi-reports/azure-pipelines.yml`**
- Trigger on reports folder changes
- Three environments: Dev → Staging → Prod
- Manual approval for production
- Data source config per environment

**`examples/powerbi-reports/datasource-config.json`**
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

---

## Files to Create

```
.azure-pipelines/
├── jobs/
│   └── deploy-powerbi.yml
└── scripts/
    └── powerbi/
        ├── deploy-report.ps1
        ├── rebind-datasource.ps1
        └── refresh-dataset.ps1

examples/
└── powerbi-reports/
    ├── azure-pipelines.yml
    ├── datasource-config.json
    └── reports/
        ├── sample-report.rdl      # Placeholder
        └── sample-dashboard.pbix  # Placeholder
```

---

## Prerequisites (Setup Required)

### 1. Azure AD App Registration
```
App Registrations → New → "PowerBI-DevOps-Deploy"
API Permissions:
  - Power BI Service → Delegated:
    - Report.ReadWrite.All
    - Dataset.ReadWrite.All
    - Workspace.ReadWrite.All
```

### 2. Power BI Admin Portal
```
Admin Portal → Tenant Settings → Developer Settings:
  - Enable "Service principals can use Fabric APIs"
  - Add security group containing the app
```

### 3. Azure DevOps Service Connection
```
Project Settings → Service Connections → New → Azure Resource Manager
  - Service Principal (manual)
  - Use App ID and Secret from step 1
```

### 4. Workspace Access
```
Power BI Workspace → Access → Add the Service Principal as Admin or Member
```

---

## Verification

1. **Syntax check:** `yamllint` on job template
2. **Script test:** Run PowerShell scripts locally with test workspace
3. **Pipeline test:**
   - Deploy sample RDL to dev workspace
   - Deploy sample PBIX to dev workspace
   - Verify data source rebinding works
   - Check reports render correctly in Power BI Service

---

## Notes

- RDL files may require "TakeOver" API call after import for credentials
- PBIX semantic models need refresh after data source change
- Consider using Key Vault for connection strings (not hardcoded JSON)
- Gateway bindings add complexity - not included in initial version
