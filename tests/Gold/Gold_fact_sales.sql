/*
------------------------------------------------------
---------------------GOLD LAYER-----------------------
------------------------------------------------------
FACT - SALES
------------------------------------------------------
*/

SELECT
	sls.sls_ord_num,
	sls.sls_prd_key,
	sls.sls_cust_id,
	sls.sls_order_dt,
	sls.sls_ship_dt,
	sls.sls_due_dt,
	sls.sls_sales,
	sls.sls_quantity,
	sls.sls_price
FROM Silver.crm_sales_details sls;

--Data Lookup - Derive the surrogate keys from other tables

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

--Create Gold Layer Object - View: Gold.fact_sales

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

--DATA QUALITY CHECKS

SELECT * FROM Gold.fact_sales;

--Check if all Dimension tables can successfully join to the fact table

SELECT * 
FROM Gold.fact_sales fs
LEFT JOIN Gold.dim_customers cu
ON fs.customer_key = cu.customer_key
WHERE CU.customer_key IS NULL;

SELECT * 
FROM Gold.fact_sales fs
LEFT JOIN Gold.dim_products pr
ON fs.product_key = pr.product_key
WHERE pr.product_key IS NULL;