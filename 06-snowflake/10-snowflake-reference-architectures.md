# Snowflake Reference Architectures

## Architecture 1 — Modern ELT Lakehouse (Snowflake-primary)

```mermaid
graph TD
    subgraph Sources
        ERP[ERP / CRM] & SHOP[Shopify] & API[APIs]
    end
    subgraph Ingestion
        FV[Fivetran<br/>managed connectors]
        SNOW_PIPE[Snowpipe<br/>continuous file loading]
    end
    subgraph Snowflake
        RAW[Raw Schema<br/>per-source landing]
        STG[Staging<br/>dbt staging models]
        INT[Intermediate<br/>dbt cross-source]
        GOLD[Gold Marts<br/>dbt marts]
    end
    subgraph Serving
        BI[Tableau · Power BI<br/>Looker]
        SHARE[Data Sharing<br/>partners · suppliers]
        SP[Snowpark<br/>Python ML]
    end

    ERP & SHOP & API --> FV --> RAW
    Files --> SNOW_PIPE --> RAW
    RAW --> STG --> INT --> GOLD
    GOLD --> BI & SHARE & SP
```

**Key design decisions:**
- Fivetran handles all source connectors (no custom ingestion code)
- dbt owns all transformation logic (version-controlled, tested)
- Separate warehouses: `ETL_WH` for dbt runs, `BI_WH` for Tableau, `ADMIN_WH` for maintenance
- Snowflake Data Sharing for partner/supplier data distribution
- Snowpark for Python-based ML feature engineering (no data egress)

---

## Architecture 2 — Hybrid Databricks + Snowflake

```mermaid
graph LR
    subgraph Databricks[Azure Databricks — ML + Streaming]
        STREAM[Structured Streaming<br/>Kafka ingestion]
        DELTA[Delta Lake<br/>Bronze · Silver]
        ML[MLflow<br/>model training]
        DELTA --> ML
    end
    subgraph Snowflake[Snowflake on Azure — SQL + BI]
        GOLD_SF[Gold Tables<br/>via UniForm / external]
        DBT[dbt on Snowflake<br/>mart models]
        BI_WH[SQL Warehouses<br/>Tableau · Power BI]
    end

    STREAM --> DELTA
    DELTA -->|Delta UniForm<br/>or COPY INTO| GOLD_SF
    GOLD_SF --> DBT --> BI_WH
```

**When to use this pattern:**
- Streaming ingestion volume too high for Snowpipe → use Databricks Structured Streaming
- Need ML on the same data as BI → Databricks for ML, Snowflake for BI
- Cost: Databricks compute cheaper for Spark-scale transforms, Snowflake better for SQL-only BI

---

## Architecture 3 — Snowflake as Data Mesh Node

```mermaid
graph TD
    subgraph Domain A — Finance
        SF_A[Snowflake — Finance<br/>fact_gl_entries · dim_cost_center]
        DBT_A[dbt Finance models]
    end
    subgraph Domain B — Marketing
        SF_B[Snowflake — Marketing<br/>fact_campaigns · dim_segment]
        DBT_B[dbt Marketing models]
    end
    subgraph Shared Platform
        SHARE_A[Snowflake Data Share<br/>from Finance domain]
        SHARE_B[Snowflake Data Share<br/>from Marketing domain]
        DH[DataHub<br/>cross-domain catalogue]
    end

    SF_A -->|publish contract| SHARE_A
    SF_B -->|publish contract| SHARE_B
    SHARE_A & SHARE_B --> DH
```

**Data mesh principles applied:**
- Each domain owns its Snowflake schema and dbt models
- Cross-domain data access via Snowflake Data Sharing (not ETL copies)
- Data contracts defined as dbt model tests + freshness checks
- DataHub as the federated data catalogue

## References
- [Snowflake Modern Data Stack](https://www.snowflake.com/workloads/data-engineering/)
- [Fivetran + Snowflake + dbt](https://fivetran.com/docs/destinations/snowflake)
- [Snowflake Data Mesh](https://www.snowflake.com/blog/data-mesh-snowflake/)
- [dbt + Snowflake Best Practices](https://docs.getdbt.com/guides/best-practices)
