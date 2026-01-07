# Architecture

Repository structure patterns, decision framework, and scaling strategy.

---

## Documents in This Section

| Document                                               | Purpose                                    |
| ------------------------------------------------------ | ------------------------------------------ |
| [MONO-VS-MULTI-REPO.md](./MONO-VS-MULTI-REPO.md)       | Decision framework with pros/cons          |
| [MONO-REPO-STRUCTURE.md](./MONO-REPO-STRUCTURE.md)     | Example structure, tooling (Nx, Turborepo) |
| [MULTI-REPO-STRUCTURE.md](./MULTI-REPO-STRUCTURE.md)   | Example structure, shared package patterns |
| [FOLDER-CONVENTIONS.md](./FOLDER-CONVENTIONS.md)       | Standard folder naming across languages    |
| [DEPENDENCY-MANAGEMENT.md](./DEPENDENCY-MANAGEMENT.md) | Version pinning, shared packages, updates  |
| [SCALING-STRATEGY.md](./SCALING-STRATEGY.md)           | Growing from 15 to 100+ developers         |

---

## Decision Framework: Mono vs Multi-Repo

### When Mono-Repo Works Best

- Shared code/types across services
- Atomic changes across multiple packages
- Unified versioning/release
- Strong tooling investment (Nx, Turborepo, Bazel)

### When Multi-Repo Works Best

- Independent team ownership
- Different release cadences
- Varied compliance requirements per service
- Simpler CI/CD per repo

### Hybrid Approach

- Mono-repo per domain/team
- Shared packages in dedicated repos (npm/NuGet/PyPI internal feeds)

---

## Proposed Structure (Mono-Repo)

```t
/
├── .azure-pipelines/          # Pipeline templates
│   ├── templates/
│   │   ├── build-js.yml
│   │   ├── build-python.yml
│   │   ├── build-dotnet.yml
│   │   └── deploy-*.yml
│   └── ci.yml                 # Main CI orchestrator
├── .config/                   # Shared configs
│   ├── eslint/
│   ├── prettier/
│   ├── sonar/
│   └── commitlint/
├── apps/                      # Deployable applications
│   ├── api-gateway/           # .NET API
│   ├── web-portal/            # React/TS frontend
│   ├── etl-jobs/              # Python Databricks jobs
│   └── reports/               # Power BI
├── libs/                      # Shared libraries
│   ├── common-types/          # Cross-language schemas
│   ├── utils-js/
│   ├── utils-py/
│   └── utils-dotnet/
├── scripts/                   # BAT/SH utilities
├── sql/                       # Database scripts
│   ├── migrations/
│   └── stored-procs/
├── docs/                      # This documentation
└── tools/                     # Build/dev tooling
```

---

## Proposed Structure (Multi-Repo)

```t
# Repo: shared-configs
├── eslint/
├── prettier/
├── sonar/
└── pipeline-templates/

# Repo: api-gateway
├── src/
├── tests/
├── azure-pipelines.yml        # Extends shared templates
└── README.md

# Repo: web-portal
├── src/
├── tests/
├── azure-pipelines.yml
└── README.md

# Repo: databricks-etl
├── notebooks/
├── jobs/
├── tests/
└── databricks.yml
```

---

## Language-Specific Conventions

| Language | Source                 | Tests                    | Config           | Build Output |
| -------- | ---------------------- | ------------------------ | ---------------- | ------------ |
| JS/TS    | `src/`                 | `tests/` or `__tests__/` | root             | `dist/`      |
| Python   | `src/` or package name | `tests/`                 | `pyproject.toml` | `dist/`      |
| C#/.NET  | `src/`                 | `tests/`                 | `*.csproj`       | `bin/`       |
| SQL      | `sql/`                 | `sql/tests/`             | N/A              | N/A          |

---

## Scaling Considerations

| Team Size | Recommendation                                 |
| --------- | ---------------------------------------------- |
| 1-20      | Mono-repo, simple CI                           |
| 20-50     | Mono-repo with Nx/Turborepo, affected-based CI |
| 50-100    | Consider domain-split mono-repos               |
| 100+      | Multi-repo with strong shared package strategy |

---

## Next Steps

1. Review [MONO-VS-MULTI-REPO.md](./MONO-VS-MULTI-REPO.md) for detailed comparison
2. Decide structure with team leads
3. Proceed to [../03-PIPELINES/README.md](../03-PIPELINES/README.md)
