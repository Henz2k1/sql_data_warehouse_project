/*
===============================================================================
Quality Checks Script: Gold Layer Validation
===============================================================================
Script Purpose:
    This script performs quality checks to validate the integrity, consistency, 
    and accuracy of the Gold Layer views (Star Schema). These checks ensure:
    - Primary/Surrogate key uniqueness in dimension tables.
    - Referential integrity between fact and dimension tables (no orphaned records).
    - Validation of relationships in the data model for analytical reliability.

Database Context:
    Target Database: DataWarehouse
    Target Schema:    gold

Validation Scope:
    1. Dimension Keys   : Validate unique constraints on customer_key and product_key.
    2. Model Integrity  : Detect orphaned fact records resulting from failed joins.

Execution Flow:
    1. Switches context to 'DataWarehouse'.
    2. Runs surrogate key uniqueness tests for 'gold.dim_customers' and 'gold.dim_products'.
    3. Runs referential integrity checks between 'gold.fact_sales' and dimensions.

Notes & Warnings:
    - All queries have an expectation of returning NO RESULTS (0 rows).
    - Any returned rows indicate orphaned foreign keys or broken dimension logic.
===============================================================================
*/

USE DataWarehouse;
GO

-- =============================================================================
-- DIMENSION TABLES QUALITY CHECKS
-- =============================================================================

-------------------------------------------------------------------------------
-- View: gold.dim_customers
-------------------------------------------------------------------------------

-- Check for Uniqueness of Customer Key
-- Expectation: No Results
SELECT 
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY 
    customer_key
HAVING COUNT(*) > 1;


-------------------------------------------------------------------------------
-- View: gold.dim_products
-------------------------------------------------------------------------------

-- Check for Uniqueness of Product Key
-- Expectation: No Results
SELECT 
    product_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY 
    product_key
HAVING COUNT(*) > 1;


-- =============================================================================
-- FACT TABLE & REFERENTIAL INTEGRITY CHECKS
-- =============================================================================

-------------------------------------------------------------------------------
-- View: gold.fact_sales
-------------------------------------------------------------------------------

-- Check Data Model Connectivity & Referential Integrity (Fact to Dimensions)
-- Expectation: No Results
SELECT 
    f.order_number,
    f.customer_key AS fact_customer_key,
    f.product_key  AS fact_product_key,
    c.customer_key AS dim_customer_key,
    p.product_key  AS dim_product_key
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
WHERE p.product_key IS NULL 
   OR c.customer_key IS NULL;
