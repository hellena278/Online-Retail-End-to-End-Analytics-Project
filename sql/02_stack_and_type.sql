-- 02: Stack both years and convert text columns to proper data types.
USE online_retail_project;

DROP TABLE IF EXISTS master_online_retail;
CREATE TABLE master_online_retail AS
SELECT '2009-2010' AS dataset_period, s.* FROM staging_2009_2010 s WHERE TRIM(invoice) <> ''
UNION ALL
SELECT '2010-2011', s.* FROM staging_2010_2011 s WHERE TRIM(invoice) <> '';
-- Expected: 1,055,233 rows

-- Test the date format first. The right format returns 0 NULLs.
-- (The source dates are month/day/year with seconds.)
SELECT
  SUM(STR_TO_DATE(TRIM(invoice_date), '%m/%d/%Y %H:%i:%s') IS NULL) AS mdy_nulls,
  SUM(STR_TO_DATE(TRIM(invoice_date), '%d/%m/%Y %H:%i:%s') IS NULL) AS dmy_nulls
FROM master_online_retail;

DROP TABLE IF EXISTS master_online_retail_typed;
CREATE TABLE master_online_retail_typed AS
SELECT
    dataset_period,
    TRIM(invoice)     AS invoice,
    TRIM(stock_code)  AS stock_code,
    TRIM(description) AS description,
    CAST(TRIM(quantity) AS SIGNED) AS quantity,
    STR_TO_DATE(TRIM(invoice_date), '%m/%d/%Y %H:%i:%s') AS invoice_date,
    CAST(REPLACE(REPLACE(TRIM(price), '$', ''), ',', '') AS DECIMAL(12,4)) AS price,
    -- blank customer IDs become real NULLs; "13085.0" becomes 13085
    CASE WHEN TRIM(customer_id) REGEXP '^[0-9]+(\\.0)?$'
         THEN CAST(SUBSTRING_INDEX(TRIM(customer_id), '.', 1) AS UNSIGNED) END AS customer_id,
    TRIM(REPLACE(country, '\r', '')) AS country
FROM master_online_retail;

-- Checks. Expected: 1,055,233 rows | 0 NULL dates | 242,865 NULL customers
-- | dates from 2009-12-01 to 2011-12-09
SELECT COUNT(*) AS total_rows,
       SUM(invoice_date IS NULL)  AS null_dates,
       SUM(customer_id IS NULL)   AS null_customers,
       MIN(invoice_date)          AS first_date,
       MAX(invoice_date)          AS last_date
FROM master_online_retail_typed;
