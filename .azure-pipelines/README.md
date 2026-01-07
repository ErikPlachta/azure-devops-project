# Azure Pipelines Architecture

Modular, scalable pipeline templates with single-source-of-truth patterns.

## Folder Structure

```
.azure-pipelines/
├── README.md                     # This file
├── configs/                      # Tool configurations (single source of truth)
│   ├── eslint/                   # ESLint configs by strictness level
│   │   ├── base.js               # Standard rules for production code
│   │   ├── strict.js             # Maximum enforcement for critical systems
│   │   └── relaxed.js            # Lighter rules for internal tools/POCs
│   ├── ruff/                     # Python linter configs
│   │   ├── base.toml
│   │   ├── strict.toml
│   │   └── relaxed.toml
│   ├── dotnet/                   # .NET analyzer configs
│   │   ├── base.editorconfig
│   │   ├── strict.editorconfig
│   │   ├── relaxed.editorconfig
│   │   └── stylecop.json
│   └── sonar/                    # SonarCloud profiles
│       └── sonar-project.properties.template
│
├── jobs/                         # Reusable job definitions (atomic units)
│   ├── lint.yml                  # Multi-language lint job
│   ├── test.yml                  # Multi-language test job
│   ├── scan-sonar.yml            # SonarCloud analysis
│   ├── scan-dependencies.yml     # Dependency vulnerability scan
│   ├── scan-secrets.yml          # Secret detection (gitleaks, trufflehog)
│   ├── build-artifact.yml        # Build and publish artifacts
│   ├── deploy-appservice.yml     # App Service deployment with slots
│   ├── deploy-databricks.yml     # Databricks Asset Bundle deployment
│   ├── deploy-powerbi.yml        # Power BI PBIX deployment
│   └── smoke-test.yml            # Post-deploy validation
│
├── stages/                       # Stage compositions
│   ├── ci.yml                    # CI stage (lint + test + scan)
│   ├── cd-ut.yml                 # Deploy to UT (develop branch)
│   ├── cd-st.yml                 # Deploy to ST (release/* or main)
│   └── cd-pr.yml                 # Deploy to PR (main with slot swap)
│
├── templates/                    # High-level orchestrators
│   ├── ci-cd-full.yml            # Complete CI/CD: CI → Scan → UT → ST → PR
│   ├── ci-only.yml               # CI without deployment (for PRs/libs)
│   ├── cd-promote.yml            # Promote artifacts between environments
│   ├── ci-typescript.yml         # TS convenience wrapper (backward compat)
│   ├── ci-python.yml             # Python convenience wrapper
│   ├── ci-dotnet.yml             # .NET convenience wrapper
│   ├── cd-appservice.yml         # App Service deployment template
│   ├── cd-databricks.yml         # Databricks deployment template
│   └── cd-powerbi.yml            # Power BI deployment template
│
└── variables/                    # Variable templates
    ├── common.yml                # Tool versions, shared settings
    ├── environments.yml          # Environment-specific vars (ut/st/pr)
    └── thresholds.yml            # Quality gate thresholds
```

## Design Principles

### 1. Single Source of Truth
- Tool configs in `/configs/` - inherited by all projects
- Job definitions in `/jobs/` - parameterized, reusable
- Thresholds in `/variables/thresholds.yml` - centralized quality gates

### 2. Composition Over Inheritance
- **Jobs** are atomic units (lint, test, scan, deploy)
- **Stages** compose jobs for specific workflows
- **Templates** compose stages for complete pipelines

### 3. Configuration Levels
Each language has three config levels:
| Level | Use Case | Enforcement |
|-------|----------|-------------|
| `relaxed` | Internal tools, scripts, POCs | Suggestions/warnings |
| `base` | Standard production code | Warnings + key errors |
| `strict` | Critical systems, compliance | Errors + security rules |

### 4. Configuration Hierarchy
```
Global defaults (variables/thresholds.yml)
    └── Language defaults (configs/{language}/base.*)
        └── Config level override (relaxed/strict)
            └── Project overrides (project/.azdo/overrides.yml)
```

### 5. Conditional Execution
All jobs support:
- `enabled` parameter for feature flags
- Branch conditions for environment targeting
- Language detection for multi-language repos

## Quick Start

### Full CI/CD Pipeline (App Service)
```yaml
# azure-pipelines.yml
trigger:
  branches:
    include: [main, develop, feature/*]

extends:
  template: /.azure-pipelines/templates/ci-cd-full.yml
  parameters:
    language: typescript
    deployTarget: appservice
    workingDirectory: src/my-api
    configLevel: strict
    coverageThreshold: 90
    appServiceName: app-my-api
```

### Full CI/CD Pipeline (Databricks)
```yaml
extends:
  template: /.azure-pipelines/templates/ci-cd-full.yml
  parameters:
    language: python
    deployTarget: databricks
    workingDirectory: src/etl
    configLevel: strict
    databricksHostUT: $(databricks-host-ut)
    databricksHostST: $(databricks-host-st)
    databricksHostPR: $(databricks-host-pr)
```

### CI Only (Libraries/PRs)
```yaml
extends:
  template: /.azure-pipelines/templates/ci-only.yml
  parameters:
    language: python
    workingDirectory: libs/shared-utils
    configLevel: base
    buildArtifact: false
```

### Custom Job Composition
```yaml
stages:
  - stage: Build
    jobs:
      - template: /.azure-pipelines/jobs/lint.yml
        parameters:
          language: typescript
          workingDirectory: src/api
          configLevel: strict

      - template: /.azure-pipelines/jobs/test.yml
        parameters:
          language: typescript
          workingDirectory: src/api
          coverageThreshold: 95  # Override default

  - stage: Deploy
    dependsOn: Build
    jobs:
      - template: /.azure-pipelines/jobs/deploy-appservice.yml
        parameters:
          environment: ut
          appServiceName: app-my-api
          useSlot: false
```

### Promote Between Environments
```yaml
# Manual promotion pipeline
extends:
  template: /.azure-pipelines/templates/cd-promote.yml
  parameters:
    deployTarget: appservice
    sourceEnvironment: st
    targetEnvironment: pr
    appServiceName: app-my-api
```

## Parameters Reference

### ci-cd-full.yml
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `language` | string | Yes | - | `typescript`, `python`, `dotnet` |
| `deployTarget` | string | Yes | - | `appservice`, `databricks`, `powerbi` |
| `workingDirectory` | string | No | `.` | Project path |
| `configLevel` | string | No | `base` | `relaxed`, `base`, `strict` |
| `coverageThreshold` | number | No | `90` | Min code coverage % |
| `appServiceName` | string | Cond | - | For appservice deploy |
| `databricksHost*` | string | Cond | - | For databricks deploy |
| `workspaceId*` | string | Cond | - | For powerbi deploy |
| `runLint` | boolean | No | `true` | Enable lint job |
| `runTests` | boolean | No | `true` | Enable test job |
| `runSonar` | boolean | No | `true` | Enable SonarCloud |
| `runSmokeTest` | boolean | No | `true` | Enable smoke tests |
| `deployToUT` | boolean | No | `true` | Enable UT deploy |
| `deployToST` | boolean | No | `true` | Enable ST deploy |
| `deployToPR` | boolean | No | `true` | Enable PR deploy |

### Job Parameters
All jobs accept:
- `workingDirectory`: Path to project
- `enabled`: Skip job entirely (default: true)

Lint jobs also accept:
- `configLevel`: relaxed/base/strict
- `failOnWarning`: Treat warnings as errors

Test jobs also accept:
- `coverageThreshold`: Override global threshold
- `testFilter`: Pattern for selective tests

## Branch Strategy

| Branch | Deploys To | Trigger |
|--------|-----------|---------|
| `feature/*` | (CI only) | Push |
| `develop` | UT | Push |
| `release/*` | ST | Push |
| `main` | ST → PR | Push |

## Environment Approvals

Configure in Azure DevOps Environments:
- `barings-appservice-st`: Optional approval
- `barings-appservice-pr`: Required approval + checks
- `barings-databricks-*`: Same pattern
- `barings-powerbi-*`: Same pattern
