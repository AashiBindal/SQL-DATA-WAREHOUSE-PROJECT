-- EXEC silver.load_silver;


CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN

    --==============================================================
    -- Declare Variables
    --==============================================================

    DECLARE 
        @start_time       DATETIME,
        @end_time         DATETIME,
        @batch_start_time DATETIME,
        @batch_end_time   DATETIME;


    BEGIN TRY

        --==============================================================
        -- Start Overall Batch
        --==============================================================

        SET @batch_start_time = GETDATE();

        PRINT '================================================';
        PRINT '        STARTING SILVER LAYER LOAD';
        PRINT '================================================';


        --==============================================================
        -- BUILD SILVER LAYER -> silver.crm_cust_info
        --==============================================================

        SET @start_time = GETDATE();

        PRINT '------------------------------------------------';
        PRINT 'BUILD SILVER LAYER -> silver.crm_cust_info';
        PRINT '------------------------------------------------';

        PRINT '>> Truncating Table: silver.crm_cust_info';

        TRUNCATE TABLE silver.crm_cust_info;


        PRINT '>> Inserting Data Into: silver.crm_cust_info';

        INSERT INTO silver.crm_cust_info
        (
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

            CASE
                WHEN UPPER(TRIM(cst_marital_status)) = 'M'
                    THEN 'MARRIED'
                WHEN UPPER(TRIM(cst_marital_status)) = 'S'
                    THEN 'SINGLE'
                ELSE 'n/a'
            END AS cst_marital_status,

            CASE
                WHEN UPPER(TRIM(cst_gndr)) = 'F'
                    THEN 'FEMALE'
                WHEN UPPER(TRIM(cst_gndr)) = 'M'
                    THEN 'MALE'
                ELSE 'n/a'
            END AS cst_gndr,

            cst_create_date

        FROM
        (
            SELECT
                *,
                ROW_NUMBER() OVER
                (
                    PARTITION BY cst_id
                    ORDER BY cst_create_date DESC
                ) AS flag_last

            FROM bronze.crm_cust_info

            WHERE cst_id IS NOT NULL
        ) t

        WHERE flag_last = 1;


        SET @end_time = GETDATE();

        PRINT '>> crm_cust_info loaded successfully';
        PRINT '>> Duration: '
              + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
              + ' seconds';


        --==============================================================
        -- BUILD SILVER LAYER -> silver.crm_prd_info
        --==============================================================

        SET @start_time = GETDATE();

        PRINT '------------------------------------------------';
        PRINT 'BUILD SILVER LAYER -> silver.crm_prd_info';
        PRINT '------------------------------------------------';

        PRINT '>> Truncating Table: silver.crm_prd_info';

        TRUNCATE TABLE silver.crm_prd_info;


        PRINT '>> Inserting Data Into: silver.crm_prd_info';

        INSERT INTO silver.crm_prd_info
        (
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

            -- Extract category ID
            REPLACE(
                SUBSTRING(prd_key, 1, 5),
                '-',
                '_'
            ) AS cat_id,

            -- Extract product ID
            SUBSTRING(
                prd_key,
                7,
                LEN(prd_key)
            ) AS prd_key,

            prd_nm,

            ISNULL(prd_cost, 0) AS prd_cost,

            -- Standardize product line
            CASE UPPER(TRIM(prd_line))
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'n/a'
            END AS prd_line,

            CAST(prd_start_dt AS DATE) AS prd_start_dt,

            -- Calculate end date as one day before next start date
            CAST
            (
                LEAD(prd_start_dt) OVER
                (
                    PARTITION BY prd_key
                    ORDER BY prd_start_dt
                ) - 1
                AS DATE
            ) AS prd_end_dt

        FROM bronze.crm_prd_info;


        SET @end_time = GETDATE();

        PRINT '>> crm_prd_info loaded successfully';
        PRINT '>> Duration: '
              + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
              + ' seconds';


        --==============================================================
        -- BUILD SILVER LAYER -> silver.crm_sales_details
        --==============================================================

        SET @start_time = GETDATE();

        PRINT '------------------------------------------------';
        PRINT 'BUILD SILVER LAYER -> silver.crm_sales_details';
        PRINT '------------------------------------------------';

        PRINT '>> Truncating Table: silver.crm_sales_details';

        TRUNCATE TABLE silver.crm_sales_details;


        PRINT '>> Inserting Data Into: silver.crm_sales_details';

        INSERT INTO silver.crm_sales_details
        (
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

            -- Standardize Order Date
            CASE
                WHEN sls_order_dt = 0
                     OR LEN(sls_order_dt) <> 8
                    THEN NULL
                ELSE
                    TRY_CONVERT
                    (
                        DATE,
                        CONVERT(VARCHAR(8), sls_order_dt),
                        112
                    )
            END AS sls_order_dt,

            -- Standardize Ship Date
            CASE
                WHEN sls_ship_dt = 0
                     OR LEN(sls_ship_dt) <> 8
                    THEN NULL
                ELSE
                    TRY_CONVERT
                    (
                        DATE,
                        CONVERT(VARCHAR(8), sls_ship_dt),
                        112
                    )
            END AS sls_ship_dt,

            -- Standardize Due Date
            CASE
                WHEN sls_due_dt = 0
                     OR LEN(sls_due_dt) <> 8
                    THEN NULL
                ELSE
                    TRY_CONVERT
                    (
                        DATE,
                        CONVERT(VARCHAR(8), sls_due_dt),
                        112
                    )
            END AS sls_due_dt,

            -- Recalculate Sales if missing or incorrect
            CASE
                WHEN sls_sales IS NULL
                     OR sls_sales <= 0
                     OR sls_sales <> sls_quantity * ABS(sls_price)
                    THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END AS sls_sales,

            sls_quantity,

            -- Derive Price if missing or invalid
            CASE
                WHEN sls_price IS NULL
                     OR sls_price <= 0
                    THEN sls_sales / NULLIF(sls_quantity, 0)
                ELSE sls_price
            END AS sls_price

        FROM bronze.crm_sales_details;


        SET @end_time = GETDATE();

        PRINT '>> crm_sales_details loaded successfully';
        PRINT '>> Duration: '
              + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
              + ' seconds';


        --==============================================================
        -- BUILD SILVER LAYER -> silver.erp_cust_az12
        --==============================================================

        SET @start_time = GETDATE();

        PRINT '------------------------------------------------';
        PRINT 'BUILD SILVER LAYER -> silver.erp_cust_az12';
        PRINT '------------------------------------------------';

        PRINT '>> Truncating Table: silver.erp_cust_az12';

        TRUNCATE TABLE silver.erp_cust_az12;


        PRINT '>> Inserting Data Into: silver.erp_cust_az12';

        INSERT INTO silver.erp_cust_az12
        (
            cid,
            bdate,
            gen
        )
        SELECT

            -- Remove NAS prefix
            CASE
                WHEN cid LIKE 'NAS%'
                    THEN SUBSTRING(cid, 4, LEN(cid))
                ELSE cid
            END AS cid,

            -- Convert invalid/future birth dates to NULL
            CASE
                WHEN TRY_CONVERT(DATE, bdate) > CAST(GETDATE() AS DATE)
                    THEN NULL
                ELSE TRY_CONVERT(DATE, bdate)
            END AS bdate,

            -- Standardize Gender
            CASE
                WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE')
                    THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')
                    THEN 'Male'
                ELSE 'n/a'
            END AS gen

        FROM bronze.erp_cust_az12;


        SET @end_time = GETDATE();

        PRINT '>> erp_cust_az12 loaded successfully';
        PRINT '>> Duration: '
              + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
              + ' seconds';


        --==============================================================
        -- BUILD SILVER LAYER -> silver.erp_loc_a101
        --==============================================================

        SET @start_time = GETDATE();

        PRINT '------------------------------------------------';
        PRINT 'BUILD SILVER LAYER -> silver.erp_loc_a101';
        PRINT '------------------------------------------------';

        PRINT '>> Truncating Table: silver.erp_loc_a101';

        TRUNCATE TABLE silver.erp_loc_a101;


        PRINT '>> Inserting Data Into: silver.erp_loc_a101';

        INSERT INTO silver.erp_loc_a101
        (
            cid,
            cntry
        )
        SELECT

            -- Remove hyphen from customer ID
            REPLACE(cid, '-', '') AS cid,

            -- Standardize Country
            CASE
                WHEN TRIM(cntry) = 'DE'
                    THEN 'Germany'

                WHEN TRIM(cntry) IN ('US', 'USA')
                    THEN 'United State'

                WHEN TRIM(cntry) = ''
                     OR cntry IS NULL
                    THEN 'n/a'

                ELSE TRIM(cntry)
            END AS cntry

        FROM bronze.erp_loc_a101;


        SET @end_time = GETDATE();

        PRINT '>> erp_loc_a101 loaded successfully';
        PRINT '>> Duration: '
              + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
              + ' seconds';


        --==============================================================
        -- BUILD SILVER LAYER -> silver.erp_px_cat_g1v2
        --==============================================================

        SET @start_time = GETDATE();

        PRINT '------------------------------------------------';
        PRINT 'BUILD SILVER LAYER -> silver.erp_px_cat_g1v2';
        PRINT '------------------------------------------------';

        PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';

        TRUNCATE TABLE silver.erp_px_cat_g1v2;


        PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';

        INSERT INTO silver.erp_px_cat_g1v2
        (
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


        SET @end_time = GETDATE();

        PRINT '>> erp_px_cat_g1v2 loaded successfully';
        PRINT '>> Duration: '
              + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
              + ' seconds';


        --==============================================================
        -- End Overall Batch
        --==============================================================

        SET @batch_end_time = GETDATE();

        PRINT '================================================';
        PRINT '        SILVER LAYER LOAD COMPLETED';
        PRINT '================================================';

        PRINT '>> Total Batch Duration: '
              + CAST(
                    DATEDIFF(
                        SECOND,
                        @batch_start_time,
                        @batch_end_time
                    ) AS NVARCHAR
                )
              + ' seconds';

        PRINT '================================================';


    END TRY


    --==============================================================
    -- ERROR HANDLING
    --==============================================================

    BEGIN CATCH

        PRINT '================================================';
        PRINT '        ERROR OCCURRED DURING SILVER LOAD';
        PRINT '================================================';

        PRINT 'Error Number: '
              + CAST(ERROR_NUMBER() AS NVARCHAR);

        PRINT 'Error Message: '
              + ERROR_MESSAGE();

        PRINT 'Error Line: '
              + CAST(ERROR_LINE() AS NVARCHAR);

        PRINT 'Error Procedure: '
              + ISNULL(ERROR_PROCEDURE(), 'N/A');

        PRINT '================================================';

        THROW;

    END CATCH

END;
GO
