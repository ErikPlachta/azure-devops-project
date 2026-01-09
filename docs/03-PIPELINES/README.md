# Pipelines

CI/CD templates, patterns, and deployment strategies.

---

## Documents in This Section

| Document | Purpose |
|----------|---------|
| [PIPELINE-OVERVIEW.md](./PIPELINE-OVERVIEW.md) | How Azure Pipelines work, key concepts |
| [TEMPLATE-STRATEGY.md](./TEMPLATE-STRATEGY.md) | Reusable templates, extends vs includes |
| [CI-WORKFLOW.md](./CI-WORKFLOW.md) | Build → Test → Scan → Report |
| [CD-WORKFLOW.md](./CD-WORKFLOW.md) | Deploy → Validate → Promote |
| [TRIGGERS.md](./TRIGGERS.md) | Branch triggers, PR validation, schedules |
| [VARIABLES.md](./VARIABLES.md) | Variable groups, Key Vault linking, secrets |
| [AGENTS.md](./AGENTS.md) | Microsoft-hosted vs self-hosted, pools |
| [COST-ESTIMATION.md](./COST-ESTIMATION.md) | Pipeline minutes, parallel jobs, optimization |

### Language-Specific
| Document | Purpose |
|----------|---------|
| [JS-TS-PIPELINE.md](./JS-TS-PIPELINE.md) | Node.js build, test, deploy |
| [PYTHON-PIPELINE.md](./PYTHON-PIPELINE.md) | Python build, test, deploy |
| [DOTNET-PIPELINE.md](./DOTNET-PIPELINE.md) | .NET build, test, deploy |
| [SQL-PIPELINE.md](./SQL-PIPELINE.md) | SQL migrations, validation |

### Platform-Specific
| Document | Purpose |
|----------|---------|
| [APP-SERVICE-DEPLOY.md](./APP-SERVICE-DEPLOY.md) | Direct and containerized |
| [DATABRICKS-DEPLOY.md](./DATABRICKS-DEPLOY.md) | Asset Bundles, Unity Catalog |
| [POWERBI-DEPLOY.md](./POWERBI-DEPLOY.md) | REST API, XMLA endpoint |
| [SHAREPOINT-DEPLOY.md](./SHAREPOINT-DEPLOY.md) | File sync via PnP.PowerShell |

---

## Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     CI Pipeline                              │
├─────────────────────────────────────────────────────────────┤
│  Trigger: PR created/updated, push to develop/main          │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │  Build   │→ │  Lint    │→ │  Test    │→ │  Scan    │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
│       │             │             │             │            │
│       ▼             ▼             ▼             ▼            │
│  [Artifacts]   [ESLint/Ruff]  [Coverage]  [SonarCloud]      │
│                [StyleCop]     [90% gate]  [Quality Gate]    │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                     CD Pipeline                              │
├─────────────────────────────────────────────────────────────┤
│  Trigger: CI success + branch rules                          │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ Deploy   │→ │  Smoke   │→ │  E2E     │→ │ Promote  │    │
│  │   UT     │  │  Tests   │  │  Tests   │  │  to ST   │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
│       │                                          │           │
│       ▼                                          ▼           │
│  [Auto on PR merge]                    [Manual approval]    │
└─────────────────────────────────────────────────────────────┘
```

---

## Template Hierarchy

```yaml
# azure-pipelines.yml (per app/service)
extends:
  template: /.azure-pipelines/templates/ci-cd-full.yml
  parameters:
    language: typescript
    deployTarget: appservice
    configLevel: strict
    workingDirectory: src/my-api
```

```yaml
# /.azure-pipelines/templates/ci-cd-full.yml
# Composes: CI → Scan → UT → ST → PR
variables:
  - template: ../variables/common.yml

stages:
  - template: ../stages/ci.yml        # lint, test, build, scan
  - template: ../stages/cd-ut.yml     # deploy to UT
  - template: ../stages/cd-st.yml     # deploy to ST
  - template: ../stages/cd-pr.yml     # deploy to PR
```

---

## Environment Strategy

| Environment | Branch Source | Trigger | Approval | Purpose |
|-------------|---------------|---------|----------|---------|
| UT | `feature/*`, `develop` | Auto (PR merge) | None | Dev testing |
| ST | `release/*` | Manual | Tech Lead | UAT/Integration |
| PR | `main` | Manual | Change Board | Production |

---

## Quality Gates (Pipeline Enforcement)

| Gate | Stage | Failure Action |
|------|-------|----------------|
| Lint errors | Build | Block |
| Test failures | Test | Block |
| Coverage < 90% | Test | Block |
| SonarCloud fail | Scan | Block |
| Critical vulnerabilities | Scan | Block |
| Smoke test fail | Deploy | Rollback |

`[SOC2-CC8]` All gates provide audit trail via pipeline logs.

---

## Variable Management

```yaml
# Variable group linked to Key Vault
variables:
  - group: kv-barings-$(environment)  # UT, ST, PR

# Runtime variables
  - name: buildConfiguration
    value: 'Release'
```

`[SOC2-CC6]` Secrets never stored in YAML, always Key Vault reference.

---

## Cost Optimization

| Strategy | Impact |
|----------|--------|
| Affected-only builds (Nx/Turborepo) | 60-80% reduction |
| Caching (npm, pip, NuGet) | 20-40% faster |
| Parallel jobs | Faster, but costs more |
| Self-hosted agents | Lower cost at scale |

See [COST-ESTIMATION.md](./COST-ESTIMATION.md) for calculator.

---

## Next Steps

1. Review [TEMPLATE-STRATEGY.md](./TEMPLATE-STRATEGY.md)
2. Pick language-specific guide to implement first
3. Setup variable groups per environment
