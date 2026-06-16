# Data Transformation Layer (dbt Core)


This directory contains the data transformation framework utilizing **dbt Core** to convert raw, ingested e-commerce data within our DuckDB data warehouse into an analytics-ready Star Schema.

## 🛠️ Transformation Architecture


The repository enforces a strict separation of concerns across two primary layers:

```text
  [Raw Ingested Tables] 
          │
          ▼
   ┌──────────────┐
   │ Staging (stg)│  <-- Column renaming, type casting, basic text trimming
   └──────┬───────┘
          │
          ▼
   ┌──────────────┐
   │ Marts (core) │  <-- Self-healing dimensions, human-grain CLV aggregations
   └──────────────┘

1. Staging Layer (models/staging/olist/): Performs lightweight transformations directly on the raw tables. This includes renaming cryptic columns, enforcing explicit data type casting, basic string cleansing (LOWER(TRIM())), and exposing initial data testing boundaries.

2. Marts Layer (models/marts/core/): Combines staging models into high-performance dimensional star schema structures (dim_ and fct_ tables). This layer applies core business logic, constructs complex metrics (such as Customer Lifetime Value), and handles advanced data deduplication.
```
---

## 🏗️ Technical Highlights Implemented


- Self-Healing Dimensions (dim_products.sql): Utilizes a custom UNION ALL validation pattern to intercept and capture transactional product records missing from the core marketing catalog, eliminating data dropouts or downstream NULL rendering bugs.

- Granular Cohort Windowing (dim_customers.sql): Employs the ROW_NUMBER() window function to partition history across unique human boundaries (customer_unique_id), capturing a user's absolute latest active geographical profile without duplicating financial metrics.

- Modular Code Reuse (Macros): Implements a DRY (Don't Repeat Yourself) design pattern by replacing repetitive hashing concatenation snippets with a reusable macro utility (generate_surrogate_key.sql) to generate surrogate keys.

---

## 🚀 How To Execute & Test Transformations


Ensure your terminal workspace has your Python virtual environment active and that you have navigated to this sub-directory:
```bash
cd ../olist_transform
```
1. Install Dependencies
Download and compile external open-source packages (such as dbt_utils) declared within your packages.yml:
```bash
dbt deps
```
2. Build the Project
Compile the SQL scripts, execute all staging and marts models against the local DuckDB database, and run all schema/singular data quality validation tests in a single command:
```bash
dbt build --profiles-dir .
```
3. Generate the Interactive Documentation
dbt builds rich documentation and dependency graphs automatically. To generate and open your interactive local lineage documentation webpage, run:
```bash
dbt docs generate --profiles-dir .
dbt docs serve --profiles-dir .
```
---

## 🔍 Data Quality Control Framework


- Data trust is managed using a combination of automated constraints:
Schema Tests (core.yml & source.yml): Enforces field-level integrity across structural keys using built-in assertions (unique, not_null, and explicit foreign-key relationships).

- Singular Tests (tests/): Contains custom SQL evaluation files (e.g., assert_total_item_amount_is_positive.sql) that run analytical margin and financial logic safety checks directly against production models.

---



