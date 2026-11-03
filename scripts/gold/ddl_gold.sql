/*
------------------------------------------------------------------------------
---------------------GOLD LAYER-----------------------
------------------------------------------------------------------------------
DDL SCRIPT : Create Gold Views

Purpose:
	This script creates Views for the Gold Layer in the data warehouse.
	Each View performs transformations and combines data from the Silver layer
	to produce a clean, enriched and business- ready dataset.

------------------------------------------------------------------------------
*/
------------------------------------------------------------------------------
-- Dimension : gold.dim_customers
------------------------------------------------------------------------------
IF OBJECT_ID('gold.dim_customers','V') IS NOT NULL
	DROP VIEW gold.dim_customers;
GO
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

GO
------------------------------------------------------------------------------
-- Dimension : gold.dim_products
------------------------------------------------------------------------------
IF OBJECT_ID('gold.dim_products','V') IS NOT NULL
	DROP VIEW gold.dim_products;

GO

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

GO
------------------------------------------------------------------------------
-- Fact : gold.fact_sales
------------------------------------------------------------------------------
IF OBJECT_ID('gold.fact_sales','V') IS NOT NULL
	DROP VIEW gold.fact_sales;
GO

CREATE VIEW Gold.fact_sales AS
	SELECT
		sls.sls_ord_num AS order_number,
		pr.product_key,
		cs.customer_key,
		sls.sls_order_dt AS order_date,
		sls.sls_ship_dt AS shipping_date,
		sls.sls_due_dt AS due_date,
		sls.sls_sales AS sales_amount,
		sls.sls_quantity AS sales_quantity,
		sls.sls_price AS sales_price
	FROM Silver.crm_sales_details sls
	LEFT JOIN Gold.dim_products pr
	ON sls.sls_prd_key = pr.product_number
	LEFT JOIN Gold.dim_customers cs
	ON sls.sls_cust_id = cs.customer_id;