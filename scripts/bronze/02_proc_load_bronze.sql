/*
===============================================================================
Stored Procedure: bronze.load_bronze
===============================================================================
Purpose:
    Loads raw data from CSV files into the bronze layer.
    Truncates all bronze tables and reloads them from source files
    located at C:/temp/datasets/. Designed for full-refresh ingestion.

Usage:
    CALL bronze.load_bronze();

Notes:
    - Server-side COPY is used; the PostgreSQL service must have
      read access to the source file paths.
    - Per-step duration is reported via RAISE NOTICE.
    - On error, the offending step and SQL state are reported.
===============================================================================
*/

CREATE OR REPLACE PROCEDURE bronze.load_bronze()
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
    RAISE NOTICE 'Loading Bronze Layer';
    RAISE NOTICE '================================================';

    -- -----------------------------------------------------------------------
    -- CRM Tables
    -- -----------------------------------------------------------------------
    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Loading CRM Tables';
    RAISE NOTICE '------------------------------------------------';

    v_start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: bronze.crm_cust_info';
    TRUNCATE TABLE bronze.crm_cust_info;
    RAISE NOTICE '>> Inserting Data Into: bronze.crm_cust_info';
    COPY bronze.crm_cust_info
        FROM 'C:/temp/datasets/source_crm/cust_info.csv'
        WITH (FORMAT csv, HEADER true, DELIMITER ',');
    v_end_time := clock_timestamp();
    RAISE NOTICE '   Load Duration: % seconds',
        EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    v_start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: bronze.crm_prd_info';
    TRUNCATE TABLE bronze.crm_prd_info;
    RAISE NOTICE '>> Inserting Data Into: bronze.crm_prd_info';
    COPY bronze.crm_prd_info
        FROM 'C:/temp/datasets/source_crm/prd_info.csv'
        WITH (FORMAT csv, HEADER true, DELIMITER ',');
    v_end_time := clock_timestamp();
    RAISE NOTICE '   Load Duration: % seconds',
        EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    v_start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: bronze.crm_sales_details';
    TRUNCATE TABLE bronze.crm_sales_details;
    RAISE NOTICE '>> Inserting Data Into: bronze.crm_sales_details';
    COPY bronze.crm_sales_details
        FROM 'C:/temp/datasets/source_crm/sales_details.csv'
        WITH (FORMAT csv, HEADER true, DELIMITER ',');
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
    RAISE NOTICE '>> Truncating Table: bronze.erp_cust_az12';
    TRUNCATE TABLE bronze.erp_cust_az12;
    RAISE NOTICE '>> Inserting Data Into: bronze.erp_cust_az12';
    COPY bronze.erp_cust_az12
        FROM 'C:/temp/datasets/source_erp/CUST_AZ12.csv'
        WITH (FORMAT csv, HEADER true, DELIMITER ',');
    v_end_time := clock_timestamp();
    RAISE NOTICE '   Load Duration: % seconds',
        EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    v_start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: bronze.erp_loc_a101';
    TRUNCATE TABLE bronze.erp_loc_a101;
    RAISE NOTICE '>> Inserting Data Into: bronze.erp_loc_a101';
    COPY bronze.erp_loc_a101
        FROM 'C:/temp/datasets/source_erp/LOC_A101.csv'
        WITH (FORMAT csv, HEADER true, DELIMITER ',');
    v_end_time := clock_timestamp();
    RAISE NOTICE '   Load Duration: % seconds',
        EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    v_start_time := clock_timestamp();
    RAISE NOTICE '>> Truncating Table: bronze.erp_px_cat_g1v2';
    TRUNCATE TABLE bronze.erp_px_cat_g1v2;
    RAISE NOTICE '>> Inserting Data Into: bronze.erp_px_cat_g1v2';
    COPY bronze.erp_px_cat_g1v2
        FROM 'C:/temp/datasets/source_erp/PX_CAT_G1V2.csv'
        WITH (FORMAT csv, HEADER true, DELIMITER ',');
    v_end_time := clock_timestamp();
    RAISE NOTICE '   Load Duration: % seconds',
        EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    v_batch_end := clock_timestamp();
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Bronze Layer Completed';
    RAISE NOTICE '   Total Duration: % seconds',
        EXTRACT(EPOCH FROM (v_batch_end - v_batch_start));
    RAISE NOTICE '================================================';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '================================================';
        RAISE NOTICE 'ERROR OCCURRED DURING LOADING BRONZE LAYER';
        RAISE NOTICE 'Error Message: %', SQLERRM;
        RAISE NOTICE 'SQL State: %', SQLSTATE;
        RAISE NOTICE '================================================';
END;
$$;