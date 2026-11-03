SELECT TOP (1000) [cid]
      ,[cntry]
  FROM [DataWarehouse].[Bronze].[erp_loc_a101]

SELECT * FROM Silver.crm_cst_info;

SELECT 
REPLACE(cid,'-','') 
FROM Bronze.erp_loc_a101
WHERE REPLACE(cid,'-','') NOT IN (SELECT DISTINCT(cst_key) FROM Silver.crm_cst_info);

--Country
SELECT DISTINCT(cntry)
FROM Bronze.erp_loc_a101

SELECT distinct
CASE WHEN UPPER(TRIM(cntry)) IN ('USA','US','UNITED STATES') THEN 'United States'
     WHEN UPPER(TRIM(cntry)) IN ('DE') THEN 'Germany'
     WHEN cntry IS NULL OR cntry='' THEN 'n/a'
     ELSE cntry
END AS cntry
FROM
Bronze.erp_loc_a101


SELECT 
REPLACE(cid,'-','') AS cid,
CASE WHEN UPPER(TRIM(cntry)) IN ('USA','US','UNITED STATES') THEN 'United States'
     WHEN UPPER(TRIM(cntry)) IN ('DE') THEN 'Germany'
     WHEN cntry IS NULL OR cntry='' THEN 'n/a'
     ELSE cntry
END AS cntry
FROM
Bronze.erp_loc_a101

-------------------------------------------------
--INSERT INTO SILVER LAYER
-------------------------------------------------

INSERT INTO Silver.erp_loc_a101(
    cid,
    cntry)
SELECT 
REPLACE(cid,'-','') AS cid,
CASE WHEN UPPER(TRIM(cntry)) IN ('USA','US','UNITED STATES') THEN 'United States'
     WHEN UPPER(TRIM(cntry)) IN ('DE') THEN 'Germany'
     WHEN cntry IS NULL OR cntry='' THEN 'n/a'
     ELSE cntry
END AS cntry
FROM
Bronze.erp_loc_a101

--Verify
SELECT * FROM Silver.erp_loc_a101

--DATA QUALITY CHECKS
SELECT DISTINCT(cntry)
FROM Silver.erp_loc_a101

SELECT 
cid
FROM Silver.erp_loc_a101
WHERE cid NOT IN (SELECT DISTINCT(cst_key) FROM Silver.crm_cst_info);
