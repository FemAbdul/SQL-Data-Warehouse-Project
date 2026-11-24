/*
----------------------------------------------------------------------------
				EXPLORATORY DATA ANALYSIS
				-------------------------
				1. DATABASE EXPLORATION
				2. DIMENSIONS EXPLORATION
				3. DATE EXPLORATION
				4. MEASURES EXPLORATION
				5. MAGNITUDE EXPLORATION
				6. RANKING ANALYSIS
				
----------------------------------------------------------------------------
*/

----------------------------------------
--DATABASE EXPLORATION
----------------------------------------

--Explore All Objects in the Database
SELECT * FROM INFORMATION_SCHEMA.TABLES;

--Explore All Columns in the database
SELECT * FROM INFORMATION_SCHEMA.COLUMNS;

SELECT * FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME='dim_customers';

----------------------------------------
--DIMENSIONS EXPLORATION
----------------------------------------

--Explore All Countries Customers come from
SELECT DISTINCT country FROM Gold.dim_customers;

--Explore Categories of Products
SELECT DISTINCT category FROM Gold.dim_products;

SELECT DISTINCT category,subcategory FROM Gold.dim_products;

SELECT DISTINCT category,subcategory,product_name
FROM Gold.dim_products
ORDER BY 1,2,3;

----------------------------------------
--DATE EXPLORATION
----------------------------------------

--First and Last Order date
SELECT MIN (order_date) as first_order_date,
	MAX(order_date) as last_order_date
FROM Gold.fact_sales;

--How many years of sales data are available in yeas and months
SELECT 
	MIN (order_date) as first_order_date,
	MAX(order_date) as last_order_date,
	DATEDIFF(YEAR,MIN(order_date),MAX(order_date)) AS order_range_years,
	DATEDIFF(MONTH, MIN(order_date),MAX(order_date)) AS order_range_months
FROM Gold.fact_sales;

-- Youngest and Oldest Customer
SELECT
		MIN(birthdate) AS oldest_customer,
		DATEDIFF(YEAR,MIN(birthdate),GETDATE()) AS oldest_age,
		MAX(birthdate) AS youngest_customer,
		DATEDIFF(YEAR, MAX(birthdate),GETDATE()) AS youngest_age
FROM Gold.dim_customers;

----------------------------------------
--MEASURES EXPLORATION
----------------------------------------

--Find the Total Sales
SELECT
	SUM(sales_amount) as total_sales
FROM Gold.fact_sales;

--Find the total quantity sold
SELECT
	SUM(sales_quantity) as total_quantity
FROM Gold.fact_sales;

--Find the Average selling price
SELECT
	AVG(sales_price) as avg_price
FROM Gold.fact_sales;

--Find the total number of Orders
SELECT
	COUNT(order_number) as total_orders
FROM Gold.fact_sales;
--Verify
SELECT
	COUNT(DISTINCT order_number) as total_orders
FROM Gold.fact_sales;
--Why are both different? (one row per order LINE, not per order)
SELECT
	COUNT(*),order_number
FROM Gold.fact_sales
GROUP BY order_number
HAVING COUNT(*) > 1;

SELECT *
FROM Gold.fact_sales
WHERE order_number ='SO57282';

--Find the total number of Products
SELECT
	COUNT(product_key)
FROM Gold.dim_products;

--Find the total number of Customers
SELECT
	COUNT(customer_key) AS total_customers
FROM Gold.dim_customers;

--Find the total number of Customers who has placed an order
SELECT
	COUNT(DISTINCT customer_key) AS customers
FROM Gold.fact_sales;

--Generate a report that shows all key metrics of the Business

SELECT
	'Total Sales' as measure_name,SUM(sales_amount) as measure_value
FROM Gold.fact_sales
UNION ALL
SELECT
	'Total Quantity' as measure_name,SUM(sales_quantity) as measure_value
FROM Gold.fact_sales
UNION ALL
SELECT
	'Average Price' as measure_name,AVG(sales_price) as measure_value
FROM Gold.fact_sales
UNION ALL
SELECT
	'Total No.of Orders' as measure_name,COUNT(DISTINCT order_number) as measure_value
FROM Gold.fact_sales
UNION ALL
SELECT
	'Total No.of Products' as measure_name,COUNT(product_key) as measure_value
FROM Gold.dim_products
UNION ALL
SELECT
	'Total No.of Customers with at least one order' as measure_name,COUNT(DISTINCT customer_key) as measure_value
FROM Gold.fact_sales

----------------------------------------
--MAGNITUDE EXPLORATION
----------------------------------------

--Find Number of Customers By Country
SELECT
	country,
	COUNT(customer_key) AS Total_customers
FROM Gold.dim_customers
GROUP BY country
ORDER BY Total_customers DESC;

--Find Total Customers By Gender
SELECT
	gender,
	COUNT(customer_key) AS Total_customers
FROM Gold.dim_customers
GROUP BY gender
ORDER BY Total_customers DESC;

--Find the Total products By Category
SELECT
	category,
	COUNT(product_key) AS Total_products
FROM Gold.dim_products
GROUP BY category
ORDER BY Total_products DESC;

--Average Cost in each category
SELECT
	category,
	AVG(product_cost) AS Average_cost
FROM Gold.dim_products
GROUP BY category
ORDER BY Average_cost DESC;

--Total Revenue generated for each Category
SELECT
	p.category AS category,
	SUM(f.sales_amount) AS total_revenue
FROM Gold.fact_sales f
LEFT JOIN Gold.dim_products p
ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;

--Total Revenue Generated by each Customer
SELECT
	c.customer_key,
	c.first_name,
	c.last_name,
	SUM(f.sales_amount) AS total_revenue
FROM Gold.fact_sales f
LEFT JOIN Gold.dim_customers c
ON c.customer_key = f.customer_key
GROUP BY c.customer_key,c.first_name,c.last_name
ORDER BY total_revenue DESC;

-- Distribution of sold items across countries
SELECT
	c.country,
	SUM(f.sales_quantity) AS total_sold_quantity
FROM Gold.fact_sales f
LEFT JOIN Gold.dim_customers c
ON c.customer_key = f.customer_key
GROUP BY c.country
ORDER BY total_sold_quantity DESC;

----------------------------------------
--RANKING ANALYSIS
----------------------------------------

--Top 5 products that generate the highest revenue
SELECT TOP 5
	p.product_name,
	SUM(s.sales_amount) AS total_revenue	
FROM Gold.fact_sales s
LEFT JOIN Gold.dim_products p
ON p.product_key = s.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC;

--Worst 5 performing products in terms of sales
SELECT TOP 5
	p.product_name,
	SUM(s.sales_amount) AS total_revenue	
FROM Gold.fact_sales s
LEFT JOIN Gold.dim_products p
ON p.product_key = s.product_key
GROUP BY p.product_name
ORDER BY total_revenue ASC;

--Top 5 subcategories that perform well
SELECT TOP 5
	p.subcategory,
	SUM(s.sales_amount) AS total_revenue	
FROM Gold.fact_sales s
LEFT JOIN Gold.dim_products p
ON p.product_key = s.product_key
GROUP BY p.subcategory
ORDER BY total_revenue DESC;

--Top 10 customers with the most number of orders
SELECT TOP 10
	ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT f.order_number) DESC,
	SUM(f.sales_amount) DESC) AS row_num,
	c.customer_key,
	c.first_name,
	c.last_name,
	COUNT(DISTINCT f.order_number) AS orders,
	SUM(f.sales_amount) AS total_revenue
FROM Gold.fact_sales f
LEFT JOIN Gold.dim_customers c
ON c.customer_key = f.customer_key
GROUP BY c.customer_key,c.first_name,c.last_name
ORDER BY orders DESC,total_revenue DESC;

--Top 10 customers with the most actual revenue
SELECT * FROM (
	SELECT
		DENSE_RANK() OVER (ORDER BY SUM(f.sales_amount) DESC) AS drank,
		c.customer_key,
		c.first_name,
		c.last_name,
		COUNT(DISTINCT f.order_number) AS orders,
		SUM(f.sales_amount) AS total_revenue
	FROM Gold.fact_sales f
	LEFT JOIN Gold.dim_customers c
	ON c.customer_key = f.customer_key
	GROUP BY c.customer_key,c.first_name,c.last_name
) t
WHERE drank <= 10
ORDER BY drank;
