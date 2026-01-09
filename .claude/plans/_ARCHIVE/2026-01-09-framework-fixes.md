# Framework Critical Fixes Plan

**Created:** 2026-01-09
**Updated:** 2026-01-09
**Status:** Phase 4 & 5 Complete
**Goal:** Make Azure DevOps Reference Framework POC-ready

### Summary

Critical fixes, governance enforcement, and bug fixes complete. Framework ready for Azure DevOps testing with proper governance controls.

---

## Phase 1: Critical - Make Pipelines Runnable

### 1.1 Add Variable Imports to Templates

**Status:** DONE
**Files:**

- `.azure-pipelines/templates/ci-cd-full.yml` - added line 123-124
- `.azure-pipelines/templates/ci-only.yml` - added line 54-55

**Note:** Variables added at template level (not stage level) since these are entry points for `extends:`.

### 1.2 Verify/Create ESLint Configs

**Status:** DONE (already existed)
**Files verified:**

- `.azure-pipelines/configs/eslint/base.js`
- `.azure-pipelines/configs/eslint/relaxed.js`
- `.azure-pipelines/configs/eslint/strict.js`

### 1.3 Add Minimal Example Source Code

**Status:** DONE (already existed)
**Target:** `examples/typescript-api/`

Already contains:

- `src/index.ts` - Express app with health + calculator routes
- `src/services/calculator.ts` + `calculator.test.ts` - 15 test cases
- Full package.json, tsconfig.json, jest.config.js, .eslintrc.js

---

## Phase 2: High Priority - Framework Self-Validation

### 2.1 Create Root Pipeline

**Status:** DONE
**File:** `azure-pipelines.yml`

Created pipeline with:

- Governance validation stage (added in Phase 4)
- YAML validation (yamllint)
- JSON validation
- JS config validation
- TOML validation
- TypeScript example build & test

### 2.2 Fix Documentation Path References

**Status:** DONE
**Files:**

- `docs/04-CODE-QUALITY/README.md` - fixed config path references
- `docs/03-PIPELINES/README.md` - fixed template name and example

---

## Phase 3: Medium Priority - Documentation Stubs

### 3.1 Create Priority Docs

**Status:** Pending (deferred)
**Files:**

- `docs/01-GETTING-STARTED/PREREQUISITES.md`
- `docs/01-GETTING-STARTED/FIRST-TIME-SETUP.md`

---

## Phase 4: Governance Enforcement

### 4.1 Create Pipeline Validation Script

**Status:** DONE
**File:** `scripts/validate-pipelines.sh`

**Implemented rules:**

- Must use `extends:` pattern (no direct stages/jobs/steps)
- Must reference approved templates only
- Required parameters validation
- Framework files excluded from checks

### 4.2 Add Governance Stage to Root Pipeline

**Status:** DONE
**File:** `azure-pipelines.yml`

**Changes:**

- Added `Governance` stage as first stage
- Runs validation script
- Checks for extends pattern in project pipelines

### 4.3 Create CODEOWNERS

**Status:** DONE
**File:** `CODEOWNERS`

**Rules:**

- `.azure-pipelines/**` requires @devops-team review
- `**/azure-pipelines.yml` requires @devops-team review
- `scripts/**` requires @devops-team review

### 4.4 Add Pre-commit Hook Config

**Status:** DONE
**File:** `.pre-commit-config.yaml`

**Hooks:**

- YAML validation
- yamllint
- shellcheck
- Pipeline governance validation
- Secret detection (detect-secrets)

---

## Phase 5: Critical Bug Fixes (from Deep Review)

**Total issues found:** 43 (23 critical/high)
**Issues fixed:** 7 critical

### 5.1 Syntax Errors

**Status:** NOT A BUG
**Note:** `''dist''` is valid Azure Pipelines template expression syntax for escaped quotes

### 5.2 Security Gaps

**Status:** DONE

| File | Fix |
|------|-----|
| `jobs/scan-secrets.yml` | Changed to show summary only, not full secret content |
| `jobs/scan-secrets.yml` | TruffleHog `continueOnError` now respects `failOnDetection` param |
| `variables/common.yml` | Added `tool.gitleaks.version` variable |

### 5.3 Logic Errors

**Status:** DONE

| File | Fix |
|------|-----|
| `jobs/scan-dependencies.yml` | Fixed npm audit threshold logic (high takes precedence) |
| `jobs/lint.yml` | Removed `|| true` from shellcheck, proper error handling |
| `jobs/lint.yml` | Fixed yamllint to use explicit config or default, not fallback |

### 5.4 Hardcoded Values

**Status:** PARTIALLY DONE

| File | Status | Notes |
|------|--------|-------|
| `jobs/scan-secrets.yml` | DONE | Uses `$(tool.gitleaks.version)` |
| `templates/cd-databricks.yml` | Deferred | Low priority |
| `variables/common.yml` | Deferred | SonarCloud org intentionally org-specific |

### 5.5 Orphaned/Legacy Files

**Status:** Deferred

Legacy templates kept for backwards compatibility evaluation.

---

## Execution Log

| Date       | Task                        | Status | Notes                                    |
| ---------- | --------------------------- | ------ | ---------------------------------------- |
| 2026-01-09 | Plan created                | Done   | Quality review complete                  |
| 2026-01-09 | Variable imports added      | Done   | ci-cd-full.yml, ci-only.yml              |
| 2026-01-09 | ESLint configs verified     | Done   | Already existed (3 levels)               |
| 2026-01-09 | Example source verified     | Done   | typescript-api already complete          |
| 2026-01-09 | Root pipeline created       | Done   | Validates YAML, JSON, JS, TOML + tests   |
| 2026-01-09 | Documentation paths fixed   | Done   | CODE-QUALITY + PIPELINES READMEs         |
| 2026-01-09 | Phase 1 & 2 finalized       | Done   | POC-ready, Phase 3 deferred              |
| 2026-01-09 | Deep integrity review       | Done   | Found 43 issues, 23 critical/high        |
| 2026-01-09 | Validation script created   | Done   | scripts/validate-pipelines.sh            |
| 2026-01-09 | CODEOWNERS created          | Done   | Requires @devops-team review             |
| 2026-01-09 | Pre-commit config created   | Done   | .pre-commit-config.yaml                  |
| 2026-01-09 | Governance stage added      | Done   | First stage in root pipeline             |
| 2026-01-09 | Security gaps fixed         | Done   | Secret exposure, continueOnError         |
| 2026-01-09 | Logic errors fixed          | Done   | npm audit, shellcheck, yamllint          |
| 2026-01-09 | Gitleaks version extracted  | Done   | Now in common.yml                        |

---

## Validation Checklist

Before testing in Azure DevOps:

- [x] Variable templates imported in ci-cd-full.yml
- [x] Variable templates imported in ci-only.yml
- [x] ESLint configs exist (3 levels)
- [x] typescript-api example has source code
- [x] Root azure-pipelines.yml created
- [x] Documentation paths corrected
- [x] Governance validation script created
- [x] CODEOWNERS file created
- [x] Pre-commit hooks configured
- [x] Critical security gaps fixed
- [x] Critical logic errors fixed

## Remaining Work

- [ ] Create stub documentation files (PREREQUISITES.md, etc.)
- [ ] Add python-etl example source code
- [ ] Add dotnet-api example source code
- [ ] Parameterize hardcoded "Barings, LLC" in stylecop.json
- [ ] Evaluate orphaned legacy templates for removal
- [ ] Test full pipeline execution in Azure DevOps

---

## Related Documents

- [Testing Steps](./2026-01-09-testing-steps.md) - Azure DevOps POC testing guide

## Files Created/Modified This Session

**New Files:**
- `scripts/validate-pipelines.sh` - Governance validation script
- `CODEOWNERS` - Code review requirements
- `.pre-commit-config.yaml` - Pre-commit hooks

**Modified Files:**
- `azure-pipelines.yml` - Added Governance stage
- `.azure-pipelines/jobs/lint.yml` - Fixed shellcheck and yamllint
- `.azure-pipelines/jobs/scan-secrets.yml` - Fixed security gaps
- `.azure-pipelines/jobs/scan-dependencies.yml` - Fixed audit logic
- `.azure-pipelines/variables/common.yml` - Added gitleaks version
