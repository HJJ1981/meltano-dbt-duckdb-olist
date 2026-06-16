# Data Ingestion Layer (Meltano EL)

This directory houses the orchestration and data ingestion configuration utilizing **Meltano** to extract raw e-commerce data and load it into our local data warehouse.

## 🛠️ Pipeline Architecture
* **Extractor (Tap):** `tap-csv` — Parses raw Olist datasets from the root `/data` directory.
* **Loader (Target):** `target-duckdb` — Ingests, type-casts, and structures the data into an OLAP-optimized local DuckDB file (`mds_warehouse.db`).

---

## 🚀 Environment Setup & Ingestion

Follow these steps to initialize your environment and run the EL (Extract & Load) pipeline locally.

### 1. Initialize the Environment
From the project root directory (`olist_data_pipeline/`), set up your Python virtual environment and activate it:
```bash
# Create and activate the virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install required core packages
pip install -r requirements.txt
```
### 2. Source Data Placement
Download the Olist e-commerce dataset and place the unzipped raw .csv files directly into the root data/ folder:
- olist_orders_dataset.csv
- olist_order_items_dataset.csv
- olist_customers_dataset.csv
- olist_products_dataset.csv
- product_category_name_translation.csv

### 3. Run the Meltano Pipeline
Navigate into your Meltano project directory to install the plugins and execute the data pipeline:
```bash
# Move into the Meltano configuration folder
cd mds_project

# Install the plugins defined in meltano.yml (tap-csv and target-duckdb)
meltano install

# Execute the EL pipeline to ingest data into DuckDB
meltano run tap-csv target-duckdb
```