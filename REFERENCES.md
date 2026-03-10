# Master Reference List

All external references used across this handbook, organised by category.

---

## Foundational Books & Papers

- [Designing Data-Intensive Applications — Martin Kleppmann](https://dataintensive.net/) — The definitive book on distributed data systems
- [The Data Warehouse Toolkit — Kimball Group](https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/books/data-warehouse-dw-toolkit/) — Dimensional modeling bible
- [Building a Scalable Data Warehouse with Data Vault 2.0 — Dan Linstedt](https://www.sciencedirect.com/book/9780128025109/building-a-scalable-data-warehouse-with-data-vault-2-0)
- [Data Mesh — Zhamak Dehghani](https://www.oreilly.com/library/view/data-mesh/9781492092384/)
- [DAMA DMBOK](https://www.dama.org/cpages/body-of-knowledge) — Data management body of knowledge
- [Delta Lake Paper](https://dl.acm.org/doi/10.14778/3415478.3415560) — VLDB 2020
- [Databricks Lakehouse Paper](https://www.cidrdb.org/cidr2021/papers/cidr2021_paper17.pdf) — CIDR 2021
- [Google Dataflow / Beam Paper](https://research.google/pubs/pub43864/) — Unified batch and streaming model
- [Jay Kreps — Questioning the Lambda Architecture](https://www.oreilly.com/radar/questioning-the-lambda-architecture/)

---

## Databricks

- [Databricks Documentation](https://docs.databricks.com/en/index.html)
- [Delta Lake Documentation](https://docs.delta.io/latest/index.html)
- [Delta Lake Protocol Spec](https://github.com/delta-io/delta/blob/master/PROTOCOL.md)
- [Databricks Runtime Release Notes](https://docs.databricks.com/en/release-notes/runtime/index.html)
- [Unity Catalog Documentation](https://docs.databricks.com/en/data-governance/unity-catalog/index.html)
- [Delta Live Tables Documentation](https://docs.databricks.com/en/delta-live-tables/index.html)
- [Databricks Terraform Provider](https://registry.terraform.io/providers/databricks/databricks/latest/docs)
- [MLflow Documentation](https://mlflow.org/docs/latest/index.html)
- [Databricks Feature Store](https://docs.databricks.com/en/machine-learning/feature-store/index.html)

---

## Snowflake

- [Snowflake Documentation](https://docs.snowflake.com/)
- [Snowflake Architecture Concepts](https://docs.snowflake.com/en/user-guide/intro-key-concepts)
- [Micro-partitions & Clustering](https://docs.snowflake.com/en/user-guide/tables-clustering-micropartitions)
- [Virtual Warehouses](https://docs.snowflake.com/en/user-guide/warehouses-overview)
- [Snowflake RBAC](https://docs.snowflake.com/en/user-guide/security-access-control-overview)
- [Dynamic Data Masking](https://docs.snowflake.com/en/user-guide/security-column-ddm-use)
- [Snowflake Streams](https://docs.snowflake.com/en/user-guide/streams-intro)
- [Dynamic Tables](https://docs.snowflake.com/en/user-guide/dynamic-tables-intro)
- [Snowflake Iceberg Tables](https://docs.snowflake.com/en/user-guide/tables-iceberg)
- [Snowflake Data Sharing](https://docs.snowflake.com/en/user-guide/data-sharing-intro)
- [Snowpark](https://docs.snowflake.com/en/developer-guide/snowpark/index)
- [Resource Monitors](https://docs.snowflake.com/en/user-guide/resource-monitors)
- [Account Usage Schema](https://docs.snowflake.com/en/sql-reference/account-usage)
- [Snowflake Data Quality — DMFs](https://docs.snowflake.com/en/user-guide/data-quality-intro)
- [Snowflake Horizon Governance](https://docs.snowflake.com/en/guides-overview-govern)

---

## Apache Spark

- [Spark Documentation](https://spark.apache.org/docs/latest/)
- [Structured Streaming Guide](https://spark.apache.org/docs/latest/structured-streaming-programming-guide.html)
- [Spark Tuning Guide](https://spark.apache.org/docs/latest/tuning.html)
- [AQE Documentation](https://spark.apache.org/docs/latest/sql-performance-tuning.html#adaptive-query-execution)

---

## Streaming & Messaging

- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [Confluent Schema Registry](https://docs.confluent.io/platform/current/schema-registry/index.html)
- [Confluent Exactly-Once Blog](https://www.confluent.io/blog/exactly-once-semantics-are-possible-heres-how-apache-kafka-does-it/)
- [Confluent Stream-Table Duality](https://www.confluent.io/blog/kafka-streams-tables-part-1-event-streaming/)
- [Apache Flink Documentation](https://nightlies.apache.org/flink/flink-docs-stable/)
- [Flink Time Concepts](https://nightlies.apache.org/flink/flink-docs-stable/docs/concepts/time/)
- [Debezium Documentation](https://debezium.io/documentation/reference/stable/)
- [Azure Event Hubs](https://learn.microsoft.com/en-us/azure/event-hubs/event-hubs-about)
- [AWS Kinesis](https://docs.aws.amazon.com/kinesis/)
- [GCP Pub/Sub](https://cloud.google.com/pubsub/docs)

---

## dbt

- [dbt Documentation](https://docs.getdbt.com/)
- [dbt Project Structure Best Practices](https://docs.getdbt.com/best-practices/how-we-structure/1-guide-overview)
- [dbt Materializations](https://docs.getdbt.com/docs/build/materializations)
- [dbt Incremental Models](https://docs.getdbt.com/docs/build/incremental-models)
- [dbt Snapshots (SCD Type 2)](https://docs.getdbt.com/docs/build/snapshots)
- [dbt Testing](https://docs.getdbt.com/docs/build/data-tests)
- [dbt Semantic Layer / MetricFlow](https://docs.getdbt.com/docs/use-dbt-semantic-layer/dbt-sl)
- [dbt Mesh](https://docs.getdbt.com/best-practices/how-we-mesh/1-intro-to-dbt-mesh)
- [dbt-databricks Adapter](https://docs.getdbt.com/docs/core/connect-data-platform/databricks-setup)
- [dbt-snowflake Adapter](https://docs.getdbt.com/docs/core/connect-data-platform/snowflake-setup)
- [dbt Governance](https://docs.getdbt.com/docs/collaborate/govern/about-model-governance)
- [AutomateDV (Data Vault in dbt)](https://automate-dv.readthedocs.io/en/latest/)

---

## Apache Airflow

- [Airflow Documentation](https://airflow.apache.org/docs/apache-airflow/stable/)
- [Airflow Architecture](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/overview.html)
- [Airflow Databricks Provider](https://airflow.apache.org/docs/apache-airflow-providers-databricks/stable/index.html)
- [Airflow Snowflake Provider](https://airflow.apache.org/docs/apache-airflow-providers-snowflake/stable/index.html)
- [Airflow OpenLineage Provider](https://airflow.apache.org/docs/apache-airflow-providers-openlineage/stable/index.html)
- [Astronomer Cosmos (dbt + Airflow)](https://astronomer.github.io/astronomer-cosmos/)
- [Amazon MWAA](https://docs.aws.amazon.com/mwaa/)
- [Azure Managed Airflow](https://learn.microsoft.com/en-us/azure/data-factory/concept-managed-airflow)
- [GCP Cloud Composer](https://cloud.google.com/composer/docs)

---

## Data Quality & Observability

- [Great Expectations Documentation](https://docs.greatexpectations.io/)
- [Soda Core Documentation](https://docs.soda.io/soda-core/overview-main.html)
- [Monte Carlo Data Observability](https://www.montecarlodata.com/blog-what-is-data-observability/)
- [chispa — PySpark DataFrame Testing](https://github.com/MrPowers/chispa)
- [dbt-utils](https://github.com/dbt-labs/dbt-utils)

---

## Governance & Lineage

- [OpenLineage Specification](https://openlineage.io/docs/)
- [DataHub Documentation](https://datahubproject.io/docs/)
- [Apache Atlas](https://atlas.apache.org/)
- [Marquez](https://marquezproject.ai/)
- [GDPR Text](https://gdpr-info.eu/)
- [CCPA](https://oag.ca.gov/privacy/ccpa)
- [PDPA Singapore](https://www.pdpc.gov.sg/overview-of-pdpa/the-legislation/personal-data-protection-act)
- [NIST RBAC Standard](https://csrc.nist.gov/projects/role-based-access-control)
- [Data Vault Alliance](https://datavaultalliance.com/)
- [Kimball Group Resources](https://www.kimballgroup.com)
- [DGPO Data Governance Framework](https://datagovernance.com/the-data-governance-framework/)

---

## Table Formats

- [Apache Iceberg Documentation](https://iceberg.apache.org/docs/latest/)
- [Apache Hudi Documentation](https://hudi.apache.org/docs/overview/)
- [Delta Lake UniForm](https://docs.databricks.com/en/delta/uniform.html)

---

## Cloud Platforms

### AWS
- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [AWS Kinesis](https://docs.aws.amazon.com/kinesis/)
- [Amazon MWAA](https://docs.aws.amazon.com/mwaa/)
- [Databricks on AWS](https://docs.databricks.com/en/getting-started/overview.html)
- [Snowflake on AWS](https://docs.snowflake.com/en/user-guide/organizations-connect-aws)

### Azure
- [Azure ADLS Gen2](https://learn.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-introduction)
- [Azure Databricks](https://learn.microsoft.com/en-us/azure/databricks/)
- [Azure Event Hubs Kafka Endpoint](https://learn.microsoft.com/en-us/azure/event-hubs/event-hubs-for-kafka-ecosystem-overview)
- [Azure Entra ID](https://learn.microsoft.com/en-us/entra/fundamentals/whatis)
- [Snowflake on Azure](https://docs.snowflake.com/en/user-guide/organizations-connect-azure)
- [Azure Modern Analytics Architecture](https://learn.microsoft.com/en-us/azure/architecture/solution-ideas/articles/azure-databricks-modern-analytics-architecture)

### GCP
- [GCP Cloud Storage](https://cloud.google.com/storage/docs)
- [GCP Pub/Sub](https://cloud.google.com/pubsub/docs)
- [Databricks on GCP](https://docs.gcp.databricks.com/)
- [GCP Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [Cloud Composer](https://cloud.google.com/composer/docs)
- [Snowflake on GCP](https://docs.snowflake.com/en/user-guide/organizations-connect-gcp)
