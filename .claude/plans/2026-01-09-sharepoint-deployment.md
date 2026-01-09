# SharePoint Deployment Feature - 2026-01-09

## Summary
Added SharePoint file deployment capability to the Azure DevOps framework with environment-specific deployments.

## Work Completed

### 1. SharePoint Deploy Job Template
**File:** `/.azure-pipelines/jobs/deploy-sharepoint.yml`

Created reusable job template with:
- PnP.PowerShell for SharePoint uploads
- Environment-specific deployments (development, validate, production)
- File pattern filtering with include/exclude
- Folder structure preservation
- Pre/post deployment steps support
- Azure AD app registration auth

**Parameters:**
| Parameter | Required | Description |
|-----------|----------|-------------|
| environment | Yes | Target environment name |
| azureSubscription | Yes | Azure service connection |
| sharePointSiteUrl | Yes | Target SharePoint site |
| sharePointFolder | Yes | Target document library folder |
| sourceFolder | Yes | Local files to upload |
| filePatterns | No | Include patterns (default: `**/*`) |
| excludePatterns | No | Exclude patterns |
| cleanTargetFolder | No | Delete target before upload |

### 2. Example Project Structure
**Location:** `/examples/gpf-pm-module/`

```
GPF - PM Module/
├── CONFIG/
│   ├── GPF_v2.json                 # Production
│   ├── GPF_v2.development.json     # Development
│   ├── GPF_v2.validate.json        # Validation
│   ├── MASTER_v2.json              # Production
│   ├── MASTER_v2.development.json  # Development
│   └── MASTER_v2.validate.json     # Validation
└── Queries_v2/
    ├── portfolios.txt              # Production
    ├── portfolios.development.txt  # Development
    ├── portfolios.validate.txt     # Validation
    ├── securities.txt              # Production
    ├── securities.development.txt  # Development
    ├── securities.validate.txt     # Validation
    ├── benchmarks.txt              # Production
    ├── benchmarks.development.txt  # Development
    └── benchmarks.validate.txt     # Validation
```

### 3. Example Pipeline
**File:** `/examples/gpf-pm-module/azure-pipelines.yml`

Demonstrates:
- JSON validation for config files
- SQL linting for query files (via sqlfluff)
- Environment config consistency checks
- Branch-based deployment:
  - `develop` → Deploy `.development.*` files
  - `release/*` → Deploy `.validate.*` files
  - `main` → Deploy base files (exclude `.development.` and `.validate.`)

## Environment Mapping

| Branch | Stage | Files Deployed | Target |
|--------|-------|----------------|--------|
| develop | Deploy_Development | `*.development.json`, `*.development.txt` | Dev SharePoint |
| release/* | Deploy_Validate | `*.validate.json`, `*.validate.txt` | Validation SharePoint |
| main | Deploy_Production | `*.json`, `*.txt` (excluding env-specific) | Prod SharePoint |

## Usage

Projects consuming this template need:
1. Azure AD App Registration with SharePoint permissions
2. Azure DevOps service connection
3. Pipeline variables: `tenant`, `siteName`, `azureSubscription`

```yaml
- template: /.azure-pipelines/jobs/deploy-sharepoint.yml
  parameters:
    environment: production
    azureSubscription: '$(azureSubscription)'
    sharePointSiteUrl: 'https://tenant.sharepoint.com/sites/MySite'
    sharePointFolder: '/Shared Documents/MyApp'
    sourceFolder: '$(Build.SourcesDirectory)/files'
    filePatterns: '**/*.json'
```

## Status
- [x] Create deploy-sharepoint.yml job template
- [x] Create GPF-PM-Module example structure
- [x] Create example pipeline with validation stages
- [x] Update framework documentation
- [ ] Commit and push changes
