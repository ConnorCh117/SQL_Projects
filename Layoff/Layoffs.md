```Sql
-- Data Cleaning Project

-- 1. Remove duplicates 
-- 2. Standardize the data 
-- 3. Address null values or blank values 
-- 4. Remove any irrelevant columns or rows 

SELECT *
FROM layoffs;

-- Removing duplicates
-- Create a new table and input data instead of raw data doing all the cleaning 

CREATE TABLE layoffs_staging 
LIKE layoffs; 

INSERT INTO layoffs_staging
SELECT *
FROM layoffs; 

-- Check all the duplicate rows
WITH duplicate_cte AS (
    SELECT *, 
           ROW_NUMBER() OVER (
               PARTITION BY company, location, industry, total_laid_off, `date`, stage, country, funds_raised_millions
           ) AS row_num
    FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1; 

-- Create a new table to contain data after removing duplicates 
CREATE TABLE `layoffs_staging2` (
    `company` TEXT,
    `location` TEXT,
    `industry` TEXT,
    `total_laid_off` BIGINT DEFAULT NULL,
    `percentage_laid_off` TEXT,
    `date` TEXT,
    `stage` TEXT,
    `country` TEXT,
    `funds_raised_millions` INT DEFAULT NULL,
    `row_num` INT 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *, 
       ROW_NUMBER() OVER (
           PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
       ) AS row_num
FROM layoffs_staging;

DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- Standardizing data 

SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

SELECT DISTINCT industry 
FROM layoffs_staging2
ORDER BY 1;

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'crypto%';

UPDATE layoffs_staging2 
SET industry = 'crypto'
WHERE industry LIKE 'crypto%';

SELECT DISTINCT industry 
FROM layoffs_staging2;

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

SELECT `date`
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Check layoff-related columns with no value
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL 
OR industry = '';

-- Transform empty data to NULL value for better standardization 
UPDATE layoffs_staging2
SET industry = NULL 
WHERE industry = '';

SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

SELECT *
FROM layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2 
    ON t1.company = t2.company AND t1.location = t2.location 
WHERE t1.company = 'Airbnb';

SELECT *
FROM layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2 
    ON t1.company = t2.company AND t1.location = t2.location 
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
    ON t1.company = t2.company AND t1.location = t2.location
SET t1.industry = t2.industry 
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

SELECT *
FROM layoffs_staging2
WHERE company LIKE 'bally%';

-- Delete empty data
SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;

DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;

-- Remove irrelevant column
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT * 
FROM layoffs_staging2;

-- Exploratory Data Analysis 

-- Find the max laid-off in one go
SELECT MAX(total_laid_off)
FROM layoffs_staging2;

-- Find out which company laid off all of their employees
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1 
ORDER BY total_laid_off DESC;

-- Order by funds_raised_millions to see how big some of these companies were
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- Companies with the biggest single layoff
SELECT company, total_laid_off
FROM layoffs_staging2
ORDER BY 2 DESC
LIMIT 5;

-- Companies with the biggest aggregated layoff
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company 
ORDER BY 2 DESC
LIMIT 10;

-- By location
SELECT location, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY location
ORDER BY 2 DESC
LIMIT 10;

-- By country
SELECT country, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- By industry
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry 
ORDER BY 2 DESC;

-- By year 
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
WHERE date IS NOT NULL
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

-- By stage 
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

-- By year and month
SELECT SUBSTRING(`date`, 1, 7) AS `month`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL 
GROUP BY `month`
ORDER BY 1 ASC;

-- Calculate rolling sum of layoffs over months
WITH sum_layoff AS (
    SELECT SUBSTRING(`date`, 1, 7) AS `month`, SUM(total_laid_off) AS total_off
    FROM layoffs_staging2
    WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL 
    GROUP BY `month`
    ORDER BY 1 ASC 
)
SELECT `month`, 
       SUM(total_off) OVER (ORDER BY `month`) AS rolling_total 
FROM sum_layoff;

-- Which company in which year had the biggest layoffs?
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;

-- Which company had the biggest layoffs within each year?
WITH company_years AS (
    SELECT company, YEAR(`date`) AS years, SUM(total_laid_off) AS t_lf
    FROM layoffs_staging2
    GROUP BY company, YEAR(`date`)
    ORDER BY 3 DESC
), 
company_ranking_years AS (
    SELECT *,
           DENSE_RANK() OVER (PARTITION BY years ORDER BY t_lf DESC) AS ranking 
    FROM company_years 
    WHERE years IS NOT NULL
)
SELECT *
FROM company_ranking_years
WHERE ranking <= 5;
