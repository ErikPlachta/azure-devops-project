# Code Quality

Linting, formatting, static analysis, and quality gates.

---

## Documents in This Section

| Document | Purpose |
|----------|---------|
| [QUALITY-OVERVIEW.md](./QUALITY-OVERVIEW.md) | Philosophy, shift-left approach |
| [SONARCLOUD-SETUP.md](./SONARCLOUD-SETUP.md) | Project setup, quality profiles, gates |
| [PRE-COMMIT-HOOKS.md](./PRE-COMMIT-HOOKS.md) | Husky, lint-staged, pre-commit framework |
| [EDITOR-INTEGRATION.md](./EDITOR-INTEGRATION.md) | VS Code settings, format-on-save |
| [AI-ASSISTED-FIXES.md](./AI-ASSISTED-FIXES.md) | Using Copilot Chat to fix issues |

### Language-Specific
| Document | Purpose |
|----------|---------|
| [JS-TS-QUALITY.md](./JS-TS-QUALITY.md) | ESLint, Prettier, TypeScript strict |
| [PYTHON-QUALITY.md](./PYTHON-QUALITY.md) | Ruff, Black, mypy |
| [DOTNET-QUALITY.md](./DOTNET-QUALITY.md) | Roslyn Analyzers, StyleCop, .editorconfig |
| [SQL-QUALITY.md](./SQL-QUALITY.md) | SQLFluff, naming conventions |
| [MARKDOWN-QUALITY.md](./MARKDOWN-QUALITY.md) | markdownlint, link checking |
| [YAML-QUALITY.md](./YAML-QUALITY.md) | yamllint, schema validation |
| [SHELL-QUALITY.md](./SHELL-QUALITY.md) | shellcheck for BAT/SH |

---

## Quality Stack Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Developer Workstation                     │
├─────────────────────────────────────────────────────────────┤
│  Editor          │  Pre-commit Hook    │  Manual Check      │
│  ─────────────   │  ────────────────   │  ────────────      │
│  Format on save  │  Lint staged files  │  npm run lint      │
│  Inline errors   │  Block bad commits  │  Full codebase     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    CI Pipeline                               │
├─────────────────────────────────────────────────────────────┤
│  Lint (full)  →  Test + Coverage  →  SonarCloud Analysis    │
│  Must pass       Must hit 90%        Must pass Quality Gate │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    PR Validation                             │
├─────────────────────────────────────────────────────────────┤
│  Status checks must pass before merge                        │
│  [SOC2-CC8] Audit trail of all quality checks               │
└─────────────────────────────────────────────────────────────┘
```

---

## Tool Matrix

| Language | Linter | Formatter | Type Check | Static Analysis |
|----------|--------|-----------|------------|-----------------|
| JS/TS | ESLint | Prettier | TypeScript | SonarCloud |
| Python | Ruff | Black/Ruff | mypy | SonarCloud |
| C#/.NET | Roslyn | .editorconfig | Built-in | SonarCloud |
| SQL | SQLFluff | SQLFluff | N/A | SonarCloud |
| Markdown | markdownlint | Prettier | N/A | link-check |
| YAML | yamllint | Prettier | Schema | N/A |
| BAT/SH | shellcheck | shfmt | N/A | shellcheck |

---

## Shared Configuration Strategy

Centralized configs, extended per-project:

```
/.config/
├── eslint/
│   └── base.js           # Shared ESLint rules
├── prettier/
│   └── .prettierrc       # Shared Prettier config
├── ruff/
│   └── ruff.toml         # Shared Ruff config
├── sonar/
│   └── sonar-project.properties  # Template
└── editorconfig/
    └── .editorconfig     # Shared editor settings
```

Per-project extends:
```javascript
// apps/web-portal/.eslintrc.js
module.exports = {
  extends: ['../../.config/eslint/base.js'],
  // Project-specific overrides
};
```

---

## SonarCloud Quality Gate

Default gate (customize as needed):

| Metric | Condition | Rationale |
|--------|-----------|-----------|
| Coverage | ≥ 90% on new code | High confidence in changes |
| Duplications | < 3% on new code | DRY principle |
| Maintainability | A rating | Technical debt control |
| Reliability | A rating | No new bugs |
| Security | A rating | No new vulnerabilities |
| Security Hotspots | 100% reviewed | `[SOC2-CC7]` |

---

## Pre-commit Hook Setup

### JavaScript/TypeScript (Husky + lint-staged)
```json
// package.json
{
  "husky": {
    "hooks": {
      "pre-commit": "lint-staged",
      "commit-msg": "commitlint -E HUSKY_GIT_PARAMS"
    }
  },
  "lint-staged": {
    "*.{js,ts,tsx}": ["eslint --fix", "prettier --write"],
    "*.{json,md,yml}": ["prettier --write"]
  }
}
```

### Python (pre-commit framework)
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.1.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
```

### .NET (dotnet format)
```xml
<!-- .csproj -->
<Target Name="PreCommit" BeforeTargets="Build">
  <Exec Command="dotnet format --verify-no-changes" />
</Target>
```

---

## VS Code Settings (Team-Shared)

```jsonc
// .vscode/settings.json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "[python]": {
    "editor.defaultFormatter": "charliermarsh.ruff"
  },
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  }
}
```

---

## AI-Assisted Quality (Copilot Chat)

See [AI-ASSISTED-FIXES.md](./AI-ASSISTED-FIXES.md) for prompts like:

- "Fix all ESLint errors in this file"
- "Add JSDoc comments to all exported functions"
- "Refactor to reduce complexity below 10"

---

## Next Steps

1. Setup SonarCloud project ([SONARCLOUD-SETUP.md](./SONARCLOUD-SETUP.md))
2. Configure per-language linting
3. Install pre-commit hooks
4. Verify pipeline integration
