-- Monday Coffee -- Data Analysis 

SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;

-- Reports & Data Analysis


-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

select city_name,(population*0.25)/100000 as coffee_consumers_in_mill,city_rank
from city
order by coffee_consymers_in_mill;

-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?


SELECT *
FROM sales
WHERE TO_CHAR(sale_date, 'Q') = '4'
  AND EXTRACT(YEAR FROM sale_date) = 2023;

SELECT SUM(TOTAL) AS TOTAL_REVENUE
FROM sales
WHERE TO_CHAR(sale_date, 'Q') = '4'
  AND EXTRACT(YEAR FROM sale_date) = 2023;




SELECT CI.CITY_NAME,SUM(S.TOTAL) AS TOTAL_REVENUE
FROM sales S,CITY CI,CUSTOMER C
WHERE CI.CITY_ID=C.CITY_ID
AND S.CUSTOMER_ID=C.CUSTOMER_ID
AND TO_CHAR(S.sale_date, 'Q') = '4'
  AND EXTRACT(YEAR FROM S.sale_date) = 2023
  GROUP BY CI.CITY_NAME;


-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT P.PRODUCT_NAME,COUNT(S.PRODUCT_ID)AS UNIT_SALES
FROM PRODUCT P,SALES S
WHERE P.PRODUCT_ID=S.PRODUCT_ID
GROUP BY P.PRODUCT_NAME
ORDER BY UNIT_SALES DESC;


-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

-- city abd total sale
-- no cx in each these city


SELECT CI.CITY_NAME,ROUND(AVG(S.TOTAL),2) AS AVERAGE_SALES
FROM CITY CI,SALES S,CUSTOMER C
WHERE CI.CITY_ID=C.CITY_ID
AND S.CUSTOMER_ID=C.CUSTOMER_ID
GROUP BY CI.CITY_NAME
ORDER BY AVERAGE_SALES DESC;



-- -- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

WITH city_table AS (
    SELECT
        c.city_name,
        ROUND((c.population * 0.25) / 100000) AS coffee_consumers_in_mill
    FROM city c
),
customer_table AS (
    SELECT
        c.city_name,
        COUNT(DISTINCT cu.customer_id) AS num_of_customers
    FROM city c
    JOIN customer cu ON c.city_id = cu.city_id
    JOIN sales s ON s.customer_id = cu.customer_id
    GROUP BY c.city_name
)
SELECT
    ct.city_name,
    ct.coffee_consumers_in_mill,
    cust.num_of_customers
FROM city_table ct
JOIN customer_table cust
    ON cust.city_name = ct.city_name;




-- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

SELECT city_name, product_name, total_orders, rnk
FROM (
    SELECT
        CI.CITY_NAME    AS city_name,
        P.PRODUCT_NAME  AS product_name,
        COUNT(S.SALE_ID) AS total_orders,
        DENSE_RANK() OVER (
            PARTITION BY CI.CITY_NAME
            ORDER BY COUNT(S.SALE_ID) DESC
        ) AS rnk
    FROM SALES S, PRODUCT P, CUSTOMER C, CITY CI
    WHERE S.CUSTOMER_ID = C.CUSTOMER_ID
      AND S.PRODUCT_ID  = P.PRODUCT_ID
      AND C.CITY_ID     = CI.CITY_ID
    GROUP BY CI.CITY_NAME, P.PRODUCT_NAME
) x
WHERE rnk IN (1,2,3);



-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT * FROM products;



SELECT 
    CI.CITY_NAME,
    COUNT(DISTINCT(C.CUSTOMER_ID)) AS NUM_OF_CUST
FROM CITY CI,CUSTOMER C,SALES S
WHERE CI.CITY_ID=C.CITY_ID
AND S.CUSTOMER_ID=C.CUSTOMER_ID
AND S.PRODUCT_ID BETWEEN 1 AND 14
GROUP BY CI.CITY_NAME;



-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

-- Conclusions

WITH CITY_TABLE 
AS(
SELECT CI.CITY_NAME,
    SUM(S.TOTAL) AS TOTAL_REVENUE,
    COUNT(DISTINCT(S.CUSTOMER_ID)) AS NUM_OF_CUST,
    ROUND(
        SUM(S.TOTAL)/COUNT(DISTINCT(S.CUSTOMER_ID)),2) AS AVERAGE_SALE
FROM CITY CI,CUSTOMER C,SALES S
WHERE CI.CITY_ID=C.CITY_ID
AND S.CUSTOMER_ID=C.CUSTOMER_ID
GROUP BY CI.CITY_NAME),
 CITY_RENT AS(
SELECT CITY_NAME,ESTIMATED_RENT FROM CITY)
SELECT CR.CITY_NAME,CR.ESTIMATED_RENT,CT.TOTAL_REVENUE,CT.AVERAGE_SALE,
ROUND(CR.ESTIMATED_RENT/CT.NUM_OF_CUST,2) AS AVG_RENT_PER_CUST
FROM CITY_RENT CR,CITY_TABLE CT
WHERE CR.CITY_NAME=CT.CITY_NAME;



-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

WITH monthly_sales AS (
    SELECT
        CI.CITY_NAME AS city_name,
        EXTRACT(MONTH FROM S.SALE_DATE) AS months,
        EXTRACT(YEAR  FROM S.SALE_DATE) AS years,
        SUM(S.TOTAL) AS total_sale
    FROM SALES S, CUSTOMER C, CITY CI
    WHERE S.CUSTOMER_ID = C.CUSTOMER_ID
      AND CI.CITY_ID    = C.CITY_ID
    GROUP BY
        CI.CITY_NAME,
        EXTRACT(MONTH FROM S.SALE_DATE),
        EXTRACT(YEAR  FROM S.SALE_DATE)
)
SELECT
    city_name,
    months,
    years,
    total_sale AS month_sale,
    LAG(total_sale, 1) OVER (
        PARTITION BY city_name
        ORDER BY years, months
    ) AS last_month_sale
FROM monthly_sales
ORDER BY city_name, years, months;



-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer



WITH CITY_TABLE 
AS(
SELECT CI.CITY_NAME,
    SUM(S.TOTAL) AS TOTAL_REVENUE,
    COUNT(DISTINCT(S.CUSTOMER_ID)) AS NUM_OF_CUST,
    ROUND(
        SUM(S.TOTAL)/COUNT(DISTINCT(S.CUSTOMER_ID)),2) AS AVERAGE_SALE
FROM CITY CI,CUSTOMER C,SALES S
WHERE CI.CITY_ID=C.CITY_ID
AND S.CUSTOMER_ID=C.CUSTOMER_ID
GROUP BY CI.CITY_NAME),
 CITY_RENT AS(
SELECT CITY_NAME,ESTIMATED_RENT,POPULATION*0.25 AS ES_COFFEE_CONS FROM CITY)
SELECT CR.CITY_NAME,CR.ESTIMATED_RENT,CT.TOTAL_REVENUE,CT.AVERAGE_SALE,
ROUND(CR.ESTIMATED_RENT/CT.NUM_OF_CUST,2) AS AVG_RENT_PER_CUST,
CR.ES_COFFEE_CONS
FROM CITY_RENT CR,CITY_TABLE CT
WHERE CR.CITY_NAME=CT.CITY_NAME;

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



