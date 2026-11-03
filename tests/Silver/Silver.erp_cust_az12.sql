SELECT TOP (1000) [cid]
      ,[bdate]
      ,[gen]
  FROM [DataWarehouse].[Bronze].[erp_cust_az12]


SELECT * FROM Silver.crm_cst_info;

SELECT cid, bdate, gen
FROM Bronze.erp_cust_az12
WHERE cid LIKE '%AW00011000%';

SELECT cid, 
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
    ELSE cid
END AS cid,
bdate, gen
FROM Bronze.erp_cust_az12;

--Check invalid dates
SELECT bdate
FROM Bronze.erp_cust_az12
WHERE bdate > GETDATE();

SELECT cid, 
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
    ELSE cid
END AS cid,
CASE WHEN bdate > GETDATE() THEN NULL
    ELSE bdate
END AS bdate,
gen
FROM Bronze.erp_cust_az12;

-- Data Standardization 
SELECT DISTINCT(gen)
FROM Bronze.erp_cust_az12;

SELECT
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
    ELSE cid
END AS cid,
CASE WHEN bdate > GETDATE() THEN NULL
    ELSE bdate
END AS bdate,
CASE WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
     WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
     ELSE 'n/a'
END AS gen
FROM Bronze.erp_cust_az12;

---------------------------------------------------------
--INSERT INTO SILVER LAYER
---------------------------------------------------------
INSERT INTO Silver.erp_cust_az12(
    cid,
    bdate,
    gen
)
SELECT
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
    ELSE cid
END AS cid,
CASE WHEN bdate > GETDATE() THEN NULL
    ELSE bdate
END AS bdate,
CASE WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
     WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
     ELSE 'n/a'
END AS gen
FROM Bronze.erp_cust_az12;

--VERIFY
SELECT * FROM Silver.erp_cust_az12;

--DATA QUALITY CHECK
SELECT cid
FROM Silver.erp_cust_az12
WHERE cid NOT IN (SELECT DISTINCT(cst_key) FROM Silver.crm_cst_info)

SELECT bdate
FROM Silver.erp_cust_az12
WHERE bdate > GETDATE();

SELECT DISTINCT(gen)
FROM Silver.erp_cust_az12;
