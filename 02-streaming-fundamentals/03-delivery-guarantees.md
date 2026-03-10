# Delivery Guarantees: At-most-once, At-least-once, Exactly-once

## What problem does this solve?
Networks fail. Nodes crash. When your streaming job restarts, which records get reprocessed? The answer determines whether your data has gaps, duplicates, or is perfectly accurate.

## How it works

### At-most-once
Process each record at most once. On failure, some records may be skipped. **No duplicates, but data loss possible.**

```
Producer → Kafka → Consumer (acks after processing)
If consumer crashes BEFORE ack: record is skipped on restart
```

Use when: losing some events is acceptable (e.g., analytics metrics where slight undercounting is fine).

### At-least-once
Process each record at least once. On failure, records are reprocessed. **No data loss, but duplicates possible.**

```
Producer → Kafka → Consumer (acks after writing output)
If consumer crashes AFTER writing but BEFORE ack: record is reprocessed on restart → duplicate in output
```

Use when: duplicates can be handled downstream (e.g., idempotent MERGE, dedup logic).

### Exactly-once
Every record is processed exactly once, even across failures. **No data loss, no duplicates.**

Achieved by combining:
1. **Idempotent writes** — re-writing same data produces same result
2. **Transactional commits** — offset commit and output write are atomic

![diagram](../diagrams/02-streaming-fundamentals--03-delivery-guarantees.png)

## Spark Structured Streaming: exactly-once with Delta

```python
# Exactly-once: checkpoint + Delta atomic write
spark.readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "broker:9092") \
    .option("subscribe", "payments") \
    .load() \
    .writeStream \
    .format("delta") \
    .outputMode("append") \
    .option("checkpointLocation", "/chk/payments") \  # atomic offset tracking
    .table("silver.payments")                          # Delta atomic write
```

Delta Lake guarantees: if the job restarts, the checkpoint replays from the last committed offset, and Delta's transaction log prevents partial writes.

## Kafka producer guarantees

```python
from confluent_kafka import Producer

# Exactly-once producer config
producer = Producer({
    'bootstrap.servers': 'broker:9092',
    'enable.idempotence': True,        # exactly-once per partition
    'acks': 'all',                     # all replicas must ack
    'max.in.flight.requests.per.connection': 5
})
```

## Comparison

| Guarantee | Data loss? | Duplicates? | Complexity | Cost |
|-----------|-----------|------------|------------|------|
| At-most-once | Possible | No | Low | Low |
| At-least-once | No | Possible | Medium | Medium |
| Exactly-once | No | No | High | High |

## Real-world scenario
Payment processing: at-least-once is the minimum — you can never lose a payment event. But duplicates (processing a payment twice) are catastrophic. Solution: exactly-once Kafka → Delta with idempotent MERGE on `payment_id`. Even if the event is received twice, the MERGE produces one row.

## What goes wrong in production
- **Assuming exactly-once without checkpoints** — job restarts from beginning, reprocesses all Kafka history. Always set `checkpointLocation`.
- **Checkpoints on local disk** — node is replaced, checkpoint lost, full replay. Use ADLS/S3/GCS for checkpoints.
- **Sinking to non-idempotent systems** — writing exactly-once to Delta is safe; writing to a REST API that creates records on each call is not. Make sinks idempotent.

## References
- [Confluent — Exactly-Once Semantics in Kafka](https://www.confluent.io/blog/exactly-once-semantics-are-possible-heres-how-apache-kafka-does-it/)
- [Spark Structured Streaming Fault Tolerance](https://spark.apache.org/docs/latest/structured-streaming-programming-guide.html#fault-tolerance-semantics)
- [Delta Lake — Streaming](https://docs.delta.io/latest/delta-streaming.html)
