# Delta Live Tables Expectations

## What problem does this solve?
Adding quality checks to Spark jobs means writing boilerplate validation code in every pipeline. DLT Expectations are declarative — you state the rule, DLT handles routing, metrics, and reporting.

## How it works

DLT has three expectation modes:

| Mode | On violation | Pipeline continues? | Use when |
|------|-------------|--------------------|---------| 
| `@expect` | Record metric, keep bad row | Yes | Monitoring only |
| `@expect_or_drop` | Drop bad row, record metric | Yes | Quarantine bad records |
| `@expect_or_fail` | Fail pipeline | No | Critical data contracts |

```python
import dlt
from pyspark.sql import functions as F

# EXPECT: track violations, keep rows
@dlt.table(name="bronze_orders")
@dlt.expect("valid_order_id", "order_id IS NOT NULL")
@dlt.expect("positive_amount", "amount > 0")
def bronze_orders():
    return spark.readStream.format("kafka") \
        .option("subscribe", "orders") \
        .load() \
        .select(F.from_json("value", order_schema).alias("d")).select("d.*")

# EXPECT OR DROP: bad records silently removed
@dlt.table(name="silver_orders")
@dlt.expect_or_drop("not_null_customer", "customer_id IS NOT NULL")
@dlt.expect_or_drop("valid_status", "status IN ('placed','shipped','delivered','cancelled')")
def silver_orders():
    return dlt.read_stream("bronze_orders")

# EXPECT OR FAIL: critical check — pipeline stops if violated
@dlt.table(name="gold_fact_orders")
@dlt.expect_or_fail("no_negative_revenue", "revenue >= 0")
def gold_fact_orders():
    return dlt.read("silver_orders") \
        .groupBy("customer_id", "order_date") \
        .agg(F.sum("amount").alias("revenue"))
```

### Quarantine pattern with DLT

```python
# Separate good and bad records explicitly
@dlt.table(name="silver_orders_clean")
@dlt.expect_or_drop("valid_order", "order_id IS NOT NULL AND amount > 0")
def silver_orders_clean():
    return dlt.read_stream("bronze_orders")

@dlt.table(name="silver_orders_quarantine")
def silver_orders_quarantine():
    return dlt.read_stream("bronze_orders").filter(
        "order_id IS NULL OR amount <= 0"
    ).withColumn("quarantine_reason",
        F.when(F.col("order_id").isNull(), "null_order_id")
        .otherwise("non_positive_amount")
    )
```

### Querying expectation metrics

```sql
-- DLT event log: query expectation pass/fail rates
SELECT
    timestamp,
    details:flow_progress.metrics.num_output_rows AS output_rows,
    details:flow_progress.data_quality.dropped_records AS dropped,
    details:flow_progress.data_quality.expectations AS expectations
FROM event_log("my_pipeline_id")
WHERE event_type = 'flow_progress'
ORDER BY timestamp DESC;
```

## Real-world scenario
Payments pipeline: 500K events/hour. DLT expectation `positive_amount` catches 0.3% of events with `amount = 0` (a source bug sending $0 auth events that should be filtered). `@expect_or_drop` silently removes them from Silver, metrics dashboard shows the drop rate trend — team notices it spiking on Fridays (batch of test transactions from QA environment).

## What goes wrong in production
- **`@expect_or_fail` on every rule** — one bad record fails the entire pipeline. Use `@expect_or_drop` for row-level issues; `@expect_or_fail` only for table-level contract violations.
- **No monitoring of drop rates** — records dropped silently with `@expect_or_drop` and nobody checks. Build a dashboard from the event log.
- **DLT pipeline in development mode for cost** — development mode reruns from scratch, doesn't restore checkpoints. Use production mode for live pipelines.

## References
- [DLT Expectations Documentation](https://docs.databricks.com/en/delta-live-tables/expectations.html)
- [DLT Observability / Event Log](https://docs.databricks.com/en/delta-live-tables/observability.html)
