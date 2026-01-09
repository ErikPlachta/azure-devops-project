#!/bin/bash
# Send Teams notification with work items summary
# Reads: work-items.json, update-log.json (optional)
#
# Required env vars:
#   TEAMS_WEBHOOK_URL - Teams incoming webhook URL
#   PROJECT_NAME - Project name for card title
#
# Optional env vars:
#   SPRINT - Sprint name for subtitle
#   SHOW_UPDATES - "true" to include update summary

set -e

WEBHOOK_URL="${TEAMS_WEBHOOK_URL:?TEAMS_WEBHOOK_URL required}"
PROJECT="${PROJECT_NAME:?PROJECT_NAME required}"
SPRINT_NAME="${SPRINT:-}"
SHOW_UPDATES="${SHOW_UPDATES:-false}"

COUNT=$(cat work-items.json | jq '. | length')

# Build summary
if [ "$COUNT" -gt 0 ]; then
  # Get top 5 items
  SUMMARY=$(cat work-items.json | jq -r '.[0:5] | .[] |
    "- **\(.fields["System.Id"])**: \(.fields["System.Title"] | .[0:60]) (\(.fields["System.State"]))"' | tr '\n' '\n')

  if [ "$COUNT" -gt 5 ]; then
    SUMMARY="$SUMMARY

*...and $((COUNT - 5)) more*"
  fi
else
  SUMMARY="No work items found matching criteria."
fi

# Add update info if available
if [ "$SHOW_UPDATES" = "true" ] && [ -f "update-log.json" ]; then
  UPDATE_INFO=$(cat update-log.json | jq -r '
    if .dryRun then
      "**Updates:** Dry run - \(.processed) items would be updated"
    else
      "**Updates:** \(.updated) updated, \(.failed) failed"
    end
  ')
  SUMMARY="$SUMMARY

$UPDATE_INFO"
fi

# Build subtitle
SUBTITLE=""
[ -n "$SPRINT_NAME" ] && SUBTITLE="Sprint: $SPRINT_NAME"

# Send to Teams
curl -s -H "Content-Type: application/json" -d "{
  \"@type\": \"MessageCard\",
  \"@context\": \"http://schema.org/extensions\",
  \"themeColor\": \"0076D7\",
  \"summary\": \"Work Items Report - $PROJECT\",
  \"sections\": [{
    \"activityTitle\": \"Work Items Report - $PROJECT\",
    \"activitySubtitle\": \"$SUBTITLE\",
    \"facts\": [
      {\"name\": \"Total Items\", \"value\": \"$COUNT\"},
      {\"name\": \"Generated\", \"value\": \"$(date -u +"%Y-%m-%d %H:%M UTC")\"}
    ],
    \"markdown\": true,
    \"text\": $(echo "$SUMMARY" | jq -Rs .)
  }]
}" "$WEBHOOK_URL"

echo "Teams notification sent"
