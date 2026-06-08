/*
===============================================================================
ETL Script: Load Silver Layer
===============================================================================
Purpose:
    Populates silver tables from bronze sources, applying cleansing,
    deduplication, and standardization logic.

    Each transformation block is documented inline above its INSERT
    statement, describing the source, target, and applied rules.

Process:
    For each silver table:
        1. TRUNCATE target table
        2. INSERT transformed data from corresponding bronze table

WARNING:
    The script truncates silver tables before loading.
    All existing data in silver tables will be permanently lost.
===============================================================================
*/

-- ============================================================================
-- Source: CRM
-- ============================================================================

/*
-------------------------------------------------------------------------------
silver.crm_cust_info
-------------------------------------------------------------------------------
Source:           bronze.crm_cust_info
Transformations:
    - Filter out rows where cst_id or cst_key is NULL
    - Deduplicate by cst_id, keeping the most recent cst_create_date
    - Trim whitespace from cst_firstname and cst_lastname
    - Standardize cst_marital_status: M -> Married, S -> Single, * -> Unknown
    - Standardize cst_gndr: M -> Male, F -> Female, * -> Unknown
-------------------------------------------------------------------------------
*/


TRUNCATE TABLE silver.crm_cust_info;
INSERT INTO silver.crm_cust_info (
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date
)
SELECT
    cst_id,
	cst_key,
	TRIM(cst_firstname) AS cst_firstname,
	TRIM(cst_lastname) AS cst_lastname,
	CASE UPPER(TRIM(cst_marital_status))
		WHEN 'M' THEN 'Married'
		WHEN 'S' THEN 'Single'
		ELSE 'Unknown'
	END AS cst_marital_status,
	CASE UPPER(TRIM(cst_gndr))
		WHEN 'M' THEN 'Male'
		WHEN 'F' THEN 'Female'
		ELSE 'Unknown'
	END AS cst_gndr,
	cst_create_date 
FROM (
    SELECT *, ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS rn
	FROM bronze.crm_cust_info
	WHERE cst_id IS NOT NULL
	AND cst_key IS NOT NULL
) AS dedup
WHERE rn = 1;

/*
-------------------------------------------------------------------------------
silver.crm_prd_info
-------------------------------------------------------------------------------
Source:           bronze.crm_prd_info
Transformations:
	- Extract cat_id from prd_key (positions 1-5) and replace '-' with '_'
	for compatibility with erp_px_cat_g1v2.id
	- Trim prd_key to start from position 7 (sales_details key format) 
	e.g.  CO-RF-FR-R92B-58 -> cat_id = CO_RF, prd_key = R92B-58
	- prd_cost: pass through as-is (NULLs are preserved as "cost unknown")
    - Standardize prd_line: trim whitespace, then map codes:
    M -> Mountain, R -> Road, S -> Other Sales, T -> Touring, * -> Unknown
    - Recalculate prd_end_dt as the day before the next version's start date
	using LEAD() over prd_key partition (original prd_end_dt discarded as unreliable)
-------------------------------------------------------------------------------
*/

TRUNCATE TABLE silver.crm_prd_info;
INSERT INTO silver.crm_prd_info (
    prd_id, cat_id, prd_key, prd_nm, prd_cost,
    prd_line, prd_start_dt, prd_end_dt
)
SELECT
    prd_id,
    REPLACE(SUBSTRING(prd_key FROM 1 FOR 5), '-', '_') AS cat_id,
	SUBSTRING(prd_key FROM 7) AS prd_key,
	prd_nm,
    prd_cost,
    CASE UPPER(TRIM(prd_line))
	    WHEN 'M' THEN 'Mountain'
	    WHEN 'R' THEN 'Road'
	    WHEN 'S' THEN 'Other Sales'
	    WHEN 'T' THEN 'Touring'
	    ELSE 'Unknown'
    END,
    prd_start_dt,
    LEAD(prd_start_dt) 
    OVER(PARTITION BY prd_key ORDER BY prd_start_dt) - INTERVAL '1 day' AS prd_end_dt
FROM bronze.crm_prd_info;

/*
-------------------------------------------------------------------------------
silver.crm_sales_details
-------------------------------------------------------------------------------
Source:           bronze.crm_sales_details
Transformations:
    - Convert YYYYMMDD integer dates (order, ship, due) to DATE type;
      invalid values (zeros, non-8-digit numbers) become NULL
    - Recalculate sls_sales when null, non-positive, or inconsistent
      with quantity * price
    - Recalculate sls_price when null or non-positive,
      derived from sales / quantity; otherwise normalize via ABS
-------------------------------------------------------------------------------
*/

TRUNCATE TABLE silver.crm_sales_details;
INSERT INTO silver.crm_sales_details
(
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price
)
SELECT
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	CASE
		WHEN sls_order_dt = 0
			OR LENGTH(CAST(sls_order_dt AS TEXT)) != 8
		THEN NULL
		ELSE TO_DATE(CAST(sls_order_dt AS TEXT), 'YYYYMMDD')
	END AS sls_order_dt,
	CASE
		WHEN sls_ship_dt = 0
			OR LENGTH(CAST(sls_ship_dt AS TEXT)) != 8
		THEN NULL
		ELSE TO_DATE(CAST(sls_ship_dt AS TEXT), 'YYYYMMDD')
	END AS sls_ship_dt,
	CASE
		WHEN sls_due_dt = 0
			OR LENGTH(CAST(sls_due_dt AS TEXT)) != 8
		THEN NULL
		ELSE TO_DATE(CAST(sls_due_dt AS TEXT), 'YYYYMMDD')
	END AS sls_due_dt,
	CASE
		WHEN sls_sales IS NULL 
			OR sls_sales <= 0
			OR sls_sales != sls_quantity * ABS(sls_price)
		THEN sls_quantity * ABS(sls_price)
		ELSE sls_sales
	END AS sls_sales,
	sls_quantity,
	CASE
		WHEN sls_price IS NULL
			OR sls_price <= 0
		THEN ABS(sls_sales) / NULLIF(sls_quantity, 0)
		ELSE ABS(sls_price)
	END AS sls_price
FROM bronze.crm_sales_details;