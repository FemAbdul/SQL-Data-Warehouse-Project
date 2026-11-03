/*
------------------------------------------------------
---------------------GOLD LAYER-----------------------
------------------------------------------------------
DIMENSION - PRODUCTS
------------------------------------------------------
*/

SELECT * FROM Silver.crm_prd_info;
SELECT * FROM Silver.erp_px_cat_g1v2;

--Filter out all historical data
SELECT cr.prd_id,
	cr.cat_id,
	cr.prd_key,
	cr.prd_nm,
	cr.prd_cost,
	cr.prd_line,
	cr.prd_start_dt
FROM Silver.crm_prd_info cr
WHERE cr.prd_end_dt IS NULL;


SELECT cr.prd_id,
	cr.cat_id,
	cr.prd_key,
	cr.prd_nm,
	cr.prd_cost,
	cr.prd_line,
	cr.prd_start_dt,
	er.cat,
	er.subcat,
	er.maintenance
FROM Silver.crm_prd_info cr
LEFT JOIN Silver.erp_px_cat_g1v2 er
ON cr.cat_id = er.id
WHERE cr.prd_end_dt IS NULL;

--Check the uniqueness
SELECT prd_key, COUNT(*)
FROM(
	SELECT 
		cr.prd_id,
		cr.cat_id,
		cr.prd_key,
		cr.prd_nm,
		cr.prd_cost,
		cr.prd_line,
		cr.prd_start_dt,
		er.cat,
		er.subcat,
		er.maintenance
	FROM Silver.crm_prd_info cr
	LEFT JOIN Silver.erp_px_cat_g1v2 er
	ON cr.cat_id = er.id
	WHERE cr.prd_end_dt IS NULL
)T GROUP BY prd_key
HAVING COUNT(*) > 1;

--Group Relevant Information together and giving meaningful names

SELECT cr.prd_id AS product_id,
	cr.prd_key AS product_number,
	cr.prd_nm AS product_name,
	cr.cat_id AS  category_id,
	er.cat AS category,
	er.subcat AS subcategory,
	er.maintenance,
	cr.prd_cost AS product_cost,
	cr.prd_line AS product_line,
	cr.prd_start_dt AS start_date
	
FROM Silver.crm_prd_info cr
LEFT JOIN Silver.erp_px_cat_g1v2 er
ON cr.cat_id = er.id
WHERE cr.prd_end_dt IS NULL;

--Create a surrogate key
SELECT
	ROW_NUMBER() OVER(ORDER BY cr.prd_start_dt, cr.prd_key) AS product_key, 
	cr.prd_id AS product_id,
	cr.prd_key AS product_number,
	cr.prd_nm AS product_name,
	cr.cat_id AS  category_id,
	er.cat AS category,
	er.subcat AS subcategory,
	er.maintenance,
	cr.prd_cost AS product_cost,
	cr.prd_line AS product_line,
	cr.prd_start_dt AS start_date
	
FROM Silver.crm_prd_info cr
LEFT JOIN Silver.erp_px_cat_g1v2 er
ON cr.cat_id = er.id
WHERE cr.prd_end_dt IS NULL;

--Create Gold Layer Object - View: dim_products

CREATE VIEW Gold.dim_products AS
	SELECT
		ROW_NUMBER() OVER(ORDER BY cr.prd_start_dt, cr.prd_key) AS product_key, 
		cr.prd_id AS product_id,
		cr.prd_key AS product_number,
		cr.prd_nm AS product_name,
		cr.cat_id AS  category_id,
		er.cat AS category,
		er.subcat AS subcategory,
		er.maintenance,
		cr.prd_cost AS product_cost,
		cr.prd_line AS product_line,
		cr.prd_start_dt AS start_date
	
	FROM Silver.crm_prd_info cr
	LEFT JOIN Silver.erp_px_cat_g1v2 er
	ON cr.cat_id = er.id
	WHERE cr.prd_end_dt IS NULL;

--DATA QUALITY CHECKS
SELECT * FROM gold.dim_products;