# Scheduled Work Item Scan Jobs - 2026-01-09

## Overview
Create scheduled pipeline job that scans Azure DevOps Work Items within a specified Project with configurable filters.

## Proposed Architecture

### Job Template
**File:** `/.azure-pipelines/jobs/scan-work-items.yml`

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| projectName | string | Yes | - | Azure DevOps project to scan |
| organizationUrl | string | Yes | - | `https://dev.azure.com/{org}` |
| sprint | string | No | `@CurrentIteration` | Sprint/Iteration path |
| areaPath | string | No | - | Filter by area path |
| teamName | string | No | - | Owning team filter |
| workItemTypes | string[] | No | `['User Story']` | Types to query |
| states | string[] | No | `['New','Active']` | State filter |
| assignedTo | string | No | - | Assigned user filter |
| tags | string[] | No | - | Tag filters |
| createdAfter | string | No | - | Created date filter |
| modifiedAfter | string | No | - | Modified date filter |
| outputFormat | string | No | `json` | `json`, `csv`, `markdown` |
| publishArtifact | boolean | No | `true` | Publish results as artifact |
| sendNotification | boolean | No | `false` | Send email/Teams notification |

### Query Fields (User Story)
Standard fields to return:
- `System.Id`
- `System.Title`
- `System.State`
- `System.AssignedTo`
- `System.IterationPath`
- `System.AreaPath`
- `System.Tags`
- `System.CreatedDate`
- `System.ChangedDate`
- `Microsoft.VSTS.Common.Priority`
- `Microsoft.VSTS.Common.AcceptanceCriteria`
- `Microsoft.VSTS.Scheduling.StoryPoints`

### Implementation Options

#### Option 1: Azure CLI (Recommended)
Uses built-in `az boards work-item` commands.
```bash
az boards query --wiql "SELECT ... FROM WorkItems WHERE ..."
```

**Pros:** No dependencies, native ADO integration
**Cons:** WIQL syntax required

#### Option 2: REST API via PowerShell
Direct REST calls to `/_apis/wit/wiql`.
```powershell
Invoke-RestMethod -Uri "$org/$project/_apis/wit/wiql?api-version=7.0"
```

**Pros:** Full control, more flexible
**Cons:** More code to maintain

#### Option 3: Python azure-devops SDK
```python
from azure.devops.connection import Connection
from msrest.authentication import BasicAuthentication
```

**Pros:** Type-safe, SDK support
**Cons:** Requires Python installation

### Proposed Schedule Patterns

| Schedule | Cron | Use Case |
|----------|------|----------|
| Daily standup | `0 8 * * 1-5` | Morning report M-F 8am |
| Sprint review | `0 14 * * 5` | Friday 2pm for sprint end |
| Weekly | `0 9 * * 1` | Monday morning summary |
| End of day | `0 17 * * 1-5` | EOD status check |

### Example Pipeline

```yaml
# scheduled-work-item-report.yml
schedules:
  - cron: '0 8 * * 1-5'
    displayName: 'Daily standup report'
    branches:
      include:
        - main
    always: true

trigger: none
pr: none

jobs:
  - template: /.azure-pipelines/jobs/scan-work-items.yml
    parameters:
      organizationUrl: 'https://dev.azure.com/MyOrg'
      projectName: 'MyProject'
      sprint: '@CurrentIteration'
      teamName: 'Platform Team'
      workItemTypes: ['User Story', 'Bug']
      states: ['Active', 'In Progress']
      outputFormat: 'markdown'
      sendNotification: true
```

### Notification Integration
- Teams webhook for channel posts
- Email via SendGrid/SMTP
- Azure Logic App trigger for complex workflows

## Implementation Steps

1. Create `scan-work-items.yml` job template
2. Add WIQL query builder helper script
3. Add output formatters (json, csv, markdown)
4. Add Teams/email notification steps
5. Create example scheduled pipeline
6. Update framework documentation

## Files to Create

| File | Purpose |
|------|---------|
| `/.azure-pipelines/jobs/scan-work-items.yml` | Main job template |
| `/scripts/build-wiql-query.sh` | WIQL query builder |
| `/scripts/format-work-items.py` | Output formatter |
| `/examples/scheduled-reports/azure-pipelines.yml` | Example pipeline |

## Status
- [ ] Create scan-work-items.yml job template
- [ ] Create WIQL query builder script
- [ ] Create output formatters
- [ ] Add Teams notification support
- [ ] Create example scheduled pipeline
- [ ] Update framework documentation
- [ ] Commit and push changes
