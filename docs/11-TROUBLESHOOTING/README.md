# Troubleshooting

Common issues, FAQs, and escalation paths.

---

## Documents in This Section

| Document | Purpose |
|----------|---------|
| [COMMON-ISSUES.md](./COMMON-ISSUES.md) | Frequently encountered problems |
| [PIPELINE-ERRORS.md](./PIPELINE-ERRORS.md) | CI/CD failure resolution |
| [SONARCLOUD-ISSUES.md](./SONARCLOUD-ISSUES.md) | Quality gate failures |
| [DEPLOYMENT-ISSUES.md](./DEPLOYMENT-ISSUES.md) | Deploy failures per platform |
| [ESCALATION.md](./ESCALATION.md) | Who to contact, when |

---

## Quick Fixes

### Pipeline Won't Trigger

| Symptom | Cause | Fix |
|---------|-------|-----|
| No trigger on push | Path filters exclude changes | Check `paths.include` in YAML |
| PR validation not running | Branch policies not set | Configure in Repo Settings → Policies |
| Scheduled run missing | Cron syntax wrong | Use [crontab.guru](https://crontab.guru) to validate |

### Build Failures

| Error | Cause | Fix |
|-------|-------|-----|
| `npm ci` fails | Lock file mismatch | Delete `node_modules`, run `npm install`, commit lock |
| `dotnet restore` fails | NuGet feed auth | Check service connection to Azure Artifacts |
| `pip install` fails | Package not found | Check `requirements.txt` spelling, PyPI availability |

### Test Failures

| Error | Cause | Fix |
|-------|-------|-----|
| Coverage below threshold | New code not tested | Add tests for uncovered lines |
| Tests pass locally, fail in CI | Environment difference | Check Node/Python version, env vars |
| Flaky tests | Race conditions, timing | Add proper waits, mock external calls |

### SonarCloud Issues

| Error | Cause | Fix |
|-------|-------|-----|
| Quality gate failed | New issues introduced | Fix issues shown in SonarCloud dashboard |
| "Not enough memory" | Large codebase | Increase `sonar.javascript.node.maxspace` |
| Coverage not showing | Report not found | Check coverage report path in config |

### Deployment Failures

| Platform | Error | Fix |
|----------|-------|-----|
| App Service | "Deployment failed" | Check deployment logs in Kudu (SCM site) |
| App Service | 5xx after deploy | Check Application Insights for exceptions |
| Databricks | "Token expired" | Rotate token in Key Vault |
| Databricks | "Workspace not found" | Verify host URL in pipeline variables |
| Power BI | "Unauthorized" | Refresh service principal credentials |

---

## Diagnostic Commands

### Pipeline Debug
```yaml
# Add to pipeline for debugging
- script: |
    echo "Build.SourceBranch: $(Build.SourceBranch)"
    echo "Build.Reason: $(Build.Reason)"
    echo "System.PullRequest.SourceBranch: $(System.PullRequest.SourceBranch)"
    env
  displayName: 'Debug info'
```

### Local Reproduction
```bash
# Reproduce pipeline locally (JS)
npm ci
npm run lint
npm run test -- --coverage
npm run build

# Check coverage threshold
cat coverage/coverage-summary.json | jq '.total.lines.pct'
```

### SonarCloud Local Scan
```bash
# Run SonarCloud analysis locally
npx sonar-scanner \
  -Dsonar.projectKey=barings_myproject \
  -Dsonar.organization=barings \
  -Dsonar.sources=src \
  -Dsonar.host.url=https://sonarcloud.io \
  -Dsonar.login=$SONAR_TOKEN
```

---

## FAQ

### General

**Q: How do I add a new language/framework?**
A:
1. Add linting config to `/.config/`
2. Create pipeline template in `/.azure-pipelines/templates/`
3. Document in relevant sections
4. Update INDEX.md language matrix

**Q: How do I skip CI for a commit?**
A: Add `[skip ci]` to commit message. Use sparingly.

**Q: How do I re-run a failed pipeline?**
A: Click "Rerun" in Azure DevOps. For specific stages, use "Rerun failed jobs".

### Branching

**Q: I need to hotfix production urgently**
A:
1. Create `hotfix/ABC-xxx-description` from `main`
2. Implement minimal fix
3. Get expedited review (1 senior reviewer)
4. Merge to `main` and `develop`
5. Document in incident report

**Q: My PR shows merge conflicts**
A:
1. Fetch latest target branch: `git fetch origin develop`
2. Rebase: `git rebase origin/develop`
3. Resolve conflicts
4. Force push: `git push --force-with-lease`

### Testing

**Q: How do I exclude a file from coverage?**
A:
```javascript
// jest.config.js
coveragePathIgnorePatterns: ['/path/to/exclude/']
```

**Q: Tests timeout in CI but pass locally**
A: CI may be slower. Increase timeout:
```javascript
jest.setTimeout(30000); // 30 seconds
```

### SonarCloud

**Q: How do I suppress a false positive?**
A:
```javascript
// For single line:
const x = eval(code); // NOSONAR: reason

// For block (in SonarCloud UI):
// Mark as "Won't Fix" with explanation
```

**Q: Quality gate keeps failing on old code**
A: Configure to only check new code:
- SonarCloud → Project Settings → Quality Gate → "Sonar way" (new code only)

### Deployment

**Q: How do I rollback a deployment?**
A:
- App Service: Swap slots back, or redeploy previous artifact
- Databricks: Redeploy previous version via DAB
- Power BI: Restore from backup dataset

**Q: Deployment succeeds but app doesn't work**
A:
1. Check Application Insights / logs
2. Verify environment variables set correctly
3. Check health endpoint
4. Review recent code changes

---

## Escalation Matrix

| Issue Type | First Contact | Escalate To | SLA |
|------------|---------------|-------------|-----|
| Pipeline failure | Self-service (this guide) | DevOps Team | 4 hours |
| Security vulnerability | DevOps Team | Security Team | 1 hour |
| Production outage | On-call engineer | Incident Commander | 15 min |
| Access issues | IT Help Desk | DevOps Team | 8 hours |
| Compliance question | DevOps Team | Compliance Officer | 24 hours |

### Contact Channels

| Team | Channel | Hours |
|------|---------|-------|
| DevOps | Teams: #devops-support | Business hours |
| Security | Email: security@barings.com | 24/7 for critical |
| On-call | PagerDuty | 24/7 |

---

## Logging and Monitoring

### Where to Find Logs

| Component | Location |
|-----------|----------|
| Pipeline runs | Azure DevOps → Pipelines → Runs |
| App Service | Azure Portal → App Service → Log stream |
| Databricks | Workspace → Jobs → Run history |
| Power BI | Azure Portal → Power BI Embedded → Metrics |
| Key Vault access | Azure Portal → Key Vault → Diagnostic logs |

### Setting Up Alerts

```yaml
# Azure Monitor alert (ARM template snippet)
{
  "type": "Microsoft.Insights/metricAlerts",
  "properties": {
    "criteria": {
      "odata.type": "Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria",
      "allOf": [{
        "name": "HighErrorRate",
        "metricName": "Http5xx",
        "operator": "GreaterThan",
        "threshold": 10,
        "timeAggregation": "Total"
      }]
    }
  }
}
```

---

## Next Steps

1. Bookmark this page
2. Try self-service fixes first
3. Escalate if blocked >30 minutes
4. Contribute fixes back to this guide
