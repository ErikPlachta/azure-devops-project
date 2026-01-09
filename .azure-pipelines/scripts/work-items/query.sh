#!/bin/bash
# Query Azure DevOps Work Items using WIQL
# Outputs: work-items.json
#
# Required env vars:
#   PROJECT_NAME - Azure DevOps project
#
# Optional env vars (filters):
#   WORK_ITEM_TYPES - Comma-separated types (default: "User Story")
#   STATES - Comma-separated states (default: "New,Active")
#   SPRINT - Iteration path (default: @CurrentIteration)
#   AREA_PATH - Area path filter
#   ASSIGNED_TO - Assigned user filter
#   PRIORITY - Priority filter (1-4)
#   TAGS - Comma-separated tag filters
#   CREATED_AFTER - Created date filter (YYYY-MM-DD)
#   MODIFIED_AFTER - Modified date filter (YYYY-MM-DD)

set -e

PROJECT="${PROJECT_NAME:?PROJECT_NAME required}"
TYPES="${WORK_ITEM_TYPES:-User Story}"
STATES_LIST="${STATES:-New,Active}"
SPRINT="${SPRINT:-}"
AREA="${AREA_PATH:-}"
ASSIGNED="${ASSIGNED_TO:-}"
PRIO="${PRIORITY:-}"
TAG_LIST="${TAGS:-}"
CREATED="${CREATED_AFTER:-}"
MODIFIED="${MODIFIED_AFTER:-}"

# Build SELECT clause
WIQL="SELECT [System.Id], [System.Title], [System.State], [System.AssignedTo], "
WIQL+="[System.IterationPath], [System.AreaPath], [System.Tags], "
WIQL+="[System.CreatedDate], [System.ChangedDate], "
WIQL+="[Microsoft.VSTS.Common.Priority], [Microsoft.VSTS.Scheduling.StoryPoints] "
WIQL+="FROM WorkItems WHERE "

# Work Item Types
TYPE_CLAUSE=""
IFS=',' read -ra TYPE_ARR <<< "$TYPES"
for i in "${!TYPE_ARR[@]}"; do
  TYPE=$(echo "${TYPE_ARR[$i]}" | xargs)  # trim whitespace
  if [ $i -eq 0 ]; then
    TYPE_CLAUSE="[System.WorkItemType] = '$TYPE'"
  else
    TYPE_CLAUSE="$TYPE_CLAUSE OR [System.WorkItemType] = '$TYPE'"
  fi
done
WIQL+="($TYPE_CLAUSE)"

# States
STATE_CLAUSE=""
IFS=',' read -ra STATE_ARR <<< "$STATES_LIST"
for i in "${!STATE_ARR[@]}"; do
  STATE=$(echo "${STATE_ARR[$i]}" | xargs)
  if [ $i -eq 0 ]; then
    STATE_CLAUSE="[System.State] = '$STATE'"
  else
    STATE_CLAUSE="$STATE_CLAUSE OR [System.State] = '$STATE'"
  fi
done
WIQL+=" AND ($STATE_CLAUSE)"

# Sprint/Iteration
if [ -n "$SPRINT" ]; then
  if [ "$SPRINT" = "@CurrentIteration" ]; then
    WIQL+=" AND [System.IterationPath] = @CurrentIteration"
  else
    WIQL+=" AND [System.IterationPath] UNDER '$PROJECT\\$SPRINT'"
  fi
fi

# Area Path
if [ -n "$AREA" ]; then
  WIQL+=" AND [System.AreaPath] UNDER '$AREA'"
fi

# Assigned To
if [ -n "$ASSIGNED" ]; then
  WIQL+=" AND [System.AssignedTo] = '$ASSIGNED'"
fi

# Priority
if [ -n "$PRIO" ]; then
  WIQL+=" AND [Microsoft.VSTS.Common.Priority] = $PRIO"
fi

# Created After
if [ -n "$CREATED" ]; then
  WIQL+=" AND [System.CreatedDate] >= '$CREATED'"
fi

# Modified After
if [ -n "$MODIFIED" ]; then
  WIQL+=" AND [System.ChangedDate] >= '$MODIFIED'"
fi

# Tags
if [ -n "$TAG_LIST" ]; then
  TAG_CLAUSE=""
  IFS=',' read -ra TAG_ARR <<< "$TAG_LIST"
  for i in "${!TAG_ARR[@]}"; do
    TAG=$(echo "${TAG_ARR[$i]}" | xargs)
    if [ $i -eq 0 ]; then
      TAG_CLAUSE="[System.Tags] CONTAINS '$TAG'"
    else
      TAG_CLAUSE="$TAG_CLAUSE OR [System.Tags] CONTAINS '$TAG'"
    fi
  done
  WIQL+=" AND ($TAG_CLAUSE)"
fi

WIQL+=" ORDER BY [System.ChangedDate] DESC"

echo "##[section]WIQL Query:"
echo "$WIQL"
echo ""

# Execute query
echo "##[section]Executing query..."
RESULT=$(az boards query --wiql "$WIQL" --output json 2>&1) || {
  echo "##vso[task.logissue type=error]Query failed: $RESULT"
  exit 1
}

COUNT=$(echo "$RESULT" | jq '. | length')
echo "##[section]Found $COUNT work items"

# Output results
echo "$RESULT" > work-items.json
echo "$COUNT"
