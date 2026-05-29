/*
===============================================================================
DDL Script: Create Bronze Tables
===============================================================================
Purpose:
	Creates raw (bronze) tables for source systems: CRM and ERP.
	Tables mirror the structure of source CSV files without any 
	transformations or constraints. Data cleansing and type casting
	are performed downstream in the silver layer.
	
	Naming convention:
		<source>_<entity>
		e.g. crm_cust_info, erp_cust_az12
		
WARNING:
	The script drops existing bronze tables before recreating them.
	Any data in these tables will be permanently lost.
===============================================================================
*/

-- ============================================================================
-- Source: CRM
-- ============================================================================

DROP TABLE IF EXISTS bronze.crm_cust_info;
CREATE TABLE bronze.crm_cust_info(
cst_id INTEGER,
cst_key VARCHAR(50),
cst_firstname VARCHAR(50),
cst_lastname VARCHAR(50),
cst_marital_status VARCHAR(50),
cst_gndr VARCHAR(50),
cst_create_date DATE
);

DROP TABLE IF EXISTS bronze.crm_prd_info;
CREATE TABLE bronze.crm_prd_info(
prd_id INTEGER,
prd_key VARCHAR(50),
prd_nm VARCHAR(50),
prd_cost INTEGER,
prd_line VARCHAR(50),
prd_start_dt DATE,
prd_end_dt DATE
);

DROP TABLE IF EXISTS bronze.crm_sales_details;
CREATE TABLE bronze.crm_sales_details (
    sls_ord_num VARCHAR(50),
    sls_prd_key VARCHAR(50),
    sls_cust_id INTEGER,
    sls_order_dt INTEGER,
    sls_ship_dt INTEGER,
    sls_due_dt INTEGER,
    sls_sales INTEGER,
    sls_quantity INTEGER,
    sls_price INTEGER
);