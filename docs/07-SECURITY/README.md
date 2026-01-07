# Security

Secrets management, RBAC, scanning, and compliance controls.

---

## Documents in This Section

| Document | Purpose |
|----------|---------|
| [SECURITY-OVERVIEW.md](./SECURITY-OVERVIEW.md) | Security principles, threat model |
| [KEY-VAULT-SETUP.md](./KEY-VAULT-SETUP.md) | Azure Key Vault configuration |
| [SECRETS-IN-PIPELINES.md](./SECRETS-IN-PIPELINES.md) | Variable groups, Key Vault linking |
| [LOCAL-DEV-SECRETS.md](./LOCAL-DEV-SECRETS.md) | Developer workstation setup |
| [RBAC-MODEL.md](./RBAC-MODEL.md) | Role definitions, least privilege |
| [SECURITY-SCANNING.md](./SECURITY-SCANNING.md) | SAST, SCA, secrets detection |
| [COMPLIANCE-CONTROLS.md](./COMPLIANCE-CONTROLS.md) | SOC 2, SEC, GDPR mapping |
| [INCIDENT-RESPONSE.md](./INCIDENT-RESPONSE.md) | Security incident procedures |

---

## Security Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Key Vault                           │
│  ─────────────────────────────────────────────────────────  │
│  kv-barings-ut  │  kv-barings-st  │  kv-barings-pr         │
│  [SOC2-CC6]                                                  │
└─────────────────────────────────────────────────────────────┘
         │                  │                  │
         ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────────┐
│                 Azure DevOps Variable Groups                 │
│  ─────────────────────────────────────────────────────────  │
│  Linked to Key Vault, scoped per environment                 │
│  [SOC2-CC6]                                                  │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                    CI/CD Pipeline                            │
│  ─────────────────────────────────────────────────────────  │
│  Secrets injected at runtime, never in logs                  │
│  [SOC2-CC7]                                                  │
└─────────────────────────────────────────────────────────────┘
```

---

## Secrets Management

### Never Do
- ❌ Store secrets in code
- ❌ Commit .env files
- ❌ Log secret values
- ❌ Pass secrets via command line args
- ❌ Store in pipeline YAML

### Always Do
- ✅ Use Azure Key Vault
- ✅ Link variable groups to Key Vault
- ✅ Access via managed identity
- ✅ Rotate secrets regularly
- ✅ Audit access logs

---

## Key Vault Structure

| Vault | Purpose | Access |
|-------|---------|--------|
| `kv-barings-ut` | Development secrets | Developers (read), Pipelines |
| `kv-barings-st` | Staging secrets | Tech Leads, Pipelines |
| `kv-barings-pr` | Production secrets | Ops Team, Pipelines (limited) |

### Secret Naming Convention
```
{service}-{purpose}-{qualifier}

Examples:
- api-gateway-db-connection
- etl-databricks-token
- powerbi-service-principal-secret
```

`[SOC2-CC6]` All vault access logged and auditable.

---

## Pipeline Secrets

```yaml
# Variable group linked to Key Vault
variables:
  - group: kv-barings-$(environment)

steps:
  - script: |
      # Secret available as env var, not logged
      echo "Connecting to database..."
      # $(db-connection-string) is masked in logs
    env:
      DB_CONNECTION: $(db-connection-string)
```

### Secret Masking
Azure DevOps automatically masks variables marked as secret. Additionally:

```yaml
- script: |
    echo "##vso[task.setvariable variable=mySecret;issecret=true]$(sensitiveValue)"
```

---

## RBAC Model

### Azure DevOps Project Roles

| Role | Permissions | Assigned To |
|------|-------------|-------------|
| Project Admin | Full control | DevOps leads |
| Contributors | Code, pipelines, boards | Developers |
| Readers | View only | Stakeholders |
| Build Admin | Pipeline management | CI/CD engineers |

### Key Vault Access Policies

| Role | Secrets | Keys | Certificates |
|------|---------|------|--------------|
| Developer | Get, List (UT only) | None | None |
| Pipeline SP | Get | None | None |
| Ops Team | Get, List, Set | Get, List | Get, List |
| Security Team | Full | Full | Full |

`[SOC2-CC6]` Least privilege principle enforced.

---

## Security Scanning

### Pipeline Integration

```yaml
stages:
  - stage: SecurityScan
    jobs:
      - job: SAST
        steps:
          # SonarCloud handles SAST
          - task: SonarCloudAnalyze@1

      - job: DependencyScan
        steps:
          # Dependency vulnerability scanning
          - script: npm audit --audit-level=high
          - script: pip-audit
          - script: dotnet list package --vulnerable

      - job: SecretScan
        steps:
          # Detect accidentally committed secrets
          - script: |
              npx secretlint "**/*"
              # or: trufflehog git file://. --only-verified
```

### Scanning Matrix

| Scan Type | Tool | Frequency | Gate |
|-----------|------|-----------|------|
| SAST | SonarCloud | Every PR | Block on critical |
| SCA (Dependencies) | npm audit, pip-audit, dotnet | Every PR | Block on high |
| Secrets | secretlint, trufflehog | Every PR | Block on any |
| Container | Trivy | On image build | Block on critical |
| IaC | Checkov | On infra change | Block on high |

---

## Compliance Control Mapping

### SOC 2 Type II

| Control | Implementation | Evidence |
|---------|----------------|----------|
| CC6.1 - Logical Access | Azure AD + RBAC | Access reviews, audit logs |
| CC6.2 - Access Removal | Automated deprovisioning | HR integration logs |
| CC6.3 - Access Authorization | PR approvals, branch policies | Pipeline history |
| CC7.1 - System Monitoring | Azure Monitor, Log Analytics | Dashboards, alerts |
| CC7.2 - Anomaly Detection | SonarCloud, security scans | Scan reports |
| CC8.1 - Change Authorization | PR process, approvals | ADO history |

### SEC 17a-4 (Record Retention)
| Requirement | Implementation |
|-------------|----------------|
| Immutable records | Azure Immutable Blob Storage |
| Retention period | 7 years (configurable) |
| Audit trail | Git history, pipeline logs |

### GDPR Article 32
| Requirement | Implementation |
|-------------|----------------|
| Encryption at rest | Key Vault, Azure encryption |
| Encryption in transit | TLS 1.2+ enforced |
| Access controls | RBAC, least privilege |
| Audit logging | Azure Monitor |

`[GDPR-Art32]` All personal data handling documented and auditable.

---

## .gitignore Security

```gitignore
# Secrets - NEVER commit
.env
.env.*
*.pem
*.key
credentials.json
secrets.json
*.pfx
appsettings.*.json  # If contains secrets

# IDE/tool configs that may contain secrets
.idea/
.vscode/settings.json  # Use settings.json.template
```

---

## Pre-commit Secret Detection

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/secretlint/secretlint
    rev: v7.0.0
    hooks:
      - id: secretlint
```

---

## Next Steps

1. Setup Key Vaults per environment
2. Create variable groups linked to Key Vault
3. Configure RBAC policies
4. Enable security scanning in pipelines
5. Review compliance mapping with security team
