import os
import pandas as pd
from sqlalchemy import create_engine, text
from dotenv import load_dotenv


# ---------------------------------
# LOAD ENVIRONMENT VARIABLES
# ---------------------------------
from dotenv import load_dotenv
import os

# ---------------------------------
# LOAD ENVIRONMENT VARIABLES (EXPLICIT)
# ---------------------------------
load_dotenv(dotenv_path=os.path.join(os.getcwd(), ".env"))

DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = int(os.getenv("DB_PORT", 5432))  # <-- FORCE INT + DEFAULT

print("DEBUG CONFIG:")
print("DB_NAME:", DB_NAME)
print("DB_USER:", DB_USER)
print("DB_HOST:", DB_HOST)
print("DB_PORT:", DB_PORT)



DATA_DIR = "data/raw"

# ---------------------------------
# CREATE DATABASE ENGINE
# ---------------------------------
from sqlalchemy.engine import URL

db_url = URL.create(
    drivername="postgresql+psycopg",
    username=DB_USER,
    password=os.getenv("DB_PASSWORD"),  # RAW password, no encoding needed
    host=DB_HOST,
    port=DB_PORT,
    database=DB_NAME,
)

engine = create_engine(db_url)


# ---------------------------------
# HELPER FUNCTION
# ---------------------------------
def load_csv(table_name, file_name, date_cols=None):
    print(f"Loading {table_name}...")
    df = pd.read_csv(os.path.join(DATA_DIR, file_name))

    if date_cols:
        for col in date_cols:
            df[col] = pd.to_datetime(df[col])

    df.to_sql(
        table_name,
        engine,
        if_exists="append",
        index=False
    )

# ---------------------------------
# TRUNCATE TABLES (SAFE RE-RUN)
# ---------------------------------
with engine.begin() as conn:
    conn.execute(text("""
        TRUNCATE TABLE
            account_profitability,
            support_costs,
            usage_metrics,
            invoices,
            subscriptions,
            plans,
            accounts
        RESTART IDENTITY CASCADE;
    """))

# ---------------------------------
# LOAD DATA (ORDER MATTERS)
# ---------------------------------
load_csv("accounts", "accounts.csv", date_cols=["signup_date"])
load_csv("plans", "plans.csv")
load_csv("subscriptions", "subscriptions.csv", date_cols=["start_date"])
load_csv("invoices", "invoices.csv", date_cols=["billing_month"])
load_csv("usage_metrics", "usage_metrics.csv", date_cols=["usage_month"])
load_csv("support_costs", "support_costs.csv", date_cols=["support_month"])

print("✅ ETL pipeline completed successfully.")

# ---------------------------------
# BUILD ACCOUNT PROFITABILITY TABLE
# ---------------------------------
print("Building account_profitability...")

# 1. Clear existing data
with engine.connect() as conn:
    conn.execute(text("TRUNCATE TABLE account_profitability;"))

# 2. Read transformation SQL
with open("sql/transforms.sql", "r") as f:
    profitability_sql = f.read()

# 3. Execute transformation and fetch results
with engine.connect() as conn:
    result_df = pd.read_sql_query(profitability_sql, conn)

print("Rows generated for profitability:", len(result_df))

if result_df.empty:
    raise ValueError("Profitability SQL returned 0 rows — check transforms.sql logic")

# 4. Load into Postgres
result_df.to_sql(
    "account_profitability",
    engine,
    if_exists="append",
    index=False
)

print("✅ account_profitability table built successfully.")
