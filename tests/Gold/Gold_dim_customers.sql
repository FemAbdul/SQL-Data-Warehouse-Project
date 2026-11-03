/*
------------------------------------------------------
---------------------GOLD LAYER-----------------------
------------------------------------------------------
DIMENSION - CUSTOMERS
------------------------------------------------------
*/
SELECT crm.cst_id,
      crm.cst_key,
      crm.cst_firstname,
      crm.cst_lastname,
      crm.cst_maritalstatus,
      crm.cst_gndr,
      crm.cst_create_date,
      er1.bdate,
      er1.gen,
      lc.cntry
FROM Silver.crm_cst_info crm
LEFT JOIN Silver.erp_cust_az12 er1 
ON crm.cst_key = er1.cid
LEFT JOIN Silver.erp_loc_a101 lc
ON crm.cst_key = lc.cid;

--After joining check for NULLS OR DUPLICATES

SELECT cst_id, count(*)
FROM
(
    SELECT crm.cst_id,
      crm.cst_key,
      crm.cst_firstname,
      crm.cst_lastname,
      crm.cst_maritalstatus,
      crm.cst_gndr,
      crm.cst_create_date,
      er1.bdate,
      er1.gen,
      lc.cntry
    FROM Silver.crm_cst_info crm
    LEFT JOIN Silver.erp_cust_az12 er1 
    ON crm.cst_key = er1.cid
    LEFT JOIN Silver.erp_loc_a101 lc
    ON crm.cst_key = lc.cid
    
) T GROUP BY cst_id
HAVING COUNT(*) > 1


--CHECK FOR MISMATCH IN GENDER FROM BOTH TABLES
USE DataWarehouse;
SELECT DISTINCT
    crm.cst_gndr,
    er1.gen
    FROM Silver.crm_cst_info crm
    LEFT JOIN Silver.erp_cust_az12 er1 
    ON crm.cst_key = er1.cid
    LEFT JOIN Silver.erp_loc_a101 lc
    ON crm.cst_key = lc.cid

--Data Integration
SELECT DISTINCT
    crm.cst_gndr,
    er1.gen,
    CASE WHEN crm.cst_gndr != 'n/a' THEN crm.cst_gndr
        ELSE COALESCE(er1.gen,'n/a')
    END AS new_gen
FROM Silver.crm_cst_info crm
LEFT JOIN Silver.erp_cust_az12 er1
ON crm.cst_key = er1.cid
LEFT JOIN Silver.erp_loc_a101 lc
    ON crm.cst_key = lc.cid


SELECT crm.cst_id,
      crm.cst_key,
      crm.cst_firstname,
      crm.cst_lastname,
      crm.cst_maritalstatus,
      CASE WHEN crm.cst_gndr != 'n/a' THEN crm.cst_gndr
        ELSE COALESCE(er1.gen,'n/a')
      END AS new_gen,
      crm.cst_create_date,
      er1.bdate,
      lc.cntry
FROM Silver.crm_cst_info crm
LEFT JOIN Silver.erp_cust_az12 er1 
ON crm.cst_key = er1.cid
LEFT JOIN Silver.erp_loc_a101 lc
ON crm.cst_key = lc.cid;


--Use Friendly Names
SELECT crm.cst_id AS customer_id,
      crm.cst_key AS customer_number,
      crm.cst_firstname AS first_name,
      crm.cst_lastname AS last_name,
      lc.cntry AS country,
      crm.cst_maritalstatus AS marital_status,
      CASE WHEN crm.cst_gndr != 'n/a' THEN crm.cst_gndr
        ELSE COALESCE(er1.gen,'n/a')
      END AS gender,
      er1.bdate AS birthdate,
      crm.cst_create_date AS createt_date    
FROM Silver.crm_cst_info crm
LEFT JOIN Silver.erp_cust_az12 er1 
ON crm.cst_key = er1.cid
LEFT JOIN Silver.erp_loc_a101 lc
ON crm.cst_key = lc.cid;

--Surrogate Key
SELECT 
      ROW_NUMBER() OVER (ORDER BY crm.cst_id) AS customer_key,
      crm.cst_id AS customer_id,
      crm.cst_key AS customer_number,
      crm.cst_firstname AS first_name,
      crm.cst_lastname AS last_name,
      lc.cntry AS country,
      crm.cst_maritalstatus AS marital_status,
      CASE WHEN crm.cst_gndr != 'n/a' THEN crm.cst_gndr
        ELSE COALESCE(er1.gen,'n/a')
      END AS gender,
      er1.bdate AS birthdate,
      crm.cst_create_date AS createt_date    
FROM Silver.crm_cst_info crm
LEFT JOIN Silver.erp_cust_az12 er1 
ON crm.cst_key = er1.cid
LEFT JOIN Silver.erp_loc_a101 lc
ON crm.cst_key = lc.cid;

--Create Objects for the Gold Layer - View
CREATE VIEW Gold.dim_customers AS
SELECT 
      ROW_NUMBER() OVER (ORDER BY crm.cst_id) AS customer_key,
      crm.cst_id AS customer_id,
      crm.cst_key AS customer_number,
      crm.cst_firstname AS first_name,
      crm.cst_lastname AS last_name,
      lc.cntry AS country,
      crm.cst_maritalstatus AS marital_status,
      CASE WHEN crm.cst_gndr != 'n/a' THEN crm.cst_gndr
        ELSE COALESCE(er1.gen,'n/a')
      END AS gender,
      er1.bdate AS birthdate,
      crm.cst_create_date AS createt_date    
FROM Silver.crm_cst_info crm
LEFT JOIN Silver.erp_cust_az12 er1 
ON crm.cst_key = er1.cid
LEFT JOIN Silver.erp_loc_a101 lc
ON crm.cst_key = lc.cid;

--DATA QUALITY CHECKS
SELECT * FROM gold.dim_customers;
SELECT DISTINCT gender FROM gold.dim_customers;