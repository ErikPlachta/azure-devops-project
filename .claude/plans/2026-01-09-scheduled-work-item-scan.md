# Scheduled Work Item Scan Jobs - 2026-01-09

## Overview

Created scheduled pipeline job that scans Azure DevOps Work Items with configurable filters and optional update operations.

## Implementation

### Job Template

**File:** `/.azure-pipelines/jobs/scan-work-items.yml`

Uses Azure CLI (`az boards`) for querying and updating work items.

### Query Parameters

| Parameter         | Type   | Default             | Description                   |
| ----------------- | ------ | ------------------- | ----------------------------- |
| organizationUrl   | string | required            | `https://dev.azure.com/{org}` |
| projectName       | string | required            | Project to scan               |
| azureSubscription | string | required            | Azure service connection      |
| sprint            | string | `@CurrentIteration` | Sprint/Iteration filter       |
| areaPath          | string | -                   | Area path filter              |
| teamName          | string | -                   | Team filter                   |
| assignedTo        | string | -                   | Assigned to filter            |
| workItemTypes     | object | `['User Story']`    | Types to query                |
| states            | object | `['New','Active']`  | State filter                  |
| tags              | object | -                   | Tag filters                   |
| priority          | string | -                   | Priority (1-4)                |
| createdAfter      | string | -                   | Created date filter           |
| modifiedAfter     | string | -                   | Modified date filter          |

### Update Parameters

| Parameter       | Type    | Default | Description                      |
| --------------- | ------- | ------- | -------------------------------- |
| enableUpdates   | boolean | false   | Enable work item modifications   |
| dryRun          | boolean | true    | Preview changes without applying |
| updateCondition | string  | -       | jq filter for items to update    |
| addTags         | object  | -       | Tags to add                      |
| removeTags      | object  | -       | Tags to remove                   |
| setState        | string  | -       | Set state                        |
| setAssignedTo   | string  | -       | Set assignee                     |
| setPriority     | string  | -       | Set priority                     |
| addComment      | string  | -       | Add discussion comment           |
| attachFile      | string  | -       | File to attach                   |

### Output Parameters

| Parameter             | Type    | Default             | Description                  |
| --------------------- | ------- | ------------------- | ---------------------------- |
| outputFormat          | string  | `json`              | `json`, `csv`, `markdown`    |
| publishArtifact       | boolean | true                | Publish as pipeline artifact |
| artifactName          | string  | `work-items-report` | Artifact name                |
| sendTeamsNotification | boolean | false               | Send Teams notification      |
| teamsWebhookUrl       | string  | -                   | Teams webhook URL            |

## Example Pipeline

**File:** `/examples/scheduled-reports/azure-pipelines.yml`

Demonstrates:

- Daily standup report (M-F 8am)
- Weekly sprint summary (Friday 4pm)
- Stale items check with auto-tagging (Monday 9am)
- Priority 1 bugs alert

### Schedule Patterns

| Schedule       | Cron          | Use Case           |
| -------------- | ------------- | ------------------ |
| Daily standup  | `0 8 * * 1-5` | Morning report M-F |
| Weekly summary | `0 16 * * 5`  | Friday EOD summary |
| Stale check    | `0 9 * * 1`   | Monday cleanup     |

## Usage Examples

### Basic Query (Read-Only)

```yaml
- template: /.azure-pipelines/jobs/scan-work-items.yml
  parameters:
    organizationUrl: "https://dev.azure.com/MyOrg"
    projectName: "MyProject"
    azureSubscription: "my-azure-connection"
    sprint: "@CurrentIteration"
    workItemTypes: ["User Story", "Bug"]
    states: ["Active"]
    outputFormat: "markdown"
```

### Update Stale Items

```yaml
- template: /.azure-pipelines/jobs/scan-work-items.yml
  parameters:
    organizationUrl: "https://dev.azure.com/MyOrg"
    projectName: "MyProject"
    azureSubscription: "my-azure-connection"
    states: ["Active"]
    enableUpdates: true
    dryRun: false
    updateCondition: 'select(.fields["System.ChangedDate"] < "2026-01-01")'
    addTags: ["Stale", "Review-Needed"]
    addComment: "Marked as stale by automated pipeline."
```

### Close Resolved Items

```yaml
- template: /.azure-pipelines/jobs/scan-work-items.yml
  parameters:
    organizationUrl: "https://dev.azure.com/MyOrg"
    projectName: "MyProject"
    azureSubscription: "my-azure-connection"
    states: ["Resolved"]
    modifiedAfter: "" # All resolved items
    enableUpdates: true
    dryRun: false
    updateCondition: 'select(.fields["System.State"] == "Resolved")'
    setState: "Closed"
    addComment: "Auto-closed by pipeline after verification period."
```

## Prerequisites

1. Azure DevOps PAT or Service Principal with:
   - Work Items (Read, Write)
   - Project access
2. Azure service connection in ADO
3. Teams webhooks (if notifications enabled)

## Status

- [x] Create scan-work-items.yml job template
- [x] Add query parameters for all standard WIT fields
- [x] Add update operations (tags, state, assignment, comments)
- [x] Add attachment support
- [x] Add dry run mode for safe testing
- [x] Create example scheduled pipeline
- [ ] Update framework documentation
- [ ] Commit and push changes
