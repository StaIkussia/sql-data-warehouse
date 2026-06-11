/*
===============================================================================
Stored Procedure: silver.load_silver
===============================================================================
Purpose:
	Loads filtered, standardized, and cleansed data from the bronze layer into the silver layer.
	Truncates all silver tables and reloads them from its corresponding bronze source using defined transformation rules.

Usage:
	CALL silver.load_silver();

WARNING:
	This procedure truncates all silver tables before reloading.
	All existing data in the silver layer will be permanently lost.
	Ensure bronze tables are populated before executing this procedure.

Notes:
	- This procedure depends on the bronze layer being fully loaded.
	Run bronze.load_bronze() before calling this procedure.
	- Per-table load duration is reported via RAISE NOTICE.
	- On error, the offending step and SQL state are reported.
===============================================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_batch_start TIMESTAMP;
    v_batch_end TIMESTAMP;
BEGIN
	v_batch_start := clock_timestamp();
	RAISE NOTICE '================================================';
	RAISE NOTICE 'Loading Silver Layer';
	RAISE NOTICE '================================================';

	-- -----------------------------------------------------------------------
	-- CRM Tables
	-- -----------------------------------------------------------------------
	RAISE NOTICE '------------------------------------------------';
	RAISE NOTICE 'Inserting CRM Tables';
	RAISE NOTICE '------------------------------------------------';

	v_start_time := clock_timestamp();
	RAISE NOTICE '>> Truncating Table: silver.crm_cust_info';
	TRUNCATE TABLE silver.crm_cust_info;
	RAISE NOTICE '>> Inserting Data Into: silver.crm_cust_info';
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
	v_end_time := clock_timestamp();
	RAISE NOTICE '   Load Duration: % seconds',
		EXTRACT(EPOCH FROM (v_end_time - v_start_time));

	v_start_time := clock_timestamp();
	RAISE NOTICE '>> Truncating Table: silver.crm_prd_info';
	TRUNCATE TABLE silver.crm_prd_info;
	RAISE NOTICE '>> Inserting Data Into: silver.crm_prd_info';
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
	v_end_time := clock_timestamp();
	RAISE NOTICE '   Load Duration: % seconds',
		EXTRACT(EPOCH FROM (v_end_time - v_start_time));

	v_start_time := clock_timestamp();
	RAISE NOTICE '>> Truncating Table: silver.crm_sales_details';
	TRUNCATE TABLE silver.crm_sales_details;
	RAISE NOTICE '>> Inserting Data Into: silver.crm_sales_details';
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
	v_end_time := clock_timestamp();
	RAISE NOTICE '   Load Duration: % seconds',
		EXTRACT(EPOCH FROM (v_end_time - v_start_time));

	-- -----------------------------------------------------------------------
	-- ERP Tables
	-- -----------------------------------------------------------------------
	RAISE NOTICE '------------------------------------------------';
	RAISE NOTICE 'Loading ERP Tables';
	RAISE NOTICE '------------------------------------------------';

	v_start_time := clock_timestamp();
	RAISE NOTICE '>> Truncating Table: silver.erp_cust_az12';
	TRUNCATE TABLE silver.erp_cust_az12;
	RAISE NOTICE '>> Inserting Data Into: silver.erp_cust_az12';
    INSERT INTO silver.erp_cust_az12
	(
		cid,
		bdate,
		gen
	)
	SELECT 
		CASE 
			WHEN SUBSTRING(cid FROM 1 FOR 3) = 'NAS' THEN SUBSTRING(cid FROM 4)
			ELSE cid
		END AS cid,
		bdate,
		CASE 
			WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
			WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
			ELSE 'Unknown'
		END AS gen
	FROM (
	SELECT * FROM bronze.erp_cust_az12
	WHERE bdate IS NULL
	OR (bdate < CURRENT_DATE AND bdate > '1900-01-01'));
	v_end_time := clock_timestamp();
	RAISE NOTICE '   Load Duration: % seconds',
		EXTRACT(EPOCH FROM (v_end_time - v_start_time));

	v_start_time := clock_timestamp();
	RAISE NOTICE '>> Truncating Table: silver.erp_loc_a101';
	TRUNCATE TABLE silver.erp_loc_a101;
    RAISE NOTICE '>> Inserting Data Into: silver.erp_loc_a101';
	INSERT INTO silver.erp_loc_a101
	(
		cid,
		cntry
	)
	SELECT
		REPLACE(cid, '-','') AS cid,
		CASE
			WHEN cntry IS NULL OR TRIM(cntry) = '' THEN 'Unknown'
			WHEN UPPER(TRIM(cntry)) IN ('US','USA') THEN 'United States'
			WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
			ELSE TRIM(cntry)
		END AS cntry
	FROM bronze.erp_loc_a101;
	v_end_time := clock_timestamp();
	RAISE NOTICE '   Load Duration: % seconds',
		EXTRACT(EPOCH FROM (v_end_time - v_start_time));

	v_start_time := clock_timestamp();
	RAISE NOTICE '>> Truncating Table: silver.erp_px_cat_g1v2';
	TRUNCATE TABLE silver.erp_px_cat_g1v2;
	RAISE NOTICE '>> Inserting Data Into: silver.erp_px_cat_g1v2';
    INSERT INTO silver.erp_px_cat_g1v2
	(
		id,
		cat,
		subcat,
		maintenance
	)
	SELECT
		id,
		cat,
		subcat,
		CASE
			WHEN UPPER(TRIM(maintenance)) = 'YES' THEN TRUE
			ELSE FALSE
		END AS maintenance
	FROM bronze.erp_px_cat_g1v2;
	v_end_time := clock_timestamp();
	RAISE NOTICE '	Load Duration: % seconds',
		EXTRACT(EPOCH FROM (v_end_time - v_start_time));

	v_batch_end := clock_timestamp();
	RAISE NOTICE '================================================';
	RAISE NOTICE 'Loading Silver Layer Completed';
	RAISE NOTICE '   Total Duration: % seconds',
		EXTRACT(EPOCH FROM (v_batch_end - v_batch_start));
	RAISE NOTICE '================================================';

EXCEPTION
	WHEN OTHERS THEN
		RAISE NOTICE '================================================';
		RAISE NOTICE 'ERROR OCCURRED DURING LOADING SILVER LAYER';
		RAISE NOTICE 'Error Message: %', SQLERRM;
		RAISE NOTICE 'SQL State: %', SQLSTATE;
		RAISE NOTICE '================================================';
END;
$$;