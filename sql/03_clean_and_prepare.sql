-- 03: Build master_final: remove the year overlap, standardize text,
-- add helper columns, label every row, and create analysis views.
-- Run one statement at a time. The UPDATEs take a few minutes.
USE online_retail_project;
SET SQL_SAFE_UPDATES = 0;

-- 1. Working copy (the typed table stays as a backup)
DROP TABLE IF EXISTS master_final;
CREATE TABLE master_final AS SELECT * FROM master_online_retail_typed;
ALTER TABLE master_final ADD COLUMN row_id INT AUTO_INCREMENT PRIMARY KEY FIRST;

-- 2. Remove the year overlap (1-9 Dec 2010 appears in both sheets).
-- An indexed lookup table keeps the DELETE fast.
DROP TABLE IF EXISTS overlap_inv;
CREATE TABLE overlap_inv (invoice VARCHAR(20) PRIMARY KEY);
INSERT INTO overlap_inv
SELECT DISTINCT invoice FROM master_final WHERE dataset_period = '2010-2011';

DELETE m FROM master_final m
JOIN overlap_inv o ON m.invoice = o.invoice
WHERE m.dataset_period = '2009-2010';
DROP TABLE overlap_inv;
-- Expected: 1,033,031 rows (22,202 overlap rows removed)

-- 3. Standardize text
UPDATE master_final SET
  description = UPPER(TRIM(description)),
  stock_code  = UPPER(TRIM(stock_code)),
  country = CASE TRIM(country)
      WHEN 'EIRE'  THEN 'Ireland'
      WHEN 'RSA'   THEN 'South Africa'
      WHEN 'USA'   THEN 'United States'
      WHEN 'Korea' THEN 'South Korea'
      ELSE TRIM(country) END;

-- 4. Helper columns
ALTER TABLE master_final
  ADD COLUMN invoice_day     DATE,
  ADD COLUMN invoice_year    SMALLINT,
  ADD COLUMN invoice_quarter TINYINT,
  ADD COLUMN invoice_month   TINYINT,
  ADD COLUMN year_month_key  CHAR(7),
  ADD COLUMN month_name      VARCHAR(10),
  ADD COLUMN day_of_week     VARCHAR(10),
  ADD COLUMN day_num         TINYINT,
  ADD COLUMN invoice_hour    TINYINT,
  ADD COLUMN is_weekend      TINYINT,
  ADD COLUMN revenue         DECIMAL(14,4),
  ADD COLUMN row_type        VARCHAR(20),
  ADD COLUMN has_customer    TINYINT;

UPDATE master_final SET
  invoice_day     = DATE(invoice_date),
  invoice_year    = YEAR(invoice_date),
  invoice_quarter = QUARTER(invoice_date),
  invoice_month   = MONTH(invoice_date),
  year_month_key  = DATE_FORMAT(invoice_date, '%Y-%m'),
  month_name      = MONTHNAME(invoice_date),
  day_of_week     = DAYNAME(invoice_date),
  day_num         = WEEKDAY(invoice_date) + 1,      -- 1 = Monday
  invoice_hour    = HOUR(invoice_date),
  is_weekend      = (WEEKDAY(invoice_date) >= 5),
  revenue         = quantity * price,
  has_customer    = (customer_id IS NOT NULL);

-- 5. Label every row (nothing is deleted; Power BI measures filter on row_type)
UPDATE master_final SET row_type = CASE
    WHEN invoice LIKE 'A%'                                        THEN 'adjustment'
    WHEN stock_code NOT REGEXP '^[0-9]{5}'                        THEN 'non_product'   -- POST, DOT, M, BANK CHARGES...
    WHEN invoice LIKE 'C%'                                        THEN 'cancellation'
    WHEN quantity < 0                                             THEN 'neg_qty_no_C'  -- damages, write-offs
    WHEN price <= 0 OR description IS NULL OR description = ''    THEN 'zero_price'
    ELSE 'sale' END;

-- 6. Analysis views
CREATE OR REPLACE VIEW v_sales AS
  SELECT * FROM master_final WHERE row_type = 'sale';
CREATE OR REPLACE VIEW v_sales_customers AS
  SELECT * FROM master_final WHERE row_type = 'sale' AND has_customer = 1;
CREATE OR REPLACE VIEW v_returns AS
  SELECT * FROM master_final WHERE row_type = 'cancellation';
