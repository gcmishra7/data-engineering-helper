# Contributing to Data Engineering Handbook

Thank you for helping make this the most practical DE reference on the internet.

## How to Contribute

### Adding a new concept file

1. Follow the file template in `TEMPLATE.md`
2. Place in the correct chapter directory
3. Add working, runnable code — no pseudocode
4. Always include a Mermaid diagram
5. Add references with links at the bottom
6. Include a "What goes wrong in production" section — this is the most valuable part

### Fixing errors

Open an issue or PR with the correction and the source that proves it.

### Adding a scenario

Scenarios in `10-scenarios/` must be end-to-end and use real tools. No toy examples.

## File Naming

Use lowercase kebab-case: `01-delta-lake-internals.md`

## Code Examples

- Python/PySpark: must run on Databricks Runtime 13+
- SQL: must run on Snowflake or Databricks SQL Warehouse (specify which)
- Terraform: must use current provider versions (specify in comments)

## References Format

```markdown
## References
- [Title](url) — one-line description of what it covers
```
