# Data Engineering Handbook

> From zero to production-grade. Every concept explained, diagrammed, and battle-tested.

A comprehensive, open reference covering **Databricks**, **Snowflake**, **data modeling**, **streaming**, **governance**, **data quality**, and the full ecosystem of tools (dbt, Airflow, Great Expectations, OpenLineage). Every file follows the same structure: concept → diagram → working code → real-world scenario → what goes wrong in production → references.

---

## Who This Is For

| Role | Start Here |
|------|-----------|
| Data Engineer (beginner) | `00-foundations/` → `01-data-modeling/` → `05-databricks/00-foundations/` |
| Data Engineer (intermediate) | `02-streaming-fundamentals/` → `05-databricks/02-spark-internals/` |
| Analytics Engineer | `01-data-modeling/05-dbt-modeling/` → `06-snowflake/03-sql-patterns/` |
| Data Architect | `03-governance/` → `04-data-quality/` → `09-cross-platform/` |
| ML Engineer | `05-databricks/06-ml-platform/` → `10-scenarios/03-ml-feature-platform/` |
| Platform / Infra Engineer | `08-cloud-platforms/` → `03-governance/02-databricks-unity-catalog/` |

---

## Repository Structure

```
data-engineering-handbook/
├── 00-foundations/                    # Tool-agnostic core concepts
├── 01-data-modeling/                  # Relational, Kimball, Data Vault, Lakehouse, dbt
├── 02-streaming-fundamentals/         # Streaming theory, Kafka, CDC
├── 03-governance/                     # Generic + Databricks Unity Catalog + Snowflake
├── 04-data-quality/                   # Generic DQ + tools + per-platform
├── 05-databricks/                     # Delta Lake, Spark, Streaming, DLT, Unity Catalog, ML
├── 06-snowflake/                      # Storage, compute, SQL, sharing, governance, Snowpark
├── 07-ecosystem-tools/                # Airflow, dbt, Great Expectations, OpenLineage
├── 08-cloud-platforms/                # AWS, Azure, GCP — integration patterns
├── 09-cross-platform/                 # Table formats, Databricks+Snowflake bridge, observability
└── 10-scenarios/                      # End-to-end real-world builds
```

---

## Content Standard

Every file follows this template:

```
## What problem does this solve?
## How it works
## Diagram  (Mermaid)
## Code example  (working, runnable)
## Real-world scenario
## What goes wrong in production
## Comparison / when to use vs alternatives
## References
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). PRs welcome — especially additional real-world scenarios, cloud-specific gotchas, and code examples.

---

## References

See [REFERENCES.md](REFERENCES.md) for the master list of all external links used across this handbook.

---

*Built with ❤️ for the data engineering community.*
