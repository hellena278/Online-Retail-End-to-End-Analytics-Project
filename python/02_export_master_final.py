"""Export the finished master_final table to CSV (for Power BI).

Streams the table in chunks, so 1M rows do not fill your memory.
(MySQL's INTO OUTFILE is blocked by secure_file_priv, so Python does the export.)
"""
import csv
import os
from getpass import getpass

import pymysql

OUT = "data/master_final_cleaned.csv"

conn = pymysql.connect(
    host="localhost",
    user=os.getenv("MYSQL_USER", "root"),
    password=os.getenv("MYSQL_PASSWORD") or getpass("MySQL password: "),
    database="online_retail_project",
    port=3306,
)
cur = conn.cursor(pymysql.cursors.SSCursor)   # server-side cursor
cur.execute("SELECT * FROM master_final ORDER BY row_id")

with open(OUT, "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow([d[0] for d in cur.description])
    rows = 0
    while True:
        batch = cur.fetchmany(100_000)
        if not batch:
            break
        w.writerows(batch)
        rows += len(batch)

conn.close()
print(f"done: {rows:,} rows written to {OUT}")   # expect 1,033,031
