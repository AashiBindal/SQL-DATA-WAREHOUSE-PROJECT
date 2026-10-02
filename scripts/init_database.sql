/*
====================================================================
Create Database and Schemas
====================================================================

Script Purpose:
    This script creates the DataWarehouse database and prepares
    the Bronze, Silver, and Gold schemas for the data warehouse.

WARNING:
    If the DataWarehouse database already exists, this script will
    drop and recreate it. Existing data will be permanently deleted.

====================================================================
*/

USE master;
GO

-- Drop and recreate the DataWarehouse database if it already exists
IF EXISTS (
    SELECT 1
    FROM sys.databases
    WHERE name = 'DataWarehouse'
)
BEGIN
    ALTER DATABASE DataWarehouse
    SET SINGLE_USER
    WITH ROLLBACK IMMEDIATE;

    DROP DATABASE DataWarehouse;
END;
GO

-- Create the DataWarehouse database
CREATE DATABASE DataWarehouse;
GO

-- Use the newly created database
USE DataWarehouse;
GO

-- Create Bronze schema
CREATE SCHEMA bronze;
GO

-- Create Silver schema
CREATE SCHEMA silver;
GO

-- Create Gold schema
CREATE SCHEMA gold;
GO
