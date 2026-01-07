# Platform Guides

Deployment patterns for Azure App Services, Databricks, and Power BI.

---

## Documents in This Section

### Azure App Services
| Document | Purpose |
|----------|---------|
| [APPSERVICE-OVERVIEW.md](./APPSERVICE-OVERVIEW.md) | Architecture, scaling, health checks |
| [APPSERVICE-DIRECT-DEPLOY.md](./APPSERVICE-DIRECT-DEPLOY.md) | Zip deploy, run from package |
| [APPSERVICE-CONTAINER-DEPLOY.md](./APPSERVICE-CONTAINER-DEPLOY.md) | Docker deployment |
| [APPSERVICE-SLOTS.md](./APPSERVICE-SLOTS.md) | Deployment slots, swap strategies |
| [APPSERVICE-MONITORING.md](./APPSERVICE-MONITORING.md) | Application Insights, alerts |

### Azure Databricks
| Document | Purpose |
|----------|---------|
| [DATABRICKS-OVERVIEW.md](./DATABRICKS-OVERVIEW.md) | Architecture, Unity Catalog, SQL Warehouse |
| [DATABRICKS-ASSET-BUNDLES.md](./DATABRICKS-ASSET-BUNDLES.md) | DAB configuration, deployment |
| [DATABRICKS-NOTEBOOKS.md](./DATABRICKS-NOTEBOOKS.md) | Notebook development, testing |
| [DATABRICKS-JOBS.md](./DATABRICKS-JOBS.md) | Job configuration, scheduling |
| [DATABRICKS-CICD.md](./DATABRICKS-CICD.md) | Pipeline integration |
| [DATABRICKS-UNITY-CATALOG.md](./DATABRICKS-UNITY-CATALOG.md) | Data governance, access control |

### Power BI
| Document | Purpose |
|----------|---------|
| [POWERBI-OVERVIEW.md](./POWERBI-OVERVIEW.md) | Architecture, workspaces, datasets |
| [POWERBI-REST-API.md](./POWERBI-REST-API.md) | API deployment patterns |
| [POWERBI-XMLA.md](./POWERBI-XMLA.md) | XMLA endpoint deployment |
| [POWERBI-CICD.md](./POWERBI-CICD.md) | Pipeline integration |
| [POWERBI-TESTING.md](./POWERBI-TESTING.md) | Data validation, visual testing |

---

## Azure App Services

### Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                    App Service Plan                          │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  app-ut     │  │  app-st     │  │  app-pr     │         │
│  │  (Dev slot) │  │  (Stage)    │  │  (Prod)     │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│                                     │  ┌─────────┐          │
│                                     └──│ Staging │          │
│                                        │  Slot   │          │
│                                        └─────────┘          │
└─────────────────────────────────────────────────────────────┘
```

### Deployment Options

| Method | Use Case | Pros | Cons |
|--------|----------|------|------|
| Zip Deploy | Simple apps | Fast, simple | No container isolation |
| Run from Package | Immutable deploy | Reliable, fast startup | Read-only filesystem |
| Container | Complex dependencies | Full control | Slower deploy, more complexity |

### Pipeline Example (Direct Deploy)
```yaml
- task: AzureWebApp@1
  inputs:
    azureSubscription: 'barings-$(environment)'
    appName: 'app-$(service)-$(environment)'
    package: '$(Pipeline.Workspace)/drop/*.zip'
    deploymentMethod: 'runFromPackage'
```

### Pipeline Example (Container)
```yaml
- task: Docker@2
  inputs:
    command: 'buildAndPush'
    repository: 'barings/$(service)'
    dockerfile: 'Dockerfile'
    containerRegistry: 'acr-barings'
    tags: '$(Build.BuildId)'

- task: AzureWebAppContainer@1
  inputs:
    azureSubscription: 'barings-$(environment)'
    appName: 'app-$(service)-$(environment)'
    imageName: 'acr-barings.azurecr.io/barings/$(service):$(Build.BuildId)'
```

---

## Azure Databricks

### Architecture (Single Workspace, Branch-Based)
```
┌─────────────────────────────────────────────────────────────┐
│               Databricks Workspace                           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Unity Catalog                                               │
│  ├── catalog_ut (Dev)                                        │
│  ├── catalog_st (Staging)                                    │
│  └── catalog_pr (Production)                                 │
│                                                              │
│  SQL Warehouses                                              │
│  ├── warehouse_ut                                            │
│  ├── warehouse_st                                            │
│  └── warehouse_pr                                            │
│                                                              │
│  Jobs (deployed via Asset Bundles)                           │
│  ├── job_etl_ut                                              │
│  ├── job_etl_st                                              │
│  └── job_etl_pr                                              │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Databricks Asset Bundles (DAB)

```yaml
# databricks.yml
bundle:
  name: etl-pipeline

workspace:
  host: https://adb-xxxx.azuredatabricks.net

environments:
  ut:
    default: true
    workspace:
      root_path: /Workspace/Users/deploy/ut
    resources:
      jobs:
        etl_job:
          name: "etl-job-ut"
          tasks:
            - task_key: "extract"
              notebook_task:
                notebook_path: ./notebooks/extract.py

  st:
    workspace:
      root_path: /Workspace/Users/deploy/st
    resources:
      jobs:
        etl_job:
          name: "etl-job-st"

  pr:
    workspace:
      root_path: /Workspace/Users/deploy/pr
    resources:
      jobs:
        etl_job:
          name: "etl-job-pr"
```

### Pipeline Example
```yaml
- script: |
    pip install databricks-cli
    databricks bundle validate -e $(environment)
    databricks bundle deploy -e $(environment)
  env:
    DATABRICKS_HOST: $(databricks-host)
    DATABRICKS_TOKEN: $(databricks-token)
```

### Unity Catalog Governance
```sql
-- Grant catalog access per environment
GRANT USAGE ON CATALOG catalog_ut TO `developers`;
GRANT USAGE ON CATALOG catalog_st TO `tech-leads`;
GRANT USAGE ON CATALOG catalog_pr TO `data-ops`;

-- Schema-level permissions
GRANT SELECT ON SCHEMA catalog_pr.gold TO `analysts`;
```

`[SOC2-CC6]` Access controlled via Unity Catalog permissions.

---

## Power BI

### Architecture
```
┌─────────────────────────────────────────────────────────────┐
│               Power BI Service                               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Workspaces                                                  │
│  ├── ws-barings-ut (Development)                             │
│  ├── ws-barings-st (Staging)                                 │
│  └── ws-barings-pr (Production)                              │
│                                                              │
│  Premium Capacity (XMLA endpoint)                            │
│  └── Dataset deployments via XMLA                            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Deployment Methods

| Method | Use Case | Capabilities |
|--------|----------|--------------|
| REST API | Reports, dashboards | Full deployment automation |
| XMLA | Datasets (tabular models) | Schema changes, partitions |
| Deployment Pipelines | Simple promotion | Built-in UI, limited automation |

### REST API Deployment
```yaml
- task: PowerShell@2
  inputs:
    targetType: 'inline'
    script: |
      $token = (Get-AzAccessToken -ResourceUrl "https://analysis.windows.net/powerbi/api").Token
      $headers = @{ Authorization = "Bearer $token" }

      # Import PBIX
      $filePath = "$(Pipeline.Workspace)/drop/report.pbix"
      $bytes = [System.IO.File]::ReadAllBytes($filePath)

      Invoke-RestMethod `
        -Uri "https://api.powerbi.com/v1.0/myorg/groups/$workspaceId/imports?datasetDisplayName=MyDataset" `
        -Method Post `
        -Headers $headers `
        -ContentType "multipart/form-data" `
        -Body $bytes
```

### XMLA Deployment
```yaml
- task: PowerShell@2
  inputs:
    targetType: 'inline'
    script: |
      # Deploy .bim model via XMLA
      $connStr = "Provider=MSOLAP;Data Source=powerbi://api.powerbi.com/v1.0/myorg/$workspace;Initial Catalog=$dataset"

      # Use Tabular Editor or Analysis Services deployment
      & TabularEditor.exe "$modelPath" -D "$connStr" -O -R
```

### Testing
```yaml
- task: PowerShell@2
  displayName: 'Validate Dataset Refresh'
  inputs:
    script: |
      # Trigger refresh
      $refreshUrl = "https://api.powerbi.com/v1.0/myorg/groups/$workspaceId/datasets/$datasetId/refreshes"
      $response = Invoke-RestMethod -Uri $refreshUrl -Method Post -Headers $headers

      # Poll for completion
      do {
        Start-Sleep -Seconds 30
        $status = Invoke-RestMethod -Uri "$refreshUrl" -Headers $headers
      } while ($status.value[0].status -eq "Unknown")

      if ($status.value[0].status -ne "Completed") {
        throw "Refresh failed: $($status.value[0].status)"
      }
```

---

## Cross-Platform Considerations

### Service Principal Setup
All platforms use Azure AD Service Principal:

```yaml
# Variable group with SP credentials
variables:
  - group: sp-barings-$(environment)

# Contains:
# - sp-client-id
# - sp-client-secret
# - sp-tenant-id
```

### Environment Consistency
| Resource | UT | ST | PR |
|----------|----|----|-----|
| App Service | app-*-ut | app-*-st | app-*-pr |
| Databricks Catalog | catalog_ut | catalog_st | catalog_pr |
| Power BI Workspace | ws-barings-ut | ws-barings-st | ws-barings-pr |
| Key Vault | kv-barings-ut | kv-barings-st | kv-barings-pr |

---

## Next Steps

1. Choose deployment method per platform
2. Setup service principals with correct permissions
3. Configure pipelines with platform-specific tasks
4. Implement smoke tests per platform
