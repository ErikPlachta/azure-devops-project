#!/bin/bash
# Pipeline Governance Validator
# Ensures azure-pipelines.yml files follow framework architecture

set -e

# Configuration
APPROVED_TEMPLATES=(
  "/.azure-pipelines/templates/ci-cd-full.yml"
  "/.azure-pipelines/templates/ci-only.yml"
  "/.azure-pipelines/templates/cd-promote.yml"
  "/.azure-pipelines/templates/ci-typescript.yml"
  "/.azure-pipelines/templates/ci-python.yml"
  "/.azure-pipelines/templates/ci-dotnet.yml"
)

ERRORS=0
WARNINGS=0

log_error() {
  echo "ERROR: $1"
  ((ERRORS++))
}

log_warning() {
  echo "WARNING: $1"
  ((WARNINGS++))
}

log_info() {
  echo "INFO: $1"
}

# Check if file uses extends pattern
check_extends_pattern() {
  local file="$1"

  if ! grep -q "^extends:" "$file"; then
    # Check if it's a root framework pipeline (allowed to have direct stages)
    if [[ "$file" == *"/.azure-pipelines/"* ]] || [[ "$file" == "azure-pipelines.yml" ]]; then
      log_info "$file: Framework file, direct stages allowed"
      return 0
    fi
    log_error "$file: Must use 'extends:' pattern with approved template"
    return 1
  fi
  return 0
}

# Check if template reference is approved
check_approved_template() {
  local file="$1"

  if ! grep -q "^extends:" "$file"; then
    return 0  # Skip if no extends (already flagged by check_extends_pattern)
  fi

  local template=$(grep -A1 "^extends:" "$file" | grep "template:" | sed 's/.*template:\s*//' | tr -d "'\"" | xargs)

  if [[ -z "$template" ]]; then
    log_error "$file: extends without template reference"
    return 1
  fi

  local approved=false
  for approved_template in "${APPROVED_TEMPLATES[@]}"; do
    if [[ "$template" == "$approved_template" ]]; then
      approved=true
      break
    fi
  done

  if [[ "$approved" == false ]]; then
    log_error "$file: Template '$template' not in approved list"
    return 1
  fi

  log_info "$file: Uses approved template '$template'"
  return 0
}

# Check for forbidden patterns (direct stages/jobs bypassing templates)
check_forbidden_patterns() {
  local file="$1"

  # Skip framework files
  if [[ "$file" == *"/.azure-pipelines/"* ]] || [[ "$file" == "azure-pipelines.yml" ]]; then
    return 0
  fi

  # Check for direct stages definition (not inside extends)
  if grep -q "^stages:" "$file"; then
    if ! grep -q "^extends:" "$file"; then
      log_error "$file: Direct 'stages:' definition not allowed. Use extends: with approved template"
      return 1
    fi
  fi

  # Check for direct jobs definition at root level
  if grep -q "^jobs:" "$file"; then
    log_error "$file: Direct 'jobs:' definition not allowed. Use extends: with approved template"
    return 1
  fi

  # Check for direct steps definition at root level
  if grep -q "^steps:" "$file"; then
    log_error "$file: Direct 'steps:' definition not allowed. Use extends: with approved template"
    return 1
  fi

  return 0
}

# Check required parameters for deploy targets
check_required_parameters() {
  local file="$1"

  if ! grep -q "deployTarget:" "$file"; then
    return 0  # No deploy target, skip
  fi

  local deploy_target=$(grep "deployTarget:" "$file" | head -1 | sed 's/.*deployTarget:\s*//' | tr -d "'\"" | xargs)

  case "$deploy_target" in
    appservice)
      if ! grep -q "appServiceName:" "$file"; then
        log_warning "$file: deployTarget=appservice but appServiceName not specified"
      fi
      ;;
    databricks)
      if ! grep -q "databricksHost" "$file"; then
        log_warning "$file: deployTarget=databricks but databricksHost* not specified"
      fi
      ;;
    powerbi)
      if ! grep -q "workspaceId" "$file"; then
        log_warning "$file: deployTarget=powerbi but workspaceId* not specified"
      fi
      ;;
  esac

  return 0
}

# Main validation
validate_file() {
  local file="$1"
  log_info "Validating: $file"

  check_extends_pattern "$file"
  check_approved_template "$file"
  check_forbidden_patterns "$file"
  check_required_parameters "$file"
}

# Find and validate all pipeline files
main() {
  local target="${1:-.}"

  echo "=========================================="
  echo "Pipeline Governance Validator"
  echo "=========================================="
  echo ""

  # Find all azure-pipelines.yml files (excluding .azure-pipelines framework folder)
  local files=$(find "$target" -name "azure-pipelines.yml" -type f | grep -v "/.azure-pipelines/")

  if [[ -z "$files" ]]; then
    log_info "No pipeline files found to validate"
    exit 0
  fi

  for file in $files; do
    validate_file "$file"
    echo ""
  done

  echo "=========================================="
  echo "Summary: $ERRORS errors, $WARNINGS warnings"
  echo "=========================================="

  if [[ $ERRORS -gt 0 ]]; then
    echo "FAILED: Governance validation failed"
    exit 1
  fi

  echo "PASSED: All pipelines follow governance rules"
  exit 0
}

main "$@"
