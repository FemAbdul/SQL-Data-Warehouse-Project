/*
---------------------------------------------------------------------------------------
---------------------------------CUSTOMER REPORT---------------------------------------
---------------------------------------------------------------------------------------
Purpose:
		This report consolidates key customer metrics and behaviors

Highlights:
	* Includes all essential customer fields
	* Segments customers into age groups and also into categories(VIP, Regular, New)
	* Aggregates customer level metrics
	* Calcualtes KPIs: recency, average order value, average monthly spend
---------------------------------------------------------------------------------------
*/
IF OBJECT_ID('Gold.report_customers','V') IS NOT NULL
	DROP VIEW gold.report_customers;
GO
CREATE VIEW Gold.report_customers AS

WITH base_query AS(
--Base Query: Retrieves core columns from tables about Customer
	SELECT
	f.order_number,
	f.product_key,
	f.order_date,
	f.sales_amount,
	f.sales_quantity,
	f.customer_key,
	d.customer_number,
	CONCAT(d.first_name,' ',d.last_name) AS customer_name,
	DATEDIFF(YEAR, d.birthdate,GETDATE()) AS age
	FROM Gold.fact_sales f
	LEFT JOIN Gold.dim_customers d
	ON f.customer_key = d.customer_key
	WHERE f.order_date IS NOT NULL)
, 
customer_aggregation AS(
SELECT 
	customer_key,
	customer_number,
	customer_name,
	age,
	COUNT(DISTINCT order_number) as total_orders,
	SUM(sales_amount) AS total_sales,
	SUM(sales_quantity) AS quantity,
	COUNT(DISTINCT product_key) as total_products,
	MAX(order_date) AS last_order_date,
	DATEDIFF(MONTH, MIN(order_date),MAX(order_date)) AS lifespan
FROM base_query
GROUP BY customer_key,
	customer_number,
	customer_name,
	age
)

SELECT
	customer_key,
	customer_number,
	customer_name,
	age,
	CASE
		WHEN age < 20 THEN 'Under 20'
		WHEN age BETWEEN 20 AND 30 THEN '20 - 29'
		WHEN age BETWEEN 30 AND 39 THEN '30 - 39'
		WHEN age BETWEEN 40 AND 49 THEN '40 - 49'
		ELSE 'Above 50'
	END AS age_group,
	CASE
        WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
        WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
        ELSE 'New'
    END AS customer_segment,
	DATEDIFF(MONTH, last_order_date,GETDATE()) AS recency,
	total_orders,
	total_sales,
	quantity,
	total_products,
	last_order_date,
	lifespan,
	CASE WHEN total_orders = 0 THEN 0
		ELSE total_sales / total_orders
	END	AS avg_order_value,
	CASE WHEN lifespan = 0 THEN total_sales
		ELSE total_sales/lifespan
	END AS avg_monthly_spend	
FROM customer_aggregation


