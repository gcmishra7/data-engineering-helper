# Snowflake SQL Patterns

## What problem does this solve?
Snowflake SQL has capabilities not found in standard SQL — QUALIFY, FLATTEN, MATCH_CONDITION, PIVOT, MERGE with complex conditions, and lateral joins. Knowing these patterns makes transformations cleaner, avoids expensive subqueries, and writes that work well with Snowflake's columnar engine.

## How it works

### QUALIFY — window function filtering without subquery

```sql
-- Standard SQL: requires subquery to filter on window function result
SELECT * FROM (
    SELECT
        order_id, customer_id, amount,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn
    FROM orders
) WHERE rn = 1;

-- Snowflake: QUALIFY eliminates the subquery
SELECT order_id, customer_id, amount
FROM orders
QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) = 1;

-- Most recent order per customer
SELECT customer_id, order_id, amount, order_date
FROM fact_orders
QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) = 1;

-- Deduplicate: keep highest-amount order per day per customer
SELECT customer_id, order_date, order_id, amount
FROM fact_orders
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id, order_date
    ORDER BY amount DESC
) = 1;

-- Running total exceeds threshold (first order where cumulative spend > 1000)
SELECT customer_id, order_date, amount,
       SUM(amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS cumulative_spend
FROM fact_orders
QUALIFY cumulative_spend >= 1000
  AND LAG(cumulative_spend, 1, 0) OVER (PARTITION BY customer_id ORDER BY order_date) < 1000;
```

### FLATTEN — unnest semi-structured data (VARIANT, ARRAY, OBJECT)

```sql
-- Source: VARIANT column with JSON array
-- raw_events.event_data = {"user_id": "u1", "items": [{"sku":"A","qty":2}, {"sku":"B","qty":1}]}

-- Flatten array of items into rows
SELECT
    e.event_id,
    e.event_date,
    e.event_data:user_id::STRING AS user_id,
    item.value:sku::STRING AS sku,
    item.value:qty::NUMBER AS qty
FROM raw_events e,
LATERAL FLATTEN(INPUT => e.event_data:items) item;

-- Result:
-- event_id | user_id | sku | qty
-- 1        | u1      | A   | 2
-- 1        | u1      | B   | 1

-- Flatten with index (keep position in array)
SELECT
    event_id,
    item.index AS item_position,
    item.value:sku::STRING AS sku
FROM raw_events,
LATERAL FLATTEN(INPUT => event_data:items, outer => TRUE) item;
-- outer => TRUE: keep rows even when array is empty (like LEFT JOIN)

-- Nested flatten: array of objects each containing another array
SELECT
    order_id,
    line.value:product_id::STRING AS product_id,
    attr.value::STRING AS attribute
FROM orders,
LATERAL FLATTEN(INPUT => line_items) line,
LATERAL FLATTEN(INPUT => line.value:attributes) attr;
```

### PIVOT and UNPIVOT

```sql
-- PIVOT: rows to columns
-- Source: monthly_sales (month VARCHAR, region VARCHAR, revenue NUMBER)
SELECT *
FROM monthly_sales
PIVOT (
    SUM(revenue) FOR month IN ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun')
) AS pvt;
-- Produces: region | Jan | Feb | Mar | Apr | May | Jun

-- Dynamic PIVOT (when column values aren't known ahead of time)
-- Use stored procedure or dbt macro

-- UNPIVOT: columns to rows
-- Source: wide table with one column per month
SELECT region, month, revenue
FROM monthly_wide
UNPIVOT (revenue FOR month IN (jan_revenue, feb_revenue, mar_revenue))
ORDER BY region, month;
```

### MERGE — full CDC upsert pattern

```sql
-- SCD Type 1: overwrite on match
MERGE INTO dim_customer AS target
USING (SELECT * FROM staging.customer_updates) AS source
    ON target.customer_id = source.customer_id
WHEN MATCHED AND source.updated_at > target.updated_at THEN
    UPDATE SET
        name = source.name,
        email = source.email,
        tier = source.tier,
        updated_at = source.updated_at
WHEN NOT MATCHED THEN
    INSERT (customer_id, name, email, tier, created_at, updated_at)
    VALUES (source.customer_id, source.name, source.email,
            source.tier, source.created_at, source.updated_at)
WHEN NOT MATCHED BY SOURCE AND target.updated_at < DATEADD(YEAR, -2, CURRENT_DATE()) THEN
    DELETE; -- remove records not in source that are over 2 years old

-- SCD Type 2: full history preservation
MERGE INTO dim_customer_history AS target
USING (
    -- Find changed records
    SELECT s.*
    FROM staging.customer_updates s
    JOIN dim_customer_history t
        ON s.customer_id = t.customer_id AND t.is_current = TRUE
    WHERE s.address != t.address OR s.tier != t.tier
) AS source
    ON target.customer_id = source.customer_id AND target.is_current = TRUE
WHEN MATCHED THEN
    UPDATE SET is_current = FALSE, valid_to = source.updated_at
WHEN NOT MATCHED THEN
    INSERT (customer_id, name, email, address, tier, is_current, valid_from, valid_to)
    VALUES (source.customer_id, source.name, source.email, source.address,
            source.tier, TRUE, source.updated_at, '9999-12-31');
```

### Window functions — production patterns

```sql
-- Moving averages (7-day and 30-day)
SELECT
    order_date,
    daily_revenue,
    AVG(daily_revenue) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
        AS revenue_7d_avg,
    AVG(daily_revenue) OVER (ORDER BY order_date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)
        AS revenue_30d_avg
FROM daily_revenue_summary;

-- Gap detection: find periods of inactivity (no orders for > 30 days)
SELECT
    customer_id,
    LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order,
    order_date,
    DATEDIFF(DAY,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date),
        order_date
    ) AS days_gap
FROM fact_orders
QUALIFY days_gap > 30;

-- Session windows: group events into sessions (30-min inactivity = new session)
SELECT
    user_id,
    event_timestamp,
    session_id,
    ROW_NUMBER() OVER (PARTITION BY user_id, session_id ORDER BY event_timestamp)
        AS event_in_session
FROM (
    SELECT
        user_id,
        event_timestamp,
        SUM(is_new_session) OVER (PARTITION BY user_id ORDER BY event_timestamp)
            AS session_id
    FROM (
        SELECT
            user_id,
            event_timestamp,
            CASE WHEN DATEDIFF(MINUTE,
                    LAG(event_timestamp) OVER (PARTITION BY user_id ORDER BY event_timestamp),
                    event_timestamp) > 30
                 THEN 1 ELSE 0 END AS is_new_session
        FROM clickstream_events
    )
);

-- Percentile buckets (decile bucketing for RFM analysis)
SELECT
    customer_id,
    total_spend,
    NTILE(10) OVER (ORDER BY total_spend DESC) AS spend_decile,
    PERCENT_RANK() OVER (ORDER BY total_spend DESC) AS spend_percentile
FROM customer_lifetime_value;
```

### Time series patterns

```sql
-- Fill missing dates (e.g., no sales on weekend = no row)
WITH date_spine AS (
    SELECT DATEADD(DAY, SEQ4(), '2024-01-01'::DATE) AS dt
    FROM TABLE(GENERATOR(ROWCOUNT => 365))
),
sales AS (
    SELECT order_date, SUM(amount) AS revenue
    FROM fact_orders
    WHERE order_date BETWEEN '2024-01-01' AND '2024-12-31'
    GROUP BY order_date
)
SELECT
    d.dt AS date,
    COALESCE(s.revenue, 0) AS revenue,
    COALESCE(s.revenue, LAG(s.revenue IGNORE NULLS)
        OVER (ORDER BY d.dt)) AS revenue_forward_filled
FROM date_spine d
LEFT JOIN sales s ON d.dt = s.order_date;

-- Year-over-year comparison
SELECT
    current_year.order_date,
    current_year.revenue AS revenue_2024,
    prior_year.revenue AS revenue_2023,
    ROUND((current_year.revenue - prior_year.revenue) * 100.0
          / NULLIF(prior_year.revenue, 0), 2) AS yoy_growth_pct
FROM daily_revenue current_year
LEFT JOIN daily_revenue prior_year
    ON current_year.order_date = DATEADD(YEAR, 1, prior_year.order_date);
```

### Handling semi-structured VARIANT data

```sql
-- Access nested fields with colon notation
SELECT
    event_id,
    event_payload:user.id::STRING AS user_id,
    event_payload:context.device.type::STRING AS device_type,
    event_payload:properties.amount::NUMBER(18,2) AS amount,
    event_payload:timestamp::TIMESTAMP_TZ AS event_ts
FROM raw_events;

-- Check if a key exists (avoids NULL on missing keys)
SELECT event_id,
    IFF(event_payload:items IS NOT NULL, ARRAY_SIZE(event_payload:items), 0)
        AS item_count
FROM raw_events;

-- Schema detection on VARIANT (useful for exploring new data)
SELECT * FROM TABLE(INFER_SCHEMA(
    LOCATION => '@my_stage/events/',
    FILE_FORMAT => 'my_json_format'
));
```

## Real-world scenario

Payments platform: complex monthly reporting SQL running for 45 minutes in Redshift. Migrated to Snowflake. Key rewrites:
- 3-level nested subqueries with `ROW_NUMBER()` → replaced with `QUALIFY` (same logic, 60% less code, Snowflake can optimise better)
- JSON unparsing loop in Python → replaced with `LATERAL FLATTEN` (ran in Snowflake, no Python needed)
- Monthly revenue pivot in pandas → replaced with `PIVOT` SQL (ran in warehouse, removed pandas dependency)

Result: 45 minutes → 4 minutes. Same results, no Python pipeline needed.

## What goes wrong in production

- **Casting VARIANT without null check** — `event_payload:amount::NUMBER` returns NULL silently if the field is missing or a string. Use `TRY_CAST` for resilience: `TRY_CAST(event_payload:amount AS NUMBER)`.
- **FLATTEN without OUTER on sparse arrays** — records with `null` or empty arrays are dropped. Use `LATERAL FLATTEN(INPUT => ..., OUTER => TRUE)` to preserve rows.
- **QUALIFY with ambiguous window frame** — `QUALIFY ROW_NUMBER() OVER (PARTITION BY x ORDER BY y) = 1` is deterministic only if `y` is unique within each partition. Add tie-breaking column to ORDER BY.
- **Large MERGE on unpartitioned tables** — MERGE scans both sides fully. Filter the source to changed records only before MERGE to reduce scan cost.

## References
- [Snowflake SQL Reference](https://docs.snowflake.com/en/sql-reference)
- [QUALIFY clause](https://docs.snowflake.com/en/sql-reference/constructs/qualify)
- [FLATTEN function](https://docs.snowflake.com/en/sql-reference/functions/flatten)
- [Semi-Structured Data](https://docs.snowflake.com/en/user-guide/semistructured-intro)
- [Window Functions](https://docs.snowflake.com/en/sql-reference/functions-analytic)
