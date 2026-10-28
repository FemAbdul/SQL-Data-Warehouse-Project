use DataWarehouse;

SELECT TOP (1000) * FROM Bronze.crm_prd_info;

--Check for Duplicate ids
SELECT prd_id, COUNT(*) AS Duplicates
FROM Bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 or prd_id IS NULL;

--SPLITTING CAT_ID AND PRD_KEY
	SELECT prd_id,
	REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
	SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
	FROM Bronze.crm_prd_info;

--CHECKING FOR PRD_KEY NOT IN SALES PRD_KEY
SELECT prd_id,
REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key
FROM Bronze.crm_prd_info
WHERE SUBSTRING(prd_key,7,LEN(prd_key)) NOT IN (SELECT DISTINCT(sls_prd_key) FROM BRONZE.crm_sales_details);


SELECT DISTINCT(sls_prd_key) FROM BRONZE.crm_sales_details
WHERE sls_prd_key = 'SO-B909-M'

--CHECK FOR UNWANTED SPACES
SELECT prd_nm
FROM Bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

--PRD_COST CHECK FOR NULLS OR NEGATIVE NUMBERS
SELECT prd_cost
FROM Bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL
--WE HAVE NULL, SO REPLACE IT WITH 0
	SELECT prd_id,
	REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
	SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,
	prd_nm,
	ISNULL(prd_cost,0) AS prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
	FROM Bronze.crm_prd_info;
--Data standardization & Consistency
--PRD_LINE , CARDINALITY  IS LOW
SELECT DISTINCT(prd_line)
FROM Bronze.crm_prd_info
--ASK EXPERT AND FIND THE FULL FORMS
	SELECT prd_id,
	REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
	SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,
	prd_nm,
	ISNULL(prd_cost,0) AS prd_cost,
	CASE WHEN UPPER(prd_line) = 'M' THEN 'Mountain'
		 WHEN UPPER(prd_line) = 'R' THEN 'Road'
		 WHEN UPPER(prd_line) = 'S' THEN 'other Sales'
		 WHEN UPPER(prd_line) = 'T' THEN 'Touring'
		 ELSE 'n/a'
	END AS prd_line,
	prd_start_dt,
	prd_end_dt
	FROM Bronze.crm_prd_info;
--short form
	SELECT prd_id,
	REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
	SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,
	prd_nm,
	ISNULL(prd_cost,0) AS prd_cost,
	CASE UPPER(prd_line) 
		WHEN  'M' THEN 'Mountain'
		 WHEN 'R' THEN 'Road'
		 WHEN 'S' THEN 'other Sales'
		 WHEN 'T' THEN 'Touring'
		 ELSE 'n/a'
	END AS prd_line,
	prd_start_dt,
	prd_end_dt
	FROM Bronze.crm_prd_info;
-------------------------
--CHECK FOR INVALID DATES

--START_DATE SHOULD BE LESS THAN END_DATE
SELECT *
FROM Bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt;
--contains historical data, 
--so end_date of first history should be less than start_date of second history and should not overlap
--inspect for a prduct
SELECT *
FROM Bronze.crm_prd_info
WHERE prd_nm ='Sport-100 Helmet- Red';
--checking for a possible solution
SELECT prd_id,prd_key,prd_nm,prd_cost,
prd_start_dt,
LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) - 1
AS end_date
FROM Bronze.crm_prd_info
WHERE prd_nm ='Sport-100 Helmet- Red';

-------------------------------------------------------------------
--Also remove the time from the date, so cast from DATETIME to DATE

	SELECT prd_id,
	REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
	SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,
	prd_nm,
	ISNULL(prd_cost,0) AS prd_cost,
	CASE UPPER(prd_line) 
		WHEN  'M' THEN 'Mountain'
		 WHEN 'R' THEN 'Road'
		 WHEN 'S' THEN 'other Sales'
		 WHEN 'T' THEN 'Touring'
		 ELSE 'n/a'
	END AS prd_line,
	CAST(prd_start_dt AS DATE) AS prd_start_dt,
	CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE)
	AS prd_end_dt
	FROM Bronze.crm_prd_info;


-------------------------------------------------------------------------
--ALTER TABLE DEFINITION TO ADD NEW CHANGES
ALTER TABLE Silver.crm_prd_info
ADD cat_id NVARCHAR(50);

ALTER TABLE Silver.crm_prd_info
ALTER COLUMN prd_start_dt DATE;

ALTER TABLE Silver.crm_prd_info
ALTER COLUMN prd_end_dt DATE;

--------------------------------------------------------------
--INSERT DATA TO SILVER LAYER
--------------------------------------------------------------

INSERT INTO Silver.crm_prd_info(
prd_id,
cat_id,
prd_key,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
)
	SELECT prd_id,
	REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
	SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,
	prd_nm,
	ISNULL(prd_cost,0) AS prd_cost,
	CASE UPPER(TRIM(prd_line)) 
		WHEN  'M' THEN 'Mountain'
		 WHEN 'R' THEN 'Road'
		 WHEN 'S' THEN 'other Sales'
		 WHEN 'T' THEN 'Touring'
		 ELSE 'n/a'
	END AS prd_line,
	CAST(prd_start_dt AS DATE) AS prd_start_dt,
	CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE)
	AS prd_end_dt
	FROM Bronze.crm_prd_info;

--------------------------------------------------------------
--DATA QUALITY CHECK
--------------------------------------------------------------

SELECT prd_id, COUNT(*) AS Duplicates
FROM Silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 or prd_id IS NULL;

--CHECK FOR UNWANTED SPACES
SELECT prd_nm
FROM Silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

--PRD_COST CHECK FOR NULLS OR NEGATIVE NUMBERS
SELECT prd_cost
FROM Silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL

--Data standardization & Consistency

SELECT DISTINCT(prd_line)
FROM Silver.crm_prd_info

--CHECK FOR INVALID DATES
SELECT *
FROM Silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;
--
SELECT * FROM Silver.crm_prd_info;