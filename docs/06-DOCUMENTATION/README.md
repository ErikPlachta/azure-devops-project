# Documentation Generation

Auto-doc tooling, inline standards, wiki sync, and AI assistance.

---

## Documents in This Section

| Document | Purpose |
|----------|---------|
| [DOC-STRATEGY.md](./DOC-STRATEGY.md) | Philosophy: code as source of truth |
| [WIKI-SYNC.md](./WIKI-SYNC.md) | Pipeline to publish to Azure DevOps Wiki |
| [AI-DOC-GENERATION.md](./AI-DOC-GENERATION.md) | Copilot Chat prompts for docs |
| [DOC-QUALITY-GATES.md](./DOC-QUALITY-GATES.md) | Enforcing inline documentation |

### Language-Specific
| Document | Purpose |
|----------|---------|
| [JS-TS-DOCS.md](./JS-TS-DOCS.md) | JSDoc/TSDoc → TypeDoc |
| [PYTHON-DOCS.md](./PYTHON-DOCS.md) | Docstrings → Sphinx |
| [DOTNET-DOCS.md](./DOTNET-DOCS.md) | XML comments → DocFX |
| [SQL-DOCS.md](./SQL-DOCS.md) | Inline comments → Markdown |
| [SHELL-DOCS.md](./SHELL-DOCS.md) | Header comments → Markdown |

---

## Documentation Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Source Code                               │
│  ─────────────────────────────────────────────────────────  │
│  JSDoc / TSDoc / Docstrings / XML Comments                   │
│  (Inline documentation following language standards)         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼ CI Pipeline
┌─────────────────────────────────────────────────────────────┐
│                    Doc Generator                             │
│  ─────────────────────────────────────────────────────────  │
│  TypeDoc │ Sphinx │ DocFX │ Custom SQL/Shell parsers        │
│  Output: Markdown files                                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Azure DevOps Wiki                         │
│  ─────────────────────────────────────────────────────────  │
│  Auto-synced from /docs-generated/ folder                    │
│  Versioned, searchable, accessible                           │
└─────────────────────────────────────────────────────────────┘
```

---

## Tool Matrix

| Language | Inline Format | Generator | Output |
|----------|---------------|-----------|--------|
| JS/TS | JSDoc/TSDoc | TypeDoc | Markdown |
| Python | Google/NumPy docstrings | Sphinx | Markdown |
| C#/.NET | XML comments | DocFX | Markdown |
| SQL | `-- @description` comments | Custom parser | Markdown |
| BAT/SH | Header block comments | Custom parser | Markdown |

---

## Inline Documentation Standards

### JavaScript/TypeScript (TSDoc)
```typescript
/**
 * Calculates the total price including tax.
 *
 * @param items - Array of cart items
 * @param taxRate - Tax rate as decimal (e.g., 0.08 for 8%)
 * @returns Total price including tax
 *
 * @example
 * ```ts
 * const total = calculateTotal([{ price: 100 }], 0.08);
 * // Returns: 108
 * ```
 */
export function calculateTotal(items: CartItem[], taxRate: number): number {
  // ...
}
```

### Python (Google style)
```python
def calculate_total(items: list[CartItem], tax_rate: float) -> float:
    """Calculate the total price including tax.

    Args:
        items: List of cart items.
        tax_rate: Tax rate as decimal (e.g., 0.08 for 8%).

    Returns:
        Total price including tax.

    Raises:
        ValueError: If tax_rate is negative.

    Example:
        >>> calculate_total([CartItem(price=100)], 0.08)
        108.0
    """
```

### C#/.NET (XML)
```csharp
/// <summary>
/// Calculates the total price including tax.
/// </summary>
/// <param name="items">Array of cart items.</param>
/// <param name="taxRate">Tax rate as decimal (e.g., 0.08 for 8%).</param>
/// <returns>Total price including tax.</returns>
/// <exception cref="ArgumentException">Thrown when taxRate is negative.</exception>
/// <example>
/// <code>
/// var total = CalculateTotal(items, 0.08m);
/// </code>
/// </example>
public decimal CalculateTotal(CartItem[] items, decimal taxRate)
```

### SQL
```sql
-- =============================================================================
-- @name: sp_calculate_customer_balance
-- @description: Calculates the current balance for a customer
-- @param @customer_id: The unique customer identifier
-- @returns: Current balance as MONEY
-- @example: EXEC sp_calculate_customer_balance @customer_id = 12345
-- @author: [auto from git]
-- @modified: [auto from git]
-- =============================================================================
CREATE PROCEDURE sp_calculate_customer_balance
    @customer_id INT
AS
BEGIN
    -- Implementation
END
```

### Shell (BAT/SH)
```bash
#!/bin/bash
# =============================================================================
# @name: deploy.sh
# @description: Deploys application to specified environment
# @param $1: Environment (ut|st|pr)
# @param $2: Version tag
# @example: ./deploy.sh ut v1.2.3
# =============================================================================
```

---

## Quality Gate: Documentation Enforcement

### ESLint (JS/TS)
```javascript
// .eslintrc.js
module.exports = {
  plugins: ['jsdoc'],
  rules: {
    'jsdoc/require-jsdoc': ['error', {
      require: {
        FunctionDeclaration: true,
        MethodDefinition: true,
        ClassDeclaration: true,
      },
      publicOnly: true,  // Only exported members
    }],
    'jsdoc/require-description': 'error',
    'jsdoc/require-param': 'error',
    'jsdoc/require-returns': 'error',
  },
};
```

### Ruff (Python)
```toml
# ruff.toml
[lint]
select = [
  "D",      # pydocstyle
]

[lint.pydocstyle]
convention = "google"
```

### .NET (StyleCop)
```xml
<!-- .editorconfig or stylecop.json -->
<Rules AnalyzerId="StyleCop.Analyzers">
  <Rule Id="SA1600" Action="Error" /> <!-- Elements should be documented -->
  <Rule Id="SA1601" Action="Error" /> <!-- Partial elements documented -->
  <Rule Id="SA1602" Action="Error" /> <!-- Enumeration items documented -->
</Rules>
```

---

## Wiki Sync Pipeline

```yaml
# azure-pipelines/docs-sync.yml
trigger:
  branches:
    include:
      - main
  paths:
    include:
      - src/**
      - docs/**

stages:
  - stage: GenerateDocs
    jobs:
      - job: BuildDocs
        steps:
          # TypeScript docs
          - script: npx typedoc --out docs-generated/api-ts src/

          # Python docs
          - script: sphinx-build -b markdown docs/sphinx docs-generated/api-py

          # .NET docs
          - script: docfx build docfx.json

  - stage: PublishWiki
    jobs:
      - job: SyncWiki
        steps:
          - checkout: self
          - checkout: wiki  # Azure DevOps Wiki repo
          - script: |
              cp -r docs-generated/* wiki/
              cd wiki
              git add .
              git commit -m "docs: auto-sync from main [skip ci]"
              git push
```

---

## AI-Assisted Documentation (Copilot Chat)

### Generating Missing Docs
```
Prompt: "Add TSDoc comments to all exported functions in this file.
Include @param, @returns, and @example for each."
```

### Improving Existing Docs
```
Prompt: "Review the docstrings in this module. Add missing Args,
Returns, and Raises sections. Use Google style."
```

### Generating README
```
Prompt: "Generate a README.md for this module based on the inline
documentation. Include: purpose, installation, usage examples,
API reference summary."
```

See [AI-DOC-GENERATION.md](./AI-DOC-GENERATION.md) for complete prompt library.

---

## Next Steps

1. Configure doc generators per language
2. Setup wiki sync pipeline
3. Enable linting rules for doc enforcement
4. Train team on inline doc standards
