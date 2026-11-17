# Step-by-Step Guide: Raw Data to Dashboard to GitHub

## Phase A: Inspect and clean the raw sheets (Excel / Google Sheets)

1. Open both worksheets. Record row counts, blanks per column, negative values and the date range.
2. Remove duplicate rows.
3. Delete the blank rows the duplicate removal leaves behind.
4. Remove the "Adjust bad debt" rows (invoices starting with `A`).
5. Save each sheet as a CSV file into `data/raw/`.

## Phase B: Build the database (MySQL and Python)

1. Run `sql/01_create_staging.sql` to create two text-only staging tables.
2. Run `python/01_import_csv_to_mysql.py`. Check it prints 518,593 and 536,640 rows.
3. Run `sql/02_stack_and_type.sql`: stack both years, then convert text to proper types.
   - Expect 1,055,233 rows, 0 NULL dates and 242,865 NULL customer IDs.
4. Run `sql/03_clean_and_prepare.sql` one statement at a time. It builds `master_final`:
   - removes the year overlap (22,202 rows), leaving 1,033,031
   - standardizes text and adds date, hour, weekend and revenue columns
   - labels every row and creates the views
5. Run `sql/04_validation_checks.sql` and compare each result with the expected value.
6. Run `sql/05_analysis_queries.sql` for the SQL analysis.

## Phase C: Export to CSV

1. Run `python/02_export_master_final.py`.
2. It writes `data/master_final_cleaned.csv` (1,033,031 rows).

MySQL's `INTO OUTFILE` is blocked by `secure_file_priv` on most setups, so Python does the export.

## Phase D: Build the Power BI dashboard

1. **Load:** Get data → Text/CSV → `master_final_cleaned.csv` → Transform data.
2. **Types:** `invoice` and `stock_code` Text, `customer_id` Whole number, `invoice_date` Date/Time. Rename the table `retail`.
3. **Model:** add the columns, the `ProductNames` table and the measures from `powerbi/measures.dax`. Sort `month_name` by `invoice_month` and `Day` by `day_num`.
4. **Theme:** View → Themes → Browse for themes → `powerbi/Retail_Clean_Theme.json`.
5. **Canvas:** 1920 x 1080 on every page.
6. **Header:** build the title, three slicers (year, month, country), a page navigator and the footnote once, then copy them to each page.
7. **Pages:**

| Page | Visuals |
|---|---|
| 1. Executive Overview | 5 cards, monthly revenue by year, top 10 countries, top 8 excluding the UK, revenue by customer type |
| 2. Seasonal Demand | 4 cards, monthly units, quarterly units, orders by day and hour (heatmap), weekday vs weekend revenue |
| 3. Product Performance | Top 10 by net revenue, top 10 by net units, product summary table |
| 4. Operations & Cancellations | 4 cards, return value by month, most returned products, return value by country, cancellation lines by weekday |

8. **Polish:** chart titles, a finding under each title, alt text on every visual, tab order, and a footnote about the partial month.
9. **Check:** clear all slicers and compare with the check values at the bottom of `measures.dax`.
10. **Export:** File → Export → PDF. Convert each page to PNG for the README.

## Phase E: Publish on GitHub

1. Create an empty repository on GitHub (no README, no .gitignore).
2. Add your four screenshots to `images/` (`page1_overview.png`, `page2_seasonal.png`, `page3_products.png`, `page4_operations.png`).
3. Replace the author section in `README.md`.
4. In the project folder:

```bash
git init
git add .
git commit -m "Online Retail II: SQL, Python and Power BI project"
git branch -M main
git remote add origin https://github.com/<your-username>/<repo-name>.git
git push -u origin main
```

5. On GitHub, set a one-line description and topics: `power-bi`, `sql`, `mysql`, `python`, `data-analysis`, `dashboard`, `portfolio`.
6. Pin the repository on your profile and link it from your CV and LinkedIn.

Large files stay out of the repo: `.gitignore` excludes `data/raw/` and the full CSV (GitHub limits files to 100 MB). A 5,000-row sample is included in `data/`.
