--===================================
--bronze.crm_cust_info.csv table 
--===================================


--Check for Nulls or Duplicates IN primary Key 
--Expectation : no result 

SELECT 
cst_id ,
COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) >1 OR  
cst_id is null 

--Nulls or Duplicates

--cst_id,error
--29449		2
--29473		2
--29433		2
--NULL		3
--29483		2
--29466		3

--REMOVE DUPLICATES 
SELECT *
FROM(
SELECT 
*,
ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last 
FROM bronze.crm_cust_info
)t where flag_last = 1

--Check for unwanted Spaces : if the original value is not equal to the same value after trimming it means there are spaces !
--expectation : no result 

SELECT cst_firstname 
from bronze.crm_cust_info
where cst_firstname != TRIM(cst_firstname)

SELECT cst_lastname 
from bronze.crm_cust_info
where cst_lastname != TRIM(cst_lastname)

--remove unwanted spaces 

SELECT 
cst_id ,
cst_key ,
TRIM(cst_firstname) as cst_firstname ,
TRIM(cst_lastname) as cst_lastname ,
cst_marital_status ,
cst_gndr ,
cst_create_date 
FROM(
SELECT 
*,
ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last 
FROM bronze.crm_cust_info
)t where flag_last = 1 and cst_id is not null

--Data Standardization and Consistency 
--Check the consistency of values in low cardinality columns

SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info

--in our data warehouse , 
--we aim to store clear and meaningful values rather than using abbreviated terms 
--&
--IN our data warehouse , i use the default value n/a for missing values 
SELECT 
cst_id ,
cst_key ,
TRIM(cst_firstname) as cst_firstname ,
TRIM(cst_lastname) as cst_lastname ,
 
CASE WHEN UPPER(TRIM(cst_marital_status)) = 'M' then 'MARRIED'
     WHEN UPPER(TRIM(cst_marital_status)) = 'S' then 'SINGLE' 
     ELSE 'n/a'
     END AS cst_marital_status,

CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' then 'FEMALE'
     WHEN UPPER(TRIM(cst_gndr)) = 'M' then 'MALE' 
     ELSE 'n/a'
     END AS cst_gndr ,

cst_create_date 
FROM(
SELECT 
*,
ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last 
FROM bronze.crm_cust_info
)t where flag_last = 1 and cst_id is not null
---------------------------------------------------------------------------------

--========================
PRINT('BUILD SILVER LAYER ->silver.crm_cust_info')
--========================
TRUNCATE TABLE silver.crm_cust_info ;
--Now insertion IN SILVER LAYER 

INSERT INTO silver.crm_cust_info(
cst_id ,
cst_key,
cst_firstname,
cst_lastname,
cst_marital_status,
cst_gndr,
cst_create_date
)
SELECT 
cst_id ,
cst_key ,
TRIM(cst_firstname) as cst_firstname ,
TRIM(cst_lastname) as cst_lastname ,
 
CASE WHEN UPPER(TRIM(cst_marital_status)) = 'M' then 'MARRIED'
     WHEN UPPER(TRIM(cst_marital_status)) = 'S' then 'SINGLE' 
     ELSE 'n/a'
     END AS cst_marital_status,

CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' then 'FEMALE'
     WHEN UPPER(TRIM(cst_gndr)) = 'M' then 'MALE' 
     ELSE 'n/a'
     END AS cst_gndr ,

cst_create_date 
FROM(
SELECT 
*,
ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last          
FROM bronze.crm_cust_info                                                                  
)t where flag_last = 1 and cst_id is not null                                              
----------------------------------------------------------------------------------------------

--===================================
--bronze.crm_prd_info.csv table 
--===================================

SELECT 
prd_id ,
prd_key,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
FROM bronze.crm_prd_info

--Check for Nulls or Duplicates IN primary Key 
--Expectation : no result 

SELECT 
prd_id ,
COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) >1 OR  
prd_id is null 
------------------------------------
SELECT 
prd_id ,
prd_key,
SUBSTRING(prd_key , 1 , 5) as cat_id ,
SUBSTRING(prd_key , 7 , LEN(prd_key)) as prd_key , 
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
FROM bronze.crm_prd_info
------------------------------------
SELECT DISTINCT id from bronze.erp_px_cat_g1v2
------------------------------------
--erp->id->>>>CO_RF
--crm->cat_id->>>CO-RF
------------------------------------
SELECT sls_prd_key from bronze.crm_sales_details
------------------------------------
--Replace '-' with'_' 
SELECT 
prd_id ,
prd_key,
REPLACE(SUBSTRING(prd_key , 1 , 5), '-' , '_') as cat_id ,
SUBSTRING(prd_key , 7 , LEN(prd_key)) as prd_key ,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
FROM bronze.crm_prd_info
----------------------------------------
--Check for unwanted spaces 
SELECT prd_nm
from bronze.crm_prd_info
where prd_nm != TRIM(prd_nm)
---------------------------------------
--Check null or negative numbers 
SELECT 
prd_cost
FROM bronze.crm_prd_info
where prd_cost <0 or prd_cost is null

-------------------------------------
--fixing nulls 

SELECT 
prd_id ,
prd_key,
REPLACE(SUBSTRING(prd_key , 1 , 5), '-' , '_') as cat_id ,
SUBSTRING(prd_key , 7 , LEN(prd_key)) as prd_key ,
prd_nm,
ISNULL(prd_cost,0) AS prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
FROM bronze.crm_prd_info

----------------------------------------
--Data Standardization and consistency 

SELECT DISTINCT prd_line
from bronze.crm_prd_info
----------------------------------------

SELECT 
prd_id ,
prd_key,
REPLACE(SUBSTRING(prd_key , 1 , 5), '-' , '_') as cat_id ,
SUBSTRING(prd_key , 7 , LEN(prd_key)) as prd_key ,
prd_nm,
ISNULL(prd_cost,0) AS prd_cost,
CASE UPPER(TRIM(prd_line)) 
     WHEN'M' THEN 'Mountain'
     WHEN 'R'  then 'Road'
     WHEN 'S' then 'other sales'
     WHEN 'T' then 'Touring'
     else 'n/a'
     end as  prd_line,
prd_start_dt,
prd_end_dt
FROM bronze.crm_prd_info
-----------------------------------------------------

--Check for invalid date orders 
SELECT 
prd_start_dt,
prd_end_dt
FROM bronze.crm_prd_info 
WHERE prd_end_dt < prd_start_dt
--end date must not be earlier than the start date 
----------------------------------------------------
SELECT 
prd_id ,
prd_key,
REPLACE(SUBSTRING(prd_key , 1 , 5), '-' , '_') as cat_id ,
SUBSTRING(prd_key , 7 , LEN(prd_key)) as prd_key ,
prd_nm,
ISNULL(prd_cost,0) AS prd_cost,
CASE UPPER(TRIM(prd_line)) 
     WHEN'M' THEN 'Mountain'
     WHEN 'R'  then 'Road'
     WHEN 'S' then 'other sales'
     WHEN 'T' then 'Touring'
     else 'n/a'
     end as  prd_line,
CAST(prd_start_dt AS DATE) AS prd_start_dt ,
CAST(LEAD(prd_start_dt ) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS  prd_end_dt
FROM bronze.crm_prd_info

-----------------------------------------------------
--========================
PRINT('BUILD SILVER LAYER -> silver.crm_prd_info')
--========================
TRUNCATE TABLE silver.crm_prd_info ;
--INSERTION IN SILVER LAYER 

INSERT INTO silver.crm_prd_info (
prd_id ,
cat_id ,
prd_key ,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt 
)
SELECT
prd_id 
prd_key,
REPLACE(SUBSTRING(prd_key , 1 , 5), '-' , '_') as cat_id , --extract category id 
SUBSTRING(prd_key , 7 , LEN(prd_key)) as prd_key ,         --extract product  id
prd_nm,
ISNULL(prd_cost,0) AS prd_cost,
CASE UPPER(TRIM(prd_line)) 
         WHEN'M' THEN 'Mountain'
         WHEN 'R'  then 'Road'
         WHEN 'S' then 'other sales'
         WHEN 'T' then 'Touring'
         else 'n/a'
     end as  prd_line, --map product line codes to descriptive values 
CAST(prd_start_dt AS DATE) AS prd_start_dt ,
CAST(LEAD(prd_start_dt ) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)-1
AS DATE )
AS  prd_end_dt --cal end date as one day before the next start date
FROM bronze.crm_prd_info
--------------------------------------------------------------------------------------------------------

--===================================
--bronze.crm_sales_details.csv table 
--===================================

SELECT
 sls_ord_num  ,
    sls_prd_key,
    sls_cust_id  ,
    sls_order_dt ,
    sls_ship_dt  ,
    sls_due_dt   ,
    sls_sales    ,
    sls_quantity ,
    sls_price    
    FROM bronze.crm_sales_details
    -------------------------------------------------------------
    --there is no issue in  sls_ord_num
    SELECT
 sls_ord_num  ,
    sls_prd_key,
    sls_cust_id  ,
    sls_order_dt ,
    sls_ship_dt  ,
    sls_due_dt   ,
    sls_sales    ,
    sls_quantity ,
    sls_price    
    FROM bronze.crm_sales_details
    where sls_ord_num != trim(sls_ord_num) --check unwanted spaces
---------------------------------------------
    --there is no issue in prd_key
        SELECT
 sls_ord_num  ,
    sls_prd_key,
    sls_cust_id  ,
    sls_order_dt ,
    sls_ship_dt  ,
    sls_due_dt   ,
    sls_sales    ,
    sls_quantity ,
    sls_price    
    FROM bronze.crm_sales_details
   WHERE sls_prd_key not in (select prd_key from silver.crm_prd_info)
-------------------------------------------
   --there is no issue in sls_cust_id
   SELECT
 sls_ord_num  ,
    sls_prd_key,
    sls_cust_id  ,
    sls_order_dt ,
    sls_ship_dt  ,
    sls_due_dt   ,
    sls_sales    ,
    sls_quantity ,
    sls_price    
    FROM bronze.crm_sales_details
   WHERE sls_cust_id not in (select cst_id from silver.crm_cust_info)
------------------------------------------

--check for invallid dates 
SELECT 
sls_order_dt 
FROM bronze.crm_sales_details 
--WHERE sls_order_dt < 0 there is no negative dates
where sls_order_dt <= 0 --negative n. or zeroes cant be cast to a date
OR LEN(sls_order_dt) != 8 
OR sls_order_dt> 20500101
OR sls_order_dt< 19000101

SELECT 
sls_ship_dt 
FROM bronze.crm_sales_details 
--WHERE sls_ship_dt < 0 there is no negative dates
where sls_ship_dt <= 0 --negative n. or zeroes cant be cast to a date
OR LEN(sls_ship_dt) != 8 
OR sls_ship_dt> 20500101
OR sls_ship_dt <19000101

-------------------------------------------------
--order date must always be earlier than the shipping date or due date
--it must be like sls_order_dt < sls_ship_dt 0r sls_order_dt < sls_due_dt
SELECT * FROM bronze.crm_sales_details
where sls_order_dt >sls_due_dt or  --check 
sls_order_dt > sls_ship_dt  --check 
--so there is no quality issue 

------------------------------------------------------

  SELECT
 sls_ord_num  ,
    sls_prd_key,
    sls_cust_id  ,
    CASE WHEN sls_order_dt = 0 or LEN(sls_order_dt) !=8 then null
         else CAST(CAST(sls_order_dt AS VARCHAR ) AS DATE)
         END sls_order_dt,
CASE WHEN sls_ship_dt   = 0 or LEN(sls_ship_dt  ) !=8 then null
         else CAST(CAST(sls_ship_dt   AS VARCHAR ) AS DATE)
         END sls_ship_dt  ,
    CASE WHEN  sls_due_dt    = 0 or LEN( sls_due_dt  ) !=8 then null
         else CAST(CAST( sls_due_dt   AS VARCHAR ) AS DATE)
         END  sls_due_dt   ,
    sls_sales    ,
    sls_quantity ,
    sls_price    
    FROM bronze.crm_sales_details

---------------------------------------------------
--BUSINESS RULES 
--sum(sales) = quantity * price 
-- X negative , zeroes , nulls are not allowed 

--check data consistency : btw sales , quantity and price 
--expectation : no result
SELECT distinct
sls_sales,
sls_quantity,
sls_price
FROM bronze.crm_sales_details
where sls_sales != sls_quantity * sls_price
or sls_sales is null or sls_quantity is null or sls_price is null
or sls_sales <= 0  or sls_quantity <= 0 or sls_price <=0
order by sls_sales,
sls_quantity,
sls_price
--result : nulls , -ve no, zeroes all are present we have to remove this 
       --: calculation is also wrong or may be price is wrong
       
--sol1-> data issues will be fixed directly in source system
--sol2-> data issues has to be fixed in data warehouse

-- if sales is -ve , 0 or null , derive it using quantity and price
-- if price is 0 or null , cal it using sales anad quantity
--if price is negative , convert it to a positive value

SELECT distinct 
sls_sales [old  sales value],
sls_quantity,
sls_price [old price value] ,
CASE WHEN sls_sales is null or sls_sales <= 0 or sls_sales != sls_quantity * ABS(sls_price)
     then sls_quantity * ABS(sls_price)
     else sls_sales
     end as sls_sales ,
CASE WHEN sls_price is null or sls_price <=0 
     then sls_sales / NULLIF(sls_quantity , 0 )
     else sls_price 
     end as sls_price

FROM bronze.crm_sales_details
where sls_sales != sls_quantity * sls_price
or sls_sales is null or sls_quantity is null or sls_price is null
or sls_sales <= 0  or sls_quantity <= 0 or sls_price <=0
order by sls_sales,
sls_quantity,
sls_price

---------------------------------------------------------------------
 SELECT
    sls_ord_num  ,
    sls_prd_key,
    sls_cust_id  ,
 CASE WHEN sls_order_dt = 0 or LEN(sls_order_dt) !=8 then null
         else CAST(CAST(sls_order_dt AS VARCHAR ) AS DATE)
         END sls_order_dt,
 CASE WHEN sls_ship_dt   = 0 or LEN(sls_ship_dt  ) !=8 then null
         else CAST(CAST(sls_ship_dt   AS VARCHAR ) AS DATE)
         END sls_ship_dt  ,
 CASE WHEN  sls_due_dt    = 0 or LEN( sls_due_dt  ) !=8 then null
         else CAST(CAST( sls_due_dt   AS VARCHAR ) AS DATE)
         END  sls_due_dt   ,
 CASE WHEN sls_sales is null or sls_sales <= 0 or sls_sales != sls_quantity * ABS(sls_price)
      then sls_quantity * ABS(sls_price)
      else sls_sales
      end as sls_sales ,
    sls_quantity ,
 CASE WHEN sls_price is null or sls_price <=0 
      then sls_sales / NULLIF(sls_quantity , 0 )
      else sls_price 
      end as sls_price   
 FROM bronze.crm_sales_details
 ----------------------------------------------------------------
 --========================
PRINT('BUILD SILVER LAYER -> silver.crm_sales_details')
--========================
 truncate table silver.crm_sales_details ;
--Now insertion IN SILVER LAYER 

INSERT INTO silver.crm_sales_details
(
sls_ord_num ,
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
 sls_ord_num  ,
 sls_prd_key,
 sls_cust_id  ,

 CASE WHEN sls_order_dt = 0 or LEN(sls_order_dt) !=8 then null
         else CAST(CAST(sls_order_dt AS VARCHAR ) AS DATE)
  END sls_order_dt,

 CASE WHEN sls_ship_dt   = 0 or LEN(sls_ship_dt  ) !=8 then null
         else CAST(CAST(sls_ship_dt   AS VARCHAR ) AS DATE)
 END sls_ship_dt  ,

 CASE WHEN  sls_due_dt    = 0 or LEN( sls_due_dt  ) !=8 then null
         else CAST(CAST( sls_due_dt   AS VARCHAR ) AS DATE)
  END  sls_due_dt   ,

 CASE WHEN sls_sales is null or sls_sales <= 0 or sls_sales != sls_quantity * ABS(sls_price)
      then sls_quantity * ABS(sls_price)
      else sls_sales
 end as sls_sales , --recalculate sales if original value is missing or incorrect

 sls_quantity ,

 CASE WHEN sls_price is null or sls_price <=0 
      then sls_sales / NULLIF(sls_quantity , 0 )
      else sls_price 
 end as sls_price   -- derive price if orignal value is invalid
 
 FROM bronze.crm_sales_details
 -------------------------------------------------------------------------------------------

 --===================================
--bronze.erp_cust_az12 table 
--===================================

SELECT 
cid , -- we dont need 'NAS' because in silver.crm_cust_info cst_id is like 11000 , 11001 etc so we have to remove it 
bdate ,
gen
from bronze.erp_cust_az12
--
SELECT * FROM silver.crm_cust_info
--------------------------------------------------------------
SELECT 
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid , 4 , LEN(cid)) 
     else cid
end cid ,
bdate ,
gen 
from bronze.erp_cust_az12
---------------------------------

--identify out-of-range dates

select distinct 
bdate 
from bronze.erp_cust_az12
where bdate < '1924-01-01'
or bdate > getdate() --check for birthdays in the future
-----------------------------------
SELECT 
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid , 4 , LEN(cid)) 
     else cid
end cid ,

CASE WHEN bdate > getdate() then null 
     else bdate 
end bdate ,

CASE WHEN UPPER(TRIM(gen)) IN ('F' , 'FEMALE') then 'Female'
     WHEN UPPER(TRIM(gen)) IN ('M' , 'MALE') then 'Male'
     else 'n/a'
     end gen
from bronze.erp_cust_az12

----------------------------------------------------------------------

 --========================
PRINT('BUILD SILVER LAYER -> silver.erp_cust_az12')
--========================
 truncate table silver.erp_cust_az12 ;
--Now insertion IN SILVER LAYER 

INSERT INTO silver.erp_cust_az12
(
cid,
bdate ,
gen
)
SELECT
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid , 4 , LEN(cid)) 
     else cid
end cid ,

CASE WHEN bdate  > getdate() then null 
     else bdate
end bdate , -- set future birthdates to null

CASE WHEN UPPER(TRIM(gen)) IN ('F' , 'FEMALE') then 'Female'
     WHEN UPPER(TRIM(gen)) IN ('M' , 'MALE') then 'Male'
     else 'n/a'
     end gen --normalize gender values and handle unknown cases
from bronze.erp_cust_az12

----------------------------------------------------------------------

 --===================================
--bronze.erp_loc_a101 table 
--===================================

select 
cid , cntry 
from 
bronze.erp_loc_a101 
-------------------------
select cst_key from silver.crm_cust_info
--remove '-' in cid
--
select 
REPLACE(cid , '-' , '') , cntry 
from 
bronze.erp_loc_a101 
--------------------------
--Data standardization and Consistency
SELECT DISTINCT 
cntry from bronze.erp_loc_a101
order by cntry
--
select 
REPLACE(cid , '-' , '')  cid,
CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany' 
     when TRIM(cntry) IN ('US' , 'USA') then 'United State' 
     when TRIM(cntry) = '' or cntry is null then 'n/a'
     else trim(cntry)
     end cntry --normalize and handle missing or blank cntry codes
from 
bronze.erp_loc_a101 

------------------------------------------------------------------------
 --========================
PRINT('BUILD SILVER LAYER -> silver.erp_loc_a101')
--========================
truncate table silver.erp_loc_a101;
--Now insertion IN SILVER LAYER 

INSERT INTO silver.erp_loc_a101
(
cid ,
cntry 
)
select 
REPLACE(cid , '-' , '')  cid,
CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany' 
     when TRIM(cntry) IN ('US' , 'USA') then 'United State' 
     when TRIM(cntry) = '' or cntry is null then 'n/a'
     else trim(cntry)
     end cntry --normalize and handle missing or blank cntry codes
from 
bronze.erp_loc_a101 
---------------------------------------------------------------------------------------------- --===================================

--===================================
--bronze.erp_px_cat_g1v2 table 
--===================================

SELECT 
id , 
cat ,
subcat ,
maintenance
FROM bronze.erp_px_cat_g1v2
--------------------------------
--Check for unwanted Spaces 
SELECT 
cat , subcat
FROM bronze.erp_px_cat_g1v2
where cat != trim(cat)  or subcat != trim(subcat) or maintenance != trim(maintenance)
--------------------------------
--Data standardization and Consistency
SELECT DISTINCT 
cat , subcat , maintenance
from bronze.erp_px_cat_g1v2
--everything is in good quality but we have to follow all steps so we can load it into silver layer 


 --========================
PRINT('BUILD SILVER LAYER -> silver.erp_px_cat_g1v2')
--========================

truncate table silver.erp_px_cat_g1v2 ;
--Now insertion IN SILVER LAYER 

INSERT INTO silver.erp_px_cat_g1v2
( id ,cat , subcat , maintenance)
SELECT 
id , 
cat ,
subcat ,
maintenance
FROM bronze.erp_px_cat_g1v2

