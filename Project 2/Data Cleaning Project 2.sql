-- Data Cleaning 
-- This Dataset is from Kaggle 
-- Objectives
-- Checking and dealing with Duplicates
-- Standardized Data and Categorize data 
-- Transforming Data 
-- Checking and Dealing with NULL and Blank Values 
-- Creating a seperate table useful for doing Exploratory Data Analysis (EDA)

-- Staging Part  - I always use this to avoid making changes to the original data 
CREATE TABLE retail_staging
LIKE retail_transactions_dataset;

INSERT retail_staging
SELECT *
FROM retail_transactions_dataset;

-- Checking for Duplicates using Windows and CTE 
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY Transaction_ID) AS row_num
FROM retail_staging;

WITH duplicates AS 
(
	SELECT *, 
	ROW_NUMBER() OVER(
	PARTITION BY Transaction_ID) AS row_num
	FROM retail_staging
)
SELECT *
FROM duplicates
WHERE row_num > 1; -- At this part it shows that the table has no duplicates 


-- Standardized Data
SELECT * 
FROM retail_staging
;
-- Starts by trimming
UPDATE retail_staging
SET Product= REPLACE(REPLACE(Product, '[', ''),']','');

UPDATE retail_staging
SET Product = REPLACE(Product, "'", '');

UPDATE retail_staging
SET Product = TRIM(Product);

UPDATE retail_staging
SET Total_Items = CHAR_LENGTH(Product) - CHAR_LENGTH(REPLACE(Product, ',', '')) + 1; -- Fixing Innacurate Total_Items

SELECT DISTINCT Promotion
FROM retail_staging;

SELECT DISTINCT Product
FROM retail_staging
ORDER BY Product;

SELECT Product, COUNT(*) AS total_units
FROM retail_staging
GROUP BY Product
ORDER BY total_units DESC;

-- Seperating the Products to easily identify and categorized it 
CREATE TABLE numbers (n INT); -- Creating a helper table 
INSERT INTO numbers (n) VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10);

CREATE TABLE list_items AS
SELECT 
	t.Transaction_ID, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX
    (t.Product, ',', n.n), ',', -1)) AS product
    FROM retail_staging t
    JOIN numbers n
		ON n.n <=10;

SELECT DISTINCT product -- By making the table it can show all the products listed on the dataset using DISTINCT
FROM retail_transaction.list_items
ORDER BY product;

-- Adding new Column and categorize each items 
ALTER TABLE list_items
ADD COLUMN category VARCHAR(255);
UPDATE list_items
SET category = CASE
    -- Food & Beverages
    WHEN Product IN ('Apple','Banana','Beef','Bread','Butter','Canned Soup','Carrots','Cereal',
                     'Cereal Bars','Cheese','Chicken','Chips','Eggs','Honey','Ice Cream','Jam',
                     'Ketchup','Mayonnaise','Milk','Mustard','Olive Oil','Onions','Orange','Pancake Mix',
                     'Pasta','Peanut Butter','Pickles','Potatoes','Rice','Salmon','Shrimp','Soda','Spinach',
                     'Syrup','Tea','Tuna','Water','Yogurt','BBQ Sauce') THEN 'Food & Beverages'

    -- Cleaning Supplies
    WHEN Product IN ('Air Freshener','Broom','Cleaning Rags','Cleaning Spray','Dish Soap',
                     'Dustpan','Laundry Detergent','Mop','Paper Towels','Sponges',
                     'Trash Bags','Trash Cans','Toilet Paper','Vinegar') THEN 'Cleaning Supplies'

    -- Personal Care
    WHEN Product IN ('Bath Towels','Deodorant','Diapers','Feminine Hygiene Products',
                     'Hair Gel','Hand Sanitizer','Shampoo','Shaving Cream','Shower Gel',
                     'Soap','Toothbrush','Toothpaste','Tissues') THEN 'Personal Care'

    -- Kitchen & Dining
    WHEN Product IN ('Dishware','Coffee','Power Strips') THEN 'Kitchen & Dining'

    -- Home & Garden
    WHEN Product IN ('Extension Cords','Garden Hose','Iron','Ironing Board',
                     'Lawn Mower','Light Bulbs','Plant Fertilizer','Vacuum Cleaner') THEN 'Home & Garden'

    -- Catch-all
    ELSE 'Miscellaneous'
END;


SELECT DISTINCT product 
FROM list_items
WHERE category= 'Food & Beverages';

SELECT category, COUNT(*) AS num_items
FROM list_items
GROUP BY category
ORDER BY num_items DESC;
-- The categorizing will be done in the last step

-- Fixing and changing Innacurate data 
SELECT Promotion, Discount_Applied, COUNT(*)
FROM category_staging
GROUP BY Promotion, Discount_Applied;

UPDATE retail_staging
SET Promotion= 'Others'
WHERE Promotion = 'None' AND Discount_Applied = 'True';

-- Transforming Data and seperating date and Time
SELECT `Date`
FROM retail_staging;

UPDATE retail_staging
SET `Date`= STR_TO_DATE(`Date`, '%Y-%m-%d %H:%i:%s'); -- Converting String to date and time

ALTER TABLE retail_staging
ADD COLUMN _time TIME AFTER `Date`; -- Creating new column for Time 

UPDATE retail_staging
SET _time= TIME(`Date`); -- Copying the time from Date column and transfer to the Time column 

UPDATE retail_staging
SET `Date`= DATE(`Date`); -- Removing the Time and make it as Date 

ALTER TABLE retail_staging
MODIFY COLUMN `Date` DATE; -- Modifying/ Changing its data type for Time and Date Column

ALTER TABLE retail_staging
MODIFY COLUMN _time TIME;

ALTER TABLE retail_staging
CHANGE _time `Time` TIME; -- Renaming the Time column 

-- End of Standardizing the Data 

-- Chekcing and Dealing with Null and blank values 

-- Searching for blank and NULL values per column 
SELECT *
FROM retail_staging
WHERE Promotion IS NULL 
OR Promotion = '';

-- No Blank or Null values for this Dataset 

-- Last part Is Creating another table with categorize products that will Be useful for EDA and editing and removing unecessary table 
-- for the category Products table
CREATE TABLE category_staging AS
SELECT 
    t.Transaction_ID,
    DATE(t.Date) AS Date,
    TIME(t.Date) AS Time,
    TRIM(SUBSTRING_INDEX(
        SUBSTRING_INDEX(t.Product, ',', n.n),
    ',', -1)) AS Product,
    t.Total_cost,
    t.Total_Items,
    t.Payment_Method,
    t.City,
    t.Store_Type,
    t.Discount_Applied,
    t.Customer_Category,
    t.Season,
    t.Promotion
FROM retail_staging t
JOIN numbers n
    ON n.n <= LENGTH(t.Product) - LENGTH(REPLACE(t.Product, ',', '')) + 1;

ALTER TABLE category_staging
ADD COLUMN Category VARCHAR(255) AFTER Product; 

-- Creating Product category Using Multiple Case
-- Food & Beverages
UPDATE category_staging
SET Category = CASE
    -- Food & Beverages
    WHEN Product IN ('Apple','Banana','Beef','Bread','Butter','Canned Soup','Carrots','Cereal',
                     'Cereal Bars','Cheese','Chicken','Chips','Eggs','Honey','Ice Cream','Jam',
                     'Ketchup','Mayonnaise','Milk','Mustard','Olive Oil','Onions','Orange','Pancake Mix',
                     'Pasta','Peanut Butter','Pickles','Potatoes','Rice','Salmon','Shrimp','Soda','Spinach',
                     'Syrup','Tea','Tuna','Water','Yogurt','BBQ Sauce','Tomatoes') THEN 'Food & Beverages'

    -- Cleaning Supplies
    WHEN Product IN ('Air Freshener','Broom','Cleaning Rags','Cleaning Spray','Dish Soap',
                     'Dustpan','Laundry Detergent','Mop','Paper Towels','Sponges',
                     'Trash Bags','Trash Cans','Toilet Paper','Vinegar') THEN 'Cleaning Supplies'

    -- Personal Care
    WHEN Product IN ('Bath Towels','Deodorant','Diapers','Feminine Hygiene Products',
                     'Hair Gel','Hand Sanitizer','Shampoo','Shaving Cream','Shower Gel',
                     'Soap','Toothbrush','Toothpaste','Tissues') THEN 'Personal Care'

    -- Kitchen & Dining
    WHEN Product IN ('Dishware','Coffee','Power Strips') THEN 'Kitchen & Dining'

    -- Home & Garden
    WHEN Product IN ('Extension Cords','Garden Hose','Iron','Ironing Board',
                     'Lawn Mower','Light Bulbs','Plant Fertilizer','Vacuum Cleaner') THEN 'Home & Garden'

    -- Catch-all
    ELSE 'Miscellaneous'
END;

-- making Backup duplicates to test for EDA 
CREATE TABLE category_staging2
LIKE category_staging;

INSERT category_staging2
SELECT *
FROM category_staging;

CREATE TABLE retail_staging2
LIKE retail_staging;

INSERT retail_staging2
SELECT *  
FROM retail_staging;

SELECT *
FROM retail_staging2;

SELECT *
FROM category_staging2;

-- removing uncecessary column for the table 
ALTER TABLE category_staging2
DROP COLUMN `Time`,
DROP COLUMN `DATE`,
DROP COLUMN Total_cost,
DROP COLUMN Total_Items,
DROP COLUMN Payment_Method,
DROP COLUMN City,
DROP COLUMN Store_Type,
DROP COLUMN Discount_Applied,
DROP COLUMN Customer_Category,
DROP COLUMN Season,
DROP COLUMN Promotion;

ALTER TABLE retail_staging2
DROP COLUMN Product;

SELECT *
FROM retail_staging;

SELECT *
FROM list_items;









