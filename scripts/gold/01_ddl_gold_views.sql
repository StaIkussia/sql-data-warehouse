/*
-------------------------------------------------------------------------------
gold.dim_customers
-------------------------------------------------------------------------------
Source:
	silver.crm_cust_info — customer demographics and status
	silver.erp_cust_az12 — birthdate and gender (secondary source)
	silver.erp_loc_a101 — country
-------------------------------------------------------------------------------
*/

DROP VIEW IF EXISTS gold.dim_customers;
CREATE VIEW gold.dim_customers AS
SELECT
	ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	ci.cst_marital_status AS marital_status,
	CASE
    	WHEN ci.cst_gndr != 'Unknown' THEN ci.cst_gndr
    	ELSE ca.gen
    END AS gender,
    ca.bdate AS birthdate,
	la.cntry AS country,
    ci.cst_create_date AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la ON ci.cst_key = la.cid;