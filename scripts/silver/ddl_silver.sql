/*
===============================================================================
DDL Script: Create Silver Layer Tables
===============================================================================
Script Purpose:
    This script initializes the schema and creates refined staging tables for the 
    'Silver' layer within the DataWarehouse environment. 

Database Context:
    Target Database: DataWarehouse
    Target Schema:    silver

Source Systems Integrated:
    1. CRM (Customer Relationship Management)
       - crm_cust_info     : Cleansed customer demographic data.
       - crm_prd_info      : Product catalog, category mappings, and lifecycle dates.
       - crm_sales_details : Transactional sales order records.
    
    2. ERP (Enterprise Resource Planning)
       - erp_loc_a101     : Customer location and standardized country mapping.
       - erp_cust_az12     : Additional customer details (birthdate, gender).
       - erp_px_cat_g1v2   : Product categories, subcategories, and maintenance flags.

Execution Flow:
    1. Switches context to 'DataWarehouse'.
    2. Checks for existing table objects in the 'silver' schema.
    3. Drops existing tables if present to ensure a clean slate (DDL reset).
    4. Recreates the tables with cleansed fields and audit metadata.

Notes & Warnings:
    - Running this script WILL DROP existing silver tables and purge their data.
    - Data structures reflect cleansed and transformed data.
    - Includes 'dwh_create_date' metadata column for lineage and auditing.
===============================================================================
*/

USE DataWarehouse;
GO

-- =============================================================================
-- CRM TABLES
-- =============================================================================

-- Table: silver.crm_cust_info
IF OBJECT_ID ('silver.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_info;
GO

CREATE TABLE silver.crm_cust_info(
    cst_id INT,
    cst_key NVARCHAR(50),
    cst_firstname NVARCHAR(50),
    cst_lastname NVARCHAR(50),
    cst_marital_status NVARCHAR(50),
    cst_gndr NVARCHAR(50),
    cst_create_date DATE,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

-- Table: silver.crm_prd_info
IF OBJECT_ID ('silver.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;
GO

CREATE TABLE silver.crm_prd_info(
    prd_id INT,
    cat_id NVARCHAR(50),
    prd_key NVARCHAR(50),
    prd_nm NVARCHAR(50),
    prd_cost INT,
    prd_line NVARCHAR(50),
    prd_start_dt DATE,
    prd_end_dt DATE,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

-- Table: silver.crm_sales_details
IF OBJECT_ID ('silver.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE silver.crm_sales_details;
GO

CREATE TABLE silver.crm_sales_details(
    sls_ord_num NVARCHAR(50),
    sls_prd_key NVARCHAR(50),
    sls_cust_id INT,
    sls_order_dt DATE,
    sls_ship_dt DATE,
    sls_due_dt DATE,
    sls_sales INT,
    sls_quantity INT,
    sls_price INT,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

-- =============================================================================
-- ERP TABLES
-- =============================================================================

-- Table: silver.erp_loc_a101
IF OBJECT_ID ('silver.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE silver.erp_loc_a101;
GO

CREATE TABLE silver.erp_loc_a101(
    cid NVARCHAR(50),
    cntry NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

-- Table: silver.erp_cust_az12
IF OBJECT_ID ('silver.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE silver.erp_cust_az12;
GO

CREATE TABLE silver.erp_cust_az12(
    cid NVARCHAR(50),
    bdate DATE,
    gen NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

-- Table: silver.erp_px_cat_g1v2
IF OBJECT_ID ('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE silver.erp_px_cat_g1v2;
GO

CREATE TABLE silver.erp_px_cat_g1v2(
    id NVARCHAR(50),
    cat NVARCHAR(50),
    subcat NVARCHAR(50),
    maintenance NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO
