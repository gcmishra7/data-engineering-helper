# Snowflake Cost Governance

## What problem does this solve?
Snowflake bills per second of compute (credits) and per TB of storage. Without governance, teams run expensive ad-hoc queries, warehouses idle all weekend, and storage grows unbounded. This guide covers the controls to keep cost proportional to value.

## How it works

### Resource Monitors (credit caps)

```sql
-- Account-level cap
CREATE RESOURCE MONITOR account_monthly
    WITH CREDIT_QUOTA = 2000
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
    TRIGGERS
        ON 80 PERCENT DO NOTIFY
        ON 95 PERCENT DO NOTIFY
        ON 100 PERCENT DO SUSPEND;

ALTER ACCOUNT SET RESOURCE_MONITOR = account_monthly;

-- Warehouse-level cap
CREATE RESOURCE MONITOR analytics_daily
    WITH CREDIT_QUOTA = 50
    FREQUENCY = DAILY
    TRIGGERS
        ON 90 PERCENT DO NOTIFY
        ON 100 PERCENT DO SUSPEND_IMMEDIATE;

ALTER WAREHOUSE analytics_wh SET RESOURCE_MONITOR = analytics_daily;
```

### Query timeout policies

```sql
-- Prevent runaway queries consuming all credits
ALTER WAREHOUSE analytics_wh SET
    STATEMENT_TIMEOUT_IN_SECONDS = 300;     -- kill queries > 5 minutes
    
ALTER WAREHOUSE etl_wh SET
    STATEMENT_TIMEOUT_IN_SECONDS = 3600;    -- ETL can run up to 1 hour

-- Statement queued timeout (don't let queries wait >5min)
ALTER WAREHOUSE analytics_wh SET
    STATEMENT_QUEUED_TIMEOUT_IN_SECONDS = 300;
```

### Cost attribution by tag / warehouse

```sql
-- Credit consumption by warehouse (last 30 days)
SELECT
    warehouse_name,
    SUM(credits_used_compute) AS compute_credits,
    SUM(credits_used_cloud_services) AS cloud_service_credits,
    SUM(credits_used_compute + credits_used_cloud_services) AS total_credits,
    ROUND(SUM(credits_used_compute + credits_used_cloud_services) * 2.5, 2) AS est_cost_usd
FROM snowflake.account_usage.warehouse_metering_history
WHERE start_time >= DATEADD(DAY, -30, CURRENT_TIMESTAMP())
GROUP BY warehouse_name
ORDER BY total_credits DESC;

-- Top 10 most expensive queries (last week)
SELECT
    query_id,
    user_name,
    warehouse_name,
    ROUND(total_elapsed_time / 3600000.0
          * credits_per_hour_of_warehouse, 4) AS estimated_credits,
    query_text
FROM (
    SELECT
        q.*,
        CASE w.size
            WHEN 'X-Small' THEN 1 WHEN 'Small' THEN 2 WHEN 'Medium' THEN 4
            WHEN 'Large' THEN 8 WHEN 'X-Large' THEN 16 ELSE 4 END
            AS credits_per_hour_of_warehouse
    FROM snowflake.account_usage.query_history q
    JOIN snowflake.account_usage.warehouses w ON q.warehouse_name = w.name
)
WHERE start_time >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
ORDER BY estimated_credits DESC
LIMIT 10;
```

### Storage cost reduction

```sql
-- Storage breakdown by database
SELECT
    table_catalog AS database_name,
    SUM(active_bytes) / 1e12 AS active_tb,
    SUM(time_travel_bytes) / 1e12 AS time_travel_tb,
    SUM(failsafe_bytes) / 1e12 AS failsafe_tb,
    SUM(active_bytes + time_travel_bytes + failsafe_bytes) / 1e12 AS total_tb
FROM snowflake.account_usage.table_storage_metrics
GROUP BY 1
ORDER BY total_tb DESC;

-- Reduce time travel on dev/test tables (default 1 day for Standard, 90 for Enterprise)
ALTER TABLE dev.sandbox.large_test_table SET DATA_RETENTION_TIME_IN_DAYS = 1;
ALTER SCHEMA dev.sandbox SET DATA_RETENTION_TIME_IN_DAYS = 1;
ALTER DATABASE dev SET DATA_RETENTION_TIME_IN_DAYS = 1;

-- Tables never queried (candidates for archiving)
SELECT
    table_catalog, table_schema, table_name,
    row_count, active_bytes / 1e9 AS size_gb,
    last_altered
FROM snowflake.account_usage.tables
WHERE last_altered < DATEADD(MONTH, -6, CURRENT_TIMESTAMP())
  AND active_bytes > 1e9  -- > 1GB
ORDER BY active_bytes DESC;
```

## Real-world scenario

Mid-size SaaS company: Snowflake bill went from $12K to $65K in 4 months. Investigation via `warehouse_metering_history`:
- `DATA_SCIENCE_WH` consuming 80% of credits — 3 data scientists running iterative ML feature queries on `facts_users` (5TB table, full scans)
- No auto-suspend on `REPORTING_WH` — running idle Friday to Monday
- Default 90-day time travel on all Enterprise tables including dev/test

Fixes:
1. Resource monitor on `DATA_SCIENCE_WH`: 100 credits/day → suspend
2. Auto-suspend on all warehouses ≤ 60 seconds
3. Dev/test databases: `DATA_RETENTION_TIME_IN_DAYS = 1`
4. Clustering key on `facts_users (event_date)` — DS queries hit only relevant partitions

Result: $65K → $18K/month.

## References
- [Resource Monitors](https://docs.snowflake.com/en/user-guide/resource-monitors)
- [Warehouse Metering History](https://docs.snowflake.com/en/sql-reference/account-usage/warehouse_metering_history)
- [Table Storage Metrics](https://docs.snowflake.com/en/sql-reference/account-usage/table_storage_metrics)
- [Data Retention Time](https://docs.snowflake.com/en/user-guide/data-time-travel)
