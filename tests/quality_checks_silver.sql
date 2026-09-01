/*
===============================================================================
Quality Checks Script: Silver Layer Validation
===============================================================================
Script Purpose:
    This script performs comprehensive data quality checks across the 'Silver' 
    layer tables to validate data consistency, integrity, and accuracy after 
    the ETL/ELT transformation process.

Database Context:
    Target Database: DataWarehouse
    Target Schema:    silver

Validation Scope:
    1. Primary Key Integrity : Check for NULLs or duplicate values.
    2. Data Hygiene          : Detect leading/trailing whitespaces in string fields.
    3. Business Rules        : Verify date order logic (e.g., Start <= End, Order <= Ship).
    4. Data Consistency      : Validate metric calculations (Sales = Quantity * Price).
    5. Domain Values         : Inspect distinct categorical values for standardization.

Execution Flow:
    1. Switches context to 'DataWarehouse'.
    2. Executes quality checks for CRM tables (cust_info, prd_info, sales_details).
    3. Executes quality checks for ERP tables (cust_az12, loc_a101, px_cat_g1v2).

Notes & Warnings:
    - Queries tagged with 'Expectation: No Results' should return 0 rows. 
    - Any returned rows indicate data anomalies that require remediation.
===============================================================================
*/

USE DataWarehouse;
GO

-- =============================================================================
-- CRM TABLES QUALITY CHECKS
-- =============================================================================

-------------------------------------------------------------------------------
-- Table: silver.crm_cust_info
-------------------------------------------------------------------------------

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT 
    cst_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 
    OR cst_id IS NULL;

-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT 
    cst_key 
FROM silver.crm_cust_info
WHERE cst_key != TRIM(cst_key);

-- Data Standardization & Consistency
SELECT DISTINCT 
    cst_marital_status 
FROM silver.crm_cust_info;


-------------------------------------------------------------------------------
-- Table: silver.crm_prd_info
-------------------------------------------------------------------------------

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT 
    prd_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 
    OR prd_id IS NULL;

-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT 
    prd_nm 
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Check for NULLs or Negative Values in Cost
-- Expectation: No Results
SELECT 
    prd_cost 
FROM silver.crm_prd_info
WHERE prd_cost < 0 
    OR prd_cost IS NULL;

-- Data Standardization & Consistency
SELECT DISTINCT 
    prd_line 
FROM silver.crm_prd_info;

-- Check for Invalid Date Orders (Start Date > End Date)
-- Expectation: No Results
SELECT 
    * 
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;


-------------------------------------------------------------------------------
-- Table: silver.crm_sales_details
-------------------------------------------------------------------------------

-- Check for Invalid Raw Date Integers (Bronze Pre-check)
-- Expectation: No Results
SELECT 
    NULLIF(sls_due_dt, 0) AS sls_due_dt 
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0 
    OR LEN(sls_due_dt) != 8 
    OR sls_due_dt > 20500101 
    OR sls_due_dt < 19000101;

-- Check for Invalid Date Orders (Order Date > Shipping/Due Dates)
-- Expectation: No Results
SELECT 
    * 
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt 
    OR sls_order_dt > sls_due_dt;

-- Check Data Consistency: Sales = Quantity * Price
-- Expectation: No Results
SELECT DISTINCT 
    sls_sales,
    sls_quantity,
    sls_price 
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
    OR sls_sales IS NULL 
    OR sls_quantity IS NULL 
    OR sls_price IS NULL
    OR sls_sales <= 0 
    OR sls_quantity <= 0 
    OR sls_price <= 0
ORDER BY 
    sls_sales, 
    sls_quantity, 
    sls_price;

-- =============================================================================
-- ERP TABLES QUALITY CHECKS
-- =============================================================================

-------------------------------------------------------------------------------
-- Table: silver.erp_cust_az12
-------------------------------------------------------------------------------

-- Identify Out-of-Range Dates
-- Expectation: Birthdates between 1924-01-01 and Today
SELECT DISTINCT 
    bdate 
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' 
    OR bdate > GETDATE();

-- Data Standardization & Consistency
SELECT DISTINCT 
    gen 
FROM silver.erp_cust_az12;


-------------------------------------------------------------------------------
-- Table: silver.erp_loc_a101
-------------------------------------------------------------------------------

-- Data Standardization & Consistency
SELECT DISTINCT 
    cntry 
FROM silver.erp_loc_a101
ORDER BY cntry;


-------------------------------------------------------------------------------
-- Table: silver.erp_px_cat_g1v2
-------------------------------------------------------------------------------

-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT 
    * 
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat) 
    OR subcat != TRIM(subcat) 
    OR maintenance != TRIM(maintenance);

-- Data Standardization & Consistency
SELECT DISTINCT 
    maintenance 
FROM silver.erp_px_cat_g1v2;
