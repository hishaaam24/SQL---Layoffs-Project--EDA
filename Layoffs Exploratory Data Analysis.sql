#EXPLORATORY DATA ANALYSIS 

SELECT * FROM layoffs_staging2;

#Checking for the Maximum laid off.
SELECT MAX(total_laId_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

#Checking the companies with the most funding and that had 100% layoff.
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;


#checking per year the total number of layoffs by each company.
SELECT 
    company,
    YEAR(`date`) AS `Year`,
    SUM(total_laid_off) AS total_laid_off
FROM
    layoffs_staging2
GROUP BY company , YEAR(`date`)
ORDER BY 3 DESC;

#Checking total layoffs each month.
select SUBSTRING(`date`,1,7) as `Month`, SUM(total_laid_off) as total_off
from layoffs_staging2
where SUBSTRING(`date`,1,7) IS NOT NULL
group by `MONTH`
order by 1 asc;

#Checking total layoff by each country.
SELECT country,SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;


-- We will now look at the Rolling total through out the months.
-- This will give us the sum of 'total_laid_off' in the sequential order of the months
-- using CTE.

#Checking Rolling Total
WITH rolling_total AS
(select SUBSTRING(`date`,1,7) as `Month`, SUM(total_laid_off) as total_off
from layoffs_staging2
where SUBSTRING(`date`,1,7) IS NOT NULL
group by `MONTH`
order by 1 asc)

select `Month`, total_off, sum(total_off) over(order by `Month`) as Rolling_Total
from rolling_total;

-- Now we can look at the Top 5 companies and their industry that has layed off the most people per year. 
-- Using CTE's.
with company_year (company, years, industry, total_laid_off) AS
(
SELECT company,YEAR(`date`), industry,  SUM(total_laid_off) 
FROM layoffs_staging2
GROUP BY company, industry, YEAR(`date`)
), company_year_ranking AS
(select *,
dense_rank() over(partition by years order by total_laid_off desc) as RANKING
from company_year
where years is not null
)
select* from company_year_Ranking
where RANKING <= 5;

