/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script initializes the schema and creates analytical views for the 
    'Gold' layer within the DataWarehouse environment. 

Database Context:
    Target Database: DataWarehouse
    Target Schema:    gold

Source Systems Integrated:
    1. Silver Layer CRM Tables
       - silver.crm_cust_info     : Cleansed customer base.
       - silver.crm_prd_info      : Cleansed product details.
       - silver.crm_sales_details : Cleansed transaction records.

    2. Silver Layer ERP Tables
       - silver.erp_cust_az12     : Cleansed demographics.
       - silver.erp_loc_a101     : Cleansed geographic data.
       - silver.erp_px_cat_g1v2   : Cleansed product categorization.

Execution Flow:
    1. Switches context to 'DataWarehouse'.
    2. Checks for existing view objects in the 'gold' schema.
    3. Drops existing views if present to ensure a clean slate (DDL reset).
    4. Recreates the dimension and fact views to model a Star Schema.

Notes & Warnings:
    - Running this script WILL DROP existing gold views and replace their logic.
    - Surrogate keys (customer_key, product_key) are dynamically generated.
    - Products view filters out historical records (prd_end_dt IS NULL).
===============================================================================
*/
USE DataWarehouse;


GO
-- =============================================================================
-- CUSTOMER DIMENSION
-- =============================================================================
-- View: gold.dim_customers
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;


GO
CREATE VIEW gold.dim_customers
AS
SELECT ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key, -- Surrogate key
       ci.cst_id AS customer_id,
       ci.cst_key AS customer_number,
       ci.cst_firstname AS first_name,
       ci.cst_lastname AS last_name,
       la.cntry AS country,
       ci.cst_marital_status AS marital_status,
       CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr ELSE COALESCE (ca.gen, 'n/a') END AS gender, -- CRM is the primary source for gender
 -- Fallback to ERP data
       ca.bdate AS birthdate,
       ci.cst_create_date AS create_date
FROM   silver.crm_cust_info AS ci
       LEFT OUTER JOIN
       silver.erp_cust_az12 AS ca
       ON ci.cst_key = ca.cid
       LEFT OUTER JOIN
       silver.erp_loc_a101 AS la
       ON ci.cst_key = la.cid;


GO
-- =============================================================================
-- PRODUCT DIMENSION
-- =============================================================================
-- View: gold.dim_products
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;


GO
CREATE VIEW gold.dim_products
AS
SELECT ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key, -- Surrogate key
       pn.prd_id AS product_id,
       pn.prd_key AS product_number,
       pn.prd_nm AS product_name,
       pn.cat_id AS category_id,
       pc.cat AS category,
       pc.subcat AS subcategory,
       pc.maintenance AS maintenance,
       pn.prd_cost AS cost,
       pn.prd_line AS product_line,
       pn.prd_start_dt AS start_date
FROM   silver.crm_prd_info AS pn
       LEFT OUTER JOIN
       silver.erp_px_cat_g1v2 AS pc
       ON pn.cat_id = pc.id
WHERE  pn.prd_end_dt IS NULL; -- Filter out all historical data


GO
-- =============================================================================
-- SALES FACT TABLE
-- =============================================================================
-- View: gold.fact_sales
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;


GO
CREATE VIEW gold.fact_sales
AS
SELECT sd.sls_ord_num AS order_number,
       pr.product_key AS product_key,
       cu.customer_key AS customer_key,
       sd.sls_order_dt AS order_date,
       sd.sls_ship_dt AS shipping_date,
       sd.sls_due_dt AS due_date,
       sd.sls_sales AS sales_amount,
       sd.sls_quantity AS quantity,
       sd.sls_price AS price
FROM   silver.crm_sales_details AS sd
       LEFT OUTER JOIN
       gold.dim_products AS pr
       ON sd.sls_prd_key = pr.product_number
       LEFT OUTER JOIN
       gold.dim_customers AS cu
       ON sd.sls_cust_id = cu.customer_id;
