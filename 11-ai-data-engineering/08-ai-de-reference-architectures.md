# AI Data Engineering — Reference Architectures

## Architecture 1 — Enterprise RAG Platform

```mermaid
graph TD
    subgraph Sources
        CONF[Confluence]
        S3[S3/ADLS]
        DB_SRC[(PostgreSQL)]
    end
    subgraph Indexing Pipeline - Databricks
        AL[Auto Loader]
        PARSE[Document Parser]
        PII[PII Scrubber]
        CHUNK[Chunker]
        EMBED[Embedding Worker]
        IDX_DELTA[Document Index]
    end
    subgraph Query Platform
        API[FastAPI]
        GUARD[Guardrails]
        VS[Pinecone]
        LLM_GW[LLM Gateway]
        LLM[GPT-4o / Claude]
    end
    subgraph Observability
        LANGFUSE[Langfuse]
        LINEAGE_TBL[Query Lineage]
        DASH[Quality Dashboard]
    end

    CONF --> AL
    S3 --> AL
    DB_SRC --> AL
    AL --> PARSE --> PII --> CHUNK --> EMBED
    EMBED --> VS
    EMBED --> IDX_DELTA
    API --> GUARD --> VS --> LLM_GW --> LLM
    API --> LANGFUSE --> LINEAGE_TBL --> DASH
```

| Node | Details |
|------|---------|
| **PostgreSQL** | product docs |
| **Auto Loader** | detect changes |
| **Document Parser** | Unstructured.io |
| **PII Scrubber** | Presidio |
| **Chunker** | semantic + parent-child |
| **Embedding Worker** | text-embedding-3-small |
| **Document Index** | Delta Lake |
| **FastAPI** | RAG endpoint |
| **Guardrails** | input + output |
| **Pinecone** | vector store |
| **LLM Gateway** | rate limit, fallback |
| **Langfuse** | tracing |
| **Query Lineage** | Delta Table |
| **Quality Dashboard** | Databricks SQL |

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
        PDF[PDFs]
        IMG[Images]
        AUDIO[Audio]
        EMAIL[Emails]
    end
    subgraph Silver - Extracted + Structured
        PARSED[Parsed Text]
        EXTRACTED[LLM Extractions]
        TRANSCRIPTS[Transcripts]
    end
    subgraph Gold - Analytical
        CLASSIFIED[Classified Documents]
        METRICS[Business Metrics]
        EMBEDDINGS[Embedding Store]
    end

    PDF --> PARSED
    IMG --> PARSED
    AUDIO --> TRANSCRIPTS
    EMAIL --> PARSED
    PARSED --> EXTRACTED
    PARSED --> CLASSIFIED
    TRANSCRIPTS --> CLASSIFIED
    EXTRACTED --> METRICS
    PARSED --> EMBEDDINGS
```

| Node | Details |
|------|---------|
| **Parsed Text** | Delta Table |
| **LLM Extractions** | invoices, contracts, claims |
| **Transcripts** | call recordings |
| **Classified Documents** | category, sentiment, topics |
| **Business Metrics** | invoice totals, claim amounts |
| **Embedding Store** | Delta + pgvector |

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
    TRIGGER[Trigger] --> AGENT[AI Agent]

    subgraph MCP Tools Available to Agent
        SQL[execute_sql]
        SCHEMA[get_schema]
        PROFILE[profile_table]
        PIPELINE[trigger_pipeline]
        NOTIFY[send_notification]
    end

    AGENT --> SQL
    AGENT --> SCHEMA
    AGENT --> PROFILE
    AGENT --> PIPELINE
    AGENT --> NOTIFY
    AGENT --> PLAN[Execution Plan]
    PLAN --> EXECUTE[Autonomous execution]
    EXECUTE --> REPORT[Summary report]
```

| Node | Details |
|------|---------|
| **Trigger** | schedule, event, user |
| **AI Agent** | Claude / GPT-4o with tools |
| **execute_sql** | Snowflake / Databricks |
| **get_schema** | Unity Catalog |
| **profile_table** | data quality |
| **trigger_pipeline** | Databricks Workflows |
| **send_notification** | Slack, PagerDuty |
| **Execution Plan** | human-approved |
| **Summary report** | to data team Slack |

**Use cases:**
- Automated data quality investigation: "silver.payments has 15% null rate spike — investigate root cause and report"
- Pipeline health check: agent queries DLT event log, checks freshness, pings on-call if SLA missed
- Ad-hoc analysis request: business user asks question → agent writes SQL → runs → returns chart

---

## Architecture 4 — Fine-Tuned Domain Model Pipeline

```mermaid
graph LR
    subgraph Training Data
        QDELTA[Q&A Pairs]
        SYNTHETIC[Synthetic Q&A]
    end
    subgraph Training Pipeline - Databricks ML
        PREP[Data Prep]
        FINETUNE[Fine-Tune]
        EVAL[Evaluation]
        MR[MLflow Model Registry]
    end
    subgraph Deployment
        SERVING[Databricks Model Serving]
        RAG2[RAG Pipeline]
    end

    QDELTA --> PREP
    SYNTHETIC --> PREP
    PREP --> FINETUNE --> EVAL --> MR --> SERVING --> RAG2
```

| Node | Details |
|------|---------|
| **Q&A Pairs** | Delta Table, human-curated |
| **Synthetic Q&A** | GPT-4o generated, from corpus |
| **Data Prep** | format, filter, split |
| **Fine-Tune** | Llama 3.1 8B, on domain data |
| **Evaluation** | RAGAS, custom rubric |
| **Databricks Model Serving** | or vLLM on GPU |
| **RAG Pipeline** | domain LLM + vector search |

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
