SELECT TOP (1000) [id]
      ,[cat]
      ,[subcat]
      ,[maintenance]
  FROM [DataWarehouse].[Bronze].[erp_px_cat_g1v2]

SELECT  cat_id FROM Silver.crm_prd_info 
   
--CHECK FOR UNWANTED SPACES
SELECT *
FROM Bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat)
    OR subcat != TRIM(subcat)
    OR maintenance != TRIM(maintenance)

--DATA STANDARDIZATION & CARDINALITY
SELECT DISTINCT(cat)
FROM Bronze.erp_px_cat_g1v2

SELECT DISTINCT(subcat)
FROM Bronze.erp_px_cat_g1v2

SELECT DISTINCT(maintenance)
FROM Bronze.erp_px_cat_g1v2

-------------------------------------------------
--INSERT INTO SILVER LAYER
-------------------------------------------------

INSERT INTO Silver.erp_px_cat_g1v2(
    id,
    cat,
    subcat,
    maintenance)
SELECT * FROM Bronze.erp_px_cat_g1v2


--Verify
SELECT * FROM Silver.erp_px_cat_g1v2