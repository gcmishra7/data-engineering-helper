# Data Engineering Handbook

> From zero to production-grade. Every concept explained, diagrammed, and battle-tested.

A comprehensive, open reference covering **Databricks**, **Snowflake**, **data modeling**, **streaming**, **governance**, **data quality**, and the full ecosystem of tools (dbt, Airflow, Great Expectations, OpenLineage). Every file follows the same structure: concept → diagram → working code → real-world scenario → what goes wrong in production → references.

---

## Who This Is For

| Role | Start Here |
|------|-----------|
| Data Engineer (beginner) | [Foundations](#-00-foundations) → [Data Modeling](#-01-data-modeling) → [Databricks Foundations](#-05-databricks) |
| Data Engineer (intermediate) | [Streaming](#-02-streaming-fundamentals) → [Spark Internals](#-05-databricks) |
| Analytics Engineer | [dbt Modeling](#-01-data-modeling) → [Snowflake SQL](#-06-snowflake) |
| Data Architect | [Governance](#-03-governance) → [Data Quality](#-04-data-quality) → [Cross-Platform](#-09-cross-platform) |
| ML Engineer | [ML Platform](#-05-databricks) → [ML Feature Platform](#-10-scenarios) |
| Platform / Infra Engineer | [Cloud Platforms](#-08-cloud-platforms) → [Unity Catalog](#-03-governance) |

---

## Table of Contents

### 📘 00 — Foundations
| # | Topic | Link |
|---|-------|------|
| 1 | Data Engineering Landscape | [View](00-foundations/01-data-engineering-landscape.md) |
| 2 | Batch vs Streaming | [View](00-foundations/02-batch-vs-streaming.md) |
| 3 | Storage Concepts | [View](00-foundations/03-storage-concepts.md) |
| 4 | Data Pipeline Patterns | [View](00-foundations/04-data-pipeline-patterns.md) |
| 5 | Data Contracts | [View](00-foundations/05-data-contracts.md) |
| 6 | Lakehouse Architecture | [View](00-foundations/06-lakehouse-architecture.md) |

### 📐 01 — Data Modeling
| # | Topic | Link |
|---|-------|------|
| 1 | Normal Forms (Relational) | [View](01-data-modeling/01-relational/01-normal-forms.md) |
| 2 | Star Schema (Kimball) | [View](01-data-modeling/02-dimensional-kimball/01-star-schema.md) |
| 3 | Slowly Changing Dimensions | [View](01-data-modeling/02-dimensional-kimball/02-slowly-changing-dimensions.md) |
| 4 | Data Vault Concepts | [View](01-data-modeling/03-data-vault/01-data-vault-concepts.md) |
| 5 | Medallion Architecture | [View](01-data-modeling/04-medallion-lakehouse/01-medallion-architecture.md) |
| 6 | dbt Project Structure | [View](01-data-modeling/05-dbt-modeling/01-dbt-project-structure.md) |
| 7 | dbt Incremental Models | [View](01-data-modeling/05-dbt-modeling/02-incremental-models.md) |

### 🌊 02 — Streaming Fundamentals
| # | Topic | Link |
|---|-------|------|
| 1 | Event Time vs Processing Time | [View](02-streaming-fundamentals/01-core-concepts/01-event-time-vs-processing-time.md) |
| 2 | Windowing (Tumbling, Sliding, Session) | [View](02-streaming-fundamentals/01-core-concepts/02-windows.md) |
| 3 | Delivery Guarantees | [View](02-streaming-fundamentals/01-core-concepts/03-delivery-guarantees.md) |
| 4 | Kafka Architecture | [View](02-streaming-fundamentals/02-messaging-systems/01-kafka-architecture.md) |
| 5 | Kafka Schema Registry | [View](02-streaming-fundamentals/02-messaging-systems/02-kafka-schema-registry.md) |
| 6 | Change Data Capture (CDC) | [View](02-streaming-fundamentals/03-change-data-capture/01-cdc-concepts.md) |

### 🔒 03 — Governance
| # | Topic | Link |
|---|-------|------|
| 1 | What is Data Governance | [View](03-governance/01-generic/01-what-is-data-governance.md) |
| 2 | Data Classification | [View](03-governance/01-generic/02-data-classification.md) |
| 3 | Data Lineage | [View](03-governance/01-generic/03-data-lineage.md) |
| 4 | Databricks Unity Catalog | [View](03-governance/02-databricks-unity-catalog/01-unity-catalog-overview.md) |
| 5 | Snowflake RBAC | [View](03-governance/03-snowflake/01-snowflake-rbac.md) |
| 6 | Cross-Platform Governance | [View](03-governance/04-cross-platform/01-cross-platform-governance.md) |

### ✅ 04 — Data Quality
| # | Topic | Link |
|---|-------|------|
| 1 | DQ Dimensions | [View](04-data-quality/01-generic/01-dq-dimensions.md) |
| 2 | DQ Framework Design | [View](04-data-quality/01-generic/02-dq-framework-design.md) |
| 3 | DQ Tools Overview | [View](04-data-quality/02-tools/01-dq-tools-overview.md) |
| 4 | DLT Expectations (Databricks) | [View](04-data-quality/03-databricks/01-dlt-expectations.md) |
| 5 | Data Metric Functions (Snowflake) | [View](04-data-quality/04-snowflake/01-data-metric-functions.md) |
| 6 | Cross-Platform DQ | [View](04-data-quality/05-cross-platform/01-cross-platform-dq.md) |

### 🔶 05 — Databricks
| # | Topic | Link |
|---|-------|------|
| 1 | Platform Overview | [View](05-databricks/00-foundations/01-databricks-platform-overview.md) |
| 2 | Delta Lake Internals | [View](05-databricks/01-delta-lake/01-delta-lake-internals.md) |
| 3 | Spark Architecture | [View](05-databricks/02-spark-internals/01-spark-architecture.md) |
| 4 | Structured Streaming Guide | [View](05-databricks/03-structured-streaming/01-structured-streaming-guide.md) |
| 5 | Delta Live Tables (DLT) | [View](05-databricks/04-delta-live-tables/01-dlt-overview.md) |
| 6 | Unity Catalog Advanced | [View](05-databricks/05-unity-catalog/01-unity-catalog-advanced.md) |
| 7 | MLflow & Feature Store | [View](05-databricks/06-ml-platform/01-mlflow-and-feature-store.md) |
| 8 | Performance Tuning | [View](05-databricks/07-performance-tuning/01-performance-tuning.md) |
| 9 | Cost Governance | [View](05-databricks/08-cost-governance/01-cost-governance.md) |
| 10 | Reference Architectures | [View](05-databricks/09-reference-architectures/01-reference-architectures.md) |

### ❄️ 06 — Snowflake
| # | Topic | Link |
|---|-------|------|
| 1 | Snowflake Architecture | [View](06-snowflake/00-foundations/01-snowflake-architecture.md) |
| 2 | Micro-Partitions & Clustering | [View](06-snowflake/01-storage-layer/01-micro-partitions-clustering.md) |
| 3 | Virtual Warehouses | [View](06-snowflake/02-compute-layer/01-virtual-warehouses.md) |
| 4 | SQL Patterns | [View](06-snowflake/03-sql-patterns/01-snowflake-sql-patterns.md) |
| 5 | Data Sharing | [View](06-snowflake/04-data-sharing/01-snowflake-data-sharing.md) |
| 6 | Governance | [View](06-snowflake/05-governance/01-snowflake-governance.md) |
| 7 | Performance Tuning | [View](06-snowflake/06-performance-tuning/01-snowflake-performance-tuning.md) |
| 8 | Cost Governance | [View](06-snowflake/07-cost-governance/01-snowflake-cost-governance.md) |
| 9 | Snowpark | [View](06-snowflake/08-snowpark/01-snowpark.md) |
| 10 | Reference Architectures | [View](06-snowflake/09-reference-architectures/01-snowflake-reference-architectures.md) |

### 🔧 07 — Ecosystem Tools
| # | Topic | Link |
|---|-------|------|
| 1 | Airflow Architecture | [View](07-ecosystem-tools/01-airflow/01-airflow-architecture.md) |
| 2 | dbt Core Patterns | [View](07-ecosystem-tools/02-dbt/01-dbt-core-patterns.md) |
| 3 | Great Expectations | [View](07-ecosystem-tools/03-great-expectations/01-great-expectations.md) |
| 4 | OpenLineage & DataHub | [View](07-ecosystem-tools/04-openlineage-datahub/01-openlineage-datahub.md) |

### ☁️ 08 — Cloud Platforms
| # | Topic | Link |
|---|-------|------|
| 1 | AWS Databricks Setup | [View](08-cloud-platforms/aws/01-aws-databricks-setup.md) |
| 2 | Azure Databricks Setup | [View](08-cloud-platforms/azure/01-azure-databricks-setup.md) |
| 3 | GCP Databricks Setup | [View](08-cloud-platforms/gcp/01-gcp-databricks-setup.md) |

### 🔀 09 — Cross-Platform
| # | Topic | Link |
|---|-------|------|
| 1 | Table Formats Compared (Delta, Iceberg, Hudi) | [View](09-cross-platform/01-table-formats-compared.md) |
| 2 | Databricks + Snowflake Bridge | [View](09-cross-platform/02-databricks-snowflake-bridge.md) |

### 🏗️ 10 — Scenarios (End-to-End)
| # | Topic | Link |
|---|-------|------|
| 1 | Fintech Payment Pipeline | [View](10-scenarios/01-fintech-payment-pipeline/README.md) |
| 2 | Retail Lakehouse | [View](10-scenarios/02-retail-lakehouse/README.md) |
| 3 | ML Feature Platform | [View](10-scenarios/03-ml-feature-platform/README.md) |
| 4 | Multi-Cloud Governance | [View](10-scenarios/04-multi-cloud-governance/README.md) |
| 5 | Streaming Quality Pipeline | [View](10-scenarios/05-streaming-quality-pipeline/README.md) |
| 6 | Data Vault Lakehouse | [View](10-scenarios/06-data-vault-lakehouse/README.md) |

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

## References

See [REFERENCES.md](REFERENCES.md) for the master list of all external links used across this handbook.

---

*Built for the data engineering community.*
