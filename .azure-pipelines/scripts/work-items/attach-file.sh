#!/bin/bash
# Attach a file to work items
# Reads: work-items.json
#
# Required env vars:
#   PROJECT_NAME - Azure DevOps project
#   ATTACH_FILE - Path to file to attach
#
# Optional env vars:
#   DRY_RUN - "true" to preview without attaching
#   UPDATE_CONDITION - jq filter for items to attach to

set -e

PROJECT="${PROJECT_NAME:?PROJECT_NAME required}"
FILE_PATH="${ATTACH_FILE:?ATTACH_FILE required}"
DRY_RUN="${DRY_RUN:-true}"
CONDITION="${UPDATE_CONDITION:-}"

if [ ! -f "$FILE_PATH" ]; then
  echo "##vso[task.logissue type=error]File not found: $FILE_PATH"
  exit 1
fi

# Filter items if condition specified
if [ -n "$CONDITION" ]; then
  ITEMS=$(cat work-items.json | jq "[ .[] | $CONDITION ]")
else
  ITEMS=$(cat work-items.json)
fi

COUNT=$(echo "$ITEMS" | jq '. | length')
echo "##[section]Attaching to $COUNT work items"

if [ "$COUNT" -eq 0 ]; then
  echo "No items to attach to"
  exit 0
fi

IDS=$(echo "$ITEMS" | jq -r '.[].id')
ATTACHED=0
FAILED=0

for ID in $IDS; do
  echo "Attaching to Work Item #$ID"

  if [ "$DRY_RUN" = "true" ] || [ "$DRY_RUN" = "True" ]; then
    echo "  [DRY RUN] Would attach: $FILE_PATH"
  else
    # Upload attachment
    UPLOAD_URL=$(az devops invoke \
      --area wit \
      --resource attachments \
      --route-parameters project="$PROJECT" \
      --http-method POST \
      --in-file "$FILE_PATH" \
      --query url -o tsv 2>/dev/null) || {
      echo "##vso[task.logissue type=warning]Failed to upload attachment for #$ID"
      FAILED=$((FAILED + 1))
      continue
    }

    if [ -n "$UPLOAD_URL" ]; then
      # Link attachment to work item
      if az boards work-item relation add \
        --id "$ID" \
        --relation-type "AttachedFile" \
        --target-url "$UPLOAD_URL" \
        --output none 2>/dev/null; then
        echo "  Attached successfully"
        ATTACHED=$((ATTACHED + 1))
      else
        echo "##vso[task.logissue type=warning]Failed to link attachment to #$ID"
        FAILED=$((FAILED + 1))
      fi
    fi
  fi
done

echo ""
echo "##[section]Attachment Summary"
echo "  Total: $COUNT"
if [ "$DRY_RUN" = "true" ] || [ "$DRY_RUN" = "True" ]; then
  echo "  Mode: DRY RUN"
else
  echo "  Attached: $ATTACHED"
  echo "  Failed: $FAILED"
fi
