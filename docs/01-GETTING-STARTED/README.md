# Getting Started

Onboarding guide for developers, tech leads, and stakeholders.

---

## Prerequisites

### Required Access

- [ ] Azure DevOps project membership
- [ ] Azure subscription (appropriate role)
- [ ] SonarCloud organization access
- [ ] Key Vault read access (for local dev secrets)

### Local Tools

- [ ] Git 2.40+
- [ ] VS Code with extensions (see [Extensions List](./VSCODE-EXTENSIONS.md))
- [ ] Language-specific SDKs (see per-language sections)
- [ ] Azure CLI
- [ ] Databricks CLI (if working with Databricks)

---

## Documents in This Section

| Document                                               | Audience   | Purpose                                       |
| ------------------------------------------------------ | ---------- | --------------------------------------------- |
| [PREREQUISITES.md](./PREREQUISITES.md)                 | All        | Detailed install/access requirements          |
| [VSCODE-EXTENSIONS.md](./VSCODE-EXTENSIONS.md)         | Developers | Required/recommended extensions               |
| [FIRST-TIME-SETUP.md](./FIRST-TIME-SETUP.md)           | Developers | Clone, configure, validate setup              |
| [AZURE-DEVOPS-OVERVIEW.md](./AZURE-DEVOPS-OVERVIEW.md) | All        | Project structure, boards, repos, pipelines   |
| [SERVICE-CONNECTIONS.md](./SERVICE-CONNECTIONS.md)     | DevOps     | How service connections work, setup reference |
| [LOCAL-DEV-SECRETS.md](./LOCAL-DEV-SECRETS.md)         | Developers | Key Vault integration for local dev           |

---

## Quick Start (5 min)

```bash
# 1. Clone repo
git clone https://dev.azure.com/barings/PROJECT/_git/REPO

# 2. Install dependencies (example for Node.js)
npm ci

# 3. Setup local secrets
az login
az keyvault secret show --vault-name kv-barings-ut --name my-secret

# 4. Verify setup
npm run lint
npm run test
```

---

## Environment Overview

| Environment | Branch                 | Purpose             | Deployment                       |
| ----------- | ---------------------- | ------------------- | -------------------------------- |
| UT          | `feature/*`, `develop` | Development/testing | Auto on PR merge                 |
| ST          | `release/*`            | Staging/UAT         | Manual approval                  |
| PR          | `main`                 | Production          | Manual approval + change request |

---

## Next Steps

1. Complete [PREREQUISITES.md](./PREREQUISITES.md)
2. Follow [FIRST-TIME-SETUP.md](./FIRST-TIME-SETUP.md)
3. Read [../02-ARCHITECTURE/README.md](../02-ARCHITECTURE/README.md) for codebase structure
4. Review [../04-CODE-QUALITY/README.md](../04-CODE-QUALITY/README.md) before first commit
