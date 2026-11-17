"""Load the two cleaned yearly CSV files into the MySQL staging tables.

Run sql/01_create_staging.sql first. The password is read from the
MYSQL_PASSWORD environment variable, or asked for in the terminal.
Never write your password in this file.
"""
import os
from getpass import getpass

import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

FILES = {
    "data/raw/cleaned_2009-2010.csv": "staging_2009_2010",
    "data/raw/cleaned_2010-2011.csv": "staging_2010_2011",
}
COLS = ["invoice", "stock_code", "description", "quantity",
        "invoice_date", "price", "customer_id", "country"]

# URL.create handles special characters (such as @) in the password.
engine = create_engine(URL.create(
    "mysql+pymysql",
    username=os.getenv("MYSQL_USER", "root"),
    password=os.getenv("MYSQL_PASSWORD") or getpass("MySQL password: "),
    host="localhost",
    port=3306,
    database="online_retail_project",
))


def load(csv_path, table):
    with engine.begin() as conn:          # begin() commits when the block ends
        conn.execute(text(f"TRUNCATE TABLE {table}"))
        sent = 0
        for chunk in pd.read_csv(csv_path, dtype=str, keep_default_na=False,
                                 chunksize=50_000):
            chunk = chunk.iloc[:, :8]
            chunk.columns = COLS
            chunk.to_sql(table, conn, if_exists="append", index=False,
                         method="multi", chunksize=5_000)
            sent += len(chunk)
    with engine.connect() as conn:        # verify from a fresh connection
        n = conn.execute(text(f"SELECT COUNT(*) FROM {table}")).scalar()
    print(f"{table}: sent {sent:,}, MySQL says {n:,}")


for path, table in FILES.items():
    load(path, table)
print("Expected: 518,593 and 536,640")
