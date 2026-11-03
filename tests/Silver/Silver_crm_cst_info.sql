SELECT TOP (1000) * FROM Bronze.crm_cst_info;

--To find duplicates in primary key
SELECT cst_id, COUNT(*) 
FROM Bronze.crm_cst_info
GROUP BY cst_id
HAVING COUNT(*) > 1;

--Analyse the duplicate rows to find the best one to maintain
SELECT *
FROM Bronze.crm_cst_info
WHERE cst_id = 29483;

--Select the row with the highest date
SELECT * FROM
(
SELECT *,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_l
FROM Bronze.crm_cst_info) F
WHERE flag_l = 1;

--
WITH rem_id_dup_cte as
(SELECT *,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_l
FROM Bronze.crm_cst_info
)
SELECT * FROM rem_id_dup_cte
WHERE flag_l = 1;

----DATA CLEANING--------
--Check the text values if they contain unwanted spaces
SELECT cst_firstname
FROM Bronze.crm_cst_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT cst_lastname
FROM Bronze.crm_cst_info
WHERE cst_lastname != TRIM(cst_lastname);


WITH rem_id_dup_cte as
(SELECT *,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_l
FROM Bronze.crm_cst_info
)
SELECT cst_id, 
	   cst_key,
	   TRIM(cst_firstname) AS cst_firstname,
	   TRIM(cst_lastname) AS cst_lastname,
	   cst_maritalstatus,
	   cst_gndr,
	   cst_create_date
FROM rem_id_dup_cte
WHERE flag_l = 1;

/* ----------Data Normalisation/ Data Standardisation-----------------
cst_maritalstatus are abbreviations, instead store meaningful values*/
USE DataWarehouse;
WITH rem_id_dup_cte as
(SELECT *,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_l
FROM Bronze.crm_cst_info
WHERE cst_id IS NOT NULL
)
SELECT cst_id, 
	   cst_key,
	   TRIM(cst_firstname) AS cst_firstname,
	   TRIM(cst_lastname) AS cst_lastname,
		CASE WHEN UPPER(cst_maritalstatus) = 'M' THEN 'Married'
			 WHEN UPPER(cst_maritalstatus) = 's' THEN 'Single'
			 ELSE 'n/a'
		END cst_maritalstatus,
	   cst_gndr,
	   cst_create_date
FROM rem_id_dup_cte
WHERE flag_l = 1;

--DO THE SAME STANDARDISATION FOR cst_gndr
WITH rem_id_dup_cte as
(SELECT *,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_l
FROM Bronze.crm_cst_info
WHERE cst_id IS NOT NULL
)
SELECT cst_id, 
	   cst_key,
	   TRIM(cst_firstname) AS cst_firstname,
	   TRIM(cst_lastname) AS cst_lastname,
		CASE WHEN UPPER(cst_maritalstatus) = 'M' THEN 'Married'
			 WHEN UPPER(cst_maritalstatus) = 'S' THEN 'Single'
			 ELSE 'n/a'
		END cst_maritalstatus,
		CASE WHEN UPPER(cst_gndr) = 'M' THEN 'Male'
			 WHEN UPPER(cst_gndr) = 'F' THEN 'Female'
			 ELSE 'n/a'
		END cst_gndr,
	   cst_create_date
FROM rem_id_dup_cte
WHERE flag_l = 1;

-----------------------------------------------------------------------------
/*INSERT THIS CLEANED DATA TO SILVER LAYER*/
-----------------------------------------------------------------------------

TRUNCATE  TABLE Silver.crm_cst_info;
WITH rem_id_dup_cte as
(SELECT *,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_l
FROM Bronze.crm_cst_info
WHERE cst_id IS NOT NULL
)
INSERT INTO Silver.crm_cst_info(
cst_id,
cst_key,
cst_firstname,
cst_lastname,
cst_maritalstatus,
cst_gndr,
cst_create_date)

SELECT cst_id, 
	   cst_key,
	   TRIM(cst_firstname) AS cst_firstname,
	   TRIM(cst_lastname) AS cst_lastname,
		CASE WHEN UPPER(cst_maritalstatus) = 'M' THEN 'Married'
			 WHEN UPPER(cst_maritalstatus) = 'S' THEN 'Single'
			 ELSE 'n/a'
		END AS cst_maritalstatus,
		CASE WHEN UPPER(cst_gndr) = 'M' THEN 'Male'
			 WHEN UPPER(cst_gndr) = 'F' THEN 'Female'
			 ELSE 'n/a'
		END AS cst_gndr,
	   cst_create_date
FROM rem_id_dup_cte
WHERE flag_l = 1;

/*----------------DATA QUALITY CHECK OF SILVER LAYER------------------*/

--To find duplicates in primary key
SELECT cst_id, COUNT(*) 
FROM Silver.crm_cst_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

SELECT cst_firstname
FROM Silver.crm_cst_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT cst_firstname
FROM Silver.crm_cst_info
WHERE cst_lastname != TRIM(cst_lastname);