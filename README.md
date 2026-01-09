# Azure DevOps Reference Framework

Enterprise CI/CD, code quality, and governance framework for multi-language codebases.

## Quick Start

```yaml
# Your project's azure-pipelines.yml
extends:
  template: /.azure-pipelines/templates/ci-cd-full.yml
  parameters:
    language: typescript    # typescript | python | dotnet
    deployTarget: appservice # appservice | databricks | powerbi | sharepoint
    configLevel: strict      # relaxed | base | strict
    workingDirectory: src/my-app
```

## Framework Structure

```
.azure-pipelines/
├── configs/                    # Linter configs (eslint, ruff, dotnet)
│   └── eslint/{relaxed,base,strict}.js
├── jobs/                       # Reusable job templates
│   ├── lint.yml               # Multi-language linting
│   ├── test.yml               # Test + coverage
│   ├── build-*.yml            # Language-specific builds
│   ├── scan-*.yml             # Security scanning
│   ├── deploy-sharepoint.yml  # SharePoint file sync
│   ├── deploy-powerbi.yml     # Power BI PBIX/RDL deploy
│   └── scan-work-items.yml    # Work item query/update
├── scripts/                    # External script logic
│   ├── common/                # Shared utilities
│   ├── work-items/            # WIT query/update scripts
│   ├── sharepoint/            # SharePoint deploy scripts
│   └── powerbi/               # Power BI deploy scripts
├── stages/                     # Stage compositions
│   ├── ci.yml                 # Lint → Test → Build → Scan
│   └── cd-{ut,st,pr}.yml      # Environment deployments
├── templates/                  # High-level orchestrators
│   ├── ci-cd-full.yml         # Full CI/CD pipeline
│   ├── ci-only.yml            # CI without deployment
│   └── cd-promote.yml         # Promotion between envs
└── variables/                  # Shared variables
    ├── common.yml             # Tool versions
    ├── environments.yml       # Env-specific vars
    └── thresholds.yml         # Quality gates

examples/
├── typescript-api/            # Node.js API example
├── gpf-pm-module/             # SharePoint deployment example
├── powerbi-reports/           # Power BI PBIX/RDL deployment
├── scheduled-reports/         # Scheduled work item reports
└── manual-work-items/         # On-demand work item queries

scripts/
└── validate-pipelines.sh      # Governance enforcement

docs/                          # Full documentation
```

## Jobs Reference

| Job | Purpose |
|-----|---------|
| `lint.yml` | ESLint, Ruff, StyleCop, ShellCheck, yamllint |
| `test.yml` | Jest, pytest, dotnet test with coverage |
| `build-typescript.yml` | Node.js build + artifact |
| `build-python.yml` | Python wheel/package |
| `build-dotnet.yml` | .NET publish |
| `scan-sonar.yml` | SonarCloud analysis |
| `scan-dependencies.yml` | npm audit, pip-audit, dotnet list |
| `scan-secrets.yml` | Gitleaks, TruffleHog |
| `deploy-sharepoint.yml` | PnP.PowerShell file sync |
| `deploy-powerbi.yml` | PBIX/RDL report deployment |
| `scan-work-items.yml` | Query/update Azure DevOps WITs |

## Quality Gates

| Gate | Threshold |
|------|-----------|
| Line Coverage | 90% |
| Branch Coverage | 85% |
| Cyclomatic Complexity | max 10 |
| Cognitive Complexity | max 15 |
| Critical Vulnerabilities | 0 |
| High Vulnerabilities | 0 |

## Environments

| Environment | Branch | Trigger | Approval |
|-------------|--------|---------|----------|
| UT (Dev) | `develop`, `feature/*` | Auto | None |
| ST (Staging) | `release/*` | Auto | Tech Lead |
| PR (Prod) | `main` | Manual | Change Board |

## Governance

Pipeline governance enforced via:
- `scripts/validate-pipelines.sh` - Validates `extends:` pattern
- `CODEOWNERS` - Requires DevOps team review
- `.pre-commit-config.yaml` - Local validation hooks

All project pipelines must extend approved templates.

## Documentation

See [docs/INDEX.md](./docs/INDEX.md) for:
- Architecture decisions
- Pipeline deep-dives
- Platform-specific guides (App Service, Databricks, Power BI, SharePoint)
- Security and compliance (SOC 2, SEC, GDPR)

## Languages & Platforms

| Languages | Platforms |
|-----------|-----------|
| TypeScript/JavaScript | Azure App Service |
| Python | Databricks |
| C#/.NET | Power BI |
| SQL | SharePoint |
| Shell/PowerShell | Azure DevOps Work Items |
