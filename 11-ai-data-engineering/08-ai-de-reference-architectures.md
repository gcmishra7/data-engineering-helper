# AI Data Engineering — Reference Architectures

## Architecture 1 — Enterprise RAG Platform

```mermaid
graph TD
    subgraph Sources
        CONF[Confluence] & S3[S3/ADLS] & DB_SRC[(PostgreSQL<br/>product docs)]
    end
    subgraph Indexing Pipeline - Databricks
        AL[Auto Loader<br/>detect changes]
        PARSE[Document Parser<br/>Unstructured.io]
        PII[PII Scrubber<br/>Presidio]
        CHUNK[Chunker<br/>semantic + parent-child]
        EMBED[Embedding Worker<br/>text-embedding-3-small]
        IDX_DELTA[Document Index<br/>Delta Lake]
    end
    subgraph Query Platform
        API[FastAPI<br/>RAG endpoint]
        GUARD[Guardrails<br/>input + output]
        VS[Pinecone<br/>vector store]
        LLM_GW[LLM Gateway<br/>rate limit · fallback]
        LLM[GPT-4o / Claude]
    end
    subgraph Observability
        LANGFUSE[Langfuse<br/>tracing]
        LINEAGE_TBL[Query Lineage<br/>Delta Table]
        DASH[Quality Dashboard<br/>Databricks SQL]
    end

    CONF & S3 & DB_SRC --> AL --> PARSE --> PII --> CHUNK --> EMBED
    EMBED --> VS
    EMBED --> IDX_DELTA
    API --> GUARD --> VS --> LLM_GW --> LLM
    API --> LANGFUSE --> LINEAGE_TBL --> DASH
```

**Key design decisions:**
- Databricks for indexing (parallelise over millions of documents)
- Parent-child chunking: 200-token children for retrieval, 2000-token parents for LLM context
- PII scrubbing before embedding AND before logging
- LLM Gateway (LiteLLM) for model routing, rate limiting, and fallback (GPT-4o → Claude if down)
- Separate evaluation pipeline runs nightly against 200-question benchmark

---

## Architecture 2 — Unstructured Data Lakehouse

```mermaid
graph LR
    subgraph Bronze - Raw Unstructured
        PDF[PDFs] & IMG[Images] & AUDIO[Audio] & EMAIL[Emails]
    end
    subgraph Silver - Extracted + Structured
        PARSED[Parsed Text<br/>Delta Table]
        EXTRACTED[LLM Extractions<br/>invoices · contracts · claims]
        TRANSCRIPTS[Transcripts<br/>call recordings]
    end
    subgraph Gold - Analytical
        CLASSIFIED[Classified Documents<br/>category · sentiment · topics]
        METRICS[Business Metrics<br/>invoice totals · claim amounts]
        EMBEDDINGS[Embedding Store<br/>Delta + pgvector]
    end

    PDF & IMG --> PARSED
    AUDIO --> TRANSCRIPTS
    EMAIL --> PARSED
    PARSED --> EXTRACTED
    PARSED & TRANSCRIPTS --> CLASSIFIED
    EXTRACTED --> METRICS
    PARSED --> EMBEDDINGS
```

**SLA targets:**

| Stage | Latency | Volume |
|---|---|---|
| Bronze landing → Silver parsed | < 30 min | 10K docs/hour |
| Silver → Gold extraction (LLM) | < 2 hours | 10K docs/hour |
| Gold → BI dashboard | < 5 min refresh | - |

---

## Architecture 3 — AI-Augmented Data Pipeline (agentic)

```mermaid
graph TD
    TRIGGER[Trigger<br/>schedule · event · user] --> AGENT[AI Agent<br/>Claude / GPT-4o with tools]

    subgraph MCP Tools Available to Agent
        SQL[execute_sql<br/>Snowflake / Databricks]
        SCHEMA[get_schema<br/>Unity Catalog]
        PROFILE[profile_table<br/>data quality]
        PIPELINE[trigger_pipeline<br/>Databricks Workflows]
        NOTIFY[send_notification<br/>Slack · PagerDuty]
    end

    AGENT --> SQL & SCHEMA & PROFILE & PIPELINE & NOTIFY
    AGENT --> PLAN[Execution Plan<br/>human-approved]
    PLAN --> EXECUTE[Autonomous execution]
    EXECUTE --> REPORT[Summary report<br/>to data team Slack]
```

**Use cases:**
- Automated data quality investigation: "silver.payments has 15% null rate spike — investigate root cause and report"
- Pipeline health check: agent queries DLT event log, checks freshness, pings on-call if SLA missed
- Ad-hoc analysis request: business user asks question → agent writes SQL → runs → returns chart

---

## Architecture 4 — Fine-Tuned Domain Model Pipeline

```mermaid
graph LR
    subgraph Training Data
        QDELTA[Q&A Pairs<br/>Delta Table<br/>human-curated]
        SYNTHETIC[Synthetic Q&A<br/>GPT-4o generated<br/>from corpus]
    end
    subgraph Training Pipeline - Databricks ML
        PREP[Data Prep<br/>format · filter · split]
        FINETUNE[Fine-Tune<br/>Llama 3.1 8B<br/>on domain data]
        EVAL[Evaluation<br/>RAGAS · custom rubric]
        MR[MLflow Model Registry]
    end
    subgraph Deployment
        SERVING[Databricks Model Serving<br/>or vLLM on GPU]
        RAG2[RAG Pipeline<br/>domain LLM + vector search]
    end

    QDELTA & SYNTHETIC --> PREP --> FINETUNE --> EVAL --> MR --> SERVING --> RAG2
```

**When to fine-tune vs pure RAG:**

| Situation | Use RAG | Use Fine-tuning |
|---|---|---|
| Private internal knowledge | ✅ (primary use case) | ❌ (data grows, RAG scales) |
| Specific output format/style | ❌ | ✅ (teach the format) |
| Domain terminology / jargon | Use RAG + few-shot | ✅ (learn domain language) |
| Knowledge cutoff issues | ✅ (add new docs to index) | ❌ (static after training) |
| Cost at scale (millions of queries) | Expensive (big context) | ✅ (smaller model + no retrieval) |

---

## Technology Selection Guide

```
Need to serve private documents to users?
└── RAG with vector database

Documents are PDFs/images/audio?
└── Unstructured pipeline (Unstructured.io / Azure DI / Whisper) → RAG

Need AI to interact with your data systems (write SQL, trigger jobs)?
└── MCP server + AI agent

Need to monitor AI pipeline quality and cost?
└── Langfuse / LangSmith + RAGAS evaluation

Storing < 500K vectors on existing Postgres stack?
└── pgvector (no new infra)

Storing > 1M vectors, need < 50ms p99 latency?
└── Pinecone (managed) or Qdrant (self-hosted)

Building on Databricks and need embedded search?
└── Databricks Vector Search (native, no separate vector DB)

Need compliance / audit trail for AI queries?
└── Query lineage in Delta + PII scrubbing + Langfuse
```

## References
- [LiteLLM Gateway](https://docs.litellm.ai/)
- [Databricks Vector Search](https://docs.databricks.com/en/generative-ai/vector-search.html)
- [vLLM for self-hosted LLM serving](https://docs.vllm.ai/)
- [LangChain Production Guide](https://python.langchain.com/docs/guides/productionization/)
