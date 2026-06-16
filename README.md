# SQL Data Warehouse Project

A corporate data warehouse implementation on PostgreSQL, built using the medallion
architecture (bronze → silver → gold). The project covers the full data engineering
lifecycle: schema design, raw data ingestion, multi-source ETL transformation, data
quality validation, and business-facing analytical views.

---

## Architecture

```
CSV Sources (CRM + ERP)
        │
        ▼
┌─────────────────┐
│     BRONZE      │  Raw ingestion — data loaded as-is from source files
│  6 tables       │  Stored procedure: bronze.load_bronze()
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│     SILVER      │  Cleansed, deduplicated, standardized data
│  6 tables       │  Stored procedure: silver.load_silver()
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│      GOLD       │  Business-facing star schema (views)
│  3 views        │  dim_customers · dim_products · fact_sales
└─────────────────┘
```

### Star Schema (Gold Layer)

```
gold.dim_customers ──┐
                     ├── gold.fact_sales
gold.dim_products  ──┘
```

---

## Source Systems

| Source | Tables | Description |
|--------|--------|-------------|
| CRM | crm_cust_info, crm_prd_info, crm_sales_details | Customer, product, and sales data |
| ERP | erp_cust_az12, erp_loc_a101, erp_px_cat_g1v2 | Demographics, locations, categories |

---

## ETL Transformations (Silver Layer)

| Table | Key Transformations |
|-------|-------------------|
| crm_cust_info | Deduplication via ROW_NUMBER(), TRIM on name fields, standardization of gender and marital status codes |
| crm_prd_info | prd_key parsing into cat_id and product_number, prd_line code expansion, SCD2 end-date calculation via LEAD() |
| crm_sales_details | Integer-to-DATE conversion with validity guards, sales/price recalculation for corrupted values |
| erp_cust_az12 | NAS prefix removal from cid, birthdate range filtering (< 1900 or future dates → NULL), gender standardization |
| erp_loc_a101 | Hyphen removal from cid, country code standardization (US/USA → United States, DE → Germany) |
| erp_px_cat_g1v2 | maintenance field conversion from Yes/No string to BOOLEAN |

---

## Stack

- PostgreSQL — database engine
- PL/pgSQL — stored procedures for bronze and silver loading
- DBeaver — SQL client
- Git / Git Bash — version control

---

## Repository Structure

```
sql-data-warehouse/
├── datasets/
│   ├── source_crm/          # cust_info.csv, prd_info.csv, sales_details.csv
│   └── source_erp/          # CUST_AZ12.csv, LOC_A101.csv, PX_CAT_G1V2.csv
├── docs/
├── scripts/
│   ├── 00_init_database.sql
│   ├── bronze/
│   │   ├── 01_ddl_bronze_tables.sql
│   │   └── 02_proc_load_bronze.sql
│   ├── silver/
│   │   ├── 01_ddl_silver_tables.sql
│   │   ├── 02_load_silver.sql
│   │   └── 03_proc_load_silver.sql
│   └── gold/
│       └── 01_ddl_gold_views.sql
├── tests/
│   └── quality_checks.sql
├── .gitignore
├── LICENSE
└── README.md
```

---

## Setup

**Prerequisites:** PostgreSQL installed locally, DBeaver or any SQL client.

**1. Initialize the database**

Connect to the default `postgres` database and run:

```
scripts/00_init_database.sql
-- Creates data_warehouse database with bronze, silver, gold schemas
```

**2. Create table structures**

Connect to `data_warehouse` and run in order:

```
scripts/bronze/01_ddl_bronze_tables.sql
scripts/silver/01_ddl_silver_tables.sql
scripts/gold/01_ddl_gold_views.sql
```

**3. Copy source files**

Place CSV files in a directory accessible to the PostgreSQL server process.
Update file paths in `scripts/bronze/02_proc_load_bronze.sql` if needed.

**4. Load data**

```sql
CALL bronze.load_bronze();   -- ~1 second
CALL silver.load_silver();   -- ~1 second
-- Gold views update automatically
```

**5. Query the gold layer**

```sql
SELECT * FROM gold.dim_customers LIMIT 20;
SELECT * FROM gold.dim_products  LIMIT 20;
SELECT * FROM gold.fact_sales    LIMIT 20;
```

---

## Data Quality Checks

See `tests/quality_checks.sql` for validation queries covering:

- Duplicate keys in dimension tables
- NULL values in required fields
- Referential integrity between fact and dimension tables
- Date range anomalies
- Arithmetic consistency in sales figures

---

## Status

Complete — bronze, silver, and gold layers implemented and tested.