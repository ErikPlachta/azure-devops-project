# Contributing to This Documentation

Guidelines for maintaining and extending this reference.

---

## Documentation Standards

### File Naming
- Use UPPERCASE with hyphens: `BRANCH-POLICIES.md`
- README.md for section indexes
- Prefix with number for ordered content: `01-SETUP.md`

### Content Structure

```markdown
# Title

Brief description (1-2 sentences).

---

## Documents in This Section (if index)

| Document | Purpose |
|----------|---------|
| [NAME.md](./NAME.md) | What it covers |

---

## Section Content

### Subsection

Content here.

---

## Next Steps

1. Action item
2. Action item
```

### Formatting Rules
- Use tables for comparisons, matrices, quick reference
- Use code blocks with language hints
- Use `[SOC2-XXX]` tags for compliance references
- Keep lines under 100 characters in markdown
- One blank line between sections

---

## Adding New Content

### New Document
1. Create file in appropriate section folder
2. Add entry to section's README.md table
3. Update INDEX.md if major addition
4. Follow naming convention

### New Section
1. Create folder: `XX-SECTION-NAME/`
2. Create `README.md` with section overview
3. Add navigation entry to `/docs/INDEX.md`
4. Cross-reference from related sections

### New Example
1. Add to `/docs/10-EXAMPLES/` under appropriate subfolder
2. Update examples README with table entry
3. Test that code actually works

---

## Compliance Tags

Use these tags inline when content relates to compliance:

| Tag | Meaning |
|-----|---------|
| `[SOC2-CC6]` | Logical/Physical Access Controls |
| `[SOC2-CC7]` | System Operations |
| `[SOC2-CC8]` | Change Management |
| `[SEC-17a]` | Record Retention |
| `[GDPR-Art32]` | Security of Processing |

Example:
```markdown
All vault access is logged and auditable. `[SOC2-CC6]`
```

---

## Review Process

1. Create PR with changes
2. Assign to DevOps team member
3. Verify:
   - Links work
   - Code examples are valid
   - Consistent formatting
   - Compliance tags where applicable
4. Merge after approval

---

## Version History

Update the version table in INDEX.md for significant changes:

```markdown
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.2.0 | YYYY-MM-DD | Name | Added Databricks section |
```

---

## Questions?

Contact DevOps team via Teams: #devops-support
