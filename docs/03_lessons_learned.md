# Problems Solved and Lessons Learned

| Problem | Cause | Fix | Lesson |
|---|---|---|---|
| Missing customer IDs did not count as missing | Blanks were empty text, not NULL | Converted blanks to NULL | Check for empty strings as well as NULL |
| Min and max dates looked wrong | The date column was still text, so it sorted alphabetically | Converted with `STR_TO_DATE` | Verify data types, not just values |
| 609,137 NULLs with day/month format | Source dates are month first | Tested both formats, used month/day/year | Test the format before converting |
| "Truncated incorrect datetime value" | The format left out the seconds | Added `:%s` | Match the format to the raw text exactly |
| Overlap delete timed out ("Lock wait timeout") | The join had no index | Built an indexed lookup table first | Index join keys on large deletes |
| Export blocked by `secure_file_priv` | MySQL only writes to one approved folder | Exported with Python | Use the tool that fits the environment |
| Python could not connect | A password with `@` broke the connection string | Used `URL.create` / `pymysql.connect` | Pass credentials separately, never in a string |
| Quantity and price sorted as text | The columns stayed VARCHAR after stacking | Cast to numeric types when building the typed table | Cast early. `ORDER BY` on text gives wrong rankings |
| Cancelled-orders count showed 1 in Power BI | `invoice` was converted to a number, so "C" invoices went blank | Kept `invoice` as Text. Counted cancellations by `row_type` | Stop Power BI from auto-converting ID columns |
| One product appeared twice | A stock code had two descriptions | One name per code in a lookup table | Build a clean product dimension |
| Products had wrong names ("Wonky Bottom/Broken") | `MAX(description)` picks the alphabetically last one | Used the most common sales description | Check lookup tables against known products |
| Top sellers were misleading | Two bulk orders were later cancelled | Ranked by net revenue and net units | Define the metric before ranking |
| Weekend and customer donuts showed 0 and 1 | Raw flag columns | Added readable label columns | Label flags for the audience |
| Dashboard numbers changed with a slicer on | Country slicer was left on "Australia" | Cleared slicers before saving | Reset slicers before sharing |

## Notes from cleaning up the SQL

- Working scripts grow messy. The final repo keeps one numbered script per stage.
- Query labels should say what the query does. "Shows 2009 revenue" actually summed 2009 and 2010, and a "customer count" counted rows. The final queries use `COUNT(DISTINCT ...)` and clear date ranges.
- Order monthly results by month, not by revenue, when the result is a time series.
