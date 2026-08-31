/*
================================================================================
STORED PROCEDURE: bronze.load_bronze
================================================================================

ARCHITECTURE OVERVIEW:
    This stored procedure implements the Bronze layer ingestion process of the 
    3-Tier Medallion Architecture (Bronze -> Silver -> Gold). 

    - Bronze Layer Purpose:
      Acts as the raw landing zone. Data is ingested from external source systems 
      (CRM and ERP flat files) into relational staging tables. No data transformation, 
      type casting, or business logic cleansing is applied at this stage. Data is 
      stored in its original structure to maintain historical fidelity.

    - Load Strategy: Full Load (Truncate & Load)
      1. TRUNCATE TABLE: Instantly purges all existing rows in the staging table.
      2. BULK INSERT: High-performance stream loading directly from disk flat files.

KEY TECHNICAL FEATURES & OPTIMIZATIONS:
    1. Performance Tuning:
       - SET NOCOUNT ON: Suppresses "(X) rows affected" network messages for speed.
       - TABLOCK Hint: Acquires a table-level lock during BULK INSERT, enabling 
         minimal logging and maximizing throughput.
         
    2. Operational Transparency & Logging:
       - Real-time formatted console output via PRINT statements.
       - Dynamic execution timing using GETDATE() and DATEDIFF().
       - Exact row tracking using system function @@ROWCOUNT.

    3. Resilience & Error Handling:
       - Structured TRY...CATCH block captures unexpected failures (e.g., missing 
         files, lock timeouts, path errors).
       - Uses THROW to re-raise original exceptions for external orchestrators 
         (e.g., Azure Data Factory, SSIS, Apache Airflow).

SOURCE TO TARGET MAPPINGS:
    Source File Path                                       | Target Table
    -------------------------------------------------------|-------------------------
    .../source_crm/cust_info.csv                           | bronze.crm_cust_info
    .../source_crm/prd_info.csv                            | bronze.crm_prd_info
    .../source_crm/sales_details.csv                       | bronze.crm_sales_details
    .../source_erp/LOC_A101.csv                            | bronze.erp_loc_a101
    .../source_erp/CUST_AZ12.csv                           | bronze.erp_cust_az12
    .../source_erp/PX_CAT_G1V2.csv                         | bronze.erp_px_cat_g1v2

PARAMETERS:
    None.

USAGE EXAMPLES:
    EXEC bronze.load_bronze;
================================================================================
*/

USE DataWarehouse;
GO

CREATE OR ALTER PROCEDURE bronze.load_bronze AS 
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
        PRINT '               LOADING BRONZE LAYER (FULL REFRESH)';
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
        PRINT '  >> [TRUNCATE & LOAD] Table: bronze.crm_cust_info';
        
        TRUNCATE TABLE bronze.crm_cust_info;
        BULK INSERT bronze.crm_cust_info
        FROM 'D:\PROJECTS\AKIENI\DOCUMENTS\RESOURCES\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @rows_inserted = @@ROWCOUNT;
        SET @end_time = GETDATE();
        PRINT '     [STATUS]   : SUCCESS';
        PRINT '     [ROWS]     : ' + CAST(@rows_inserted AS VARCHAR) + ' rows inserted';
        PRINT '     [DURATION] : ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' sec';
        PRINT '';

        -- Load Product Info (CRM)
        SET @start_time = GETDATE();
        PRINT '  >> [TRUNCATE & LOAD] Table: bronze.crm_prd_info';
        
        TRUNCATE TABLE bronze.crm_prd_info;
        BULK INSERT bronze.crm_prd_info
        FROM 'D:\PROJECTS\AKIENI\DOCUMENTS\RESOURCES\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @rows_inserted = @@ROWCOUNT;
        SET @end_time = GETDATE();
        PRINT '     [STATUS]   : SUCCESS';
        PRINT '     [ROWS]     : ' + CAST(@rows_inserted AS VARCHAR) + ' rows inserted';
        PRINT '     [DURATION] : ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' sec';
        PRINT '';

        -- Load Sales Details (CRM)
        SET @start_time = GETDATE();
        PRINT '  >> [TRUNCATE & LOAD] Table: bronze.crm_sales_details';
        
        TRUNCATE TABLE bronze.crm_sales_details;
        BULK INSERT bronze.crm_sales_details
        FROM 'D:\PROJECTS\AKIENI\DOCUMENTS\RESOURCES\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
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

        -- Load Location Data (ERP)
        SET @start_time = GETDATE();
        PRINT '  >> [TRUNCATE & LOAD] Table: bronze.erp_loc_a101';
        
        TRUNCATE TABLE bronze.erp_loc_a101;
        BULK INSERT bronze.erp_loc_a101
        FROM 'D:\PROJECTS\AKIENI\DOCUMENTS\RESOURCES\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @rows_inserted = @@ROWCOUNT;
        SET @end_time = GETDATE();
        PRINT '     [STATUS]   : SUCCESS';
        PRINT '     [ROWS]     : ' + CAST(@rows_inserted AS VARCHAR) + ' rows inserted';
        PRINT '     [DURATION] : ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' sec';
        PRINT '';

        -- Load Customer Demographics/AZ Data (ERP)
        SET @start_time = GETDATE();
        PRINT '  >> [TRUNCATE & LOAD] Table: bronze.erp_cust_az12';
        
        TRUNCATE TABLE bronze.erp_cust_az12;
        BULK INSERT bronze.erp_cust_az12
        FROM 'D:\PROJECTS\AKIENI\DOCUMENTS\RESOURCES\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @rows_inserted = @@ROWCOUNT;
        SET @end_time = GETDATE();
        PRINT '     [STATUS]   : SUCCESS';
        PRINT '     [ROWS]     : ' + CAST(@rows_inserted AS VARCHAR) + ' rows inserted';
        PRINT '     [DURATION] : ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' sec';
        PRINT '';

        -- Load Product Categories (ERP)
        SET @start_time = GETDATE();
        PRINT '  >> [TRUNCATE & LOAD] Table: bronze.erp_px_cat_g1v2';
        
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;
        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'D:\PROJECTS\AKIENI\DOCUMENTS\RESOURCES\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @rows_inserted = @@ROWCOUNT;
        SET @end_time = GETDATE();
        PRINT '     [STATUS]   : SUCCESS';
        PRINT '     [ROWS]     : ' + CAST(@rows_inserted AS VARCHAR) + ' rows inserted';
        PRINT '     [DURATION] : ' + CAST(DATEDIFF(second, @start_time, @end_time) AS VARCHAR) + ' sec';
        PRINT '';

        PRINT '====================================================================';
        PRINT '  BRONZE LAYER LOAD COMPLETED SUCCESSFULLY';
        PRINT '  TOTAL DURATION: ' + CAST(DATEDIFF(second, @batch_start_time, GETDATE()) AS VARCHAR) + ' second(s)';
        PRINT '====================================================================';

    END TRY
    BEGIN CATCH
        PRINT '';
        PRINT '====================================================================';
        PRINT '  [ERROR] BRONZE LAYER LOAD FAILED!';
        PRINT '--------------------------------------------------------------------';
        PRINT '  Error Message : ' + ERROR_MESSAGE();
        PRINT '  Error Number  : ' + CAST(ERROR_NUMBER() AS VARCHAR);
        PRINT '  Error State   : ' + CAST(ERROR_STATE() AS VARCHAR);
        PRINT '====================================================================';

        THROW;
    END CATCH;
END;
GO


EXEC bronze.load_bronze;
