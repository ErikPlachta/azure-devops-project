# Testing

Testing strategy, coverage requirements, and validation approaches.

---

## Documents in This Section

| Document | Purpose |
|----------|---------|
| [TESTING-STRATEGY.md](./TESTING-STRATEGY.md) | Philosophy, pyramid, risk-based approach |
| [COVERAGE-REQUIREMENTS.md](./COVERAGE-REQUIREMENTS.md) | Thresholds, exclusions, reporting |
| [TEST-DATA-MANAGEMENT.md](./TEST-DATA-MANAGEMENT.md) | Fixtures, factories, anonymization |
| [MOCKING-STRATEGIES.md](./MOCKING-STRATEGIES.md) | When/how to mock, test doubles |

### By Testing Type
| Document | Purpose |
|----------|---------|
| [SMOKE-TESTING.md](./SMOKE-TESTING.md) | Critical path validation post-deploy |
| [UNIT-TESTING.md](./UNIT-TESTING.md) | Code-level testing, 90% coverage |
| [INTEGRATION-TESTING.md](./INTEGRATION-TESTING.md) | Module/service interaction |
| [CONTRACT-TESTING.md](./CONTRACT-TESTING.md) | Consumer-driven contracts (Pact) |
| [REGRESSION-TESTING.md](./REGRESSION-TESTING.md) | Preventing unintended breakage |
| [E2E-TESTING.md](./E2E-TESTING.md) | User journey validation |
| [ACCEPTANCE-TESTING.md](./ACCEPTANCE-TESTING.md) | Business requirement verification |
| [PERFORMANCE-TESTING.md](./PERFORMANCE-TESTING.md) | Load, stress, benchmark |

### By Language
| Document | Purpose |
|----------|---------|
| [JS-TS-TESTING.md](./JS-TS-TESTING.md) | Jest/Vitest, Testing Library |
| [PYTHON-TESTING.md](./PYTHON-TESTING.md) | pytest, coverage.py |
| [DOTNET-TESTING.md](./DOTNET-TESTING.md) | xUnit, NUnit, coverlet |
| [SQL-TESTING.md](./SQL-TESTING.md) | tSQLt, pytest-sql, data validation |
| [NOTEBOOK-TESTING.md](./NOTEBOOK-TESTING.md) | Databricks notebook validation |

---

## Testing Pyramid

```
                    ┌─────────┐
                    │   E2E   │  Few, slow, high confidence
                    │  Tests  │  Real user journeys
                    ├─────────┤
                 ┌──┴─────────┴──┐
                 │  Integration  │  Module boundaries
                 │    Tests      │  API contracts
                 ├───────────────┤
           ┌─────┴───────────────┴─────┐
           │       Unit Tests          │  Many, fast, isolated
           │       (90% coverage)      │  Business logic
           └───────────────────────────┘
```

---

## Testing Matrix by Platform

| Testing Type | App Services | Databricks | Power BI | Pipeline Stage |
|--------------|--------------|------------|----------|----------------|
| Smoke | ✓ Health endpoints | ✓ Job ping | ✓ Dataset connect | Post-deploy |
| Unit | ✓ 90% coverage | ✓ Extracted functions | N/A | CI |
| Integration | ✓ API + DB | ✓ Notebook chains | ✓ Data source | CI |
| Contract | ✓ Pact (APIs) | Optional | N/A | CI |
| Regression | ✓ Full suite | ✓ Full suite | ✓ Visual regression | CI |
| E2E | ✓ Playwright/Cypress | ✓ Job run validation | ✓ Refresh + render | CD (UT) |
| Acceptance | ✓ BDD/Gherkin | ✓ Data quality | ✓ Report accuracy | CD (ST) |
| Performance | ✓ k6/Artillery | ✓ Query timing | ✓ Refresh timing | Scheduled |

---

## Coverage Requirements

### Standard Code (JS/TS, Python, C#/.NET)
| Metric | Threshold | Enforcement |
|--------|-----------|-------------|
| Line coverage | ≥ 90% | PR block |
| Branch coverage | ≥ 85% | Warning |
| New code coverage | ≥ 90% | PR block (SonarCloud) |

### Coverage Exclusions
```javascript
// Example: jest.config.js
coveragePathIgnorePatterns: [
  '/node_modules/',
  '/__mocks__/',
  '/generated/',      // Auto-generated code
  '/migrations/',     // DB migrations
  '*.config.js'       // Config files
]
```

### Non-Standard Code
| Type | Validation Approach |
|------|---------------------|
| SQL | Query result assertions, data quality checks |
| Notebooks | Cell execution validation, output assertions |
| Power BI | DAX measure tests, refresh success |

---

## Test Naming Convention

```
[UnitOfWork]_[Scenario]_[ExpectedBehavior]

Examples:
- calculateTotal_withEmptyCart_returnsZero
- userService_createWithDuplicateEmail_throwsConflict
- processPayment_insufficientFunds_declinesTransaction
```

---

## Test Organization

```
/tests/
├── unit/                    # Fast, isolated
│   ├── services/
│   └── utils/
├── integration/             # Module boundaries
│   ├── api/
│   └── database/
├── e2e/                     # Full user journeys
│   └── scenarios/
├── performance/             # Load/stress
│   └── k6/
├── fixtures/                # Shared test data
└── helpers/                 # Test utilities
```

---

## CI Pipeline Integration

```yaml
# Test stage
- stage: Test
  jobs:
    - job: UnitTests
      steps:
        - script: npm test -- --coverage
        - task: PublishTestResults@2
          inputs:
            testResultsFiles: '**/junit.xml'
        - task: PublishCodeCoverageResults@1
          inputs:
            codeCoverageTool: 'Cobertura'
            summaryFileLocation: '**/coverage.xml'

    - job: IntegrationTests
      dependsOn: UnitTests
      steps:
        - script: npm run test:integration

    - job: CoverageGate
      dependsOn: UnitTests
      steps:
        - script: |
            COVERAGE=$(cat coverage/coverage-summary.json | jq '.total.lines.pct')
            if (( $(echo "$COVERAGE < 90" | bc -l) )); then
              echo "##vso[task.logissue type=error]Coverage $COVERAGE% below 90%"
              exit 1
            fi
```

---

## Databricks/Notebook Testing

Separate concerns:
1. **Extract logic to functions** → Unit test with pytest
2. **Notebook execution validation** → Run notebook, assert outputs
3. **Data quality checks** → Great Expectations, dbt tests

```python
# Extracted function (testable)
def transform_data(df: DataFrame) -> DataFrame:
    return df.filter(col("status") == "active")

# Test
def test_transform_data_filters_active():
    input_df = spark.createDataFrame([...])
    result = transform_data(input_df)
    assert result.count() == expected_count
```

---

## SQL Testing

```python
# pytest with SQL assertions
def test_customer_aggregation():
    result = execute_sql("SELECT * FROM vw_customer_summary WHERE id = 1")
    assert result['total_orders'] == 5
    assert result['lifetime_value'] > 0
```

```sql
-- tSQLt unit test
CREATE PROCEDURE [tests].[test_sp_calculate_balance]
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.Transactions';
    INSERT INTO dbo.Transactions VALUES (1, 100), (1, -30);

    DECLARE @result MONEY;
    EXEC @result = dbo.sp_calculate_balance @customer_id = 1;

    EXEC tSQLt.AssertEquals 70, @result;
END
```

---

## Performance Testing

```javascript
// k6 load test
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 50,
  duration: '5m',
  thresholds: {
    http_req_duration: ['p(95)<500'],  // 95% under 500ms
    http_req_failed: ['rate<0.01'],    // <1% errors
  },
};

export default function () {
  const res = http.get('https://api.example.com/health');
  check(res, { 'status 200': (r) => r.status === 200 });
  sleep(1);
}
```

---

## Next Steps

1. Choose testing frameworks per language
2. Setup coverage reporting in pipelines
3. Create smoke test suites per platform
4. Integrate with SonarCloud for coverage tracking
