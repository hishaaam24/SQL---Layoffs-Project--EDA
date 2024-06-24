#DATA_CLEANING

SELECT * FROM layoffs;

-- We will not work on the main Data Set so as to not corrupt anything
-- We will make a copy of the same Data Set so we can work and query on it.

CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT * FROM layoffs_staging;
 
#Inserting values into the new table we created.
INSERT layoffs_staging
SELECT * FROM 
layoffs;

#Using Row number to assign unique value to each row.
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company,industry,total_laid_off,percentage_laid_off,`date`) AS row_num
FROM layoffs_staging;


#Using CTE to find the duplicates.
with cte_duplicates AS (
select *,
row_number() over (partition by company, location ,industry ,percentage_laid_off ,`date` ,stage ,country , funds_raised_millions) as row_num
from layoffs_staging
)
select * from cte_duplicates
where row_num > 1;

-- As we cant directly delete the duplicate values from this table, we have to create a new table with the exact same data and adding 'row_num' as new column.
#Creating New table
CREATE TABLE `layoffs_staging2` (
    `company` TEXT,
    `location` TEXT,
    `industry` TEXT,
    `total_laid_off` INT DEFAULT NULL,
    `percentage_laid_off` TEXT,
    `date` TEXT,
    `stage` TEXT,
    `country` TEXT,
    `funds_raised_millions` INT DEFAULT NULL,
    `row_num` INT
)  ENGINE=INNODB DEFAULT CHARSET=UTF8MB4 COLLATE = UTF8MB4_0900_AI_CI;

#Inserting values into this new Table and adding new column with row_number() for unique identification.
INSERT INTO layoffs_staging2
(select *,
row_number() over (partition by company, location ,industry ,percentage_laid_off ,`date` ,stage ,country , funds_raised_millions) as row_num
from layoffs_staging
);

#Deleting the duplicate Values.
DELETE  
FROM layoffs_staging2
WHERE row_num>1;

SELECT * FROM layoffs_staging2;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#STANDARDIZE_THE_DATA

#Removing empty spaces.
UPDATE layoffs_staging2
SET company = TRIM(company);

select * from layoffs_staging2;

#Checking for naming issue in Industry.
select distinct industry
from layoffs_staging2
order by 1;

#Setting the naming scheme correctly( there were 3 names for the same industry -- crypto, cryptocurrency and crypto currency).
UPDATE layoffs_staging2
SET industry = 'Crypto'
where industry like 'Crypto%';

#Checking for any issues in country.
select distinct country
from layoffs_staging2
order by 1;

#Updating country name correctly.(-- removed the fullstop(.) at the end of united states causing it to appear twice as United states--)
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' from country); 

#Converting date orientation to corrrect format so as to update the format.
UPDATE layoffs_staging2
SET `date` = str_to_date(`date`,'%m/%d/%Y'); 

ALTER TABLE layoffs_staging2
MODIFY column `date` DATE; -- Changes the format of the column from str/text to date--

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#DEALING_WITH_NULLS

#Checking for any null or empty values in industry.
select *
from layoffs_staging2
where industry is null or industry = '';

select * from
layoffs_staging2
where company = 'airbnb';

-- After checking the null values we are able to populate them with the help of company and location --
-- To do this we need to first set blank all spaces to null so we can populate it and avoid any errors -- 

#Setting blanks to NULL.
UPDATE layoffs_staging2
SET industry = NULL
where industry = ''; 

#Checking for the relation between the company and location.
select t1.company,t1.industry, t2.industry
from layoffs_staging2 t1
join layoffs_staging2 t2
	ON t1.company = t2.company
   AND t1.location =t2.location
where (t1.industry is NULL)
AND t2.industry is not null;

#populating the nulls with appropriate values
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
where t1.industry is NULL 
AND t2.industry is not NULL;


-- Checking the total_laid_off and percentage_laid_off--
-- If they are both NULLS, we have no use for them--

#Removing nulls.
DELETE
from layoffs_staging2
where total_laid_off is NULL 
and percentage_laid_off is NULL;

-- Now the row_num column which we used to idnetify duplicates is of no use anymore--

#Removing row_num column.
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

Select * from layoffs_staging2;
