-- Exploratory Data Analysis EDA

-- Starting with Date And Total_Cost to determine sales 
SELECT * FROM retail_transaction.retail_staging2;

-- Checking Range of Year using DISTINCT 
SELECT DISTINCT year(`Date`) as `Year` 
FROM retail_staging2
ORDER BY `Year`;

-- Total Sales every month of each year using aggregate Functions
SELECT MONTH(`Date`) AS Num,YEAR(`Date`) AS `Year` ,MONTHNAME(`Date`)AS `Month`, ROUND(SUM(Total_Cost),0) AS Total_Sales
FROM retail_staging2
GROUP BY Num,`Year`,`Month`
ORDER BY Num,`Year`,`Month`;

-- Total Sales Per Year
SELECT YEAR(`Date`) AS `Year`, ROUND(SUM(Total_Cost),0) AS Total_Sales
FROM retail_staging2
GROUP BY `Year`
ORDER BY `Year`; 


-- Comparison of Total sales, Transaction and average sales per year 
SELECT YEAR(`Date`) AS `Year`, 
ROUND(SUM(Total_Cost),0) AS Total_Sales,
COUNT(Transaction_ID) AS Transaction_made,
ROUND(SUM(Total_Cost)/COUNT(Transaction_ID),2) AS Avg_Sale_Per_Transaction
FROM retail_staging2
GROUP BY `Year`
ORDER BY `Year`; 


-- Checking Peak Hours total sales and transactions made in specified year and month
SELECT HOUR(`Time`) As `Hour`,YEAR(`Date`) AS `Year`, MONTH(`Date`) AS `Month`,
ROUND(SUM(Total_Cost),0) AS Total_sales,
COUNT(*) AS Transactions
FROM retail_staging2
WHERE MONTH(`Date`)= '1' AND YEAR(`Date`)='2020'
GROUP BY `Year`,`Month`,`Hour`
ORDER BY `Hour`;


-- Query for sales over specified Months and Time Range
SELECT YEAR(`Date`)AS `Year`,MONTHNAME(`Date`) AS `Month` ,ROUND(SUM(Total_Cost),2) AS Total_Sales 
FROM retail_staging2
WHERE MONTH(`Date`) BETWEEN 1 AND 3 AND YEAR(`Date`) BETWEEN'2020' AND '2024'
AND TIME(`Time`) BETWEEN '06:00:00' AND '12:00:00'
GROUP BY `Year`, `Month`
ORDER BY `Year`,FIELD(`Month`, 
	'January','February','March','April','May','June',
    'July','August','September','October','November','December'); 

SELECT YEAR(`Date`)AS `Year`,MONTHNAME(`Date`) AS `Month` ,ROUND(SUM(Total_Cost),2) AS Total_Sales 
FROM retail_staging2
WHERE MONTH(`Date`) BETWEEN 1 AND 5 
GROUP BY `Year`, `Month`
ORDER BY `Year`,FIELD(`Month`, 
	'January','February','March','April','May','June',
    'July','August','September','October','November','December');

-- Amount of transaction made
-- Transaction made for each year 
SELECT YEAR(`Date`) AS `Year`, COUNT(Transaction_ID) AS Transaction_made
FROM retail_staging2
GROUP BY `Year`
ORDER BY `Year`; 

-- Transaction Made each month of the years
SELECT MONTH(`Date`) AS Num,YEAR(`Date`) AS `Year` ,MONTHNAME(`Date`)AS `Month`, COUNT(Transaction_ID) AS Total_transaction_made
FROM retail_staging2
GROUP BY Num,`Year`,`Month`
ORDER BY Num,`Year`,`Month`;

-- Transaction Made at specified month range per year
SELECT YEAR(`Date`)AS `Year`, COUNT(Transaction_ID) AS Total_transaction_made
FROM retail_staging2
WHERE MONTH(`Date`) BETWEEN 1 AND 5 
GROUP BY `Year`
ORDER BY `Year`;


-- sales per City over the year 
SELECT YEAR(`Date`) AS `Year`, City , ROUND(SUM(Total_Cost),0) AS Sales
FROM retail_staging2
GROUP BY `Year`,City
ORDER BY `Year`;

-- Top 3 Cities with most sales each year using windows and CTE 
WITH City_sales(years,City,Total_Cost) AS
(	
	SELECT YEAR(`Date`) AS `Year`, City , ROUND(SUM(Total_Cost),0) AS Sales
	FROM retail_staging2
	GROUP BY `Year`,City
	ORDER BY `Year`
    
),
City_sales_rank AS(
	
    SELECT *,
    DENSE_RANK() OVER(PARTITION BY years ORDER BY Total_Cost DESC) AS Ranks
    FROM City_sales
)
SELECT * FROM City_sales_rank
WHERE Ranks <=3;

-- Average spent per Payment Method
SELECT Payment_Method, ROUND(AVG(Total_Cost),2) AS avg_spent
FROM retail_staging2
GROUP BY Payment_Method;


-- For Product comparisson analysis 
-- Most sold product each season
SELECT rs.Season,
ct.Product,
COUNT(*) AS Most_Sold_Product 
FROM category_staging2 ct
JOIN retail_staging2 rs
	ON ct.Transaction_ID=rs.Transaction_ID
GROUP BY rs.Season, ct.Product
ORDER BY rs.Season, Most_Sold_Product  DESC
;

-- using CTE to identify most sold products over 900 each season 
WITH seasonal AS 
(
	SELECT rs.Season,
	ct.Product,
	COUNT(*) AS Most_Sold_Product 
	FROM category_staging2 ct
	JOIN retail_staging2 rs
	ON ct.Transaction_ID=rs.Transaction_ID
	GROUP BY rs.Season, ct.Product
	ORDER BY rs.Season, Most_Sold_Product  DESC
)
SELECT * FROM seasonal 
WHERE Most_Sold_Product >= 900;

-- Total transactions made per Product Category  
SELECT rs.Season,
ct.Category,
COUNT(*) AS total_transactions_made 
FROM category_staging2 ct
JOIN retail_staging2 rs
	ON ct.Transaction_ID=rs.Transaction_ID
GROUP BY rs.Season, ct.Category
ORDER BY rs.Season, total_transactions_made DESC
;

-- 3 Most sold Products per Month 
WITH monthly_sold AS 
(
	SELECT MONTHNAME(rt.`Date`) AS`Month`, ct.Product, COUNT(rt.Transaction_ID) AS Sold,
    DENSE_RANK() OVER(PARTITION BY MONTHNAME(rt.`Date`) ORDER BY COUNT(rt.Transaction_ID) DESC) AS ranks
	FROM retail_staging2 rt
	JOIN category_staging2 ct
		ON rt.Transaction_ID=ct.Transaction_ID
	GROUP BY `Month`, ct.Product
    ORDER BY Sold DESC

)
SELECT `Month`, Product, Sold
FROM monthly_sold
WHERE ranks <= 3
ORDER BY FIELD(`Month`, 
	'January','February','March','April','May','June',
    'July','August','September','October','November','December'); 



-- store type that has the most transaction made per city
SELECT City, Store_Type, 
COUNT(*) AS Transactions
FROM retail_staging2
GROUP BY City, Store_Type
ORDER BY Transactions DESC;

-- Store that has most sales over the years 
SELECT YEAR(`Date`) AS `Year`, Store_Type, ROUND(SUM(Total_Cost),0) AS total_sales  
FROM retail_staging2
GROUP BY `Year`, Store_Type
ORDER BY `Year`, total_sales DESC
;

-- Top 1 most selling stores each year using CTE and windows 
WITH stores AS
(
	SELECT YEAR(`Date`) AS `Year`, Store_Type, ROUND(SUM(Total_cost),0) AS total_sales  
	FROM retail_staging2
	GROUP BY `Year`, Store_Type
	ORDER BY `Year`, total_sales DESC
) ,
store_rank AS
(
	SELECT *,
    DENSE_RANK()OVER(PARTITION BY `Year` ORDER BY total_sales DESC) AS ranks
    FROM stores
)
SELECT * 
FROM store_rank
WHERE ranks = 1;

-- Top store that has the most total transaction each year and what city
WITH Store_row (years,City, Store_Type, Transactions) AS
(
	SELECT YEAR(`Date`) AS `Year`,City, Store_Type, 
	COUNT(*) AS Transactions
	FROM retail_staging2
	GROUP BY `Year`, City, Store_Type
	ORDER BY Transactions DESC 
),
Store_rank AS
(
	SELECT *,
    DENSE_RANK() OVER(PARTITION BY years ORDER BY Transactions DESC ) AS Ranks
    FROM Store_row
     
    
)
SELECT * 
FROM Store_rank
WHERE Ranks = 1;

-- Total Transactions made per store over the year on specified Cities.
SELECT YEAR(`Date`) AS `Year`,City, Store_Type, 
COUNT(*) AS Transactions
FROM retail_staging2
WHERE City='Chicago' 
GROUP BY `Year`, City, Store_Type
ORDER BY `Year`;

-- store type that has the most sales made per city
SELECT City, Store_Type, ROUND(SUM(Total_Cost),0) AS total_sales
FROM retail_staging2
GROUP BY City, Store_Type
ORDER BY total_sales DESC
;


-- Top-Performing Store by City and Store Type
WITH stores (City, Store_Type, total_sales) AS
(
	SELECT City, Store_Type, ROUND(SUM(Total_Cost),0) AS total_sales
	FROM retail_staging2
	GROUP BY City, Store_Type
	ORDER BY total_sales DESC
),
store_rank AS
(
	SELECT *,
    DENSE_RANK() OVER(PARTITION BY Store_Type ORDER BY total_sales DESC) AS ranks 
    FROM stores 
)
SELECT * 
FROM store_rank
WHERE ranks = 1
;

-- Most Used Promotion/Discount Type Applied every transaction 
SELECT Promotion AS Discount_type, COUNT(*) AS Usages
FROM retail_staging2
WHERE Discount_Applied= 'True'
GROUP BY Promotion
ORDER BY Usages DESC;

-- Total usages of discount types per year
SELECT YEAR(`Date`) As Years ,Promotion AS Discount_type, COUNT(*) AS Usages
FROM retail_staging2
WHERE Discount_Applied= 'True'
GROUP BY Years, Promotion
ORDER BY Years;

-- Most used Discount Type over the years Using windows and CTE
WITH promotions AS
(
	SELECT YEAR(`Date`) As Years ,Promotion AS Discount_type, COUNT(*) AS Usages
	FROM retail_staging2
	WHERE Discount_Applied= 'True'
	GROUP BY Years, Promotion
	ORDER BY Years
),
pr_ranks AS
(
	SELECT *, 
    DENSE_RANK()OVER(PARTITION BY Years ORDER BY Usages DESC) AS ranks
    FROM promotions

)
SELECT * 
FROM pr_ranks
WHERE ranks = 1;


-- Upon the process of EDA 
-- Summary: Retail sales remained stable from 2020–2023, peaking during 2020 due to essential demand.
-- Seattle led in 2020 sales, while Atlanta dominated in 2021–2022, showing strong recovery.
-- Store trends shifted from Supermarkets (2020) to Specialty and Pharmacy by 2023–2024.
-- Peak sales occurred midday, with consistent product and seasonal performance.
-- Overall, the data shows post-pandemic stability and steady consumer spending recovery.












