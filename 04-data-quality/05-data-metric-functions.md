# Snowflake Data Metric Functions (DMFs)

## What problem does this solve?
Running ad-hoc quality checks on Snowflake tables requires writing and scheduling SQL queries yourself. Data Metric Functions are native, scheduled quality checks built into Snowflake — no external tooling required.

## How it works

### Built-in DMFs

```sql
-- Row count
SELECT SNOWFLAKE.CORE.ROW_COUNT(REF(my_table));

-- NULL count for a column
SELECT SNOWFLAKE.CORE.NULL_COUNT(REF(my_table), 'customer_id');

-- Null percentage
SELECT SNOWFLAKE.CORE.NULL_PERCENT(REF(my_table), 'customer_id');

-- Duplicate count (non-unique values)
SELECT SNOWFLAKE.CORE.DUPLICATE_COUNT(REF(my_table), ARRAY_CONSTRUCT('order_id'));

-- Freshness (hours since last row)
SELECT SNOWFLAKE.CORE.FRESHNESS(REF(my_table), 'created_at');
```

### Custom DMF

```sql
-- Custom: % of rows with invalid email format
CREATE DATA METRIC FUNCTION prod.dq.invalid_email_pct(
    arg_t TABLE(email VARCHAR)
)
RETURNS NUMBER
AS $$
    SELECT ROUND(
        COUNT_IF(NOT REGEXP_LIKE(email, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$'))
        * 100.0 / NULLIF(COUNT(*), 0),
        2
    )
    FROM arg_t
$$;

-- Custom: negative amount count
CREATE DATA METRIC FUNCTION prod.dq.negative_amount_count(
    arg_t TABLE(amount NUMBER)
)
RETURNS NUMBER
AS $$
    SELECT COUNT_IF(amount < 0) FROM arg_t
$$;
```

### Attach DMFs to tables and schedule

```sql
-- Attach metrics to table
ALTER TABLE prod.sales.orders
    ADD DATA METRIC FUNCTION SNOWFLAKE.CORE.NULL_COUNT ON (customer_id)
    ADD DATA METRIC FUNCTION SNOWFLAKE.CORE.DUPLICATE_COUNT ON (order_id)
    ADD DATA METRIC FUNCTION prod.dq.negative_amount_count ON (total_amount);

-- Schedule: run every hour
ALTER TABLE prod.sales.orders
    SET DATA_METRIC_SCHEDULE = 'TRIGGER_ON_CHANGES';  -- or '60 MINUTES'

-- Or trigger on table changes only
ALTER TABLE prod.sales.orders
    SET DATA_METRIC_SCHEDULE = 'TRIGGER_ON_CHANGES';
```

### Query results

```sql
-- View scheduled metric results
SELECT
    table_name,
    metric_name,
    value,
    measurement_time
FROM SNOWFLAKE.LOCAL.DATA_QUALITY_MONITORING_RESULTS
WHERE table_name = 'ORDERS'
ORDER BY measurement_time DESC;

-- Build a quality trend dashboard
SELECT
    DATE(measurement_time) AS check_date,
    metric_name,
    AVG(value) AS avg_value
FROM SNOWFLAKE.LOCAL.DATA_QUALITY_MONITORING_RESULTS
WHERE table_name = 'ORDERS'
  AND measurement_time >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY 1, 2
ORDER BY 1, 2;
```

## Real-world scenario
Analytics team noticed revenue dashboard going stale every few days. Investigation: `FRESHNESS` DMF on `fact_orders` showed 18-hour lag on 3 occasions in a month. Root cause: the Fivetran sync was silently failing. With TRIGGER_ON_CHANGES, the freshness DMF fires immediately when data stops arriving — instead of analysts noticing hours later.

## What goes wrong in production
- **DMF compute cost** — DMFs run on the table's default warehouse. Schedule them to run off-peak or use a dedicated small warehouse.
- **Results table not monitored** — DMFs write to `DATA_QUALITY_MONITORING_RESULTS` but nobody queries it. Build a Streamlit dashboard or connect to your alerting system.
- **Custom DMF wrong return type** — must return a NUMBER. Returning VARCHAR causes silent failure.

## References
- [Snowflake Data Metric Functions](https://docs.snowflake.com/en/user-guide/data-quality-intro)
- [Snowflake Custom DMFs](https://docs.snowflake.com/en/user-guide/data-quality-custom-metric-functions)
- [Snowflake Account Usage](https://docs.snowflake.com/en/sql-reference/account-usage)
