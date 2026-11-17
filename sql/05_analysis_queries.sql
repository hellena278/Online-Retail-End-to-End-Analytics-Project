-- 05: Analysis queries. Run on the views created in 03.
--   v_sales            sales rows only
--   v_sales_customers  sales rows with a customer ID
--   v_returns          cancellation rows
-- Revenue is gross sales unless a query says "net".
USE online_retail_project;

-- ------------------------------------------------------------
-- A. Data checks
-- ------------------------------------------------------------
-- Biggest orders by quantity (quantity must be numeric, see 02)
SELECT invoice, stock_code, description, quantity, invoice_date, price, revenue
FROM v_sales ORDER BY quantity DESC LIMIT 20;

-- Highest unit prices
SELECT invoice, stock_code, description, quantity, invoice_date, price, revenue
FROM v_sales ORDER BY price DESC LIMIT 20;

-- ------------------------------------------------------------
-- B. Headline numbers
-- ------------------------------------------------------------
SELECT ROUND(SUM(revenue), 2)                           AS sales_revenue,    -- ~19,642,692
       SUM(quantity)                                    AS units_sold,       -- ~11,187,774
       COUNT(DISTINCT invoice)                          AS orders,           -- 39,516
       COUNT(DISTINCT customer_id)                      AS customers,        -- 5,852
       ROUND(SUM(revenue) / COUNT(DISTINCT invoice), 2) AS avg_order_value   -- ~497.08
FROM v_sales;

-- ------------------------------------------------------------
-- C. Seasonality
-- ------------------------------------------------------------
-- Monthly revenue (2011-12 is partial: data ends 9 Dec 2011)
SELECT year_month_key,
       COUNT(DISTINCT invoice) AS orders,
       ROUND(SUM(revenue), 2)  AS revenue
FROM v_sales
GROUP BY year_month_key
ORDER BY year_month_key;

-- Orders by weekday (day_num 1 = Monday)
SELECT day_num, day_of_week, COUNT(DISTINCT invoice) AS orders
FROM v_sales GROUP BY day_num, day_of_week ORDER BY day_num;

-- Orders by hour
SELECT invoice_hour, COUNT(DISTINCT invoice) AS orders
FROM v_sales GROUP BY invoice_hour ORDER BY invoice_hour;

-- Weekday vs weekend share of revenue (weekend ~9%)
SELECT CASE WHEN is_weekend = 1 THEN 'Weekend' ELSE 'Weekday' END AS day_type,
       ROUND(SUM(revenue), 2)                                      AS revenue,
       ROUND(100 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1)    AS share_pct
FROM v_sales GROUP BY is_weekend;

-- ------------------------------------------------------------
-- D. Countries and customers
-- ------------------------------------------------------------
-- Top 10 countries with share of revenue (UK ~85.5%)
SELECT country,
       ROUND(SUM(revenue), 2)                                   AS revenue,
       ROUND(100 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1) AS share_pct
FROM v_sales GROUP BY country ORDER BY revenue DESC LIMIT 10;

-- Registered customers per country
SELECT country, COUNT(DISTINCT customer_id) AS customers
FROM v_sales_customers GROUP BY country ORDER BY customers DESC;

-- Top 10 customers
SELECT customer_id,
       COUNT(DISTINCT invoice) AS orders,
       ROUND(SUM(revenue), 2)  AS revenue
FROM v_sales_customers GROUP BY customer_id ORDER BY revenue DESC LIMIT 10;

-- Guest share of revenue (~13%)
SELECT ROUND(100 * SUM(CASE WHEN customer_id IS NULL THEN revenue END) / SUM(revenue), 1) AS guest_share_pct
FROM v_sales;

-- ------------------------------------------------------------
-- E. Products
-- ------------------------------------------------------------
-- One clean name per stock code: the most common description on sales rows.
-- (Some codes have several descriptions. Taking MAX would pick junk names.)
CREATE OR REPLACE VIEW v_product_names AS
SELECT stock_code, description AS product_name
FROM (
    SELECT stock_code, description,
           ROW_NUMBER() OVER (PARTITION BY stock_code
                              ORDER BY COUNT(*) DESC, description) AS rn
    FROM v_sales
    WHERE description <> ''
    GROUP BY stock_code, description
) AS t
WHERE rn = 1;

-- Top 10 products by NET revenue (sales minus returns)
WITH sales AS (
    SELECT stock_code, SUM(revenue) AS sales_rev, SUM(quantity) AS sales_units
    FROM v_sales GROUP BY stock_code
), rets AS (
    SELECT stock_code, -SUM(revenue) AS return_rev, -SUM(quantity) AS return_units
    FROM v_returns GROUP BY stock_code
)
SELECT s.stock_code,
       p.product_name,
       ROUND(s.sales_rev - COALESCE(r.return_rev, 0), 2)     AS net_revenue,
       s.sales_units - COALESCE(r.return_units, 0)           AS net_units
FROM sales s
LEFT JOIN rets r          ON r.stock_code = s.stock_code
LEFT JOIN v_product_names p ON p.stock_code = s.stock_code
ORDER BY net_revenue DESC
LIMIT 10;

-- ------------------------------------------------------------
-- F. Returns and cancellations
-- ------------------------------------------------------------
-- Totals: return value ~716K, units ~468K, 17,914 lines
SELECT ROUND(-SUM(revenue), 2) AS return_value,
       -SUM(quantity)          AS units_returned,
       COUNT(*)                AS cancellation_lines
FROM v_returns;

-- Return rate by month (return value divided by sales revenue)
SELECT s.year_month_key,
       ROUND(s.revenue, 2)                         AS sales_revenue,
       ROUND(COALESCE(r.revenue, 0), 2)            AS return_value,
       ROUND(100 * COALESCE(r.revenue, 0) / s.revenue, 2) AS return_rate_pct
FROM (SELECT year_month_key, SUM(revenue) AS revenue FROM v_sales GROUP BY year_month_key) s
LEFT JOIN (SELECT year_month_key, -SUM(revenue) AS revenue FROM v_returns GROUP BY year_month_key) r
       ON r.year_month_key = s.year_month_key
ORDER BY s.year_month_key;

-- Most returned products (units)
SELECT r.stock_code, p.product_name, -SUM(r.quantity) AS units_returned
FROM v_returns r
LEFT JOIN v_product_names p ON p.stock_code = r.stock_code
GROUP BY r.stock_code, p.product_name
ORDER BY units_returned DESC LIMIT 10;
