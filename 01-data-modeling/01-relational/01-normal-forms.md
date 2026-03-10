# Normal Forms: 1NF through BCNF

## What problem does this solve?
Unnormalised tables have data anomalies: insert anomalies, update anomalies, delete anomalies. Normalisation eliminates these through systematic decomposition.

## How it works

### First Normal Form (1NF)
Every column holds atomic values. No repeating groups.

```sql
-- VIOLATES 1NF
CREATE TABLE customers_bad (customer_id INT, name VARCHAR, phone_numbers VARCHAR); -- "555-1234, 555-5678"

-- SATISFIES 1NF
CREATE TABLE customer_phones (customer_id INT, phone_number VARCHAR, phone_type VARCHAR, PRIMARY KEY (customer_id, phone_number));
```

### Second Normal Form (2NF)
1NF + every non-key column depends on the *entire* composite primary key.

```sql
-- VIOLATES 2NF: customer_name depends only on customer_id, not (customer_id, product_id)
CREATE TABLE order_items_bad (customer_id INT, product_id INT, customer_name VARCHAR, quantity INT, PRIMARY KEY (customer_id, product_id));

-- SATISFIES 2NF
CREATE TABLE customers (customer_id INT PRIMARY KEY, customer_name VARCHAR);
CREATE TABLE order_items (customer_id INT, product_id INT, quantity INT, PRIMARY KEY (customer_id, product_id));
```

### Third Normal Form (3NF)
2NF + no transitive dependencies (non-key depends on non-key).

```sql
-- VIOLATES 3NF: zip_code → city (transitive via order_id → zip_code → city)
CREATE TABLE orders_bad (order_id INT PRIMARY KEY, zip_code VARCHAR, city VARCHAR);

-- SATISFIES 3NF
CREATE TABLE zip_codes (zip_code VARCHAR PRIMARY KEY, city VARCHAR, state VARCHAR);
CREATE TABLE orders (order_id INT PRIMARY KEY, zip_code VARCHAR REFERENCES zip_codes);
```

## Decision: when to normalise vs denormalise

| Scenario | Recommendation |
|----------|---------------|
| OLTP transactional DB | Normalise to 3NF |
| Analytics / BI | Denormalise — reduce joins |
| Data Vault raw layer | Strictly normalised |
| Kimball Gold / star schema | Intentionally denormalised |

## Real-world scenario
SaaS company stores `customer_email` in every order row (500K orders). Customer changes email → 500K rows to update, one update fails → inconsistency. Fix: normalise, one row in `customers`, orders reference by `customer_id`.

## What goes wrong in production
- **Over-normalising analytics** — 8-table joins kill query performance. Denormalise at the serving layer.
- **Under-normalising OLTP** — update anomalies corrupt transactional data.

## References
- [PostgreSQL DDL Documentation](https://www.postgresql.org/docs/current/ddl.html)
- [DAMA DMBOK Chapter 5](https://www.dama.org/cpages/body-of-knowledge)
