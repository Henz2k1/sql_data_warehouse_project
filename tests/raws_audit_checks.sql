/*
===============================================================================
Data Audit Script: Bronze vs Silver Row Count Validation
===============================================================================
Script Purpose:
    This script compares row counts between raw ingestion tables (Bronze) 
    and cleansed staging tables (Silver) to audit data loss, deduplication, 
    or filtering actions during the ETL transformation.

Database Context:
    Target Database: DataWarehouse
    Target Schemas : bronze, silver

Audit Scope:
    - CRM Tables : crm_cust_info, crm_prd_info, crm_sales_details
    - ERP Tables : erp_loc_a101, erp_cust_az12, erp_px_cat_g1v2

Execution Flow:
    1. Switches context to 'DataWarehouse'.
    2. Performs COUNT(*) on all Bronze tables.
    3. Performs COUNT(*) on all Silver tables.
    4. Combines results using UNION ALL for a consolidated audit report.

Usage Notes:
    - Differences between Bronze and Silver counts indicate deduplication 
      or removal of invalid records (Quality Gate filters).
===============================================================================
*/

USE DataWarehouse;
GO

-- =============================================================================
-- ROW COUNT AUDIT: BRONZE VS SILVER
-- =============================================================================

-- CRM Tables Audit
SELECT 'bronze.crm_cust_info'     AS table_name, COUNT(*) AS row_count FROM bronze.crm_cust_info
UNION ALL
SELECT 'silver.crm_cust_info'     AS table_name, COUNT(*) AS row_count FROM silver.crm_cust_info
UNION ALL
SELECT 'bronze.crm_prd_info'      AS table_name, COUNT(*) AS row_count FROM bronze.crm_prd_info
UNION ALL
SELECT 'silver.crm_prd_info'      AS table_name, COUNT(*) AS row_count FROM silver.crm_prd_info
UNION ALL
SELECT 'bronze.crm_sales_details' AS table_name, COUNT(*) AS row_count FROM bronze.crm_sales_details
UNION ALL
SELECT 'silver.crm_sales_details' AS table_name, COUNT(*) AS row_count FROM silver.crm_sales_details

UNION ALL

-- ERP Tables Audit
SELECT 'bronze.erp_loc_a101'      AS table_name, COUNT(*) AS row_count FROM bronze.erp_loc_a101
UNION ALL
SELECT 'silver.erp_loc_a101'      AS table_name, COUNT(*) AS row_count FROM silver.erp_loc_a101
UNION ALL
SELECT 'bronze.erp_cust_az12'     AS table_name, COUNT(*) AS row_count FROM bronze.erp_cust_az12
UNION ALL
SELECT 'silver.erp_cust_az12'     AS table_name, COUNT(*) AS row_count FROM silver.erp_cust_az12
UNION ALL
SELECT 'bronze.erp_px_cat_g1v2'   AS table_name, COUNT(*) AS row_count FROM bronze.erp_px_cat_g1v2
UNION ALL
SELECT 'silver.erp_px_cat_g1v2'   AS table_name, COUNT(*) AS row_count FROM silver.erp_px_cat_g1v2;
