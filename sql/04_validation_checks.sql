-- 04: Validation. Compare each result with the expected value in the comment.
USE online_retail_project;

SELECT COUNT(*) FROM master_final;                       -- 1,033,031
SELECT MIN(invoice_day), MAX(invoice_day) FROM master_final;   -- 2009-12-01 to 2011-12-09
SELECT SUM(revenue IS NULL), SUM(invoice_day IS NULL) FROM master_final;  -- 0, 0

-- Row labels
SELECT row_type, COUNT(*) AS rows_n FROM master_final GROUP BY row_type ORDER BY rows_n DESC;
-- sale 1,003,214 | cancellation 17,914 | non_product 5,974
-- neg_qty_no_C 3,362 | zero_price 2,566 | adjustment 1

-- Headline numbers (sales rows only)
SELECT ROUND(SUM(revenue))               AS sales_revenue,  -- ~19,642,692
       SUM(quantity)                     AS units_sold,     -- ~11,187,774
       COUNT(DISTINCT invoice)           AS orders,         -- 39,516
       COUNT(DISTINCT customer_id)       AS customers       -- 5,852
FROM v_sales;

-- Returns
SELECT ROUND(-SUM(revenue)) AS return_value,   -- ~716,426
       -SUM(quantity)       AS units_returned, -- ~467,739
       COUNT(*)             AS cancellation_lines  -- 17,914
FROM v_returns;

-- 25 months, 2009-12 to 2011-12 (2011-12 is partial)
SELECT year_month_key, COUNT(*) FROM v_sales GROUP BY 1 ORDER BY 1;
