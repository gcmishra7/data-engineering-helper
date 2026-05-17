# PRD — Hello-World Hands-On Tutorials (dbt + Airflow)

**Status**: Draft (awaiting architect-phase approval)
**Branch**: `dev`
**Owner**: gcmishra7
**Date**: 2026-05-17

---

## 1. Problem
The repo currently has strong reference/theory material for Airflow (`07-ecosystem-tools/01-airflow-architecture.md`) and dbt (`07-ecosystem-tools/02-dbt-core-patterns.md`), but no end-to-end runnable tutorials. Readers wanting a quick refresher or a first hands-on cannot clone-and-run anything. The PR author also wants reproducible artefacts for personal revision.

## 2. Goal
Add a new top-level section **`12-hands-on-tutorials/`** with three progressive, step-by-step, runnable tutorials covering dbt, Airflow, and their integration. Each tutorial spins up via Docker Compose, runs in under ~10 minutes on a clean machine, and documents prerequisites, exact commands, expected output, and cleanup.

## 3. Non-goals
- Production-grade configuration (resource limits, prod secrets, HA).
- Cloud deployment patterns (covered in `08-cloud-platforms/`).
- Advanced dbt features (snapshots, custom materialisations, complex macros).
- Advanced Airflow features (deferrable operators, XCom custom backends, dynamic task mapping).
- Performance / scale testing.

## 4. Target users
- Data engineers wanting a 30-min refresher.
- First-time dbt / Airflow users wanting a verified hello-world.
- The author, as personal revision material.

## 5. Tutorials (in order)

### Tutorial 1 — `01-dbt-hello-world/`
Standalone dbt project against a Dockerized Postgres warehouse.

**Demonstrates**: `dbt seed`, `dbt run`, `dbt test`, source → staging → mart layering, `schema.yml`, `not_null` / `unique` tests.

**Components**:
- `docker-compose.yml` — Postgres 15 + dbt CLI container
- `dbt_project/` — project with `models/staging/`, `models/marts/`, `seeds/`, `tests/`, `profiles.yml`
- Sample data: 1 small seed (e.g., raw customer orders, 10 rows)

### Tutorial 2 — `02-airflow-hello-world/`
Standalone Airflow with one DAG.

**Demonstrates**: scheduler + webserver + (sqlite metadata DB) in Compose, DAG file structure, PythonOperator, BashOperator, task dependencies (`>>`), schedule_interval, viewing logs in the UI.

**Components**:
- `docker-compose.yml` — Airflow standalone (LocalExecutor + Postgres metadata DB)
- `dags/hello_world_dag.py` — 3 tasks: extract (Python) → transform (Python) → notify (Bash echo)
- `.env` and `airflow.cfg` overrides as needed

### Tutorial 3 — `03-airflow-dbt-integration/`
Airflow DAG that runs the dbt project from Tutorial 1.

**Demonstrates**: a single Compose stack with Airflow + Postgres warehouse + dbt; a DAG with tasks `dbt_seed >> dbt_run >> dbt_test` using `BashOperator` (kept simple — `DbtRunOperator` from `astronomer-cosmos` is mentioned as a "next step" but not used to keep dependencies light).

**Components**:
- `docker-compose.yml` — Airflow + Postgres (shared as both Airflow metadata and dbt warehouse OR two Postgres instances — to be decided in architect phase)
- `dags/dbt_pipeline_dag.py`
- `dbt_project/` — copy or symlink of the Tutorial 1 project (decision in architect phase)

## 6. Format & content standards per tutorial

Each tutorial's `README.md` must contain, in order:

1. **What you'll build** — one-paragraph summary + architecture diagram (mermaid OK).
2. **Prerequisites** — Docker Desktop version, disk space, ports needed.
3. **Step-by-step** — numbered steps with:
   - exact command in a fenced code block
   - expected stdout snippet
   - "if you see X, do Y" troubleshooting note where common
4. **Verify** — explicit verification commands and success criteria.
5. **Cleanup** — `docker compose down -v` plus anything else.
6. **What's next** — pointer to next tutorial / `07-ecosystem-tools/` theory docs.

## 7. Acceptance criteria

Per tutorial:
- A clean machine with Docker Desktop installed can run the tutorial start-to-finish following only the README, in ≤ 10 minutes wall-clock.
- All commands in the README copy-paste and execute as-is (no placeholders unfilled).
- Verification step produces the documented output.
- `docker compose down -v` leaves no residual containers, volumes, or networks.

Cross-tutorial:
- Tutorials 1 and 2 are independent (can be done in either order).
- Tutorial 3 builds on Tutorial 1 understanding but is technically self-contained (does not depend on Tutorial 1 having been run).
- Style and structure are consistent across all three READMEs.

## 8. Open questions (to resolve in architect phase)
- Q1: Postgres image version pin (15 vs 16)?
- Q2: dbt-postgres version pin?
- Q3: Airflow image version pin (2.9.x line is current stable)?
- Q4: Tutorial 3 — single Postgres or two? (Author preference TBD.)
- Q5: Should Tutorial 3 reuse Tutorial 1's `dbt_project/` (copy vs Compose-mount)?

## 9. Slice plan (preview — finalised in architect phase)
- S1: scaffold `12-hands-on-tutorials/` section + section README
- S2: Tutorial 1 — Docker Compose + dbt project skeleton
- S3: Tutorial 1 — models + tests + README
- S4: Tutorial 2 — Docker Compose + Airflow boot
- S5: Tutorial 2 — DAG + README
- S6: Tutorial 3 — Compose stack + DAG
- S7: Tutorial 3 — README + end-to-end verification

Each slice becomes one GitHub issue.

## 10. Definition of done (PRD level)
- All 7 slice issues closed.
- `dev` branch contains all three tutorials, each verifiably runnable.
- Cross-references added from `07-ecosystem-tools/01-airflow-architecture.md` and `07-ecosystem-tools/02-dbt-core-patterns.md` to the new tutorials.
- Top-level `README.md` updated to mention the new section.
- PR from `dev` → `main` opened and merged.
