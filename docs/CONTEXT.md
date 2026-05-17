# CONTEXT — data-engineering-helper

## Repo purpose
A reference handbook for data engineering: theory, patterns, and now end-to-end runnable hello-world tutorials.

## Current extension (dev branch)
Add a new top-level section **`12-hands-on-tutorials/`** containing three step-by-step runnable tutorials.

### Scope
Three tutorials, progressive:

1. **`01-dbt-hello-world/`** — Standalone dbt project (sources → staging → mart → tests) against a Dockerized Postgres warehouse.
2. **`02-airflow-hello-world/`** — Standalone Airflow project. Single DAG with 2–3 tasks demonstrating PythonOperator / BashOperator / dependencies.
3. **`03-airflow-dbt-integration/`** — Airflow DAG that orchestrates the dbt project from tutorial #1. Demonstrates the canonical Airflow→dbt pattern.

### Runtime
- **Docker Compose only.** Each tutorial ships its own `docker-compose.yml`.
- No host-side Python install required beyond Docker Desktop.

### Audience
- Data engineers wanting a quick refresher.
- New learners doing their first end-to-end dbt or Airflow run.
- Anyone forking the repo to reproduce locally.

### Format per tutorial
- `README.md` with numbered step-by-step instructions (prereqs → up → verify → cleanup).
- `docker-compose.yml` self-contained.
- Source code (dbt project, DAG file).
- Expected output snippets and verification commands.

### Working style for this extension
- User runs each step locally and reports output before moving on.
- Agent writes content; user is the sole executor in tutorial-validation mode.
- Step-by-step instructions are written so that an unaided reader could also reproduce.

## Workflow
Following the Pocock 5-step gate:
1. grill-with-docs (this CONTEXT + PRD scoping) — **in progress**
2. to-prd (PRD + parent GitHub issue) — pending
3. architect (plan in checklist, AWAIT USER APPROVAL) — pending
3.5. to-issues (slice issues) — pending
4. tdd (slice work, each slice = runnable proof) — pending
4.5. HITL review — pending
6. log-and-commit — pending

## Out of scope
- Production-grade Docker setups (resource limits, secrets management beyond env files).
- Advanced Airflow features (XCom backends, dynamic task mapping, deferrable operators).
- Advanced dbt features (snapshots, complex Jinja, dbt Cloud).
- Performance tuning.
- Cloud deployments (handled in `08-cloud-platforms/`).
