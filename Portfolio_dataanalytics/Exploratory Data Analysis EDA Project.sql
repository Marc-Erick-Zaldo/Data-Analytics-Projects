-- Exploratory Data Analysis EDA

-- Top 3 companies that has the most laidoffs 
SELECT company,YEAR(`date`), industry, total_laid_off, country
FROM layoffs_staging2
WHERE total_laid_off IN (SELECT total_laid_off FROM (
SELECT DISTINCT total_laid_off
FROM layoffs_staging2
ORDER BY total_laid_off DESC
LIMIT 3) AS top_3);

-- Sum of the laidoffs per company, Industry, Country, and Year

-- Company
SELECT company,SUM(total_laid_off) AS Overall_laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- Industry
SELECT industry,SUM(total_laid_off) AS Overall_laid_off
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- Country
SELECT country,SUM(total_laid_off) AS Overall_laid_off
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- Year
SELECT YEAR(`date`),SUM(total_laid_off) AS Overall_laid_off
FROM layoffs_staging2
WHERE YEAR(`date`) IS NOT NULL
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

-- Sum of the laidoffs over the month
SELECT SUBSTRING(`date`,1,7) AS `Month`, SUM(total_laid_off) 
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `Month`
ORDER BY 1 ASC;

-- Rolling total per Laidoffs Using CTE 
WITH Overall AS 
(
	SELECT SUBSTRING(`date`,1,7) AS `Month`, SUM(total_laid_off) AS total_layoffs 
	FROM layoffs_staging2
	WHERE SUBSTRING(`date`,1,7) IS NOT NULL
	GROUP BY `Month`
	ORDER BY 1 ASC	
)
SELECT `Month`, total_layoffs 
,SUM(total_layoffs) OVER(ORDER BY `Month`) AS Rolling_total
FROM Overall;

-- Total laidoff of companies per year 
SELECT company,YEAR(`date`) AS `Year`,SUM(total_laid_off) AS Overall_laid_off
FROM layoffs_staging2
GROUP BY company,`Year`
ORDER BY 3 DESC;

-- Adding Ranks using CTE and Windows
WITH company_year (company, years, total_laid_off) AS
(
	SELECT company,YEAR(`date`) AS `Year`,SUM(total_laid_off) AS Overall_laid_off
	FROM layoffs_staging2
    WHERE YEAR(`date`) IS NOT NULL
	GROUP BY company,`Year`
),
Company_year_rank AS (
SELECT *,
DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS Ranks
FROM company_year
)
SELECT *
FROM Company_year_rank
WHERE Ranks <=5; 

SELECT * 
FROM layoffs_staging2;

