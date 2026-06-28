import duckdb
import pandas as pd

db_path = r"\\wsl.localhost\Ubuntu\home\hujianjin\projects\olist_data_pipeline\mds_project\mds_warehouse.db"

conn = duckdb.connect(db_path, read_only=True)

# SAFE PATHING: Tell DuckDB to automatically look inside the 'raw' schema
conn.execute("SET search_path = 'raw';")

print("⚡ Connected to warehouse. Fetching Olist data models...")

# Fetch your models
fct_orders = conn.execute("SELECT * FROM raw.fct_orders").df()
dim_customers = conn.execute("SELECT * FROM raw.dim_customers").df()
dim_products = conn.execute("SELECT * FROM raw.dim_products").df()

stg_order_items = conn.execute("SELECT * FROM raw.stg_order_items").df()
stg_orders = conn.execute("SELECT * FROM raw.stg_orders").df()
stg_customers = conn.execute("SELECT * FROM raw.stg_customers").df()
stg_products = conn.execute("SELECT * FROM raw.stg_products").df()
stg_translations = conn.execute("SELECT * FROM raw.stg_product_category_name_translation").df()

conn.close()