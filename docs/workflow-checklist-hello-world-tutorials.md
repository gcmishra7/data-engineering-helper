# Workflow Checklist — Hello-World Tutorials

Slug: `hello-world-tutorials`
Branch: `dev`
PRD: [`PRD-hello-world-tutorials.md`](./PRD-hello-world-tutorials.md)
Parent issue: _TBD (will be filled when issue is opened)_

## Pocock 5-step gate

- [x] **1. grill-with-docs** — alignment captured in [`CONTEXT.md`](./CONTEXT.md); decisions: section `12-hands-on-tutorials/`, three tutorials (separate first, then integrated), Docker Compose only, full Pocock gate with GitHub issues.
- [x] **2. to-prd** — PRD drafted at [`PRD-hello-world-tutorials.md`](./PRD-hello-world-tutorials.md); parent issue: _pending_.
- [ ] **3. architect** — plan appended below; **AWAITING USER APPROVAL** before proceeding.
- [ ] **3.5. to-issues** — slice issues opened (7 planned).
- [ ] **4. tdd** — per-slice red/green/refactor (here "test" = runnable proof: `docker compose up` works and verification step passes).
- [ ] **4.5. HITL review** — agent summary + user sign-off after each slice.
- [ ] **6. log-and-commit** — entries in [`agent-log.md`](./agent-log.md), commits per slice.

---

## Architect plan

### Resolutions to PRD §8 open questions

| Q | Resolution | Rationale |
|---|---|---|
| Q1 — Postgres version | `postgres:15-alpine` | Stable, small, dbt-postgres fully supports. |
| Q2 — dbt version | `dbt-postgres==1.7.*` (installed inside dbt service container) | Latest stable line on PyPI compatible with Python 3.11 and PG15. |
| Q3 — Airflow image | `apache/airflow:2.9.3-python3.11` | Current stable line; well documented; LocalExecutor works without Celery infra. |
| Q4 — Tutorial 3 Postgres count | **One** Postgres instance, two databases (`airflow_db`, `warehouse`) | Simpler Compose, fewer resources; trade-off documented in tutorial README. |
| Q5 — Tutorial 3 dbt project source | **Self-contained copy** (not symlink/mount from Tutorial 1) | Each tutorial must be independently runnable from a clean clone. Duplication is acceptable for demo. |

### Slice details

#### S1 — Section scaffold (~15 min)
**Files**:
- `12-hands-on-tutorials/README.md`

**DoD**: section README renders on GitHub; links to the 3 sub-tutorials present (404 OK until later slices).

#### S2 — Tutorial 1: Compose + dbt skeleton (~45 min)
**Files**:
- `12-hands-on-tutorials/01-dbt-hello-world/docker-compose.yml` (services: `postgres`, `dbt`)
- `12-hands-on-tutorials/01-dbt-hello-world/dbt/dbt_project.yml`
- `12-hands-on-tutorials/01-dbt-hello-world/dbt/profiles.yml`
- `12-hands-on-tutorials/01-dbt-hello-world/dbt/seeds/raw_orders.csv` (~10 rows)
- `12-hands-on-tutorials/01-dbt-hello-world/.env.example`
- `12-hands-on-tutorials/01-dbt-hello-world/.gitignore`

**DoD**:
- `docker compose up -d postgres` → healthy.
- `docker compose run --rm dbt dbt debug` → all checks pass.

#### S3 — Tutorial 1: models + tests + README (~45 min)
**Files**:
- `dbt/models/staging/stg_orders.sql` + `schema.yml` (sources, `not_null`, `unique`)
- `dbt/models/marts/orders_summary.sql` + `schema.yml`
- `README.md` (full step-by-step)

**DoD**:
- `dbt seed && dbt run && dbt test` succeeds inside the dbt service container.
- README guides through prereqs → up → seed → run → test → verify SQL query → cleanup.
- User runs each step and reports output before next slice.

#### S4 — Tutorial 2: Compose + Airflow boot (~45 min)
**Files**:
- `12-hands-on-tutorials/02-airflow-hello-world/docker-compose.yml` (Airflow LocalExecutor + Postgres metadata)
- `12-hands-on-tutorials/02-airflow-hello-world/.env.example` (UID, FERNET_KEY, ADMIN credentials)
- `12-hands-on-tutorials/02-airflow-hello-world/dags/.gitkeep`

**DoD**: `docker compose up -d` → Airflow webserver healthy at `http://localhost:8080`, login works.

#### S5 — Tutorial 2: DAG + README (~30 min)
**Files**:
- `dags/hello_world_dag.py` — 3 tasks: `extract` (Python, generates a tiny dict) → `transform` (Python, increments a counter) → `notify` (Bash, `echo`).
- `README.md`

**DoD**: DAG visible in UI, manual trigger turns all 3 tasks green; README walks through every step.

#### S6 — Tutorial 3: Compose + DAG (~60 min)
**Files**:
- `12-hands-on-tutorials/03-airflow-dbt-integration/docker-compose.yml` (Airflow + single Postgres with `airflow_db` + `warehouse` databases, init SQL to create both)
- `12-hands-on-tutorials/03-airflow-dbt-integration/init-db/01_create_warehouse.sql`
- `dags/dbt_pipeline_dag.py` — BashOperator chain: `dbt seed >> dbt run >> dbt test` (runs against the `warehouse` DB via a profiles.yml mounted into the Airflow container)
- `dbt_project/...` — self-contained copy of Tutorial 1's dbt project
- `.env.example`

**DoD**: from inside the Airflow worker container, `dbt run` against the `warehouse` DB succeeds.

#### S7 — Tutorial 3: README + e2e verify (~30 min)
**Files**: `README.md`

**DoD**:
- Triggering the DAG end-to-end populates `warehouse.public.orders_summary`.
- README documents every step; verification SQL produces the expected row count.

### Cross-cutting (done as part of the last slice or a small S7-tail)
- Cross-link from `07-ecosystem-tools/01-airflow-architecture.md` → `12-hands-on-tutorials/02-...` and `03-...`.
- Cross-link from `07-ecosystem-tools/02-dbt-core-patterns.md` → `12-hands-on-tutorials/01-...` and `03-...`.
- Update top-level `README.md` with a row for the new section.

### Risks & mitigations
| Risk | Mitigation |
|---|---|
| Windows file mount / line-ending issues in Compose | Use bind mounts with forward-slash paths; ship `.gitattributes` forcing LF on `.sh`, `.sql`, `.py`. |
| Airflow needs ~4 GB RAM | Document in each Airflow tutorial's prereqs. |
| Port collisions on 5432 / 8080 | Document override via `.env`; suggest `5433` / `8081` as fallbacks. |
| dbt service can't reach Postgres | Use Compose service-name DNS (`host: postgres`), document network in README. |

### Total effort estimate
~4–5 hours of agent authoring + user step-by-step validation time (you run each step locally and report).

---

## Approval gate

**APPROVED 2026-05-17** with revision: user-execution model adopted (S2/S4/S6 are user-run slices following agent-authored implementation guides).

Issues opened as we hit each slice (not all up-front).

---

## Slice tracker (revised — user-execution model)

User runs each command locally; agent authors implementation guides + assists.

| # | Slice | Owner | Issue | Status |
|---|---|---|---|---|
| S1 | Tutorial 1: write implementation guide | agent | _TBD_ | pending |
| S2 | Tutorial 1: user executes guide step-by-step | user | _TBD_ | pending |
| S3 | Tutorial 2: write implementation guide | agent | _TBD_ | pending |
| S4 | Tutorial 2: user executes guide step-by-step | user | _TBD_ | pending |
| S5 | Tutorial 3: write implementation guide | agent | _TBD_ | pending |
| S6 | Tutorial 3: user executes guide step-by-step | user | _TBD_ | pending |
| S7 | Cross-links + top-level README update | agent | _TBD_ | pending |

Validation model: each "user executes" slice is a series of numbered steps inside the implementation guide. After each step the user reports output; if expected output diverges, the agent revises the guide on the spot. The guide is "done" when the user can run it top-to-bottom without intervention.
