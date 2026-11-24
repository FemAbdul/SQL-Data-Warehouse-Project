/*
----------------------------------------------------------------------------------------------------
---------------------------------PRODUCT REPORT-----------------------------------------------------
----------------------------------------------------------------------------------------------------
Purpose:
		This report consolidates key product metrics and behaviors

Highlights:
	* Includes all essential product fields
	* Segments products by revenue to identify High-Performers, Mid-Range or Low-Performers.
	* Aggregates product level metrics: total of orders, sales, quantity sold, customers & lifespan
	* Calcualtes KPIs: recency, average order revenue, average monthly revenue
----------------------------------------------------------------------------------------------------
*/
IF OBJECT_ID('Gold.report_products','V') IS NOT NULL
	DROP VIEW Gold.report_products;
GO

CREATE VIEW Gold.report_products AS

	WITH base_query AS (
	SELECT
		f.order_number,
		f.order_date,
		f.sales_amount,
		f.sales_quantity,
		f.customer_key,
		f.product_key,
		d.product_name,
		d.category,
		d.subcategory,
		d.product_cost
	

	FROM Gold.fact_sales f
	LEFT JOIN Gold.dim_products d
	ON f.product_key = d.product_key
	WHERE f.order_date IS NOT NULL
	),
	product_aggregation AS (
	SELECT
		product_key,
		product_name,
		category,
		subcategory,
		product_cost,
		COUNT(DISTINCT order_number) AS total_orders,
		COUNT(DISTINCT customer_key) AS total_customers,
		SUM(sales_quantity) AS total_quantity,
		SUM(sales_amount) AS total_sales,
		MAX(order_date) AS last_sales_date,
		DATEDIFF(MONTH, MIN(order_date),MAX(order_date)) AS lifespan,
		ROUND(AVG(CAST(sales_amount AS FLOAT)/ NULLIF (sales_quantity,0)),1) AS avg_selling_price
	FROM base_query
	GROUP BY product_key,
		product_name,
		category,
		subcategory,
		product_cost
	)
	SELECT
		product_key,
		product_name,
		category,
		subcategory,
		product_cost,
		total_orders,
		total_customers,
		total_quantity,
		total_sales,
		CASE 
			WHEN total_sales > 50000 THEN 'High Performer'
			WHEN total_sales >= 10000 THEN 'Mid-Range'
			ELSE 'Low Performer'
		END AS product_segment,
		last_sales_date,
		lifespan,
		DATEDIFF(MONTH, last_sales_date,GETDATE()) AS recency,
		avg_selling_price,
		CASE
			WHEN total_orders = 0 THEN 0
			ELSE total_sales / total_orders
		END AS avg_order_revenue,
		CASE
			WHEN lifespan = 0 THEN total_sales
			ELSE total_sales/lifespan
		END AS avg_monthly_revenue
	FROM product_aggregation




































