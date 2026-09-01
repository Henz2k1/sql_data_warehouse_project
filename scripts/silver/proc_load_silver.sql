/*
================================================================================
STORED PROCEDURE: silver.load_silver
================================================================================

ARCHITECTURE OVERVIEW:
    This stored procedure implements the Silver layer ETL process of the 
    3-Tier Medallion Architecture (Bronze -> Silver -> Gold). 

    - Silver Layer Purpose:
      Acts as the cleansed and transformed layer. Data is ingested from the 
      Bronze raw staging tables into relational target tables. In this stage, 
      data transformations, data cleansing, type casting, domain normalization, 
      and deduplication rules are strictly applied.

    - Load Strategy: Full Load (Truncate & Load)
      1. TRUNCATE TABLE: Instantly purges all existing rows in the Silver table.
      2. INSERT INTO ... SELECT: Applies cleansing rules, filters invalid records,
         normalizes values, and loads refined data into the target table.

KEY TECHNICAL FEATURES & OPTIMIZATIONS:
    1. Performance Tuning:
       - SET NOCOUNT ON: Suppresses "(X) rows affected" network messages for speed.
         
    2. Operational Transparency & Logging:
       - Real-time formatted console output via PRINT statements.
       - Dynamic execution timing using GETDATE() and DATEDIFF().
       - Exact row tracking using system function @@ROWCOUNT.

    3. Resilience & Error Handling:
       - Structured TRY...CATCH block captures unexpected failures during execution.
       - Uses THROW to re-raise original exceptions for external orchestrators 
         (e.g., Azure Data Factory, SSIS, Apache Airflow).

SOURCE TO TARGET MAPPINGS & TRANSFORMATIONS:
    Source Table              | Target Table           | Key Transformations Applied
    --------------------------|------------------------|--------------------------------------------------
    bronze.crm_cust_info      | silver.crm_cust_info   | Deduplication (ROW_NUMBER), TRIM names, Gender & Marital Status normalization
    bronze.crm_prd_info       | silver.crm_prd_info    | Extract cat_id & prd_key (SUBSTRING/REPLACE), Product Line mapping, Derive end_dt (LEAD)
    bronze.crm_sales_details  | silver.crm_sales_details| Date parsing (TRY_CAST), Recalculate sls_sales and sls_price consistency
    bronze.erp_cust_az12      | silver.erp_cust_az12   | Strip 'NAS' prefix, Nullify future birthdates, Normalize Gender
    bronze.erp_loc_a101       | silver.erp_loc_a101    | Clean hyphens in cid, Map country codes (DE, US/USA to full names)
    bronze.erp_px_cat_g1v2    | silver.erp_px_cat_g1v2 | Direct mapping of categories and metadata

PARAMETERS:
    None.

USAGE EXAMPLES:
    EXEC silver.load_silver;
================================================================================
*/

USE DataWarehouse;
GO

CREATE OR ALTER PROCEDURE silver.load_silver AS 
BEGIN
    -- Disable row count network messages to maximize execution performance
    SET NOCOUNT ON;

    -- Local variables for tracking execution duration and affected row counts
    DECLARE @batch_start_time DATETIME = GETDATE();
    DECLARE @start_time DATETIME;
    DECLARE @end_time DATETIME;
    DECLARE @rows_inserted INT;

    BEGIN TRY
        PRINT '====================================================================';
        PRINT '                LOADING SILVER LAYER (FULL REFRESH)';
        PRINT '====================================================================';

        -- =========================================================================
        -- INGESTING CRM SOURCE TABLES
        -- =========================================================================
        PRINT '';
        PRINT '--------------------------------------------------------------------';
        PRINT ' [SYSTEM] Ingesting CRM Source Data';
        PRINT '--------------------------------------------------------------------';

        -- Load Customer Info (CRM)
        SET @start_time = GETDATE();
        PRINT '  >> [TRUNCATE & LOAD] Table: silver.crm_cust_info';
        
        TRUNCATE TABLE silver.crm_cust_info;
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
            CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single' 
                 WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married' 
                 ELSE 'n/a' 
            END AS cst_marital_status,
            CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female' 
                 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male' 
                 ELSE 'n/a' 
            END AS cst_gndr,
            cst_create_date
        FROM (
            SELECT *,
                   ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) AS t
        WHERE flag_last = 1;

        SET @rows_inserted = @@ROWCOUNT;
        SET @end_time = GETDATE();
        PRINT '     [STATUS]   : SUCCESS';
        PRINT '     [ROWS]     : ' + CAST(@rows_inserted AS VARCHAR) + ' rows inserted';
        PRINT '     [DURATION] : ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' sec';
        PRINT '';

        -- Load Product Info (CRM)
        SET @start_time = GETDATE();
        PRINT '  >> [TRUNCATE & LOAD] Table: silver.crm_prd_info';
        
        TRUNCATE TABLE silver.crm_prd_info;
        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT 
            prd_id,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
            SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
            prd_nm,
            ISNULL(prd_cost, 0) AS prd_cost,
            CASE WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain' 
                 WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road' 
                 WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales' 
                 WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring' 
                 ELSE 'n/a' 
            END AS prd_line,
            CAST(prd_start_dt AS DATE) AS prd_start_dt,
            CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE) AS prd_end_dt
        FROM bronze.crm_prd_info;

        SET @rows_inserted = @@ROWCOUNT;
        SET @end_time = GETDATE();
        PRINT '     [STATUS]   : SUCCESS';
        PRINT '     [ROWS]     : ' + CAST(@rows_inserted AS VARCHAR) + ' rows inserted';
        PRINT '     [DURATION] : ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' sec';
        PRINT '';

        -- Load Sales Details (CRM)
        SET @start_time = GETDATE();
        PRINT '  >> [TRUNCATE & LOAD] Table: silver.crm_sales_details';
        
        TRUNCATE TABLE silver.crm_sales_details;
        INSERT INTO silver.crm_sales_details (
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
            CASE WHEN sls_order_dt IS NULL OR sls_order_dt = 0 OR LEN(CAST(sls_order_dt AS VARCHAR(8))) != 8 
                 THEN NULL 
                 ELSE TRY_CAST(CAST(sls_order_dt AS VARCHAR(8)) AS DATE) 
            END AS sls_order_dt,
            CASE WHEN sls_ship_dt IS NULL OR sls_ship_dt = 0 OR LEN(CAST(sls_ship_dt AS VARCHAR(8))) != 8 
                 THEN NULL 
                 ELSE TRY_CAST(CAST(sls_ship_dt AS VARCHAR(8)) AS DATE) 
            END AS sls_ship_dt,
            CASE WHEN sls_due_dt IS NULL OR sls_due_dt = 0 OR LEN(CAST(sls_due_dt AS VARCHAR(8))) != 8 
                 THEN NULL 
                 ELSE TRY_CAST(CAST(sls_due_dt AS VARCHAR(8)) AS DATE) 
            END AS sls_due_dt,
            CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) 
                 THEN sls_quantity * ABS(sls_price) 
                 ELSE sls_sales 
            END AS sls_sales,
            sls_quantity,
            CASE WHEN sls_price IS NULL OR sls_price <= 0 
                 THEN sls_sales / NULLIF(sls_quantity, 0) 
                 ELSE sls_price 
            END AS sls_price
        FROM bronze.crm_sales_details;

        SET @rows_inserted = @@ROWCOUNT;
        SET @end_time = GETDATE();
        PRINT '     [STATUS]   : SUCCESS';
        PRINT '     [ROWS]     : ' + CAST(@rows_inserted AS VARCHAR) + ' rows inserted';
        PRINT '     [DURATION] : ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' sec';
        PRINT '';

        -- =========================================================================
        -- INGESTING ERP SOURCE TABLES
        -- =========================================================================
        PRINT '--------------------------------------------------------------------';
        PRINT ' [SYSTEM] Ingesting ERP Source Data';
        PRINT '--------------------------------------------------------------------';

        -- Load Customer Demographics/AZ Data (ERP)
        SET @start_time = GETDATE();
        PRINT '  >> [TRUNCATE & LOAD] Table: silver.erp_cust_az12';
        
        TRUNCATE TABLE silver.erp_cust_az12;
        INSERT INTO silver.erp_cust_az12 (
            cid,
            bdate,
            gen
        )
        SELECT 
            CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) 
                 ELSE cid 
            END AS cid,
            CASE WHEN bdate > GETDATE() THEN NULL 
                 ELSE bdate 
            END AS bdate,
            CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female' 
                 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male' 
                 ELSE 'n/a' 
            END AS gen
        FROM bronze.erp_cust_az12;

        SET @rows_inserted = @@ROWCOUNT;
        SET @end_time = GETDATE();
        PRINT '     [STATUS]   : SUCCESS';
        PRINT '     [ROWS]     : ' + CAST(@rows_inserted AS VARCHAR) + ' rows inserted';
        PRINT '     [DURATION] : ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' sec';
        PRINT '';

        -- Load Location Data (ERP)
        SET @start_time = GETDATE();
        PRINT '  >> [TRUNCATE & LOAD] Table: silver.erp_loc_a101';
        
        TRUNCATE TABLE silver.erp_loc_a101;
        INSERT INTO silver.erp_loc_a101 (
            cid,
            cntry
        )
        SELECT 
            REPLACE(cid, '-', '') AS cid,
            CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany' 
                 WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States' 
                 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a' 
                 ELSE TRIM(cntry) 
            END AS cntry
        FROM bronze.erp_loc_a101;

        SET @rows_inserted = @@ROWCOUNT;
        SET @end_time = GETDATE();
        PRINT '     [STATUS]   : SUCCESS';
        PRINT '     [ROWS]     : ' + CAST(@rows_inserted AS VARCHAR) + ' rows inserted';
        PRINT '     [DURATION] : ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' sec';
        PRINT '';

        -- Load Product Categories (ERP)
        SET @start_time = GETDATE();
        PRINT '  >> [TRUNCATE & LOAD] Table: silver.erp_px_cat_g1v2';
        
        TRUNCATE TABLE silver.erp_px_cat_g1v2;
        INSERT INTO silver.erp_px_cat_g1v2 (
            id,
            cat,
            subcat,
            maintenance
        )
        SELECT 
            id,
            cat,
            subcat,
            maintenance
        FROM bronze.erp_px_cat_g1v2;

        SET @rows_inserted = @@ROWCOUNT;
        SET @end_time = GETDATE();
        PRINT '     [STATUS]   : SUCCESS';
        PRINT '     [ROWS]     : ' + CAST(@rows_inserted AS VARCHAR) + ' rows inserted';
        PRINT '     [DURATION] : ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' sec';
        PRINT '';

        PRINT '====================================================================';
        PRINT '  SILVER LAYER LOAD COMPLETED SUCCESSFULLY';
        PRINT '  TOTAL DURATION: ' + CAST(DATEDIFF(second, @batch_start_time, GETDATE()) AS VARCHAR) + ' second(s)';
        PRINT '====================================================================';

    END TRY
    BEGIN CATCH
        PRINT '';
        PRINT '====================================================================';
        PRINT '  [ERROR] SILVER LAYER LOAD FAILED!';
        PRINT '--------------------------------------------------------------------';
        PRINT '  Error Message : ' + ERROR_MESSAGE();
        PRINT '  Error Number  : ' + CAST(ERROR_NUMBER() AS VARCHAR);
        PRINT '  Error State   : ' + CAST(ERROR_STATE() AS VARCHAR);
        PRINT '====================================================================';

        THROW;
    END CATCH;
END;
GO
