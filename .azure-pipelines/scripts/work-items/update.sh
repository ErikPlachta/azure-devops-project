#!/bin/bash
# Update Azure DevOps Work Items
# Reads: work-items.json (or filtered subset)
# Outputs: update-log.json
#
# Required env vars:
#   (none - reads work-items.json)
#
# Optional env vars:
#   DRY_RUN - "true" to preview without applying (default: true)
#   UPDATE_CONDITION - jq filter for items to update
#   ADD_TAGS - Semicolon-separated tags to add
#   REMOVE_TAGS - Semicolon-separated tags to remove
#   SET_STATE - New state value
#   SET_ASSIGNED_TO - New assignee
#   SET_PRIORITY - New priority (1-4)
#   ADD_COMMENT - Comment to add to discussion

set -e

DRY_RUN="${DRY_RUN:-true}"
CONDITION="${UPDATE_CONDITION:-}"
ADD_TAGS="${ADD_TAGS:-}"
REMOVE_TAGS="${REMOVE_TAGS:-}"
SET_STATE="${SET_STATE:-}"
SET_ASSIGNED="${SET_ASSIGNED_TO:-}"
SET_PRIO="${SET_PRIORITY:-}"
COMMENT="${ADD_COMMENT:-}"

# Check if any updates configured
if [ -z "$ADD_TAGS" ] && [ -z "$REMOVE_TAGS" ] && [ -z "$SET_STATE" ] && \
   [ -z "$SET_ASSIGNED" ] && [ -z "$SET_PRIO" ] && [ -z "$COMMENT" ]; then
  echo "No update operations specified"
  echo '{"processed": 0, "updated": 0, "failed": 0, "dryRun": true}' > update-log.json
  exit 0
fi

# Filter items based on condition
if [ -n "$CONDITION" ]; then
  ITEMS=$(cat work-items.json | jq "[ .[] | $CONDITION ]")
else
  ITEMS=$(cat work-items.json)
fi

UPDATE_COUNT=$(echo "$ITEMS" | jq '. | length')
echo "##[section]Items matching update condition: $UPDATE_COUNT"

if [ "$UPDATE_COUNT" -eq 0 ]; then
  echo "No items to update"
  echo '{"processed": 0, "updated": 0, "failed": 0, "dryRun": '"$DRY_RUN"'}' > update-log.json
  exit 0
fi

# Get IDs
IDS=$(echo "$ITEMS" | jq -r '.[].id')

UPDATED=0
FAILED=0

for ID in $IDS; do
  echo ""
  echo "##[section]Processing Work Item #$ID"

  FIELDS=""

  # Add Tags
  if [ -n "$ADD_TAGS" ]; then
    CURRENT_TAGS=$(echo "$ITEMS" | jq -r ".[] | select(.id == $ID) | .fields[\"System.Tags\"] // \"\"")
    if [ -n "$CURRENT_TAGS" ]; then
      NEW_TAGS="$CURRENT_TAGS; $ADD_TAGS"
    else
      NEW_TAGS="$ADD_TAGS"
    fi
    FIELDS="$FIELDS System.Tags=$NEW_TAGS"
    echo "  Adding tags: $ADD_TAGS"
  fi

  # Remove Tags
  if [ -n "$REMOVE_TAGS" ]; then
    CURRENT_TAGS=$(echo "$ITEMS" | jq -r ".[] | select(.id == $ID) | .fields[\"System.Tags\"] // \"\"")
    IFS=';' read -ra REMOVE_ARR <<< "$REMOVE_TAGS"
    for tag in "${REMOVE_ARR[@]}"; do
      tag=$(echo "$tag" | xargs)
      CURRENT_TAGS=$(echo "$CURRENT_TAGS" | sed "s/; *$tag//g; s/$tag; *//g; s/^$tag$//g")
    done
    FIELDS="$FIELDS System.Tags=$CURRENT_TAGS"
    echo "  Removing tags: $REMOVE_TAGS"
  fi

  # Set State
  if [ -n "$SET_STATE" ]; then
    FIELDS="$FIELDS System.State=$SET_STATE"
    echo "  Setting state: $SET_STATE"
  fi

  # Set Assigned To
  if [ -n "$SET_ASSIGNED" ]; then
    FIELDS="$FIELDS System.AssignedTo=$SET_ASSIGNED"
    echo "  Setting assigned to: $SET_ASSIGNED"
  fi

  # Set Priority
  if [ -n "$SET_PRIO" ]; then
    FIELDS="$FIELDS Microsoft.VSTS.Common.Priority=$SET_PRIO"
    echo "  Setting priority: $SET_PRIO"
  fi

  # Apply field updates
  if [ -n "$FIELDS" ]; then
    if [ "$DRY_RUN" = "true" ] || [ "$DRY_RUN" = "True" ]; then
      echo "  [DRY RUN] Would update: $FIELDS"
    else
      if az boards work-item update --id "$ID" --fields $FIELDS --output none; then
        echo "  Updated successfully"
        UPDATED=$((UPDATED + 1))
      else
        echo "##vso[task.logissue type=warning]Failed to update work item #$ID"
        FAILED=$((FAILED + 1))
      fi
    fi
  fi

  # Add Comment
  if [ -n "$COMMENT" ]; then
    if [ "$DRY_RUN" = "true" ] || [ "$DRY_RUN" = "True" ]; then
      echo "  [DRY RUN] Would add comment: $COMMENT"
    else
      if az boards work-item update --id "$ID" --discussion "$COMMENT" --output none; then
        echo "  Added comment"
      else
        echo "##vso[task.logissue type=warning]Failed to add comment to #$ID"
      fi
    fi
  fi
done

echo ""
echo "##[section]Update Summary"
echo "  Total processed: $UPDATE_COUNT"
if [ "$DRY_RUN" = "true" ] || [ "$DRY_RUN" = "True" ]; then
  echo "  Mode: DRY RUN (no changes applied)"
  echo "{\"processed\": $UPDATE_COUNT, \"updated\": 0, \"failed\": 0, \"dryRun\": true}" > update-log.json
else
  echo "  Updated: $UPDATED"
  echo "  Failed: $FAILED"
  echo "{\"processed\": $UPDATE_COUNT, \"updated\": $UPDATED, \"failed\": $FAILED, \"dryRun\": false}" > update-log.json
fi
