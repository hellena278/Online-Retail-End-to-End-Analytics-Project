# Data Cleaning Log

## Source

*Online Retail II* (UCI Machine Learning Repository): transactions of a UK online giftware retailer, 1 Dec 2009 to 9 Dec 2011, in two worksheets.

## Row count waterfall

| Step | 2009-10 | 2010-11 | Total |
|---|---|---|---|
| Raw rows | 525,461 | 541,910 | 1,067,371 |
| Remove duplicate rows (and the blanks they leave) | 518,596 | 536,642 | 1,055,238 |
| Remove "Adjust bad debt" rows | 518,593 | 536,640 | **1,055,233** |
| Remove the year overlap (1 to 9 Dec 2010 is in both sheets) | 496,391 | 536,640 | **1,033,031** |

## Issues found and what was done

| Issue | 2009-10 | 2010-11 | Action |
|---|---|---|---|
| Duplicate rows | 6,865 | 5,268 | Removed |
| Missing description | 2,928 | 1,454 | Labelled `zero_price`, excluded from sales |
| Missing customer ID | 107,833 | 135,037 | Kept as guest checkout. Excluded from customer counts |
| Negative quantity | 12,302 | 10,587 | "C" invoices labelled `cancellation`, the rest `neg_qty_no_C` |
| Price = 0 | 3,681 | 2,510 | Labelled `zero_price` |
| Negative price ("Adjust bad debt") | 3 | 2 | Removed |
| Year overlap | 22,202 identical rows in both sheets | | Removed from the 2009-10 sheet |
| Non-product codes (POST, DOT, M, BANK CHARGES...) | yes | yes | Labelled `non_product` |
| Country labels (EIRE, RSA, USA, Korea) | yes | yes | Standardized |
| Dates stored as text (month/day/year) | yes | yes | Converted to DATETIME |

## Final row labels (`row_type`)

| Label | Rows | Used for |
|---|---|---|
| sale | 1,003,214 | All sales analysis |
| cancellation | 17,914 | Returns analysis |
| non_product | 5,974 | Excluded (postage, fees, manual entries) |
| neg_qty_no_C | 3,362 | Excluded (stock adjustments) |
| zero_price | 2,566 | Excluded (no sales value) |
| adjustment | 1 | Excluded |

Nothing is deleted after the overlap step. Every row is labelled, and the analysis uses views that filter on the label.
