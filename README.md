# SQL Data Warehouse Project

A corporate data warehouse implementation on PostgreSQL, built using the
medallion architecture (bronze, silver, gold). The project demonstrates
end-to-end data warehouse development: schema design, data ingestion,
transformation pipelines, and analytical reporting.

## Stack

- PostgreSQL
- DBeaver
- SQL (DDL, DML, CTE, window functions, stored procedures)

## Architecture

The warehouse is organized into three layers, each represented by a
dedicated schema:

- **bronze** — raw data ingested from source systems without modification.
  Used for traceability and reprocessing.
- **silver** — cleansed, standardized, and conformed data. Source of truth
  for downstream consumers.
- **gold** — business-facing data marts optimized for analytics and
  reporting.

## Repository Structure

```
sql-data-warehouse-project/
├── datasets/         Source data files (CSV)
├── docs/             Architecture documentation and diagrams
├── scripts/          SQL scripts organized by layer
│   ├── bronze/
│   ├── silver/
│   └── gold/
├── tests/            Data quality checks
└── README.md
```

## Setup

1. Install PostgreSQL and a SQL client (DBeaver recommended).
2. Connect to the default `postgres` database.
3. Execute `scripts/00_init_database.sql` to create the `data_warehouse`
   database and its schemas.
4. Reconnect to `data_warehouse`.
5. Run the layer scripts in order: `bronze/`, then `silver/`, then `gold/`.

## Status

Work in progress.