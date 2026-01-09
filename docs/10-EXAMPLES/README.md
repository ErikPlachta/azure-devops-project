# Examples

Working code snippets, templates, and reference implementations.

---

## Directory Structure

```
/docs/10-EXAMPLES/
├── pipelines/                    # Pipeline templates
│   ├── ci-js-ts.yml
│   ├── ci-python.yml
│   ├── ci-dotnet.yml
│   ├── cd-appservice.yml
│   ├── cd-appservice-container.yml
│   ├── cd-databricks.yml
│   └── cd-powerbi.yml
├── configs/                      # Shared configurations
│   ├── eslint/
│   ├── prettier/
│   ├── ruff/
│   ├── sonar/
│   └── editorconfig/
├── quality-gates/                # Quality gate scripts
│   ├── coverage-check.sh
│   ├── lint-check.sh
│   └── security-scan.sh
├── tests/                        # Test examples
│   ├── unit/
│   ├── integration/
│   ├── e2e/
│   └── performance/
├── documentation/                # Doc generation configs
│   ├── typedoc.json
│   ├── sphinx-conf.py
│   └── docfx.json
├── mono-repo/                    # Mono-repo template
│   └── (full structure)
└── multi-repo/                   # Multi-repo template
    └── (example per-repo setup)
```

---

## Quick Reference

### Pipeline Templates

| Example | Path | Use Case |
|---------|------|----------|
| JS/TS CI | [pipelines/ci-js-ts.yml](./pipelines/ci-js-ts.yml) | Node.js build, test, lint |
| Python CI | [pipelines/ci-python.yml](./pipelines/ci-python.yml) | Python build, test, lint |
| .NET CI | [pipelines/ci-dotnet.yml](./pipelines/ci-dotnet.yml) | .NET build, test, lint |
| App Service CD | [pipelines/cd-appservice.yml](./pipelines/cd-appservice.yml) | Direct deploy |
| Container CD | [pipelines/cd-appservice-container.yml](./pipelines/cd-appservice-container.yml) | Docker deploy |
| Databricks CD | [pipelines/cd-databricks.yml](./pipelines/cd-databricks.yml) | Asset Bundle deploy |
| Power BI CD | [pipelines/cd-powerbi.yml](./pipelines/cd-powerbi.yml) | REST/XMLA deploy |
| SharePoint CD | [/examples/gpf-pm-module](../../examples/gpf-pm-module) | File sync to document library |

### Configuration Examples

| Example | Path | Use Case |
|---------|------|----------|
| ESLint (base) | [configs/eslint/base.js](./configs/eslint/base.js) | Shared JS/TS rules |
| Prettier | [configs/prettier/.prettierrc](./configs/prettier/.prettierrc) | Code formatting |
| Ruff | [configs/ruff/ruff.toml](./configs/ruff/ruff.toml) | Python linting |
| SonarCloud | [configs/sonar/sonar-project.properties](./configs/sonar/sonar-project.properties) | Static analysis |
| EditorConfig | [configs/editorconfig/.editorconfig](./configs/editorconfig/.editorconfig) | Editor settings |

---

## Sample: CI Pipeline (JS/TS)

```yaml
# pipelines/ci-js-ts.yml
trigger:
  branches:
    include:
      - main
      - develop
      - feature/*
  paths:
    include:
      - 'apps/web-portal/**'
      - 'libs/utils-js/**'

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: sonarcloud-barings
  - name: nodeVersion
    value: '20.x'
  - name: coverageThreshold
    value: 90

stages:
  - stage: Build
    jobs:
      - job: BuildAndTest
        steps:
          - task: NodeTool@0
            inputs:
              versionSpec: $(nodeVersion)

          - task: Cache@2
            inputs:
              key: 'npm | "$(Agent.OS)" | package-lock.json'
              path: $(npm_config_cache)
            displayName: 'Cache npm'

          - script: npm ci
            displayName: 'Install dependencies'

          - script: npm run lint
            displayName: 'Lint'

          - script: npm run build
            displayName: 'Build'

          - script: npm run test -- --coverage --reporters=default --reporters=jest-junit
            displayName: 'Test with coverage'

          - task: PublishTestResults@2
            inputs:
              testResultsFiles: '**/junit.xml'
              testRunTitle: 'Unit Tests'

          - task: PublishCodeCoverageResults@1
            inputs:
              codeCoverageTool: 'Cobertura'
              summaryFileLocation: '**/coverage/cobertura-coverage.xml'

          - script: |
              COVERAGE=$(cat coverage/coverage-summary.json | jq '.total.lines.pct')
              echo "Coverage: $COVERAGE%"
              if (( $(echo "$COVERAGE < $(coverageThreshold)" | bc -l) )); then
                echo "##vso[task.logissue type=error]Coverage $COVERAGE% is below threshold $(coverageThreshold)%"
                exit 1
              fi
            displayName: 'Coverage gate'

  - stage: Scan
    dependsOn: Build
    jobs:
      - job: SonarCloud
        steps:
          - task: SonarCloudPrepare@1
            inputs:
              SonarCloud: 'sonarcloud-barings'
              organization: 'barings'
              scannerMode: 'CLI'
              configMode: 'file'

          - task: SonarCloudAnalyze@1

          - task: SonarCloudPublish@1
            inputs:
              pollingTimeoutSec: '300'

  - stage: Artifacts
    dependsOn: Scan
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - job: PublishArtifact
        steps:
          - task: ArchiveFiles@2
            inputs:
              rootFolderOrFile: 'dist'
              archiveFile: '$(Build.ArtifactStagingDirectory)/$(Build.BuildId).zip'

          - task: PublishBuildArtifacts@1
            inputs:
              pathToPublish: '$(Build.ArtifactStagingDirectory)'
              artifactName: 'drop'
```

---

## Sample: CD Pipeline (App Service)

```yaml
# pipelines/cd-appservice.yml
trigger: none

resources:
  pipelines:
    - pipeline: ci
      source: 'CI-WebPortal'
      trigger:
        branches:
          include:
            - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: kv-barings-$(environment)
  - name: appName
    value: 'app-webportal-$(environment)'

stages:
  - stage: DeployUT
    condition: eq(variables['Build.SourceBranch'], 'refs/heads/develop')
    variables:
      environment: ut
    jobs:
      - deployment: Deploy
        environment: 'barings-ut'
        strategy:
          runOnce:
            deploy:
              steps:
                - download: ci
                  artifact: drop

                - task: AzureWebApp@1
                  inputs:
                    azureSubscription: 'barings-ut'
                    appName: $(appName)
                    package: '$(Pipeline.Workspace)/ci/drop/*.zip'
                    deploymentMethod: 'runFromPackage'

                - task: AzureAppServiceManage@0
                  inputs:
                    azureSubscription: 'barings-ut'
                    action: 'Start Azure App Service'
                    webAppName: $(appName)

                - script: |
                    response=$(curl -s -o /dev/null -w "%{http_code}" https://$(appName).azurewebsites.net/health)
                    if [ "$response" != "200" ]; then
                      echo "##vso[task.logissue type=error]Health check failed: $response"
                      exit 1
                    fi
                  displayName: 'Smoke test'

  - stage: DeployST
    condition: eq(variables['Build.SourceBranch'], 'refs/heads/release/*')
    variables:
      environment: st
    jobs:
      - deployment: Deploy
        environment: 'barings-st'
        strategy:
          runOnce:
            deploy:
              steps:
                # Same as UT with environment-specific values
                - download: ci
                  artifact: drop
                - task: AzureWebApp@1
                  inputs:
                    azureSubscription: 'barings-st'
                    appName: 'app-webportal-st'
                    package: '$(Pipeline.Workspace)/ci/drop/*.zip'

  - stage: DeployPR
    condition: eq(variables['Build.SourceBranch'], 'refs/heads/main')
    variables:
      environment: pr
    jobs:
      - deployment: Deploy
        environment: 'barings-pr'  # Requires approval
        strategy:
          runOnce:
            deploy:
              steps:
                - download: ci
                  artifact: drop
                - task: AzureWebApp@1
                  inputs:
                    azureSubscription: 'barings-pr'
                    appName: 'app-webportal-pr'
                    package: '$(Pipeline.Workspace)/ci/drop/*.zip'
                    deployToSlotOrASE: true
                    slotName: 'staging'

                # Swap after validation
                - task: AzureAppServiceManage@0
                  inputs:
                    azureSubscription: 'barings-pr'
                    action: 'Swap Slots'
                    webAppName: 'app-webportal-pr'
                    sourceSlot: 'staging'
                    targetSlot: 'production'
```

---

## Sample: ESLint Configuration

```javascript
// configs/eslint/base.js
module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 2022,
    sourceType: 'module',
  },
  plugins: ['@typescript-eslint', 'jsdoc'],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:jsdoc/recommended-typescript',
    'prettier', // Must be last
  ],
  rules: {
    // Documentation enforcement
    'jsdoc/require-jsdoc': ['error', {
      require: {
        FunctionDeclaration: true,
        MethodDefinition: true,
        ClassDeclaration: true,
      },
      publicOnly: true,
    }],
    'jsdoc/require-description': 'error',
    'jsdoc/require-param': 'error',
    'jsdoc/require-returns': 'error',

    // Code quality
    '@typescript-eslint/explicit-function-return-type': 'error',
    '@typescript-eslint/no-unused-vars': 'error',
    '@typescript-eslint/no-explicit-any': 'warn',
    'no-console': 'warn',
    'complexity': ['warn', 10],
  },
  ignorePatterns: ['dist/', 'node_modules/', 'coverage/', '*.config.js'],
};
```

---

## Sample: Test Examples

```typescript
// tests/unit/services/cart.test.ts
import { CartService } from '../../../src/services/cart';
import { CartItem } from '../../../src/types';

describe('CartService', () => {
  describe('calculateTotal', () => {
    it('returns zero for empty cart', () => {
      const service = new CartService();
      const result = service.calculateTotal([], 0.08);
      expect(result).toBe(0);
    });

    it('calculates total with tax correctly', () => {
      const items: CartItem[] = [
        { id: '1', name: 'Item', price: 100, quantity: 2 },
      ];
      const service = new CartService();
      const result = service.calculateTotal(items, 0.08);
      expect(result).toBe(216); // 200 * 1.08
    });

    it('throws on negative tax rate', () => {
      const service = new CartService();
      expect(() => service.calculateTotal([], -0.1)).toThrow('Invalid tax rate');
    });
  });
});
```

```python
# tests/unit/test_transform.py
import pytest
from src.transform import calculate_balance

class TestCalculateBalance:
    def test_returns_zero_for_no_transactions(self):
        result = calculate_balance([])
        assert result == 0

    def test_calculates_sum_correctly(self):
        transactions = [100, -30, 50]
        result = calculate_balance(transactions)
        assert result == 120

    def test_raises_on_invalid_input(self):
        with pytest.raises(TypeError):
            calculate_balance("not a list")
```

---

## Next Steps

1. Copy relevant templates to your project
2. Modify for your specific needs
3. Reference from pipeline YAML using `extends`
