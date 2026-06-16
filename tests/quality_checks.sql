/*
===============================================================================
Data Quality Checks
===============================================================================
Purpose:
    Validates data integrity across the silver and gold layers.
    Each check returns rows only when a problem is found.
    A check that returns zero rows means the data is clean.

Usage:
    Run individual checks as needed, or execute the full script
    after loading to verify data quality end-to-end.

Sections:
    1. Silver Layer — CRM
    2. Silver Layer — ERP
    3. Gold Layer
===============================================================================
*/

-- =============================================================================
-- 1. SILVER LAYER — CRM
-- =============================================================================

-- ----------------------------------------------------------------------------
-- silver.crm_cust_info
-- ----------------------------------------------------------------------------

-- Check: no duplicate customer IDs (PRIMARY KEY integrity)
SELECT 'crm_cust_info: duplicate cst_id' AS check_name, cst_id, COUNT(*) AS cnt
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1;

-- Check: no NULL customer IDs
SELECT 'crm_cust_info: NULL cst_id' AS check_name, COUNT(*) AS cnt
FROM silver.crm_cust_info
WHERE cst_id IS NULL;

-- Check: no trailing/leading whitespace in name fields
SELECT 'crm_cust_info: whitespace in first_name' AS check_name, cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT 'crm_cust_info: whitespace in last_name' AS check_name, cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

-- Check: gender contains only standardized values
SELECT 'crm_cust_info: unexpected gender value' AS check_name, cst_gndr, COUNT(*) AS cnt
FROM silver.crm_cust_info
WHERE cst_gndr NOT IN ('Male', 'Female', 'Unknown')
GROUP BY cst_gndr;

-- Check: marital status contains only standardized values
SELECT 'crm_cust_info: unexpected marital_status value' AS check_name, cst_marital_status, COUNT(*) AS cnt
FROM silver.crm_cust_info
WHERE cst_marital_status NOT IN ('Married', 'Single', 'Unknown')
GROUP BY cst_marital_status;

-- ----------------------------------------------------------------------------
-- silver.crm_prd_info
-- ----------------------------------------------------------------------------

-- Check: no duplicate product IDs
SELECT 'crm_prd_info: duplicate prd_id' AS check_name, prd_id, COUNT(*) AS cnt
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1;

-- Check: no NULL product IDs
SELECT 'crm_prd_info: NULL prd_id' AS check_name, COUNT(*) AS cnt
FROM silver.crm_prd_info
WHERE prd_id IS NULL;

-- Check: prd_end_dt is always after prd_start_dt (when both are not NULL)
SELECT 'crm_prd_info: end_dt before start_dt' AS check_name, prd_key, prd_start_dt, prd_end_dt
FROM silver.crm_prd_info
WHERE prd_end_dt IS NOT NULL
  AND prd_end_dt < prd_start_dt;

-- Check: product line contains only standardized values
SELECT 'crm_prd_info: unexpected prd_line value' AS check_name, prd_line, COUNT(*) AS cnt
FROM silver.crm_prd_info
WHERE prd_line NOT IN ('Mountain', 'Road', 'Other Sales', 'Touring', 'Unknown')
GROUP BY prd_line;

-- Check: no negative product costs
SELECT 'crm_prd_info: negative prd_cost' AS check_name, prd_id, prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0;

-- ----------------------------------------------------------------------------
-- silver.crm_sales_details
-- ----------------------------------------------------------------------------

-- Check: sales amount equals quantity * price
SELECT 'crm_sales_details: sales != qty * price' AS check_name,
       sls_ord_num, sls_prd_key, sls_sales, sls_quantity, sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price;

-- Check: no negative or zero values in financial fields
SELECT 'crm_sales_details: non-positive sales' AS check_name, COUNT(*) AS cnt
FROM silver.crm_sales_details
WHERE sls_sales <= 0;

SELECT 'crm_sales_details: non-positive price' AS check_name, COUNT(*) AS cnt
FROM silver.crm_sales_details
WHERE sls_price <= 0;

SELECT 'crm_sales_details: non-positive quantity' AS check_name, COUNT(*) AS cnt
FROM silver.crm_sales_details
WHERE sls_quantity <= 0;

-- Check: order date is before or equal to ship date
SELECT 'crm_sales_details: order_dt after ship_dt' AS check_name,
       sls_ord_num, sls_order_dt, sls_ship_dt
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt;

-- Check: ship date is before or equal to due date
SELECT 'crm_sales_details: ship_dt after due_dt' AS check_name,
       sls_ord_num, sls_ship_dt, sls_due_dt
FROM silver.crm_sales_details
WHERE sls_ship_dt > sls_due_dt;

-- Check: no future order dates
SELECT 'crm_sales_details: future order_dt' AS check_name, COUNT(*) AS cnt
FROM silver.crm_sales_details
WHERE sls_order_dt > CURRENT_DATE;

-- =============================================================================
-- 2. SILVER LAYER — ERP
-- =============================================================================

-- ----------------------------------------------------------------------------
-- silver.erp_cust_az12
-- ----------------------------------------------------------------------------

-- Check: no NAS prefix remaining in cid
SELECT 'erp_cust_az12: NAS prefix not removed' AS check_name, cid
FROM silver.erp_cust_az12
WHERE cid LIKE 'NAS%';

-- Check: no invalid birthdates (before 1900 or in the future)
SELECT 'erp_cust_az12: invalid birthdate' AS check_name, cid, bdate
FROM silver.erp_cust_az12
WHERE bdate < '1900-01-01'
   OR bdate > CURRENT_DATE;

-- Check: gender contains only standardized values
SELECT 'erp_cust_az12: unexpected gender value' AS check_name, gen, COUNT(*) AS cnt
FROM silver.erp_cust_az12
WHERE gen NOT IN ('Male', 'Female', 'Unknown')
GROUP BY gen;

-- Check: all cid values exist in crm_cust_info (referential integrity)
SELECT 'erp_cust_az12: cid not in crm_cust_info' AS check_name, cid
FROM silver.erp_cust_az12
WHERE cid NOT IN (SELECT cst_key FROM silver.crm_cust_info);

-- ----------------------------------------------------------------------------
-- silver.erp_loc_a101
-- ----------------------------------------------------------------------------

-- Check: no hyphens remaining in cid
SELECT 'erp_loc_a101: hyphen not removed from cid' AS check_name, cid
FROM silver.erp_loc_a101
WHERE cid LIKE '%-%';

-- Check: no NULL or empty country values
SELECT 'erp_loc_a101: NULL or empty cntry' AS check_name, COUNT(*) AS cnt
FROM silver.erp_loc_a101
WHERE cntry IS NULL OR TRIM(cntry) = '';

-- Check: all cid values exist in crm_cust_info (referential integrity)
SELECT 'erp_loc_a101: cid not in crm_cust_info' AS check_name, cid
FROM silver.erp_loc_a101
WHERE cid NOT IN (SELECT cst_key FROM silver.crm_cust_info);

-- ----------------------------------------------------------------------------
-- silver.erp_px_cat_g1v2
-- ----------------------------------------------------------------------------

-- Check: no duplicate category IDs
SELECT 'erp_px_cat_g1v2: duplicate id' AS check_name, id, COUNT(*) AS cnt
FROM silver.erp_px_cat_g1v2
GROUP BY id
HAVING COUNT(*) > 1;

-- Check: no NULL category or subcategory
SELECT 'erp_px_cat_g1v2: NULL cat or subcat' AS check_name, id, cat, subcat
FROM silver.erp_px_cat_g1v2
WHERE cat IS NULL OR subcat IS NULL;

-- Check: maintenance is boolean (not NULL)
SELECT 'erp_px_cat_g1v2: NULL maintenance' AS check_name, COUNT(*) AS cnt
FROM silver.erp_px_cat_g1v2
WHERE maintenance IS NULL;

-- =============================================================================
-- 3. GOLD LAYER
-- =============================================================================

-- ----------------------------------------------------------------------------
-- gold.dim_customers
-- ----------------------------------------------------------------------------

-- Check: no duplicate customer keys
SELECT 'dim_customers: duplicate customer_key' AS check_name, customer_key, COUNT(*) AS cnt
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- Check: no NULL customer keys or IDs
SELECT 'dim_customers: NULL customer_key or customer_id' AS check_name, COUNT(*) AS cnt
FROM gold.dim_customers
WHERE customer_key IS NULL OR customer_id IS NULL;

-- Check: gender standardized
SELECT 'dim_customers: unexpected gender' AS check_name, gender, COUNT(*) AS cnt
FROM gold.dim_customers
WHERE gender NOT IN ('Male', 'Female', 'Unknown')
GROUP BY gender;

-- ----------------------------------------------------------------------------
-- gold.dim_products
-- ----------------------------------------------------------------------------

-- Check: no duplicate product keys
SELECT 'dim_products: duplicate product_key' AS check_name, product_key, COUNT(*) AS cnt
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- Check: no NULL product keys or numbers
SELECT 'dim_products: NULL product_key or product_number' AS check_name, COUNT(*) AS cnt
FROM gold.dim_products
WHERE product_key IS NULL OR product_number IS NULL;

-- ----------------------------------------------------------------------------
-- gold.fact_sales
-- ----------------------------------------------------------------------------

-- Check: no orphan sales (product_key has no match in dim_products)
SELECT 'fact_sales: orphan product_key' AS check_name, COUNT(*) AS cnt
FROM gold.fact_sales
WHERE product_key IS NULL;

-- Check: no orphan sales (customer_key has no match in dim_customers)
SELECT 'fact_sales: orphan customer_key' AS check_name, COUNT(*) AS cnt
FROM gold.fact_sales
WHERE customer_key IS NULL;

-- Check: no negative sales amounts
SELECT 'fact_sales: negative sales_amount' AS check_name, COUNT(*) AS cnt
FROM gold.fact_sales
WHERE sales_amount <= 0;

-- Check: record counts across all layers (summary)
SELECT 'bronze.crm_cust_info'    AS layer_table, COUNT(*) AS row_count FROM bronze.crm_cust_info
UNION ALL
SELECT 'bronze.crm_prd_info',     COUNT(*) FROM bronze.crm_prd_info
UNION ALL
SELECT 'bronze.crm_sales_details',COUNT(*) FROM bronze.crm_sales_details
UNION ALL
SELECT 'silver.crm_cust_info',    COUNT(*) FROM silver.crm_cust_info
UNION ALL
SELECT 'silver.crm_prd_info',     COUNT(*) FROM silver.crm_prd_info
UNION ALL
SELECT 'silver.crm_sales_details',COUNT(*) FROM silver.crm_sales_details
UNION ALL
SELECT 'gold.dim_customers',      COUNT(*) FROM gold.dim_customers
UNION ALL
SELECT 'gold.dim_products',       COUNT(*) FROM gold.dim_products
UNION ALL
SELECT 'gold.fact_sales',         COUNT(*) FROM gold.fact_sales
ORDER BY layer_table;