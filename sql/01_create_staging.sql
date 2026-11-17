-- 01: Create the database and two text-only staging tables.
-- All columns are text on purpose, so nothing is lost or changed on import.
CREATE DATABASE IF NOT EXISTS online_retail_project;
USE online_retail_project;

DROP TABLE IF EXISTS staging_2009_2010;
DROP TABLE IF EXISTS staging_2010_2011;

CREATE TABLE staging_2009_2010 (
    invoice      VARCHAR(20),
    stock_code   VARCHAR(20),
    description  TEXT,
    quantity     VARCHAR(20),
    invoice_date VARCHAR(30),
    price        VARCHAR(30),
    customer_id  VARCHAR(20),
    country      VARCHAR(100)
);
CREATE TABLE staging_2010_2011 LIKE staging_2009_2010;

-- Next: run python/01_import_csv_to_mysql.py, then check the counts:
SELECT '2009-2010' AS dataset, COUNT(*) AS total_rows FROM staging_2009_2010
UNION ALL
SELECT '2010-2011', COUNT(*) FROM staging_2010_2011;
-- Expected: 518,593 and 536,640
