/*
===============================================================================
DDL Script: Create Silver Tables
===============================================================================
Purpose:
    Creates cleansed (silver) tables for source systems: CRM and ERP.
    Unlike bronze, silver tables contain standardized, deduplicated,
    and validated data ready for downstream business logic in the gold layer.

    Each silver table includes a technical column 'dwh_create_date' that
    records when a row was loaded into the data warehouse. This is used
    for auditing and troubleshooting load processes.

    Naming convention mirrors the bronze layer:
        <source>_<entity>    e.g. crm_cust_info, erp_cust_az12

WARNING:
    The script drops existing silver tables before recreating them.
    Any data in these tables will be permanently lost.
===============================================================================
*/

-- ============================================================================
-- Source: CRM
-- ============================================================================

DROP TABLE IF EXISTS silver.crm_cust_info;
CREATE TABLE silver.crm_cust_info(
	cst_id INTEGER PRIMARY KEY,
	cst_key VARCHAR(50),
	cst_firstname VARCHAR(50),
	cst_lastname VARCHAR(50),
	cst_marital_status VARCHAR(50),
	cst_gndr VARCHAR(50),
	cst_create_date DATE,
	dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS silver.crm_prd_info;
CREATE TABLE silver.crm_prd_info
(
	prd_id INTEGER PRIMARY KEY,
	cat_id VARCHAR(50),
	prd_key VARCHAR(50),
	prd_nm TEXT,
	prd_cost INTEGER,
	prd_line VARCHAR(50),
	prd_start_dt DATE,
	prd_end_dt DATE,
	dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS silver.crm_sales_details;
CREATE TABLE silver.crm_sales_details
(
	sls_ord_num VARCHAR(50),
	sls_prd_key VARCHAR (50),
	sls_cust_id INTEGER NOT NULL,
	sls_order_dt DATE,
	sls_ship_dt DATE,
	sls_due_dt DATE,
	sls_sales NUMERIC(10,2),
	sls_quantity INTEGER,
	sls_price NUMERIC(10,2),
	dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (sls_ord_num, sls_prd_key)
);