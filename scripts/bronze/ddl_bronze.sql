/*
===============================================================================
DDL Script: Create Bronze Layer Tables
===============================================================================
Script Purpose:
    This script initializes the schema and creates raw staging tables for the 
    'Bronze' layer within the DataWarehouse environment. 

Database Context:
    Target Database: DataWarehouse
    Target Schema:   bronze

Source Systems Integrated:
    1. CRM (Customer Relationship Management)
       - crm_cust_info     : Raw customer demographic data.
       - crm_prd_info      : Product catalog and lifecycle dates.
       - crm_sales_details : Transactional sales order records.
    
    2. ERP (Enterprise Resource Planning)
       - erp_loc_a101     : Customer location and country mapping.
       - erp_cust_az12     : Additional customer details (birthdate, gender).
       - erp_px_cat_g1v2   : Product categories, subcategories, and maintenance flags.

Execution Flow:
    1. Switches context to 'DataWarehouse'.
    2. Checks for existing table objects in the 'bronze' schema.
    3. Drops existing tables if present to ensure a clean slate (DDL reset).
    4. Recreates the tables with initial raw field definitions.

Notes & Warnings:
    - Running this script WILL DROP existing bronze tables and purge their data.
    - Data types reflect raw ingestion structures (e.g., dates stored as INT or DATETIME).
===============================================================================
*/

USE DataWarehouse;
GO

-- =============================================================================
-- CRM TABLES
-- =============================================================================

-- Table: bronze.crm_cust_info
IF OBJECT_ID ('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;
GO

CREATE TABLE bronze.crm_cust_info(
    cst_id INT,
    cst_key NVARCHAR(50),
    cst_firstname NVARCHAR(50),
    cst_lastname NVARCHAR(50),
    cst_material_status NVARCHAR(50),
    cst_gndr NVARCHAR(50),
    cst_create_date DATE
);
GO

-- Table: bronze.crm_prd_info
IF OBJECT_ID ('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;
GO

CREATE TABLE bronze.crm_prd_info(
    prd_id INT,
    prd_key NVARCHAR(50),
    prd_nm NVARCHAR(50),
    prd_cost INT,
    prd_line NVARCHAR(50),
    prd_start_dt DATETIME,
    prd_end_dt DATETIME
);
GO

-- Table: bronze.crm_sales_details
IF OBJECT_ID ('bronze.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;
GO

CREATE TABLE bronze.crm_sales_details(
    sls_ord_num NVARCHAR(50),
    sls_prd_key NVARCHAR(50),
    sls_cust_id INT,
    sls_order_dt INT,
    sls_ship_dt INT,
    sls_due_dt INT,
    cls_sales INT,
    sls_quantity INT,
    sls_price INT
);
GO

-- =============================================================================
-- ERP TABLES
-- =============================================================================

-- Table: bronze.erp_loc_a101
IF OBJECT_ID ('bronze.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;
GO

CREATE TABLE bronze.erp_loc_a101(
    cid NVARCHAR(50),
    cntry NVARCHAR(50)
);
GO

-- Table: bronze.erp_cust_az12
IF OBJECT_ID ('bronze.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;
GO

CREATE TABLE bronze.erp_cust_az12(
    cid NVARCHAR(50),
    bdate DATE,
    gen NVARCHAR(50)
);
GO

-- Table: bronze.erp_px_cat_g1v2
IF OBJECT_ID ('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;
GO

CREATE TABLE bronze.erp_px_cat_g1v2(
    id NVARCHAR(50),
    cat NVARCHAR(50),
    subcat NVARCHAR(50),
    maintenance NVARCHAR(50)
);
GO
