# Azure DevOps POC Testing Steps

**Created:** 2026-01-09
**Related:** 2026-01-09-framework-fixes.md

---

## Prerequisites

1. **Azure DevOps Project** with Pipelines enabled
2. **Service Connections** configured:
   - Azure subscription (for deployments)
   - SonarCloud (if using scan jobs)

---

## Step 1: Push to Azure DevOps

```bash
# Add Azure DevOps remote (if not already)
git remote add azdo https://dev.azure.com/{org}/{project}/_git/{repo}

# Push
git push azdo main
```

---

## Step 2: Create Variable Group

In Azure DevOps → Pipelines → Library:

1. Create group `sonarcloud-barings` with:
   - `sonar.organization` = your SonarCloud org
   - `sonar.projectKey` = project key
   - `sonar.token` = SonarCloud token (secret)

_Or_ disable SonarCloud in test runs by setting `runSonar: false`

---

## Step 3: Create Pipeline (Framework Validation)

1. Pipelines → New Pipeline
2. Select your repo
3. Choose "Existing Azure Pipelines YAML"
4. Select `/azure-pipelines.yml` (root)
5. Run

This validates all configs + builds typescript-api example.

---

## Step 4: Test Example Pipeline

1. Pipelines → New Pipeline
2. Select "Existing Azure Pipelines YAML"
3. Select `/examples/typescript-api/azure-pipelines.yml`
4. **Before running**, edit to disable deployments:

```yaml
extends:
  template: /.azure-pipelines/templates/ci-only.yml # Changed from ci-cd-full
  parameters:
    language: typescript
    workingDirectory: examples/typescript-api
    configLevel: strict
    runSonar: false # Disable until SonarCloud configured
```

5. Run

---

## Step 5: Verify Results

Check pipeline run for:

- [ ] Lint job passes
- [ ] Test job passes (coverage reported)
- [ ] Build artifact created
- [ ] No undefined variable errors

---

## Quick Local Validation First

```bash
cd examples/typescript-api
npm ci
npm run lint
npm run build
npm test
```

---

## Troubleshooting

| Issue                            | Fix                                                 |
| -------------------------------- | --------------------------------------------------- |
| `$(tool.node.version)` undefined | Variable template not imported - verify fix applied |
| SonarCloud auth fail             | Set `runSonar: false` or configure variable group   |
| ESLint config not found          | Check `.azure-pipelines/configs/eslint/` exists     |

---

## Next Steps After Successful Test

1. Configure SonarCloud integration
2. Create environment approvals (UT, ST, PR)
3. Test full CI/CD with `ci-cd-full.yml`
4. Add python-etl and dotnet-api examples
