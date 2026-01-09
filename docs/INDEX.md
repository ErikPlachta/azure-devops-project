# Azure DevOps Reference Documentation

Enterprise framework for CI/CD, documentation generation, code quality enforcement, and governance across multi-language codebases.

**Target:** Barings, LLC - Global Asset Management
**Compliance Alignment:** SOC 2 Type II, SEC regulations, GDPR
**Environments:** UT (development) → ST (staging) → PR (production)

---

## Quick Navigation

| Audience            | Start Here                                        |
| ------------------- | ------------------------------------------------- |
| New Developer       | [Getting Started](./01-GETTING-STARTED/README.md) |
| Tech Lead           | [Architecture](./02-ARCHITECTURE/README.md)       |
| DevOps Engineer     | [Pipelines](./03-PIPELINES/README.md)             |
| Manager/Stakeholder | [Governance](./08-GOVERNANCE/README.md)           |

---

## Documentation Structure

### [01 - Getting Started](./01-GETTING-STARTED/README.md)

Onboarding, prerequisites, first-time setup.

### [02 - Architecture](./02-ARCHITECTURE/README.md)

Mono-repo vs multi-repo patterns, decision framework, scaling strategy.

### [03 - Pipelines](./03-PIPELINES/README.md)

CI/CD templates, build/test/deploy patterns per language and target.

### [04 - Code Quality](./04-CODE-QUALITY/README.md)

Linting, formatting, SonarCloud integration, quality gates.

### [05 - Testing](./05-TESTING/README.md)

Testing strategy matrix, coverage requirements, validation approaches.

### [06 - Documentation Generation](./06-DOCUMENTATION/README.md)

Auto-doc tooling per language, wiki sync, inline code standards.

### [07 - Security](./07-SECURITY/README.md)

Secrets management, Key Vault, RBAC, scanning, compliance controls.

### [08 - Governance](./08-GOVERNANCE/README.md)

Branch policies, work item linking, audit trails, cost management.

### [09 - Platform Guides](./09-PLATFORMS/README.md)

Azure App Services, Databricks (Unity Catalog), Power BI deployment.

### [10 - Examples](./10-EXAMPLES/README.md)

Complete working snippets, templates, reference implementations.

### [11 - Troubleshooting](./11-TROUBLESHOOTING/README.md)

Common issues, FAQs, escalation paths.

---

## Language Coverage

| Language              | Linting          | Testing           | Doc Gen   | Pipeline |
| --------------------- | ---------------- | ----------------- | --------- | -------- |
| JavaScript/TypeScript | ESLint           | Jest/Vitest       | TypeDoc   | ✓        |
| Python                | Ruff/Pylint      | pytest            | Sphinx    | ✓        |
| C#/.NET               | Roslyn Analyzers | xUnit/NUnit       | DocFX     | ✓        |
| SQL                   | SQLFluff         | tSQLt/pytest      | Inline→MD | ✓        |
| Markdown              | markdownlint     | link-check        | N/A       | ✓        |
| YAML                  | yamllint         | schema validation | N/A       | ✓        |
| BAT/SH                | shellcheck       | bats              | Inline→MD | ✓        |

---

## Deployment Targets

| Target             | Pipeline Type      | Key Considerations                 |
| ------------------ | ------------------ | ---------------------------------- |
| Azure App Services | Direct / Container | Slots, health checks, scaling      |
| Azure Databricks   | Asset Bundles      | Unity Catalog, workspace branches  |
| Power BI           | REST API / XMLA    | Dataset refresh, report deployment |

---

## Testing Matrix

| Testing Type | Goal                         | App Services | Databricks    | Power BI    |
| ------------ | ---------------------------- | ------------ | ------------- | ----------- |
| Smoke        | Critical functionality works | ✓            | ✓             | ✓           |
| Unit         | Code change safety           | ✓ (90%)      | ✓ (extracted) | N/A         |
| Integration  | Module interaction           | ✓            | ✓             | ✓ (data)    |
| Contract     | Consumer compatibility       | ✓ (APIs)     | Optional      | N/A         |
| Regression   | Unintended effects           | ✓            | ✓             | ✓           |
| E2E          | User journeys                | ✓            | ✓ (jobs)      | ✓ (refresh) |
| Acceptance   | Business requirements        | ✓            | ✓             | ✓           |
| Performance  | Load behavior                | ✓            | ✓ (query)     | ✓ (refresh) |

---

## Quality Gates

| Gate                    | Threshold                    | Enforcement |
| ----------------------- | ---------------------------- | ----------- |
| Code Coverage           | 90% (JS/TS, Python, C#/.NET) | PR block    |
| SonarCloud Quality Gate | Pass                         | PR block    |
| Linting                 | Zero errors                  | PR block    |
| Security Scan           | No critical/high             | PR block    |
| Documentation           | Required on public API       | PR block    |

---

## Compliance Mapping

Controls are tagged throughout documentation:

- `[SOC2-CC6]` - Logical/Physical Access Controls
- `[SOC2-CC7]` - System Operations
- `[SOC2-CC8]` - Change Management
- `[SEC-17a]` - Record Retention
- `[GDPR-Art32]` - Security of Processing

---

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for doc standards and update process.

---

## Version

| Version | Date       | Author  | Changes             |
| ------- | ---------- | ------- | ------------------- |
| 0.1.0   | 2026-01-06 | Initial | Framework structure |
