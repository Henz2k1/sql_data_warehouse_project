/*
DOCUMENTATION & SCRIPT SUMMARY:
================================================================================
This SQL script initializes an Enterprise Data Warehouse using the 3-Tier 
Medallion Architecture (Bronze, Silver, Gold pattern):

1. Master Switch: Switches context to the 'master' database to manage system databases.
2. Clean Reset: Checks if 'DataWarehouse' exists, force-terminates active connections 
   via SINGLE_USER mode, and drops the existing database.
3. Creation: Creates a brand new, clean 'DataWarehouse' database instance.
4. Schema Setup: Creates three distinct logical schemas:
   - 'bronze': Raw/ingested data layer (landing zone, unchanged original source formats).
   - 'silver': Cleansed, normalized, and transformed data layer.
   - 'gold': Aggregated, business-ready data model (dimensional modeling, star schemas).
================================================================================
================================================================================
WARNING:
This script drops and recreates the 'DataWarehouse' database.
Executing this script will PERMANENTLY DELETE all existing data, schemas, 
and objects stored inside 'DataWarehouse'. Use with extreme caution in 
production environments.
================================================================================
*/

-- Switch to master database to perform administrative database lifecycle operations
USE master;
GO

-- Safely drop the existing DataWarehouse database if it already exists
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    -- Terminate all active user connections immediately to unlock the database
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    
    -- Drop the database instance
    DROP DATABASE DataWarehouse;
END;
GO

-- Create a fresh instance of the DataWarehouse database
CREATE DATABASE DataWarehouse;
GO -- Mandatory batch separator: ensures the database is fully created before switching context

-- Switch active session context to the newly created DataWarehouse
USE DataWarehouse;
GO

-- =============================================================================
-- MEDALLION ARCHITECTURE SCHEMA CREATION
-- =============================================================================

-- 1. Bronze Schema: Ingestion layer for raw data coming directly from source systems
CREATE SCHEMA bronze;
GO

-- 2. Silver Schema: Refined layer containing validated, cleaned, and standardized data
CREATE SCHEMA silver;
GO

-- 3. Gold Schema: Presentation layer formatted into star/snowflake schemas for reporting & BI
CREATE SCHEMA gold;
GO
