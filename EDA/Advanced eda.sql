/*
				ADVANCED ANALYTICS
*/
-------------------------------------------------
--Change over Time
-------------------------------------------------
--Daily Sales
SELECT
	order_date,
	SUM(sales_amount) AS total_amount
FROM
	Gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY order_date
ORDER BY order_date;

--Total Sales and Customers Over Year and Month
SELECT
	YEAR(order_date) AS order_year,
	MONTH(order_date) AS order_month,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(sales_quantity) AS total_quantity,
	SUM(sales_amount) AS total_amount
FROM
	Gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date),MONTH(order_date)
ORDER BY YEAR(order_date),MONTH(order_date);

-------------------------------------------------
--Cumulative Analysis
-------------------------------------------------
SELECT
	order_year,
	total,
	SUM(total) OVER (ORDER  BY order_year) AS running_total
FROM 
(
	SELECT
		YEAR(order_date) as order_year,
		SUM(sales_amount) as total
	FROM 
	Gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY YEAR(order_date)
) t
ORDER BY order_year;

--Running total per year
SELECT
    order_date,
    total_sales,
    SUM(total_sales) OVER (PARTITION BY YEAR(order_date) ORDER BY order_date) AS running_total_sales
FROM (
    SELECT
        DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1) AS order_date,
        SUM(sales_amount) AS total_sales
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1)
) AS t;

--Moving Average
SELECT
    order_date,
    total_sales,
    SUM(total_sales) OVER (PARTITION BY YEAR(order_date) ORDER BY order_date) AS running_total_sales,
	AVG(avg_price) OVER (ORDER BY order_date) AS cumulative_average,
	AVG(avg_price) OVER (ORDER BY YEAR(order_date)) AS cumulative_average,
	AVG(avg_price) OVER (PARTITION BY YEAR(order_date) ORDER BY order_date) AS moving_average
FROM (
    SELECT
        DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1) AS order_date,
        SUM(sales_amount) AS total_sales,
		AVG(sales_price) AS avg_price
	FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1)
) AS t;

--INNER WINDOW SET TO YEAR
SELECT
    order_date,
    total_sales,
    SUM(total_sales) OVER (PARTITION BY YEAR(order_date) ORDER BY order_date) AS running_total_sales,
	AVG(avg_price) OVER (ORDER BY order_date) AS cumulative_average,
	AVG(avg_price) OVER (ORDER BY YEAR(order_date)) AS cumulative_average,
	AVG(avg_price) OVER (PARTITION BY YEAR(order_date) ORDER BY order_date) AS moving_average
FROM (
    SELECT
        DATEFROMPARTS(YEAR(order_date),1 , 1) AS order_date,
        SUM(sales_amount) AS total_sales,
		AVG(sales_price) AS avg_price
	FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATEFROMPARTS(YEAR(order_date), 1, 1)
) AS t;

----
SELECT
    order_date,
    total_sales,
    SUM(total_sales) OVER (ORDER BY order_date) AS running_total_sales,
    avg_price,
    AVG(avg_price)   OVER (ORDER BY order_date) AS moving_average
FROM (
    SELECT
        DATEFROMPARTS(YEAR(order_date), 1, 1) AS order_date,
        SUM(sales_amount) AS total_sales,
        AVG(sales_price)  AS avg_price
    FROM Gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATEFROMPARTS(YEAR(order_date), 1, 1)
) AS t
ORDER BY order_date;

-------------------------------------------------
--Performance Analysis
-------------------------------------------------

SELECT
    YEAR(f.order_date) AS order_year,
    p.product_name,
    SUM(f.sales_amount) AS current_sales
FROM Gold.fact_sales f
LEFT JOIN Gold.dim_products p
ON f.product_key = p.product_key
WHERE f.order_date IS NOT NULL
GROUP BY p.product_name, YEAR(f.order_date)
ORDER BY p.product_name, YEAR(f.order_date)

--Compare current sales with Average sales of the product

WITH yealy_product_sales_cte AS(
    SELECT
        YEAR(f.order_date) AS order_year,
        p.product_name AS product_name,
        SUM(f.sales_amount) AS current_sales
    FROM Gold.fact_sales f
    LEFT JOIN Gold.dim_products p
    ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY p.product_name, YEAR(f.order_date)
)

SELECT 
    order_year,
    product_name,
    current_sales,
    AVG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS avg_sales,
    current_sales - AVG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS diff_avg,
    CASE
        WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Above Average'
        WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Below Average'
        ELSE 'Avg'
    END AS avg_flag,
    --Previous year sale
    LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS prevs_sales,
    current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS diff_py,
    CASE
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS cur_py_flag
FROM yealy_product_sales_cte
ORDER BY product_name, order_year

-------------------------------------------------
--Part to Whole Analysis
-------------------------------------------------
--Categories that contribute most to the sales

WITH total_sales_cte AS(
    SELECT
        p.category,
        SUM(f.sales_amount) AS total_cat_sales

    FROM Gold.fact_sales f
    LEFT JOIN Gold.dim_products p
    ON f.product_key = p.product_key
    GROUP BY p.category
)
SELECT
    category,
    total_cat_sales,
    SUM(total_cat_sales) OVER() AS total_sales,
    CONCAT(ROUND((CAST(total_cat_sales AS FLOAT)  / (SUM(total_cat_sales) OVER() )* 100),2) , '%') AS percentage_sales
FROM total_sales_cte
ORDER BY total_cat_sales DESC;

-------------------------------------------------
--Data Segmentation
-------------------------------------------------
--Segment products into cost ranges and Count the number of products in each range
WITH cost_segment_cte AS(
    SELECT
        product_key,
        product_name,
        product_cost,
        CASE
            WHEN product_cost < 100 THEN 'BELOW 100'
            WHEN product_cost BETWEEN 100 AND 500 THEN '100 - 500'
            WHEN product_cost BETWEEN 500 AND 1000 THEN '500 - 1000'
            ELSE 'ABOVE 1000'
        END AS cost_segment
    FROM Gold.dim_products
)
SELECT
    cost_segment,
    COUNT(product_key) AS number_of_products
FROM cost_segment_cte
GROUP BY cost_segment;

--Group Customers into segments based on their spending behaviour
WITH customer_segment_cte AS(
    SELECT
        c.customer_key,
        MIN(f.order_date) AS starting_date,
        MAX(f.order_date) AS ending_date,
        SUM(sales_amount) AS total_spending,
        DATEDIFF(MONTH, MIN(f.order_date),MAX(f.order_date)) AS lifespan
    FROM Gold.fact_sales f
    LEFT JOIN Gold.dim_customers c
    ON c.customer_key = f.customer_key
    GROUP BY c.customer_key
)
SELECT 
    cust_segment,
    COUNT(customer_key) AS tot_customers
FROM (
        SELECT
            customer_key,
            CASE
                WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
                WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
                ELSE 'New'
            END AS cust_segment
        FROM customer_segment_cte
      ) t
GROUP BY cust_segment
ORDER BY tot_customers;