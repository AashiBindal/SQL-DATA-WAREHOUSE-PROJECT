
/*
===============================================================================
DDL Script: Create Gold Layer Views
===============================================================================
Script Purpose:
    This script creates views in the Gold Layer of the Data Warehouse.

    The Gold Layer contains business-ready data used for reporting,
    analytics, and business intelligence.

Views Created:
    1. gold.dim_customers
    2. gold.dim_products
    3. gold.fact_sales

===============================================================================
*/


-- =============================================================================
-- 1. DIMENSION TABLE: GOLD.DIM_CUSTOMERS
-- =============================================================================
-- Purpose:
--     Stores customer information enriched with demographic and geographic
--     details from CRM and ERP source tables.
--
-- Highlights:
--     - Generates a surrogate key using ROW_NUMBER().
--     - CRM is considered the master source for customer gender.
--     - ERP gender is used as a fallback when CRM gender is unavailable.
--     - Joins customer information with location and demographic data.
-- =============================================================================

CREATE VIEW gold.dim_customers AS

SELECT
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,
    ci.cst_id AS customer_id,
    ci.cst_key AS customer_number,
    ci.cst_firstname AS first_name,
    ci.cst_lastname AS last_name,
    la.cntry AS country,
    ci.cst_marital_status AS marital_status,

    CASE
        WHEN ci.cst_gndr != 'n/a'
            THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'n/a')
    END AS gender,

    ca.bdate AS birthdate,
    ci.cst_create_date AS create_date

FROM silver.crm_cust_info ci

LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid

LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid;


-- =============================================================================
-- 2. DIMENSION TABLE: GOLD.DIM_PRODUCTS
-- =============================================================================
-- Purpose:
--     Provides product information along with category and subcategory
--     details.
--
-- Highlights:
--     - Generates a surrogate product key using ROW_NUMBER().
--     - Combines CRM product information with ERP category details.
--     - Filters out historical product records by selecting only active
--       products (prd_end_dt IS NULL).
-- =============================================================================

CREATE VIEW gold.dim_products AS

SELECT
    ROW_NUMBER() OVER (
        ORDER BY pn.prd_start_dt, pn.prd_key
    ) AS product_key,

    pn.prd_id AS product_id,
    pn.prd_key AS product_number,
    pn.prd_nm AS product_name,
    pn.cat_id AS category_id,
    pc.cat AS category,
    pc.subcat AS subcategory,
    pc.maintenance AS maintenance_required,
    pn.prd_cost AS cost,
    pn.prd_line AS product_line,
    pn.prd_start_dt AS start_date

FROM silver.crm_prd_info pn

LEFT JOIN silver.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.id

WHERE pn.prd_end_dt IS NULL;


-- =============================================================================
-- 3. FACT TABLE: GOLD.FACT_SALES
-- =============================================================================
-- Purpose:
--     Stores transactional sales data for business analysis and reporting.
--
-- Highlights:
--     - Connects sales transactions with customer and product dimensions.
--     - Uses surrogate keys from Gold dimension views.
--     - Includes sales amount, quantity, price, and important order dates.
-- =============================================================================

CREATE VIEW gold.fact_sales AS

SELECT
    sd.sls_ord_num AS order_number,
    pr.product_key,
    cu.customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS shipping_date,
    sd.sls_due_dt AS due_date,
    sd.sls_sales AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price AS price

FROM silver.crm_sales_details sd

LEFT JOIN gold.dim_products pr
    ON sd.sls_prd_key = pr.product_number

LEFT JOIN gold.dim_customers cu
    ON sd.sls_cust_id = cu.customer_id;


-- =============================================================================
-- END OF GOLD LAYER VIEW CREATION
-- =============================================================================
