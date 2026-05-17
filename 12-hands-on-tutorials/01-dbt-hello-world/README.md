# Tutorial 1 — dbt Hello-World

A standalone dbt project running against a Dockerized Postgres warehouse. You'll load a small CSV, build two SQL models, and run data quality tests — end-to-end.

**Time**: ~15–20 min (first build is slow due to image pulls).
**No host-side install needed** beyond Docker Desktop.

---

## What you'll build

```
raw_orders.csv  ──seed──►  warehouse.analytics.raw_orders
                                        │
                                        ▼  (view)
                            warehouse.analytics.stg_orders
                                        │
                                        ▼  (table)
                            warehouse.analytics.orders_summary
```

Three things happen:
1. **Seed** — a CSV gets loaded into Postgres as a table.
2. **Models** — two SQL transformations run: a staging view (renames/casts) and a mart table (aggregates).
3. **Tests** — dbt checks that `order_id` is unique and not-null, status values are one of {completed, pending, cancelled}, etc.

---

## Prerequisites

- Docker Desktop running (Windows/Mac/Linux).
- ~2 GB free disk for images.
- Port `5432` free on host (or change it via `.env`).
- A code editor (VS Code, Notepad++, anything that handles `.yml`, `.sql`, `.csv`).

Quick check:

```bash
docker --version
docker compose version
```

Expected: both commands print a version string. If `docker compose version` errors, you have an old Compose v1 — install Docker Desktop ≥ v4.x.

---

## Directory layout (what you'll create)

```
01-dbt-hello-world/
├── docker-compose.yml
├── dbt.Dockerfile
├── .env.example
├── .gitignore
├── README.md                 ← this file (already here)
└── dbt/
    ├── dbt_project.yml
    ├── profiles.yml
    ├── seeds/
    │   └── raw_orders.csv
    └── models/
        ├── staging/
        │   ├── stg_orders.sql
        │   └── schema.yml
        └── marts/
            ├── orders_summary.sql
            └── schema.yml
```

---

## Step 0 — Open a terminal in this directory

```bash
cd C:/Users/DELL/Job-apps/agentic/data-engineering-helper/12-hands-on-tutorials/01-dbt-hello-world
```

(Use PowerShell, Git Bash, or any shell. All commands below work in any of them — Docker handles the platform differences.)

**✅ Checkpoint**: `pwd` (Bash) or `Get-Location` (PowerShell) shows you're in `01-dbt-hello-world/`.

---

## Step 1 — Create the Postgres + dbt Compose file

Create a file named **`docker-compose.yml`** in this directory with the content below.

```yaml
services:
  postgres:
    image: postgres:15-alpine
    container_name: dbt_pg
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-dbt}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-dbt}
      POSTGRES_DB: ${POSTGRES_DB:-warehouse}
    ports:
      - "${POSTGRES_PORT:-5432}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-dbt}"]
      interval: 5s
      timeout: 5s
      retries: 10

  dbt:
    build:
      context: .
      dockerfile: dbt.Dockerfile
    container_name: dbt_cli
    depends_on:
      postgres:
        condition: service_healthy
    volumes:
      - ./dbt:/usr/app/dbt
    working_dir: /usr/app/dbt
    environment:
      DBT_PROFILES_DIR: /usr/app/dbt
      POSTGRES_HOST: postgres
      POSTGRES_USER: ${POSTGRES_USER:-dbt}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-dbt}
      POSTGRES_DB: ${POSTGRES_DB:-warehouse}

volumes:
  postgres_data:
```

**Why these choices**:
- `postgres:15-alpine` — small (~80 MB), stable.
- Service name `postgres` becomes the DNS hostname inside the Compose network, so the dbt container reaches Postgres at `host: postgres` (not `localhost`).
- `healthcheck` + `depends_on: condition: service_healthy` makes dbt wait for Postgres to actually accept connections.
- The dbt service has no long-running process — we'll `docker compose run --rm dbt <subcommand>` to invoke it ad-hoc.

---

## Step 2 — Create the dbt Dockerfile

Create **`dbt.Dockerfile`** in this directory:

```dockerfile
FROM python:3.11-slim

RUN pip install --no-cache-dir "dbt-postgres>=1.7,<1.8"

WORKDIR /usr/app/dbt

ENTRYPOINT ["dbt"]
CMD ["--help"]
```

**Why**: a tiny image whose entrypoint is `dbt`, so `docker compose run dbt run` translates to `dbt run`.

---

## Step 3 — Create the dbt project files

Create the directory `dbt/` and inside it create the four config/project files below.

### 3a. `dbt/dbt_project.yml`

```yaml
name: 'hello_world'
version: '1.0.0'
config-version: 2

profile: 'hello_world'

model-paths: ["models"]
seed-paths: ["seeds"]
test-paths: ["tests"]
analysis-paths: ["analyses"]
macro-paths: ["macros"]
snapshot-paths: ["snapshots"]

target-path: "target"
clean-targets:
  - "target"
  - "dbt_packages"

models:
  hello_world:
    staging:
      +materialized: view
    marts:
      +materialized: table
```

### 3b. `dbt/profiles.yml`

```yaml
hello_world:
  target: dev
  outputs:
    dev:
      type: postgres
      host: "{{ env_var('POSTGRES_HOST', 'postgres') }}"
      user: "{{ env_var('POSTGRES_USER', 'dbt') }}"
      password: "{{ env_var('POSTGRES_PASSWORD', 'dbt') }}"
      dbname: "{{ env_var('POSTGRES_DB', 'warehouse') }}"
      port: 5432
      schema: analytics
      threads: 2
```

**Why**: normally `profiles.yml` lives at `~/.dbt/profiles.yml`. Putting it next to `dbt_project.yml` (and setting `DBT_PROFILES_DIR=/usr/app/dbt` in the Compose file) keeps everything in the repo. Using `env_var()` keeps secrets out of the file.

---

## Step 4 — Create the seed data

Create **`dbt/seeds/raw_orders.csv`** with exactly this content (10 rows + header):

```csv
order_id,customer_id,order_date,amount,status
1,101,2026-01-05,49.99,completed
2,102,2026-01-06,15.50,completed
3,101,2026-01-08,120.00,completed
4,103,2026-01-10,8.75,pending
5,102,2026-01-12,67.20,completed
6,104,2026-01-15,250.00,completed
7,101,2026-01-18,33.00,cancelled
8,105,2026-01-20,89.90,completed
9,103,2026-01-22,42.10,completed
10,102,2026-01-25,19.99,pending
```

---

## Step 5 — Create the staging model and tests

### 5a. `dbt/models/staging/stg_orders.sql`

```sql
{{ config(materialized='view') }}

with source as (
    select * from {{ ref('raw_orders') }}
),

renamed as (
    select
        order_id::int           as order_id,
        customer_id::int        as customer_id,
        order_date::date        as order_date,
        amount::numeric(10,2)   as amount,
        status::text            as status
    from source
)

select * from renamed
```

**What `{{ ref('raw_orders') }}` does**: at compile time, dbt resolves this to the fully-qualified table name (`analytics.raw_orders` here) AND records `stg_orders` as depending on `raw_orders`, so dbt builds them in the correct order.

### 5b. `dbt/models/staging/schema.yml`

```yaml
version: 2

models:
  - name: stg_orders
    description: "Renamed and typed view over the raw orders seed."
    columns:
      - name: order_id
        description: "Primary key from the source."
        tests:
          - not_null
          - unique
      - name: customer_id
        tests:
          - not_null
      - name: status
        tests:
          - accepted_values:
              values: ['completed', 'pending', 'cancelled']
```

---

## Step 6 — Create the mart model and tests

### 6a. `dbt/models/marts/orders_summary.sql`

```sql
{{ config(materialized='table') }}

select
    customer_id,
    count(*)                                                      as total_orders,
    sum(case when status = 'completed' then 1 else 0 end)         as completed_orders,
    sum(case when status = 'completed' then amount else 0 end)    as completed_revenue,
    min(order_date)                                               as first_order_date,
    max(order_date)                                               as last_order_date
from {{ ref('stg_orders') }}
group by customer_id
```

### 6b. `dbt/models/marts/schema.yml`

```yaml
version: 2

models:
  - name: orders_summary
    description: "Per-customer aggregate of orders."
    columns:
      - name: customer_id
        tests:
          - not_null
          - unique
      - name: total_orders
        tests:
          - not_null
```

---

## Step 7 — Create the env file

Create **`.env.example`**:

```
POSTGRES_USER=dbt
POSTGRES_PASSWORD=dbt
POSTGRES_DB=warehouse
POSTGRES_PORT=5432
```

Then copy it to `.env` (which Compose auto-loads):

```bash
cp .env.example .env
```

If you have local Postgres running on 5432, edit `.env` and change `POSTGRES_PORT` to e.g. `5433` first.

---

## Step 8 — Create `.gitignore`

Create **`.gitignore`** at the tutorial root:

```
.env
dbt/target/
dbt/dbt_packages/
dbt/logs/
```

---

## Step 9 — Sanity check: list what you created

```bash
ls -R
```

Or on PowerShell:

```powershell
Get-ChildItem -Recurse -Name
```

**✅ Checkpoint** — you should see something like:

```
docker-compose.yml
dbt.Dockerfile
.env
.env.example
.gitignore
README.md
dbt/
dbt/dbt_project.yml
dbt/profiles.yml
dbt/seeds/raw_orders.csv
dbt/models/staging/stg_orders.sql
dbt/models/staging/schema.yml
dbt/models/marts/orders_summary.sql
dbt/models/marts/schema.yml
```

---

## Step 10 — Build the dbt image

```bash
docker compose build
```

First run pulls `python:3.11-slim` and installs dbt-postgres — takes 1–3 minutes.

**Expected tail of output**:

```
 => => writing image sha256:...
 => => naming to docker.io/library/01-dbt-hello-world-dbt
```

**✅ Checkpoint**: command exits 0 (no error).

---

## Step 11 — Start Postgres

```bash
docker compose up -d postgres
```

Then wait a few seconds and check:

```bash
docker compose ps
```

**Expected**:

```
NAME      ...   STATUS                   PORTS
dbt_pg    ...   Up X seconds (healthy)   0.0.0.0:5432->5432/tcp
```

**✅ Checkpoint**: `STATUS` shows `(healthy)`. If it shows `(health: starting)`, wait another 5–10s and re-run `docker compose ps`.

**🐛 Troubleshooting** — if you see `Bind for 0.0.0.0:5432 failed: port is already allocated`, you have another Postgres on that port. Edit `.env`: set `POSTGRES_PORT=5433`, then `docker compose down && docker compose up -d postgres`.

---

## Step 12 — Verify dbt can reach Postgres

```bash
docker compose run --rm dbt debug
```

**Expected** (last lines):

```
  Connection test: [OK connection ok]

All checks passed!
```

**✅ Checkpoint**: see `All checks passed!`

**🐛 Troubleshooting** — if you see `connection refused`, Postgres isn't healthy yet. Wait 10s and retry. If `dbname "warehouse" does not exist`, your `.env` is mis-set — confirm `POSTGRES_DB=warehouse`.

---

## Step 13 — Load the seed

```bash
docker compose run --rm dbt seed
```

**Expected**:

```
1 of 1 START seed file analytics.raw_orders ...
1 of 1 OK loaded seed file analytics.raw_orders ... [INSERT 10 in X.XXs]

Completed successfully

Done. PASS=1 WARN=0 ERROR=0 SKIP=0 TOTAL=1
```

**✅ Checkpoint**: `PASS=1`, 10 rows loaded.

---

## Step 14 — Build the models

```bash
docker compose run --rm dbt run
```

**Expected** (order may vary):

```
1 of 2 START sql view model analytics.stg_orders ...
1 of 2 OK created sql view model analytics.stg_orders ... [CREATE VIEW in X.XXs]
2 of 2 START sql table model analytics.orders_summary ...
2 of 2 OK created sql table model analytics.orders_summary ... [SELECT 5 in X.XXs]

Completed successfully

Done. PASS=2 WARN=0 ERROR=0 SKIP=0 TOTAL=2
```

**✅ Checkpoint**: `PASS=2`. Note the `SELECT 5` on `orders_summary` — that's 5 unique customers.

---

## Step 15 — Run the tests

```bash
docker compose run --rm dbt test
```

**Expected**:

```
1 of 7 START test ... PASS
2 of 7 START test ... PASS
...
Done. PASS=7 WARN=0 ERROR=0 SKIP=0 TOTAL=7
```

**✅ Checkpoint**: all 7 tests pass (3 on `stg_orders` + 2 unique/not-null on `orders_summary` + 1 unique on `stg_orders.order_id` + accepted_values).

If tests fail, dbt prints which row(s) violated. Fix the seed CSV and re-run.

---

## Step 16 — Query the final mart

```bash
docker compose exec postgres psql -U dbt -d warehouse -c "SELECT * FROM analytics.orders_summary ORDER BY customer_id;"
```

**Expected**:

```
 customer_id | total_orders | completed_orders | completed_revenue | first_order_date | last_order_date
-------------+--------------+------------------+-------------------+------------------+-----------------
         101 |            3 |                2 |            169.99 | 2026-01-05       | 2026-01-18
         102 |            3 |                2 |             82.70 | 2026-01-06       | 2026-01-25
         103 |            2 |                1 |             42.10 | 2026-01-10       | 2026-01-22
         104 |            1 |                1 |            250.00 | 2026-01-15       | 2026-01-15
         105 |            1 |                1 |             89.90 | 2026-01-20       | 2026-01-20
(5 rows)
```

**✅ Final checkpoint**: 5 rows, customer `101` shows 3 total orders / 2 completed / 169.99 revenue (49.99 + 120.00).

---

## Step 17 — (Optional) Generate and view dbt docs

```bash
docker compose run --rm dbt docs generate
```

This creates an HTML site under `dbt/target/`. You can `docker compose run --rm -p 8081:8080 dbt docs serve --port 8080 --host 0.0.0.0` to browse it, but for this tutorial just inspecting `dbt/target/manifest.json` or `catalog.json` is enough to see what dbt knows about your project.

---

## Step 18 — Cleanup

```bash
docker compose down -v
```

The `-v` removes the postgres volume. To also remove the built image:

```bash
docker rmi 01-dbt-hello-world-dbt
```

**✅ Checkpoint**: `docker compose ps` shows nothing.

---

## What you just learned

- **dbt's compile-vs-run model** — `{{ ref() }}` builds a DAG so dbt knows model order.
- **Materialisations** — `view` is cheap and always fresh; `table` is expensive but query-fast.
- **Tests are first-class** — `not_null`, `unique`, `accepted_values` ship out-of-the-box.
- **`profiles.yml` separates connection from project** — same project, swap profile to deploy to a different warehouse.
- **`env_var()` keeps secrets out of YAML** — friendly with `.env` / CI / secrets managers.

## What's next

- Tutorial 2 — [`../02-airflow-hello-world/`](../02-airflow-hello-world/) — orchestration basics.
- Tutorial 3 — [`../03-airflow-dbt-integration/`](../03-airflow-dbt-integration/) — Airflow runs this dbt project on a schedule.
- Theory deep-dive — [`../../07-ecosystem-tools/02-dbt-core-patterns.md`](../../07-ecosystem-tools/02-dbt-core-patterns.md).
