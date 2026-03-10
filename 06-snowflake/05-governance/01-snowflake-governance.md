# Snowflake Governance: Horizon

## What problem does this solve?
Data governance in Snowflake goes beyond RBAC. Snowflake Horizon provides a unified governance layer: classification, masking, row access policies, object tagging, and lineage — all native to Snowflake without a separate governance tool.

## How it works

### Dynamic Data Masking

```sql
-- Create masking policy
CREATE MASKING POLICY mask_email AS (val STRING) RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('PII_ADMIN', 'DATA_OWNER') THEN val
        WHEN IS_ROLE_IN_SESSION('ANALYST_ROLE') THEN
            CONCAT(LEFT(val, 2), '****@', SPLIT_PART(val, '@', 2))
        ELSE '****REDACTED****'
    END;

-- Apply to column
ALTER TABLE prod.silver.customers
    MODIFY COLUMN email SET MASKING POLICY mask_email;

-- Masking policy on VARIANT column
CREATE MASKING POLICY mask_variant_phone AS (val VARIANT) RETURNS VARIANT ->
    CASE WHEN CURRENT_ROLE() = 'PII_ADMIN' THEN val
         ELSE TO_VARIANT('****')
    END;
```

### Row Access Policies

```sql
-- Create row access policy
CREATE ROW ACCESS POLICY region_access AS (ship_region STRING) RETURNS BOOLEAN ->
    CASE
        WHEN CURRENT_ROLE() = 'GLOBAL_ANALYST' THEN TRUE  -- see all
        WHEN CURRENT_ROLE() = 'REGIONAL_ANALYST' THEN
            ship_region IN (
                SELECT allowed_region
                FROM security.user_region_mapping
                WHERE username = CURRENT_USER()
            )
        ELSE FALSE
    END;

-- Apply to table
ALTER TABLE prod.gold.fact_orders
    ADD ROW ACCESS POLICY region_access ON (ship_region);

-- Verify policy
SELECT * FROM INFORMATION_SCHEMA.POLICY_REFERENCES
    WHERE POLICY_NAME = 'REGION_ACCESS';
```

### Object Tagging (classification + lineage)

```sql
-- Create tags for classification
CREATE TAG data_classification ALLOWED_VALUES 'PUBLIC', 'INTERNAL', 'CONFIDENTIAL', 'RESTRICTED';
CREATE TAG pii_type ALLOWED_VALUES 'name', 'email', 'phone', 'address', 'ssn', 'card';
CREATE TAG data_owner;
CREATE TAG business_domain;

-- Apply tags
ALTER TABLE prod.silver.customers
    SET TAG data_classification = 'CONFIDENTIAL',
             data_owner = 'data-engineering-team',
             business_domain = 'customer';

ALTER TABLE prod.silver.customers
    MODIFY COLUMN email SET TAG pii_type = 'email';
ALTER TABLE prod.silver.customers
    MODIFY COLUMN phone SET TAG pii_type = 'phone';

-- Query tags across the account (data catalogue view)
SELECT
    object_database, object_schema, object_name, column_name,
    tag_name, tag_value
FROM snowflake.account_usage.tag_references
WHERE tag_name IN ('DATA_CLASSIFICATION', 'PII_TYPE')
ORDER BY object_database, object_schema, object_name;

-- Auto-tag with Snowflake's built-in classifier (Enterprise+)
SELECT SYSTEM$CLASSIFY('prod.silver.customers', {'auto_tag': true});
-- Snowflake detects PII columns and applies tags automatically
```

### Access History and Lineage

```sql
-- Who accessed which columns (GDPR audit capability)
SELECT
    query_start_time,
    user_name,
    direct_objects_accessed,
    base_objects_accessed
FROM snowflake.account_usage.access_history
WHERE query_start_time >= DATEADD(HOUR, -24, CURRENT_TIMESTAMP())
  AND ARRAY_CONTAINS('PROD.SILVER.CUSTOMERS.EMAIL'::VARIANT,
                     direct_objects_accessed)
ORDER BY query_start_time DESC;

-- Column-level lineage: what tables feed into this column?
SELECT *
FROM snowflake.account_usage.access_history
WHERE ARRAY_CONTAINS('PROD.GOLD.FACT_ORDERS.REVENUE'::VARIANT,
                     objects_modified)
LIMIT 20;
```

## What goes wrong in production

- **Masking policy on non-SECURE view** — if a masking policy is applied to a base table column but a regular (non-secure) view exposes that column via a transformation, the transformation may bypass masking. Test all access paths.
- **Row access policy performance** — policies that JOIN to a mapping table on every row scan add overhead. Keep mapping tables small and cached. For high-volume tables, consider denormalising the access column.

## References
- [Snowflake Horizon](https://docs.snowflake.com/en/guides-overview-govern)
- [Dynamic Data Masking](https://docs.snowflake.com/en/user-guide/security-column-ddm-intro)
- [Row Access Policies](https://docs.snowflake.com/en/user-guide/security-row-intro)
- [Object Tagging](https://docs.snowflake.com/en/user-guide/object-tagging)
- [Access History](https://docs.snowflake.com/en/sql-reference/account-usage/access_history)
