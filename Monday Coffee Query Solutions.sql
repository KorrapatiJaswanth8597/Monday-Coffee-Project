
-- Monday Coffee -- Data Analysis

USE monday_coffee;

SELECT * FROM city;
SELECT * FROM [products ];
SELECT * FROM [customers ];
SELECT * FROM [sales ];


-- Reports & Data Analysis

/*
Q.1 Coffee Consumers Count
How many people in each city are estimated to consume coffee, given
that 25% of the population does?
*/

SELECT * FROM city;
SELECT * FROM [customers ];

SELECT city_name, 
CAST((population * 0.25)/1000000 AS DECIMAL(10,2)) AS coffee_consumers_in_millions,
city_rank
FROM city
ORDER BY coffee_consumers_in_millions DESC;

------------------------------------------------------------------------------

/*
Q.2
Total Revenue from Coffee Sales
What is the total revenue generated from coffee sales across all 
cities in the last quarter of 2023?
*/

SELECT * FROM [sales ];
SELECT * FROM city;
SELECT * FROM [customers ];

SELECT city_name, SUM(total) AS total_revenue 
FROM city AS ci
INNER JOIN [customers ] AS cu
ON ci.city_id = cu.city_id
INNER JOIN [sales ] AS s
ON cu.customer_id = s.customer_id
WHERE YEAR(sale_date) = 2023 AND DATEPART(QUARTER,sale_date) = 4
GROUP BY city_name
ORDER BY total_revenue DESC

--------------------------------------------------------------

/*
Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?
*/

SELECT * FROM [sales ];
SELECT * FROM [products ];

SELECT product_name, COUNT(s.sale_id) AS total_orders
FROM [sales ] AS s
RIGHT JOIN [products ] AS p
ON s.product_id = p.product_id
GROUP BY product_name
ORDER BY total_orders DESC;

-------------------------------------------------------------------

/*
Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

*/

SELECT * FROM city;
SELECT * FROM [customers ];
SELECT * FROM [sales ];

WITH city_sales_summary AS (
SELECT city_name, SUM(total)  AS Total_Sales ,
COUNT(DISTINCT s.customer_id) AS total_customers
FROM city AS ci
INNER JOIN [customers ] AS cu
ON ci.city_id = cu.city_id
INNER JOIN [sales ] AS s
ON cu.customer_id = s.customer_id
GROUP BY city_name)

SELECT city_name, Total_Sales, total_customers,
CAST(Total_sales/total_customers AS DECIMAL(10,2)) AS avg_sale_per_customer
FROM city_sales_summary
ORDER BY Total_Sales DESC;

----------------------------------------------------------------------------------

/*
 Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, unique customets, estimated coffee consumers (25%)
*/

SELECT * FROM city;
SELECT * FROM [customers ];

WITH estimated_coffee_consumers AS (
SELECT city_name, 
CAST(population*0.25/1000000 AS DECIMAL(10,2)) AS coffee_consumers_in_millions
FROM city ),

unique_customers_by_city AS (
SELECT city_name,
COUNT(DISTINCT cu.customer_id) AS unique_customers
FROM city AS ci 
INNER JOIN [customers ] AS cu 
ON ci.city_id = cu.city_id 
GROUP BY city_name)

SELECT ecc.city_name, coffee_consumers_in_millions,
unique_customers
FROM estimated_coffee_consumers AS ecc
INNER JOIN unique_customers_by_city AS uc
ON ecc.city_name = uc.city_name;

--------------------------------------------------------------------------------------
/*
Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?
*/

WITH city_product_order_counts AS (
SELECT city_name, product_name,
COUNT(s.sale_id) AS total_orders
FROM city AS c 
INNER JOIN [customers ] AS cu
ON c.city_id = cu.city_id
INNER JOIN [sales ] AS s
ON cu.customer_id = s.customer_id 
INNER JOIN [products ] AS P
ON s.product_id = p.product_id
GROUP BY city_name, product_name
--ORDER BY city_name, total_orders DESC
),

top_products_by_city AS (
SELECT city_name, product_name, total_orders,
DENSE_RANK() OVER(PARTITION BY city_name ORDER BY total_orders DESC) AS rnk 
FROM city_product_order_counts )

SELECT city_name, product_name, total_orders
FROM top_products_by_city
WHERE rnk<=3;
----------------------------------------------------------------------

/*
 Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have
purchased coffee products?
*/

SELECT * FROM [customers ];
SELECT * FROM city;
 
SELECT ci.city_name, COUNT(DISTINCT cu.customer_id) AS unique_cus
FROM city AS ci
INNER JOIN [customers ] AS cu
ON ci.city_id = cu.city_id
INNER JOIN [sales ] AS s
ON cu.customer_id = s.customer_id 
INNER JOIN [products ] AS p
ON s.product_id = p.product_id
GROUP BY ci.city_name;

------------------------------------------------------

/*
Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

-- Conclusions
*/

SELECT * FROM [sales ];
SELECT * FROM city;

WITH city_sales_metrics AS (
SELECT city_name,   
COUNT(DISTINCT s.customer_id) AS total_cus,
CAST(SUM(total)/ COUNT(DISTINCT s.customer_id)  AS DECIMAL(10,2)) AS avg_sales_pr_cus
FROM city AS ci 
LEFT JOIN [customers ] AS cu 
ON ci.city_id = cu.city_id
INNER JOIN [sales ] AS s
ON cu.customer_id = s.customer_id
GROUP BY city_name ),

city_rent_data AS (
SELECT city_name, 
estimated_rent 
FROM city)

SELECT crd.city_name, estimated_rent,
total_cus, avg_sales_pr_cus,
CAST(estimated_rent/total_cus  AS DECIMAL(10,2)) AS avg_rent_pr_cus
FROM city_rent_data AS crd
INNER JOIN city_sales_metrics AS csm
ON crd.city_name = csm.city_name
ORDER BY avg_sales_pr_cus DESC;

-----------------------------------------------------------------------------------------

/*
 Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline)
in sales over different time periods (monthly)
-- by each city
*/

SELECT * FROM city;
SELECT * FROM [customers ];
SELECT * FROM [sales ];

WITH monthly_city_revenue AS (
SELECT city_name, 
MONTH(sale_date) AS month_,
YEAR(sale_date) AS year_,
SUM(total) AS total_revenue 
FROM city AS ci 
INNER JOIN [customers ] AS cu 
ON ci.city_id = cu.city_id 
INNER JOIN [sales ] AS s
ON cu.customer_id = s.customer_id
GROUP BY city_name, MONTH(sale_date),
YEAR(sale_date)),

revenue_with_lag AS (
SELECT city_name, month_, total_revenue AS curr_month_sale ,year_,
LAG(total_revenue,1,total_revenue) OVER(PARTITION BY city_name ORDER BY year_, month_) AS previous_sales
FROM monthly_city_revenue)

SELECT city_name, month_,  curr_month_sale, previous_sales,year_,
(curr_month_sale - previous_sales) AS sales_diff, 
CAST((curr_month_sale - previous_sales)*100/previous_sales  AS DECIMAL(10,2)) AS perc
FROM revenue_with_lag;

-------------------------------------------------------------------------------------------------

/*
Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name,
total sale, total rent, total customers, estimated coffee consumer
*/

SELECT * FROM city;

SELECT city_name, SUM(total) AS total_revenue, 
estimated_rent AS total_rent,
COUNT(DISTINCT cu.customer_id) AS total_cus, 
CAST(population*0.25/1000000 AS DECIMAL(10,2)) AS estimated_coffee_consumer,
CAST(SUM(total)/COUNT(DISTINCT cu.customer_id) AS DECIMAL(10,2)) AS avg_sales_per_cus,
CAST(estimated_rent/COUNT(DISTINCT cu.customer_id)  AS DECIMAL(10,2)) AS avg_rent_per_cus
FROM city AS ci
INNER JOIN [customers ] AS cu
ON ci.city_id = cu.city_id
INNER JOIN [sales ] AS s
ON cu.customer_id = s.customer_id
GROUP BY city_name, estimated_rent,population
ORDER BY total_revenue DESC;


/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.
*/

------------------------------------------------------------------------------------------------------






 