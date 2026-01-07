# Governance

Branch policies, work items, audit trails, and cost management.

---

## Documents in This Section

| Document | Purpose |
|----------|---------|
| [GOVERNANCE-OVERVIEW.md](./GOVERNANCE-OVERVIEW.md) | Principles, enforcement philosophy |
| [BRANCH-POLICIES.md](./BRANCH-POLICIES.md) | Protection rules, reviewers, build validation |
| [BRANCH-STRATEGY.md](./BRANCH-STRATEGY.md) | Branching model (GitFlow variant) |
| [PR-PROCESS.md](./PR-PROCESS.md) | Review guidelines, merge requirements |
| [WORK-ITEM-LINKING.md](./WORK-ITEM-LINKING.md) | Traceability from commit to requirement |
| [AUDIT-TRAILS.md](./AUDIT-TRAILS.md) | What's logged, retention, compliance |
| [COST-MANAGEMENT.md](./COST-MANAGEMENT.md) | Pipeline costs, optimization, budgets |
| [CHANGE-MANAGEMENT.md](./CHANGE-MANAGEMENT.md) | Production change process |

---

## Branch Strategy

```
main (PR - Production)
 │
 ├── release/1.2.0 (ST - Staging)
 │    │
 │    └── feature/ABC-123-add-login
 │    └── feature/ABC-124-fix-header
 │
 └── develop (UT - Development)
      │
      └── feature/ABC-125-new-api
      └── bugfix/ABC-126-null-check
```

| Branch | Environment | Purpose | Merge Target |
|--------|-------------|---------|--------------|
| `main` | PR | Production-ready | N/A (protected) |
| `release/*` | ST | Release candidate | `main` |
| `develop` | UT | Integration | `release/*` |
| `feature/*` | Local/UT | New work | `develop` |
| `bugfix/*` | Local/UT | Bug fixes | `develop` |
| `hotfix/*` | ST→PR | Emergency fixes | `main` + `develop` |

---

## Branch Policies

### `main` Branch
| Policy | Setting | Rationale |
|--------|---------|-----------|
| Require PR | ✅ | No direct pushes `[SOC2-CC8]` |
| Min reviewers | 2 | Four-eyes principle |
| Build validation | ✅ | CI must pass |
| Work item linking | ✅ | Traceability `[SOC2-CC8]` |
| Comment resolution | All resolved | No open issues |
| Merge strategy | Squash | Clean history |
| Reset on push | ✅ | New commits require re-review |

### `develop` Branch
| Policy | Setting |
|--------|---------|
| Require PR | ✅ |
| Min reviewers | 1 |
| Build validation | ✅ |
| Work item linking | ✅ |

### `release/*` Branches
| Policy | Setting |
|--------|---------|
| Require PR | ✅ |
| Min reviewers | 2 |
| Build validation | ✅ |
| Include code owners | ✅ |

---

## Work Item Linking

All commits must reference a work item:

```
feat(api): add user authentication

Implements OAuth2 flow with Azure AD integration.

AB#12345
```

### Commit Message Format
```
type(scope): description

[optional body]

AB#<work-item-id>
```

See [../STANDARDS/SEMANTIC-NAMING.md](../STANDARDS/SEMANTIC-NAMING.md) for full specification.

### Enforcement

```yaml
# Pipeline step to verify work item link
- script: |
    COMMIT_MSG=$(git log -1 --format=%B)
    if ! echo "$COMMIT_MSG" | grep -qE "AB#[0-9]+"; then
      echo "##vso[task.logissue type=error]Commit must reference work item (AB#xxxxx)"
      exit 1
    fi
```

---

## PR Process

### Before Creating PR
- [ ] Code compiles/builds locally
- [ ] All tests pass locally
- [ ] Linting passes
- [ ] Documentation updated (if applicable)
- [ ] Work item linked

### PR Template
```markdown
## Summary
[Brief description of changes]

## Related Work Items
AB#[work-item-id]

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No secrets committed
```

### Review Guidelines
| Reviewer Focus | Check For |
|----------------|-----------|
| Code quality | Readability, maintainability, patterns |
| Security | Injection, secrets, vulnerabilities |
| Performance | N+1 queries, memory leaks, efficiency |
| Testing | Coverage, edge cases, assertions |
| Documentation | Updated, accurate, complete |

---

## Audit Trails

`[SOC2-CC8]` All changes tracked and auditable.

### What's Logged

| Event | Location | Retention |
|-------|----------|-----------|
| Code changes | Git history | Permanent |
| PR reviews | Azure DevOps | 7 years |
| Pipeline runs | Azure DevOps | 2 years |
| Deployments | Pipeline logs + Azure Activity | 7 years |
| Access changes | Azure AD + DevOps audit | 7 years |
| Secret access | Key Vault logs | 7 years |

### Audit Query Examples
```
# Azure DevOps audit logs
https://dev.azure.com/{org}/_settings/audit

# Filter by user
TargetUser eq 'user@barings.com'

# Filter by action
Action eq 'Git.PushSucceeded'
```

---

## Cost Management

### Pipeline Cost Factors

| Factor | Impact | Optimization |
|--------|--------|--------------|
| Parallel jobs | Higher cost, faster | Balance based on need |
| Build minutes | Per-minute cost | Caching, affected-only builds |
| Artifacts storage | Per-GB cost | Retention policies |
| Self-hosted agents | Lower runtime cost | Initial setup investment |

### Cost Estimation

| Scenario | MS-Hosted (est.) | Self-Hosted (est.) |
|----------|------------------|---------------------|
| 100 builds/month, 10min avg | ~$150/month | ~$50/month + VM |
| 500 builds/month, 15min avg | ~$1,125/month | ~$200/month + VM |
| 1000 builds/month, 10min avg | ~$1,500/month | ~$300/month + VM |

### Optimization Strategies

```yaml
# Caching dependencies
- task: Cache@2
  inputs:
    key: 'npm | "$(Agent.OS)" | package-lock.json'
    path: $(npm_config_cache)

# Affected-only builds (Nx)
- script: npx nx affected --target=build --base=origin/main
```

---

## Change Management (Production)

`[SOC2-CC8]` Production changes require formal process.

### Standard Change
1. Work item created and approved
2. Code complete with tests
3. PR approved (2 reviewers)
4. Pipeline passes all gates
5. Deploy to ST, acceptance testing
6. Deploy to PR with approval

### Emergency Change
1. Create hotfix branch from `main`
2. Implement fix with minimal scope
3. Expedited review (1 senior reviewer)
4. Deploy directly to PR
5. Backport to `develop`
6. Document in incident report

### Change Windows
| Environment | Window | Approval |
|-------------|--------|----------|
| UT | Anytime | Auto |
| ST | Business hours | Tech Lead |
| PR | Scheduled windows | Change Board |

---

## Next Steps

1. Configure branch policies in Azure DevOps
2. Setup PR templates
3. Configure audit log exports
4. Establish change windows and approval matrix
