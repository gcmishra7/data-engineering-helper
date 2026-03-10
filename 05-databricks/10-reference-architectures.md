# Databricks Reference Architectures

## What problem does this solve?
Choosing how to wire together Databricks with cloud storage, streaming, orchestration, and serving layers is one of the highest-leverage decisions in platform design. Wrong choices early mean expensive rewrites later. This guide presents proven reference architectures for the three most common patterns.

## Architecture 1 — Batch Lakehouse (Azure)

```mermaid
graph TD
    subgraph Sources
        DB1[(ERP / CRM)]
        API[REST APIs]
        FILES[File Drops]
    end

    subgraph Ingestion
        ADF[Azure Data Factory]
        DBZ[Debezium on AKS]
        AUTO[Auto Loader]
    end

    subgraph Storage[ADLS Gen2]
        BRONZE[Bronze Container]
        SILVER[Silver Container]
        GOLD[Gold Container]
    end

    subgraph Compute[Azure Databricks]
        JOB1[Job Cluster: Ingest]
        JOB2[Job Cluster: Transform]
        JOB3[Job Cluster: Serve]
        SQL[SQL Warehouse]
    end

    subgraph Serving
        PBI[Power BI]
        SYNAPSE[Azure Synapse]
    end

    DB1 --> DBZ --> BRONZE
    API --> ADF --> BRONZE
    FILES --> AUTO --> BRONZE
    BRONZE --> JOB2 --> SILVER
    SILVER --> JOB3 --> GOLD
    GOLD --> SQL --> PBI
    GOLD --> SYNAPSE
```

| Node | Details |
|------|---------|
| **ERP / CRM** | PostgreSQL |
| **REST APIs** | Salesforce, Shopify |
| **File Drops** | SFTP, SharePoint |
| **Azure Data Factory** | Copy Activity, Schedule |
| **Debezium on AKS** | CDC from PostgreSQL |
| **Auto Loader** | Event Grid trigger |
| **Bronze Container** | raw, immutable |
| **Silver Container** | cleaned, Delta |
| **Gold Container** | aggregated, Delta |
| **Job Cluster: Ingest** | Bronze pipeline |
| **Job Cluster: Transform** | Silver DLT pipeline |
| **Job Cluster: Serve** | Gold dbt models |
| **SQL Warehouse** | BI queries |
| **Power BI** | dashboards |
| **Azure Synapse** | external tables |

**Key design decisions:**
- Debezium for operational DBs (real-time CDC), ADF for bulk/API sources
- Auto Loader with Event Grid for file-based sources (scales to millions of files)
- DLT for Bronze→Silver (built-in quality, lineage)
- dbt for Silver→Gold (SQL-first, version-controlled transformation logic)
- SQL Warehouse for analyst queries (serverless, no cluster management)
- Unity Catalog: single metastore governs all three layers

---

## Architecture 2 — Real-Time Streaming Lakehouse (Azure)

```mermaid
graph LR
    APP[Application Events] --> EH[Azure Event Hubs]
    DB2[(PostgreSQL)] --> DBZ2[Debezium] --> EH

    EH -->|Structured Streaming| ADB[Databricks]

    subgraph DLT[Delta Live Tables]
        B2[Bronze]
        S2[Silver]
        G2[Gold]
    end

    ADB --> B2 --> S2 --> G2

    G2 --> DBSQL[Databricks SQL]
    G2 --> ALERT[Alerting]
    S2 --> MLSERVE[Model Serving]
```

| Node | Details |
|------|---------|
| **Application Events** | clickstream, payments |
| **Azure Event Hubs** | Kafka-compatible |
| **Databricks** | DLT Pipeline |
| **Bronze** | raw Kafka events |
| **Silver** | parsed, deduped, scored |
| **Gold** | 5-min aggregations |
| **Databricks SQL** | live dashboard |
| **Alerting** | Databricks SQL Alerts |
| **Model Serving** | real-time scoring |

**SLA targets:**
| Stage | Latency |
|---|---|
| App event → Event Hubs | < 1s |
| Event Hubs → Bronze (DLT) | < 30s |
| Bronze → Silver (DLT) | < 2 min |
| Silver → Gold aggregations | < 5 min |
| Gold → Dashboard refresh | < 1 min |

**Key design decisions:**
- DLT Continuous mode for Bronze→Silver (sub-minute processing)
- DLT Triggered mode for Gold (5-min windows, more cost-efficient)
- `@expect_or_drop` on Silver for data quality, event log for monitoring
- Checkpoint stored on ADLS (never local disk)
- `maxOffsetsPerTrigger` set to prevent runaway batch sizes after outages

---

## Architecture 3 — Multi-Cloud Lakehouse (Azure primary + GCP analytics)

```mermaid
graph TD
    subgraph Azure[Azure — Primary]
        ADLS[ADLS Gen2]
        ADB[Databricks Workspace]
        UC[Unity Catalog]
    end

    subgraph GCP[GCP — Analytics]
        BQ[BigQuery]
        SF[Snowflake on GCP]
    end

    ADLS -->|Delta UniForm, Iceberg metadata| BQ
    ADLS -->|Delta UniForm, zero copy| SF
    ADB -->|Databricks-to-BigQuery, spark-bigquery connector| BQ
    UC -->|Delta Sharing, open protocol| GCP
```

| Node | Details |
|------|---------|
| **ADLS Gen2** | Delta Lake storage |
| **Databricks Workspace** | ETL + ML |
| **Unity Catalog** | Primary Metastore |
| **BigQuery** | SQL analytics + BI |
| **Snowflake on GCP** | Data sharing |

**Key design decisions:**
- Delta UniForm on Gold tables: write once in Delta, Snowflake/BigQuery read as Iceberg
- No data duplication between Azure and GCP
- Unity Catalog on Azure governs; BigQuery Policy Tags govern on GCP side
- Delta Sharing for cross-org data delivery (auditors, partners)

---

## Architecture 4 — ML Platform Lakehouse

```mermaid
graph TD
    subgraph Data[Delta Lake — Feature Engineering]
        SIL[Silver Tables]
        FS[Feature Store]
        SIL --> FS
    end

    subgraph Training[Model Training]
        EXP[MLflow Experiments]
        MR[Model Registry]
        FS --> EXP --> MR
    end

    subgraph Inference[Serving]
        BATCH[Batch Scoring]
        RT[Model Serving]
        MR --> BATCH
        MR --> RT
    end

    subgraph Monitoring[Model Monitoring]
        DRIFT[Databricks Lakehouse Monitoring]
        BATCH --> DRIFT
        DRIFT --> RETRAIN[Trigger Retraining]
        RETRAIN --> EXP
    end
```

| Node | Details |
|------|---------|
| **Silver Tables** | clean events |
| **Feature Store** | precomputed features |
| **MLflow Experiments** | hyperparameter tuning |
| **Model Registry** | Staging to Production |
| **Batch Scoring** | nightly Delta table |
| **Model Serving** | REST endpoint |
| **Databricks Lakehouse Monitoring** | data drift, model drift |
| **Trigger Retraining** | Databricks Workflow |

**Key design decisions:**
- Feature Store as the single source of truth for features (no training-serving skew)
- MLflow Model Registry for versioning and promotion gates
- Batch scoring writes to Gold Delta (queryable, auditable)
- Model Serving for real-time (latency < 100ms)
- Lakehouse Monitoring detects data drift → triggers automated retraining workflow

---

## Cluster topology patterns

### Pattern A — Shared cluster (small team, cost priority)
```
1x All-Purpose cluster (4 workers, Standard_DS4_v2)
├── Interactive notebooks (analysts + engineers share)
├── Ad-hoc queries
└── Auto-terminate: 30 min idle

Cost: ~$50-80/day depending on usage
Risk: one person's runaway query impacts everyone
```

### Pattern B — Separated by workload (medium team)
```
1x SQL Warehouse (Small, serverless)     ← analysts only
1x All-Purpose cluster (engineers only)  ← exploration, dev
N× Job Clusters (production pipelines)  ← each job gets own cluster

Cost: pay per query (SQL Warehouse) + pay per job run
Risk: low — workloads isolated
```

### Pattern C — Enterprise production
```
Cluster Pool (8 pre-warmed spot VMs)
├── ETL Job Clusters (acquire from pool)     ← Bronze/Silver pipelines
├── ML Job Clusters (GPU, on-demand)         ← model training
├── Multiple SQL Warehouses                  ← per team, sized appropriately
└── Cluster Policies (enforce per group)

Cost: pool idle cost + DBU for active jobs
Risk: spot interruption on workers (handled by restart policy)
```

## Orchestration patterns

### Pattern A — Databricks Workflows only
Use when: all work is within Databricks (Spark, DLT, SQL, ML)

```
Daily Pipeline Job:
  Task 1: ingest_bronze       (Auto Loader, job cluster)
  Task 2a: dlt_silver         (DLT pipeline, after task 1)
  Task 2b: validate_quality   (notebook, after task 1)
  Task 3: build_gold          (dbt, after task 2a + 2b)
  Task 4: notify_slack        (Python, always runs)
```

### Pattern B — Airflow orchestrates Databricks
Use when: pipeline includes non-Databricks systems (Fivetran, Snowflake, dbt Cloud)

```python
# Cloud Composer / MWAA DAG
from airflow.providers.databricks.operators.databricks import DatabricksRunNowOperator
from airflow.providers.fivetran.operators.fivetran import FivetranOperator

fivetran_sync = FivetranOperator(task_id="sync_sources", connector_id="...")
run_silver = DatabricksRunNowOperator(task_id="transform_silver", job_id=12345)
run_dbt = DbtCloudRunJobOperator(task_id="dbt_gold", job_id=67890)

fivetran_sync >> run_silver >> run_dbt
```

## What goes wrong in production

- **Tight coupling between ingest and transform** — running Bronze ingest and Silver transform in the same Spark session. If Silver fails, Bronze must rerun too. Separate into distinct jobs with clear checkpoints.
- **No environment separation** — running exploratory ML experiments in the same workspace as production ETL. A mis-configured experiment job consumes all cluster resources. Separate dev/staging/prod workspaces.
- **Hardcoded cluster configuration** — cluster node type hardcoded in notebooks. When the team migrates from Azure to GCP, every notebook needs editing. Parameterise via cluster policies and job configs.
- **Missing alerting on Gold freshness** — Gold tables are 4 hours stale because an upstream DLT pipeline silently stalled. No alert fired. Always set SLA alerts on Gold table `_metadata.file_modification_time`.

## References
- [Databricks Reference Architectures](https://docs.databricks.com/en/lakehouse-architecture/index.html)
- [Azure Databricks Modern Analytics Architecture](https://learn.microsoft.com/en-us/azure/architecture/solution-ideas/articles/azure-databricks-modern-analytics-architecture)
- [Delta UniForm](https://docs.databricks.com/en/delta/uniform.html)
- [Lakehouse Monitoring](https://docs.databricks.com/en/lakehouse-monitoring/index.html)
