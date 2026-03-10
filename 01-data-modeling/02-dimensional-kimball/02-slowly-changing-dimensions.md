# Slowly Changing Dimensions (SCD)

## What problem does this solve?
Dimension attributes change over time — a customer moves city, a product changes category. How do you handle historical accuracy? If a sale happened when the customer lived in Singapore but they now live in London, which city should the historical report show?

## How it works

### SCD Type 1 — Overwrite
No history. Just update the current value.
```sql
UPDATE dim_customer SET city = 'London' WHERE customer_id = 42;
```
Use when: history doesn't matter (e.g., fixing a typo, phone number).

### SCD Type 2 — Add New Row (most common)
Keep full history. Each version gets its own surrogate key and validity dates.

```sql
-- dim_customer with SCD Type 2
customer_sk | customer_id | name  | city      | valid_from | valid_to   | is_current
1           | 42          | Alice | Singapore | 2020-01-01 | 2024-06-30 | false
2           | 42          | Alice | London    | 2024-07-01 | 9999-12-31 | true
```

Fact rows joined to `customer_sk=1` correctly show Singapore for historical sales.

```sql
-- dbt snapshot (SCD Type 2 automatically)
{% snapshot dim_customer_snapshot %}
{{
    config(
        target_schema='snapshots',
        unique_key='customer_id',
        strategy='timestamp',
        updated_at='updated_at',
    )
}}
SELECT * FROM {{ source('crm', 'customers') }}
{% endsnapshot %}
```

### SCD Type 3 — Add Column
Keep current + one prior value. Limited history.
```sql
customer_id | city_current | city_previous
42          | London       | Singapore
```
Use when: only one level of history needed and you never need to go further back.

### SCD Type 6 — Hybrid (1+2+3)
Row per version (Type 2) + current value column denormalised (Type 3) for easy "as of today" queries without filtering on `is_current`.

## Delta Lake implementation (SCD Type 2)

```python
from delta.tables import DeltaTable
from pyspark.sql import functions as F

# Merge incoming changes into SCD Type 2 dim
deltaTable = DeltaTable.forName(spark, "gold.dim_customer")

deltaTable.alias("target").merge(
    source=updates.alias("source"),
    condition="target.customer_id = source.customer_id AND target.is_current = true"
).whenMatchedUpdate(
    condition="target.city != source.city",
    set={"valid_to": F.current_date(), "is_current": F.lit(False)}
).execute()

# Insert new versions
new_versions = updates.withColumn("valid_from", F.current_date()) \
    .withColumn("valid_to", F.lit("9999-12-31").cast("date")) \
    .withColumn("is_current", F.lit(True))
deltaTable.alias("t").merge(new_versions.alias("s"), "t.customer_id = s.customer_id AND t.is_current = true") \
    .whenNotMatchedInsertAll().execute()
```

## Real-world scenario
Retail bank: customer `segment` changes from "Retail" to "Private Banking" when their AUM crosses $1M. Historical profitability reports must show which segment they were in at the time of each transaction, not their current segment. SCD Type 2 is mandatory.

## What goes wrong in production
- **Missing `valid_to` filter** — queries return duplicate rows (one per version). Always filter `WHERE is_current = true` or join with date range logic.
- **Exploding history** — high-frequency updates (e.g., last_login timestamp) create thousands of rows per customer. Only capture slowly-changing attributes.

## References
- [Kimball — Slowly Changing Dimensions](https://www.kimballgroup.com/2008/08/slowly-changing-dimensions/)
- [dbt Snapshots Documentation](https://docs.getdbt.com/docs/build/snapshots)
