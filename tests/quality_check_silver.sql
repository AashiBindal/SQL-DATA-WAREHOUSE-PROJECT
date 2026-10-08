--check quality in silver 

--===================================
--silver.crm_cust_info.csv table 
--===================================


--Check for Nulls or Duplicates IN primary Key 
--Expectation : no result 

SELECT 
cst_id ,
COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) >1 OR  
cst_id is null 

--Check for unwanted Spaces : if the original value is not equal to the same value after trimming it means there are spaces !
--expectation : no result 

SELECT cst_firstname 
from silver.crm_cust_info
where cst_firstname != TRIM(cst_firstname)

SELECT cst_lastname 
from silver.crm_cust_info
where cst_lastname != TRIM(cst_lastname)


--data standardization and consistency
SELECT DISTINCT cst_gndr
from silver.crm_cust_info

SELECT * FROM silver.crm_cust_info


--removes unnecessary spaces to ensure data consistency , and uniformity across all records 
--data normalization and standardization -> maps coded values to meaningful , user-friendly descriptions 
--handling missing data -> fills in the blanks by adding a default value 
--remove duplicates -> ensure only one record per entity by identifying and retaing the most relevent row 



--===================================
--silver.crm_prd_info.csv table 
--===================================



--Check for Nulls or Duplicates IN primary Key 
--Expectation : no result 

SELECT 
prd_id ,
COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) >1 OR  
prd_id is null 

--Check for unwanted Spaces : if the original value is not equal to the same value after trimming it means there are spaces !
--expectation : no result 

SELECT prd_nm
from silver.crm_prd_info
where prd_nm != TRIM(prd_nm)

--Check for nulls or negative number 
--expectation : no result 
SELECT prd_cost 
FROM silver.crm_prd_info 
WHERE prd_cost <0 or prd_cost is null

--data standardization and consistency
SELECT DISTINCT prd_line
from silver.crm_prd_info

--Check for invalid date orders 
SELECT *
FROM silver.crm_prd_info
where prd_end_dt<prd_start_dt

SELECT * FROM silver.crm_prd_info


--===================================
--silver.crm_sales_details.csv table 
--===================================


--check bussiness rule
SELECT distinct
sls_sales,
sls_quantity,
sls_price
FROM silver.crm_sales_details
where sls_sales != sls_quantity * sls_price
or sls_sales is null or sls_quantity is null or sls_price is null
or sls_sales <= 0  or sls_quantity <= 0 or sls_price <=0
order by sls_sales,
sls_quantity,
sls_price

--check for invalid date orders 
SELECT * FROM silver.crm_sales_details
where sls_order_dt > sls_ship_dt or   sls_order_dt	> sls_due_dt


select * from silver.crm_sales_details
------------------------------------------------------

--===================================
--silver.erp_cust_ax12.csv table 
--===================================

--Identify out of range
SELECT DISTINCT 
bdate 
from silver.erp_cust_az12
where bdate < '1924-01-01' or bdate > getdate()

--Data Standardization and consistency 

SELECT DISTINCT
gen
from silver.erp_cust_az12

select*from silver.erp_cust_az12

--------------------------------------------------------------



