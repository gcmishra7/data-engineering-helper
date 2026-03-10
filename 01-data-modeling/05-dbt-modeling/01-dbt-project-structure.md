# dbt Project Structure

## What problem does this solve?
Without structure, dbt projects become unmaintainable — models scattered everywhere, no clear ownership, tests missing, documentation nonexistent. A standard project layout makes it navigable by any team member.

## How it works

```
my_dbt_project/
├── dbt_project.yml          ← project config, model materialisation defaults
├── profiles.yml             ← connection config (gitignored)
├── packages.yml             ← dbt-utils, dbt-expectations, etc.
│
├── models/
│   ├── staging/             ← 1:1 with source tables, light cleaning only
│   │   ├── crm/
│   │   │   ├── _crm__sources.yml    ← source definitions
│   │   │   ├── _crm__models.yml     ← model docs + tests
│   │   │   ├── stg_crm__customers.sql
│   │   │   └── stg_crm__orders.sql
│   │   └── payments/
│   ├── intermediate/        ← business logic, joins, not exposed to BI
│   │   └── int_orders_joined.sql
│   └── marts/               ← Gold layer, BI-facing, owned by domain
│       ├── sales/
│       │   ├── fact_orders.sql
│       │   └── dim_customer.sql
│       └── finance/
│           └── fact_revenue.sql
│
├── seeds/                   ← small static CSVs (lookup tables)
├── snapshots/               ← SCD Type 2 tracking
├── tests/                   ← custom data tests (.sql files)
├── macros/                  ← reusable Jinja functions
└── analyses/                ← ad-hoc SQL, not materialised
```

### Materialisation strategy by layer

```yaml
# dbt_project.yml
models:
  my_project:
    staging:
      +materialized: view          # cheap, always fresh
    intermediate:
      +materialized: ephemeral     # compiled inline, no table created
    marts:
      +materialized: table         # materialised for BI performance
      sales:
        fact_orders:
          +materialized: incremental  # large tables use incremental
```

### Staging model pattern
```sql
-- models/staging/crm/stg_crm__customers.sql
WITH source AS (
    SELECT * FROM {{ source('crm', 'customers') }}
),
renamed AS (
    SELECT
        customer_id,
        LOWER(TRIM(email))          AS email,
        INITCAP(full_name)          AS customer_name,
        created_at::TIMESTAMP       AS created_at,
        updated_at::TIMESTAMP       AS updated_at,
        _ingested_at                AS _source_loaded_at
    FROM source
)
SELECT * FROM renamed
```

### Source definition with freshness
```yaml
# models/staging/crm/_crm__sources.yml
sources:
  - name: crm
    database: raw
    schema: crm
    tables:
      - name: customers
        freshness:
          warn_after: {count: 6, period: hour}
          error_after: {count: 24, period: hour}
        loaded_at_field: _ingested_at
        columns:
          - name: customer_id
            tests: [not_null, unique]
          - name: email
            tests: [not_null]
```

## Real-world scenario
Analytics engineering team of 6. 200 dbt models. Without structure: staging models contain business logic, mart models re-implement the same joins differently, tests inconsistent. With structure above: staging is boring (1:1 with source), all business logic is in intermediate or marts, every model has tests and documentation, new team members are productive in 1 day.

## What goes wrong in production
- **Business logic in staging** — staging should be "renaming and light casting only." Logic in staging = it gets reused by wrong consumers.
- **No intermediate layer** — complex joins repeated in every mart. One change = update 8 models.
- **Missing `_sources.yml`** — dbt `source freshness` can't run. Stale data reaches analysts undetected.

## References
- [dbt Project Structure Guide](https://docs.getdbt.com/best-practices/how-we-structure/1-guide-overview)
- [dbt Materializations](https://docs.getdbt.com/docs/build/materializations)
- [dbt Sources](https://docs.getdbt.com/docs/build/sources)
