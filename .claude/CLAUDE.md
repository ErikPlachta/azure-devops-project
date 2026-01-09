# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Azure DevOps Reference Framework - enterprise CI/CD templates and documentation for multi-language codebases (TypeScript, Python, .NET). This is primarily a template/documentation repo, not application code.

## Architecture

**.azure-pipelines/** - Modular pipeline templates:
- `configs/` - Linter configs (eslint, ruff, dotnet) with 3 levels: relaxed, base, strict
- `jobs/` - Atomic CI/CD jobs (lint, test, scan-*, build-*, deploy-*)
- `stages/` - Stage compositions (ci.yml, cd-ut/st/pr.yml)
- `templates/` - High-level orchestrators (ci-cd-full.yml, ci-only.yml, cd-*.yml)
- `variables/` - Shared vars (common.yml, environments.yml, thresholds.yml)

**Composition pattern:** Jobs → Stages → Templates

## Pipeline Usage

Projects extend templates in their azure-pipelines.yml:
```yaml
extends:
  template: /.azure-pipelines/templates/ci-cd-full.yml
  parameters:
    language: typescript|python|dotnet
    deployTarget: appservice|databricks|powerbi
    configLevel: relaxed|base|strict
    workingDirectory: src/my-project
```

## Quality Gates

- Coverage: 90% lines, 85% branches
- Complexity: max 10 cyclomatic, 15 cognitive
- Security: 0 critical/high vulnerabilities
- All enforced via PR block

## Environments

UT (develop) → ST (release/*, main) → PR (main with approval)

## Commit Convention

Follow Conventional Commits: `type(scope): summary`
Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
