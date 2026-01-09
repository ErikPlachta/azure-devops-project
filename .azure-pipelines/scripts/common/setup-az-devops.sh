#!/bin/bash
# Setup Azure DevOps CLI extension and defaults
# Usage: source setup-az-devops.sh <org_url> <project_name>

set -e

ORG_URL="${1:?Organization URL required}"
PROJECT="${2:?Project name required}"

# Install extension if needed
az extension add --name azure-devops --only-show-errors 2>/dev/null || true

# Configure defaults
az devops configure --defaults organization="$ORG_URL" project="$PROJECT"

echo "Azure DevOps CLI configured for $PROJECT"
