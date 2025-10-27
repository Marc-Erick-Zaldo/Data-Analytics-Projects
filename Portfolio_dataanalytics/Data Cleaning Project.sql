-- Data Cleaning Project 

SELECT *
FROM layoffs;

-- Data cleaning 
-- 1 Removing duplicates 
-- 2 Standarize Data
-- 3 Null Values or blank values
-- 4 remove any uncecesarry columns 

-- Staging part
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT * 
FROM layoffs;

-- Dealing with duplicates 
-- 1 identifying duplicates using windows and CTE 
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 
`date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

WITH duplicates AS
(
	SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 
	`date`, stage, country, funds_raised_millions) AS row_num
	FROM layoffs_staging
)
SELECT *
FROM duplicates
WHERE row_num > 1;

-- Checking each identified duplicates
SELECT * 
FROM layoffs_staging
WHERE company = 'Casper';

SELECT *
FROM layoffs_staging;

-- Creating new table to be able to delete the duplicates 
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- importing window partition as a table content for staging2
INSERT INTO layoffs_staging2
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 
	`date`, stage, country, funds_raised_millions) AS row_num
	FROM layoffs_staging;
    
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Deleting duplicates
DELETE 
FROM layoffs_staging2
WHERE row_num > 1;

SELECT *
FROM layoffs_staging2;
-- End of dealing with duplicates 

-- Standardizing data Objective
-- 1 dealing with white spaces 
-- 2 identifying different data that has same values
-- 3 Converting raw date data from text to actual date type

-- dealing with white spaces using TRIM 
SELECT company, TRIM(company)
FROM layoffs_staging2
;
UPDATE layoffs_staging2
SET company= TRIM(company);

-- Dealing with different data that has same values using TRIM with TRAILING for typo
-- Used DISTINCT to identify different values and analyze every entries with inconsistent naming
-- and standardized these variations. Example (Crypto vs. Cryptocurrency)
SELECT DISTINCT industry
FROM layoffs_staging2
;
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1; 

-- Converting the date from text to a real time value
SELECT `date`
FROM layoffs_staging2
;
UPDATE layoffs_staging2
SET `date`= STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE
;
SELECT *
FROM layoffs_staging2;

-- Dealing with NULL values or blank values Objectives
-- Identifying Blanks and Nulls
-- Checking Null and blank values for simillar company that has complete data entry 
-- Converting Blank values to NULL
-- Using SELF JOIN to fill those blank values
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Starting with Null and blank value on industry 
SELECT * 
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

SELECT * -- Finding a match for a blank value includes in depth checking 
FROM layoffs_staging2
WHERE company= 'Airbnb';

-- Making all blank value as NULL values (convertion)
UPDATE layoffs_staging2
SET industry = NULL 
WHERE industry = '';

-- SELF JOIN method to match the industry tables that has same company
-- this method is to fill all the blank values of the same company that has industry
-- value on it since its the same  
SELECT t1.industry, t2.industry 
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company=t2.company
WHERE (t1.industry IS NULL OR t1.industry='')
AND t2.industry IS NOT NULL;

-- Updating just copying the method above but since blanks is converted to null update the 
-- WHERE function 
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company=t2.company 
SET t1.industry = t2.industry
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL;


-- Dealing and deleting unecessary data
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Deleting the temporary column the 'row_num' it only used as a basis on duplicates
SELECT *
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;


-- Comparing Raw from a clean data
SELECT *
FROM layoffs_staging2
LIMIT 50;

SELECT *
FROM layoffs
LIMIT 50;







