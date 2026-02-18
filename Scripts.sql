SELECT *
FROM monday_coffee_db.city;

SELECT *
FROM monday_coffee_db.sales;

-- REPORTS AND DATA ANALYSIS 

-- Q1. Coffee Consumers Count 
-- How many people in each city are estimated to condume coffee, given that 25% of the population drinks coffee?

SELECT city_name,
	ROUND(population * 0.25/1000000, 2) AS coffee_consumers_in_millions,
    city_rank
FROM monday_coffee_db.city
ORDER BY 2 DESC;

-- Q2. Total revenue from coffee sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT *, 
YEAR(sale_date) AS Year,
QUARTER(sale_date) AS Quarter
FROM monday_coffee_db.sales
WHERE YEAR(sale_date) = '2023'AND
QUARTER(sale_date) = '4';


SELECT SUM(total)
FROM monday_coffee_db.sales
WHERE YEAR(sale_date) = '2023'AND
QUARTER(sale_date) = '4';



SELECT ci.city_name,
	   SUM(s.total) as Total_revenue
FROM monday_coffee_db.sales AS s
	JOIN monday_coffee_db.customers AS c
	ON s.customer_id = c.customer_id
		JOIN monday_coffee_db.city AS ci
				ON ci.city_id = c.city_id
WHERE YEAR(s.sale_date) = '2023'AND
		QUARTER(s.sale_date) = '4'
GROUP BY ci.city_name
ORDER BY 2 DESC;

-- Q3 Sales Count for Each Product
-- How many Units of each Coffee product have been sold?

SELECT p.product_name, 
COUNT(sale_id)
FROM monday_coffee_db.products as p
JOIN monday_coffee_db.sales AS s
ON p.product_id = s.product_id
GROUP BY p.product_name
ORDER BY 2 DESC;

-- Q4. Average Sales Amount per City
-- What is the average sales amount per customer in each city?

SELECT 
    ci.city_name,
    SUM(s.total) AS Total_sales,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    ROUND
    (
		SUM(s.total)/COUNT(DISTINCT c.customer_id),2
        ) AS avg_sale_per_customer
FROM
    monday_coffee_db.sales AS s
        JOIN
    monday_coffee_db.customers AS c ON s.customer_id = c.customer_id
        JOIN
    monday_coffee_db.city AS ci ON c.city_id = ci.city_id
GROUP BY ci.city_name
ORDER BY 4 DESC;

-- Q.5 City Population and Coffee Consumers
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current customers, estimated coffee consumers (25%)

WITH city_table AS
( 
 SELECT city_name,
 ROUND ((population * 0.25)/1000000,2) AS coffee_consumers
 FROM city
),
customers_table 
AS
(
SELECT ci.city_name,
COUNT(DISTINCT c.customer_id) AS unique_cx
FROM sales AS s
JOIN customers AS c
ON c.customer_id = s.customer_id
JOIN city AS ci
ON ci.city_id = c.city_id
GROUP BY 1
)
SELECT 
	customers_table.city_name,
    city_table.coffee_consumers AS coffee_consumers_in_millions,
    customers_table.unique_cx
FROM city_table 
JOIN customers_table 
ON city_table.city_name = customers_table.city_name;

-- 

-- Q6. Top Selling Products by city
-- What are the top 3 selling products in each city based on sales volume?

SELECT *
FROM
(
SELECT ci.city_name,
	   p.product_name,
       COUNT(s.sale_id) AS total_orders,
       DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY  COUNT(s.sale_id) DESC) AS ranking
FROM sales AS s
JOIN products AS p
ON s.product_id = p.product_id
JOIN customers AS c
ON c.customer_id = s.customer_id
JOIN city AS ci
ON ci.city_id = c.city_id
GROUP BY ci.city_name, p.product_name
-- ORDER BY ci.city_name, COUNT(s.sale_id) DESC;
) AS t
WHERE ranking <= 3;

-- Q7 
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT 
ci.city_name, 
COUNT(DISTINCT c.customer_id) AS unique_customers 
FROM city AS ci
JOIN customers AS c
ON c.city_id = ci.city_id
JOIN sales AS s
ON 	s.customer_id = c.customer_id
WHERE 
	 s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY ci.city_name 
ORDER BY 2 DESC
;


-- Q8. Average Sales VS Rent
-- Find each city and their average sale per customer and average rent per customer

WITH city_table 
AS
(
SELECT 
    ci.city_name,
    SUM(s.total) as total_revenue,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    ROUND
    (
		SUM(s.total)/COUNT(DISTINCT c.customer_id),2
        ) AS avg_sale_per_customer
FROM
    monday_coffee_db.sales AS s
        JOIN
    monday_coffee_db.customers AS c ON s.customer_id = c.customer_id
        JOIN
    monday_coffee_db.city AS ci ON c.city_id = ci.city_id
GROUP BY ci.city_name
ORDER BY 2 DESC
),
city_rent
AS
(
SELECT 
	city_name,
    estimated_rent
FROM city
)

SELECT 
	cr.city_name,
    cr.estimated_rent,
    ct.total_customers,
    ct.avg_sale_per_customer,
     ROUND(cr.estimated_rent/ct.total_customers,2) AS average_rent_per_customer
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 5 DESC ;

-- Q9 
-- Monthly Sales Growth
-- Calculate the percentage growth (or decline) in sales over different time periods(monthly) by each city
WITH monthly_sales AS
(SELECT ci.city_name,
EXTRACT(MONTH from sale_date) AS month,
EXTRACT(YEAR from sale_date) AS year,
SUM(s.total) AS total_sale
FROM sales AS s
JOIN customers AS c
on s.customer_id = c.customer_id
JOIN city AS ci
ON ci.city_id = c.city_id
GROUP BY ci.city_name, 
EXTRACT(MONTH from sale_date),
EXTRACT(YEAR from sale_date)
ORDER BY ci.city_name, 
EXTRACT(YEAR from sale_date),
EXTRACT(MONTH from sale_date)
), 
growth_ratio 
AS
(
SELECT 
	city_name,
    month,
    year,
    total_sale as cr_month_sale,
    LAG(total_sale) OVER(partition by city_name ORDER BY year, month) as last_month_sale
FROM monthly_sales
)
SELECT 
	city_name,
    month,
    year,
    cr_month_sale,
    last_month_sale,
    ROUND(((cr_month_sale- last_month_sale) / last_month_sale) * 100,2) AS growth_ratio
FROM growth_ratio
WHERE last_month_sale IS NOT NULL;

-- Q.10. Market Potential Analysis
-- Identify the top 3 cities based on the highes sales, return city name, total sale, total rent, total customers, estimasted coffee consumers

WITH city_table 
AS
(
SELECT 
    ci.city_name,
    SUM(s.total) as total_revenue,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    ROUND
    (
		SUM(s.total)/COUNT(DISTINCT c.customer_id),2
        ) AS avg_sale_per_customer
FROM
    monday_coffee_db.sales AS s
        JOIN
    monday_coffee_db.customers AS c ON s.customer_id = c.customer_id
        JOIN
    monday_coffee_db.city AS ci ON c.city_id = ci.city_id
GROUP BY ci.city_name
ORDER BY 2 DESC
),
city_rent
AS
(
SELECT 
	city_name,
    estimated_rent,
    ROUND((population * 0.25) / 1000000, 3) AS estimated_coffee_consumer_in_millions 
FROM city
)

SELECT 
	cr.city_name,
    ct.total_revenue,
    cr.estimated_rent AS total_rent,
    ct.total_customers,
    ct.avg_sale_per_customer,
    estimated_coffee_consumer_in_millions ,
     ROUND(cr.estimated_rent/ct.total_customers,2) AS average_rent_per_customer
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC ;