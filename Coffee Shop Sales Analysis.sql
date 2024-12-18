-- Create a database 
CREATE DATABASE COFFEE_SALES_DB;
USE COFFEE_SALES_DB;

-- Data Cleaning

-- Check whether all the rows have been imported
SELECT COUNT(*) FROM coffee_sales;

-- Data preview
SELECT * FROM coffee_sales;

-- Display the structure
DESCRIBE coffee_sales;

-- Update datatypes
UPDATE coffee_sales
SET transaction_date = str_to_date(transaction_date, "%d-%m-%Y");
ALTER TABLE coffee_sales
MODIFY COLUMN transaction_date DATE;

UPDATE coffee_sales
SET transaction_time = str_to_date(transaction_time, "%H:%i:%s");
ALTER TABLE coffee_sales
MODIFY COLUMN transaction_time TIME;

-- Change Column name
ALTER TABLE coffee_sales
CHANGE COLUMN ï»¿transaction_id transaction_id INT;


-- KPI requirements

-- Total sales in each respective month
SELECT CONCAT((ROUND(SUM(unit_price * transaction_qty)))/1000, "K") AS Total_Sales
FROM coffee_sales
WHERE MONTH(transaction_date) = 5; -- May month

-- TOTAL SALES - MoM difference and MoM growth
-- Selected month (CM): May= 5
-- Previous month (PM): April= 4
SELECT MONTH(transaction_date) AS month,
       ROUND(SUM(unit_price * transaction_qty)) AS total_sales,
       (SUM(unit_price * transaction_qty) - LAG(SUM(unit_price * transaction_qty), 1)
       OVER (ORDER BY MONTH(transaction_date))) / LAG(SUM(unit_price * transaction_qty), 1) 
       OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage FROM coffee_sales
WHERE MONTH(transaction_date) IN (4, 5) -- for months of April and May
GROUP BY MONTH(transaction_date)
ORDER BY MONTH(transaction_date);

-- total no of orders in each respective month
SELECT COUNT(transaction_id) AS Total_orders
FROM coffee_sales 
WHERE MONTH (transaction_date)= 3 -- march month

-- TOTAL ORDERS- MoM difference and MoM growth
-- Selected month (CM): May= 5
-- Previous month (PM): April= 4
SELECT MONTH(transaction_date) AS month,
       ROUND(COUNT(transaction_id)) AS total_orders,
       (COUNT(transaction_id) - LAG(COUNT(transaction_id), 1) 
	   OVER (ORDER BY MONTH(transaction_date))) / LAG(COUNT(transaction_id), 1) 
       OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage FROM coffee_sales
WHERE MONTH(transaction_date) IN (4, 5) -- for April and May
GROUP BY MONTH(transaction_date)
ORDER BY MONTH(transaction_date);

-- total quantity sold in each respective month
SELECT SUM(transaction_qty) AS Total_quantity_sold
FROM coffee_sales 
WHERE MONTH (transaction_date)= 4 -- april month

-- TOTAL QUANTITY SOLD- MoM difference and MoM growth
-- Selected month (CM): May= 5
-- Previous month (PM): April= 4
SELECT MONTH(transaction_date) AS month,
       ROUND(SUM(transaction_qty)) AS total_quantity_sold,
       (SUM(transaction_qty) - LAG(SUM(transaction_qty), 1) 
       OVER (ORDER BY MONTH(transaction_date))) / LAG(SUM(transaction_qty), 1) 
       OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage FROM coffee_sales
WHERE MONTH(transaction_date) IN (4, 5)   -- for April and May
GROUP BY MONTH(transaction_date)
ORDER BY MONTH(transaction_date);

-- Problem statement
-- Display total sales, total quantity sold and total orders on a particular day
SELECT CONCAT(ROUND(SUM(unit_price * transaction_qty)/1000,1), "K") AS TOTAL_SALES,
       CONCAT(ROUND(SUM(transaction_qty)/1000,1),"K") AS TOTAL_QUANTITY_SOLD,
       CONCAT(ROUND(COUNT(transaction_id)/1000,1), "K") AS TOTAL_ORDERS FROM coffee_sales
WHERE transaction_date= "2023-05-18";

-- Display the Sales by Weekends and Weekdays
-- Weekends - Sun and Sat
-- Weekdays - Mon to Fri
-- Sun=1, Mon=2...... Sat=7
SELECT CASE WHEN DAYOFWEEK(transaction_date) IN (1,7) THEN "Weekends" 
ELSE "Weekdays"
END AS day_type, ROUND(SUM(unit_price * transaction_qty),2) AS total_sales FROM coffee_sales
WHERE MONTH(transaction_date) = 5  -- Filter for May
GROUP BY CASE WHEN DAYOFWEEK(transaction_date) IN (1, 7) THEN 'Weekends'
ELSE 'Weekdays'
END;

-- Display sales by store location
SELECT store_location, CONCAT(ROUND(SUM(unit_price * transaction_qty)/1000,2), "K") as Total_Sales
FROM coffee_sales
WHERE MONTH(transaction_date) =5 -- may month
GROUP BY store_location
ORDER BY SUM(unit_price * transaction_qty) DESC;

-- Comparing daily sales with average sales – If greater than “ABOVE AVERAGE” and  lesser than “BELOW AVERAGE”
SELECT day_of_month,
CASE WHEN total_sales > avg_sales THEN 'Above Average'
	 WHEN total_sales < avg_sales THEN 'Below Average'
	 ELSE 'Average'
     END AS sales_status,
     total_sales
FROM (SELECT DAY(transaction_date) AS day_of_month,
        SUM(unit_price * transaction_qty) AS total_sales,
        AVG(SUM(unit_price * transaction_qty)) OVER () AS avg_sales
    FROM coffee_sales
    WHERE MONTH(transaction_date) = 5  -- Filter for May
    GROUP BY DAY(transaction_date)) AS sales_data
ORDER BY day_of_month;

-- Display the sales by product category
SELECT product_category, ROUND(SUM(unit_price * transaction_qty),1) as Total_Sales
FROM coffee_sales
WHERE MONTH(transaction_date) = 5 
GROUP BY product_category
ORDER BY SUM(unit_price * transaction_qty) DESC;

-- Display the sales by product category (TOP 10)
SELECT product_type, ROUND(SUM(unit_price * transaction_qty),1) as Total_Sales
FROM coffee_sales
WHERE MONTH(transaction_date) = 5 
GROUP BY product_type
ORDER BY SUM(unit_price * transaction_qty) DESC LIMIT 10;

-- Display sales by DAY | HOUR
SELECT ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales, 
       SUM(transaction_qty) AS Total_Quantity,
       COUNT(*) AS Total_Orders FROM coffee_sales
WHERE DAYOFWEEK(transaction_date) = 3 -- Filter for Tuesday (1 is Sunday, 2 is Monday, ..., 7 is Saturday)
      AND HOUR(transaction_time) = 8 -- Filter for hour number 8
      AND MONTH(transaction_date) = 5; -- Filter for May (month number 5);
      
-- display the sales from monday to sunday for the month of may
SELECT CASE 
        WHEN DAYOFWEEK(transaction_date) = 2 THEN 'Monday'
        WHEN DAYOFWEEK(transaction_date) = 3 THEN 'Tuesday'
        WHEN DAYOFWEEK(transaction_date) = 4 THEN 'Wednesday'
        WHEN DAYOFWEEK(transaction_date) = 5 THEN 'Thursday'
        WHEN DAYOFWEEK(transaction_date) = 6 THEN 'Friday'
        WHEN DAYOFWEEK(transaction_date) = 7 THEN 'Saturday'
ELSE 'Sunday'
END AS Day_of_Week, ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales
FROM coffee_sales
WHERE MONTH(transaction_date) = 5 -- Filter for May (month number 5)
GROUP BY CASE 
        WHEN DAYOFWEEK(transaction_date) = 2 THEN 'Monday'
        WHEN DAYOFWEEK(transaction_date) = 3 THEN 'Tuesday'
        WHEN DAYOFWEEK(transaction_date) = 4 THEN 'Wednesday'
        WHEN DAYOFWEEK(transaction_date) = 5 THEN 'Thursday'
        WHEN DAYOFWEEK(transaction_date) = 6 THEN 'Friday'
        WHEN DAYOFWEEK(transaction_date) = 7 THEN 'Saturday'
ELSE 'Sunday'
END;

-- Display the sales for all hours for the month of may
SELECT HOUR(transaction_time) AS Hour_of_Day,
       ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales
FROM coffee_sales
WHERE MONTH(transaction_date) = 5 -- Filter for May (month number 5)
GROUP BY HOUR(transaction_time)
ORDER BY HOUR(transaction_time);
