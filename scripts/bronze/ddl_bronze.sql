--data insertion 

CREATE OR ALTER PROCEDURE bronze.load_bronze AS 
BEGIN

    DECLARE @start_time DATETIME,
            @end_time DATETIME,
            @batch_start_time DATETIME,
            @batch_end_time DATETIME;

    BEGIN TRY 

    SET @batch_start_time = GETDATE();
        PRINT '=======================================================================';
        PRINT 'LOADING BRONZE LAYER';
        PRINT '=======================================================================';

        PRINT 'LOADING CRM TABLES';

        -- CRM CUSTOMER
        SET @start_time = GETDATE();

        TRUNCATE TABLE bronze.crm_cust_info;

        BULK INSERT bronze.crm_cust_info 
        FROM 'C:\Users\manoj\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load duration : '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' SECONDS';

        PRINT '-----------------------';


        -- CRM PRODUCT
        SET @start_time = GETDATE();

        TRUNCATE TABLE bronze.crm_prd_info;

        BULK INSERT bronze.crm_prd_info 
        FROM 'C:\Users\manoj\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load duration : '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' SECONDS';

        PRINT '-----------------------';


        -- CRM SALES
        SET @start_time = GETDATE();

        TRUNCATE TABLE bronze.crm_sales_details;

        BULK INSERT bronze.crm_sales_details
        FROM 'C:\Users\manoj\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load duration : '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' SECONDS';

        PRINT '-----------------------';


        PRINT 'LOADING ERP TABLES';


        -- ERP CUSTOMER
        SET @start_time = GETDATE();

        TRUNCATE TABLE bronze.erp_cust_az12;

        BULK INSERT bronze.erp_cust_az12
        FROM 'C:\Users\manoj\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load duration : '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' SECONDS';

        PRINT '-----------------------';


        -- ERP LOCATION
        SET @start_time = GETDATE();

        TRUNCATE TABLE bronze.erp_loc_a101;

        BULK INSERT bronze.erp_loc_a101 
        FROM 'C:\Users\manoj\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load duration : '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' SECONDS';

        PRINT '-----------------------';


        -- ERP CATEGORY
        SET @start_time = GETDATE();

        TRUNCATE TABLE bronze.erp_px_cat_g1v2;

        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'C:\Users\manoj\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load duration : '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' SECONDS';

        PRINT '-----------------------';

     SET  @batch_end_time = GETDATE();
     PRINT'========================================';
     PRINT 'Loading bronze layer is completed';
     PRINT 'Total Load Duration :  ' +  CAST(DATEDIFF(second , @batch_start_time ,@batch_end_time ) AS NVARCHAR ) + ' Seconds';
     PRINT'========================================';


    END TRY 

    BEGIN CATCH 

        PRINT '==================================';
        PRINT 'ERROR DURING LOADING BRONZE LAYER';
        PRINT 'ERROR MESSAGE : ' + ERROR_MESSAGE();
        PRINT 'ERROR NUMBER  : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'ERROR STATE   : ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '==================================';

    END CATCH 

END;
GO


-- Execute the procedure ONCE
EXEC bronze.load_bronze;
