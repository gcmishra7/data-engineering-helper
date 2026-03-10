# Streaming Windows: Tumbling, Sliding, Session

## What problem does this solve?
Raw event streams are infinite. To compute aggregations ("payments per minute", "clicks per session"), you must divide the stream into finite groups — windows.

## How it works

### Tumbling Windows
Fixed-size, non-overlapping. Every event belongs to exactly one window.

```
Time: ─────────────────────────────────────────────────►
       [──── 1min ────][──── 1min ────][──── 1min ────]
       Window 1        Window 2        Window 3
```

```python
# Payments per minute
F.window(F.col("event_ts"), "1 minute")
```

### Sliding Windows
Fixed-size, overlapping. Events can belong to multiple windows. Useful for moving averages.

```
Time: ─────────────────────────────────────────────────►
       [──── 5min ────]
              [──── 5min ────]
                     [──── 5min ────]
       ← slide: 1min →
```

```python
# 5-minute average, updated every 1 minute
F.window(F.col("event_ts"), "5 minutes", "1 minute")
```

### Session Windows
Dynamic size based on activity gaps. Window closes after a period of inactivity. Perfect for user sessions.

```
User A: ●──●────●   gap > 30min   ●──●
        [─Session 1─]             [S2]
```

```python
# Flink (session windows — not natively in Spark Structured Streaming)
# Spark alternative: use mapGroupsWithState for session tracking
```

## Spark code: all three

```python
from pyspark.sql import functions as F

# Read stream
events = spark.readStream.format("delta").table("bronze.clickstream")

# Tumbling: clicks per page per minute
tumbling = events \
    .withWatermark("event_ts", "10 minutes") \
    .groupBy(F.window("event_ts", "1 minute"), "page_id") \
    .count()

# Sliding: 5-min rolling avg revenue, updated every minute
sliding = events \
    .withWatermark("event_ts", "10 minutes") \
    .groupBy(F.window("event_ts", "5 minutes", "1 minute"), "product_id") \
    .agg(F.avg("revenue").alias("avg_revenue"))
```

## Comparison

| Window | Size | Overlap | Best for |
|--------|------|---------|----------|
| Tumbling | Fixed | None | Period reports (hourly, daily counts) |
| Sliding | Fixed | Yes | Rolling averages, moving metrics |
| Session | Dynamic | None | User activity, clickstream sessions |

## Real-world scenario
E-commerce fraud detection:
- **Tumbling (1 min)**: alert if >100 failed auth attempts per IP per minute
- **Sliding (5 min, every 1 min)**: rolling average transaction amount per card — spike detection
- **Session**: group all events in a user browsing session to detect bot-like rapid navigation

## What goes wrong in production
- **Missing watermark on windowed aggregation** — Spark error in streaming mode. Watermark is required for event-time windows.
- **Window too large for memory** — 24-hour session windows on 10M users = huge state. Use session timeout of realistic inactivity (5–30 minutes).
- **Output mode wrong** — tumbling windows need `outputMode("append")`. Sliding windows with updates need `outputMode("update")`. Mismatch causes runtime error.

## References
- [Spark Structured Streaming Windows](https://spark.apache.org/docs/latest/structured-streaming-programming-guide.html#types-of-time-windows)
- [Flink Windows Documentation](https://nightlies.apache.org/flink/flink-docs-stable/docs/dev/datastream/operators/windows/)
