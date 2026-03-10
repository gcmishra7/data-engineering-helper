# Data Classification

## What problem does this solve?
Not all data needs the same protection. Treating everything as public is a security failure; treating everything as top-secret makes data unusable. Classification maps data to the right protection controls automatically.

## How it works

### Classification Tiers

| Tier | Label | Examples | Controls |
|------|-------|---------|---------|
| 1 | **Public** | Marketing content, published reports | No restrictions |
| 2 | **Internal** | Business metrics, internal docs | Employee access only |
| 3 | **Confidential** | Customer data, contracts, salaries | Role-based, audit logged |
| 4 | **Restricted** | PII, PCI, PHI, trade secrets | Encrypted, masked, MFA required |

### Regulatory Categories

| Category | What it covers | Regulation |
|----------|---------------|-----------|
| **PII** | Name, email, phone, address, SSN, passport | GDPR, CCPA, PDPA |
| **PCI-DSS** | Card numbers, CVV, expiry dates | PCI-DSS |
| **PHI** | Medical records, diagnoses, prescriptions | HIPAA |
| **Financial** | Account numbers, transaction history | GLBA, SOX |

### Tagging schema (Unity Catalog / Snowflake)

```sql
-- Unity Catalog: tag columns with PII classification
ALTER TABLE silver.customers
ALTER COLUMN email SET TAGS ('pii_type' = 'email', 'classification' = 'restricted', 'gdpr_subject' = 'true');

ALTER TABLE silver.customers
ALTER COLUMN ssn SET TAGS ('pii_type' = 'ssn', 'classification' = 'restricted', 'pci' = 'false');

-- Query: find all PII columns across the platform
SELECT table_catalog, table_schema, table_name, column_name, tag_value
FROM system.information_schema.column_tags
WHERE tag_name = 'classification' AND tag_value = 'restricted';
```

### Automated classification (Snowflake)

```sql
-- Run automated PII detection
SELECT SYSTEM$CLASSIFY('mydb.myschema.customers', {'auto_tag': true});

-- View classification results
SELECT * FROM TABLE(mydb.INFORMATION_SCHEMA.EXTRACT_SEMANTIC_CATEGORIES('mydb.myschema.customers'));
```

## Right-to-be-forgotten (GDPR Article 17)

```python
# Delta Lake: GDPR erasure
from delta.tables import DeltaTable

def erase_customer(customer_id: str):
    delta = DeltaTable.forName(spark, "silver.customers")

    # Overwrite PII fields with null
    delta.update(
        condition=f"customer_id = '{customer_id}'",
        set={
            "email": "null",
            "phone": "null",
            "name": "ERASED",
            "erased_at": "current_timestamp()"
        }
    )

    # VACUUM to remove old file versions containing PII
    # (must wait for retention period, default 7 days)
    spark.sql(f"VACUUM silver.customers RETAIN 0 HOURS")  # requires spark.databricks.delta.retentionDurationCheck.enabled=false
```

## Real-world scenario
Healthcare company scanned 800 tables after HIPAA audit. Found PHI (patient names, diagnoses) in 47 tables that engineering thought were "de-identified." Without classification tooling, this took 3 weeks of manual review. With Snowflake automated classification + Unity Catalog tags: 800 tables scanned and classified in 4 hours. Masking policies auto-applied to restricted columns.

## What goes wrong in production
- **Classification but no enforcement** — columns are tagged PII but masking policy never applied. Tags without policies are documentation, not protection.
- **Data copied to dev/test without masking** — production PII ends up in dev environments. All non-production environments must receive masked data.
- **VACUUM too aggressive** — GDPR erasure + VACUUM breaks time travel. Set retention for compliance, not convenience.

## References
- [GDPR — Right to Erasure](https://gdpr-info.eu/art-17-gdpr/)
- [NIST Data Classification](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final)
- [PDPA Singapore](https://www.pdpc.gov.sg/overview-of-pdpa/the-legislation/personal-data-protection-act)
- [Databricks GDPR Blog](https://www.databricks.com/blog/2020/05/19/delta-lake-and-the-right-to-be-forgotten.html)
