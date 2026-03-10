# 11 — AI Data Engineering

> From RAG pipelines to MCP servers to LLMOps. Every concept explained, diagrammed, and battle-tested.

This section extends the handbook into the AI/LLM layer of the modern data stack. It covers how data engineers build, operate, and govern pipelines that power AI applications — from ingesting unstructured content to evaluating RAG quality in production.

---

## Who This Is For

| Role | Start Here |
|------|-----------|
| Data Engineer building RAG | `01-rag-fundamentals/` → `02-vector-databases/` |
| DE handling PDFs / audio / images | `03-unstructured-data-pipelines/` |
| DE building AI-augmented pipelines | `04-mcp-and-ai-tools/` |
| MLOps / Platform Engineer | `05-llm-ops-and-evaluation/` → `06-ai-governance-and-observability/` |
| Architect / Tech Lead | `07-reference-architectures/` |
| Interview prep | `ai-de-interview-questions.md` (Q96–Q150) |

---

## Section Structure

```
11-ai-data-engineering/
├── 01-rag-fundamentals/
│   ├── 01-rag-concepts.md                  RAG indexing + query pipelines, chunking, embeddings
│   └── 02-rag-pipeline-engineering.md      Incremental indexing at scale, multi-source connectors
│
├── 02-vector-databases/
│   └── 01-vector-databases.md              HNSW, IVF, pgvector, Pinecone, Weaviate, multi-tenancy
│
├── 03-unstructured-data-pipelines/
│   └── 01-unstructured-data-pipelines.md  PDF, image, audio, LLM extraction, Spark at scale
│
├── 04-mcp-and-ai-tools/
│   └── 01-mcp-model-context-protocol.md   MCP spec, FastMCP server, Snowflake + Databricks tools
│
├── 05-llm-ops-and-evaluation/
│   └── 01-llmops-and-evaluation.md         RAGAS, LLM-as-judge, Langfuse, cost tracking
│
├── 06-ai-governance-and-observability/
│   └── 01-ai-governance.md                 PII handling, guardrails, multi-tenant isolation, GDPR
│
├── 07-reference-architectures/
│   └── 01-ai-de-reference-architectures.md 4 production architectures + technology selection guide
│
└── ai-de-interview-questions.md            55 interview questions (Q96–Q150) with full answers
```

---

## Key Concepts Map

```
                    ┌─────────────────────────────┐
                    │     AI Application Layer     │
                    │   RAG Chatbot · AI Agent     │
                    └──────────────┬──────────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              ▼                    ▼                    ▼
    ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
    │  Vector Store   │  │   LLM Gateway   │  │  MCP Server     │
    │ Pinecone/pgvec  │  │ LiteLLM · GPT  │  │ SQL · Files     │
    └────────┬────────┘  └─────────────────┘  └─────────────────┘
             │
    ┌────────▼────────┐
    │ Indexing Pipeline│
    │ Databricks/Spark │
    │ Chunk · Embed   │
    └────────┬────────┘
             │
    ┌────────▼────────────────────────────────┐
    │           Unstructured Data Sources      │
    │  PDFs · Images · Audio · HTML · Email    │
    └──────────────────────────────────────────┘
```

---

## Interview Questions Coverage

Questions **Q96–Q150** in `ai-de-interview-questions.md` cover:

| Section | Questions | Topics |
|---------|-----------|--------|
| RAG Fundamentals | Q96–Q107 | Indexing pipeline, chunking, embeddings, HyDE, re-ranking, evaluation |
| Vector Databases | Q108–Q116 | ANN algorithms, pgvector, Pinecone, multi-tenancy, HNSW tuning |
| Unstructured Pipelines | Q117–Q124 | PDF parsing, LLM extraction, audio, multimodal RAG |
| MCP & AI Agents | Q125–Q132 | MCP spec, security, HITL pattern, multi-agent |
| LLMOps & Governance | Q133–Q144 | RAGAS, faithfulness, PII, guardrails, GDPR erasure |
| System Design | Q145–Q150 | Enterprise RAG, multilingual, call analytics, top mistakes |

---

## References

- [Model Context Protocol Spec](https://modelcontextprotocol.io/specification)
- [RAGAS Documentation](https://docs.ragas.io/)
- [LangChain RAG Tutorial](https://python.langchain.com/docs/tutorials/rag/)
- [Pinecone Learn](https://www.pinecone.io/learn/)
- [Databricks Generative AI](https://docs.databricks.com/en/generative-ai/index.html)
- [Unstructured.io](https://unstructured-io.github.io/unstructured/)
- [Langfuse](https://langfuse.com/docs)
- [FastMCP](https://gofastmcp.com/)
