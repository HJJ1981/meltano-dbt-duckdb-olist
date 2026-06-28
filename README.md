# End-to-End E-Commerce Analytics Pipeline using the Modern Data Stack

[![Meltano](https://img.shields.io/badge/ELT-Meltano-blueviolet?logo=meltano)](https://meltano.com/)
[![dbt Core](https://img.shields.io/badge/Transformation-dbt%20Core-orange?logo=dbt)](https://www.getdbt.com/)
[![DuckDB](https://img.shields.io/badge/Warehouse-DuckDB-yellow?logo=duckdb)](https://duckdb.org/)
[![Power BI](https://img.shields.io/badge/BI-Power%20BI-yellow?logo=power-bi)](https://powerbi.microsoft.com/)
[![Ubuntu WSL](https://img.shields.io/badge/OS-Ubuntu%20(WSL)-ubuntu?logo=ubuntu)](https://ubuntu.com/)

An end-to-end data platform engineered within an **Ubuntu/WSL Linux environment**. This project implements a fully functional Modern Data Stack to ingest, clean, model, and visualize normalized relational data from the Brazilian marketplace Olist e-commerce dataset. 

The pipeline moves from raw CSV extraction to a centralized DuckDB local warehouse, structures it into an analytics-ready Star Schema using dbt Core, and delivers high-impact executive insights through an interactive Power BI dashboard.

---

## 🛠️ Tech Stack

- Python
- Meltano
- DuckDB
- dbt Core
- SQL
- Power BI
- Ubuntu (WSL)
- Git
- GitHub

---

## 🏗️ Architecture & Data Flow


The platform is designed around ELT (Extract, Load, Transform) patterns to decouple data movement from business logic transformations:

1. **Ingestion Layer (Meltano):** Programmatically extracts raw data from local directories using `tap-csv` and loads it into a unified storage target using `target-duckdb`.
2. **Storage Layer (DuckDB):** Functions as our localized Data Warehouse (`mds_warehouse.db`), providing ultra-fast OLAP analytical query speeds.
3. **Transformation Layer (dbt Core):** * **Staging Layer (`stg_`):** Standardizes schemas, performs strict typecasting, cleans data text, and handles null values.
   * **Marts Layer (`dim_` / `fct_`):** Applies dimensional modeling logic to output modular, high-performance reporting structures.
4. **Business Intelligence Layer (Power BI):** Consumes the analytical star schema models to surface Customer Lifetime Value (CLV) and related geospatial metrics.

---

## 📂 Project Structure


```text
olist_data_pipeline/
├── .gitignore                             # Excludes .venv, raw data, and local databases
├── LICENSE                                # Open-source project licensing
├── README.md                              # Main platform showcase documentation
├── requirements.txt                       # Core Python workspace dependencies
│
├── data/
│   └── .gitkeep                           # Anchors directory structure on GitHub
│
├── mds_project/                           # Ingestion Layer (Orchestration & Target Warehouse)
│   ├── meltano.yml                        # Meltano pipeline definitions
│   └── README.md                          # Dedicated ingestion execution notes
│
├── olist_transform/                       # Transformation Layer (dbt Core Framework)
│   ├── dbt_project.yml                    # dbt execution and modeling scope targets
│   ├── packages.yml                       # Managed downstream dbt semantic extensions
│   ├── profiles.yml                       # Warehouse connection target parameters
│   ├── macros/                            # Custom global SQL logic generators
│   │   └── generate_surrogate_key.sql     
│   ├── models/
│   │   ├── staging/olist/                 # Source data cleaning and conformance
│   │   │   ├── source.yml                 
│   │   │   ├── stg_customers.sql
│   │   │   ├── stg_order_items.sql
│   │   │   ├── stg_orders.sql
│   │   │   ├── stg_product_category_name_translation.sql
│   │   │   └── stg_products.sql
│   │   └── marts/core/                    # Production Analytics Dimensional Layer
│   │       ├── core.yml                   
│   │       ├── dim_customers.sql
│   │       ├── dim_products.sql           
│   │       └── fct_orders.sql
│   └── tests/                             # Custom integrity & singular data tests
│
├── scripts/
│   └── pipeline_elt.py                    # Automation workflow utilities
│
└── dashboard/                             # Presentation Layer
    ├── olist_visualization.pbix           # Compiled semantic Power BI file
    └── screenshots/                       # Dashboard execution visual artifacts
        ├── customers_statistics.png
        ├── top_10_states_by_revenue.png
        ├── top_10_product_categories_by_revenue_and_unique_customers_count.png
        ├── 27_states_by_average_clv_per_state.png
        └── 26_states_by_total_top_1_percent_customers_count_per_state.png
```
---

## 📊 Dimensional Modeling (Star Schema)


To maximize query performance and simplify semantic interactions for business analysts, the data platform transforms transactional layers into an optimized dimensional Star Schema:

* **Fact Table:** * `fct_orders`: Grain is at the individual line-item level. Captures transactional values, freight overheads, and shipping SLA metrics.
* **Dimension Tables:** * `dim_customers`: Consolidates customer profiles down to the pure human grain (`customer_unique_id`), capturing lifetime values and their latest known geography.
  * `dim_products`: Houses the product catalog, English translations, and product velocity popularity segments.

> **Engineering Highlight:** During dashboard development, cross-layer profiling revealed structural integrity gaps where certain `product_id`s existed in the transactional tables (`stg_order_items`) but were entirely absent from the master marketing catalog (`stg_products`). Rather than masking this issue inside the BI layer, the dbt architecture was refactored to build a **self-healing dimension model** that dynamically isolates, structures, and flags these orphan records automatically.

---

## 🛠️ Deep Dive: Technical Challenges & Troubleshooting

### 1. Self-Healing Dimension Joins for Orphan Product Records
* **The Problem:** Downstream data quality assertions flagged a referential integrity violation—sales transactions were being processed that referenced a specific `product_id` missing from the master product dimension catalog.
* **The Forensic Audit:** I conducted a row-count reconciliation audit between the raw source operating system files and the data warehouse schemas using the DuckDB CLI:

```sql
-- Total lines in CSV file = 32,952 (1 Header Row + 32,951 actual data records)
SELECT COUNT(*) FROM raw.products; -- Result: 32,950 rows
```

* **The Solution:** Refactored `dim_products.sql` to implement an defensive data engineering pattern. Using a `UNION ALL` subquery pattern, the model compares ordered keys against the product catalog, extracts missing IDs, and dynamically appends them back into the base product dimension stream with an internal tag (`missing_catalog_data`).

```sql
-- Defensive modeling snippet from dim_products.sql to safeguard referential integrity
WITH ordered_product_ids AS (
    SELECT DISTINCT product_id FROM {{ ref('stg_order_items') }}
),
final_base_products AS (
    SELECT product_id, product_category_name FROM {{ ref('stg_products') }}
    UNION ALL
    -- Dynamically catch, isolate, and log missing orphan records
    SELECT 
        o.product_id,
        'missing_catalog_data' AS product_category_name
    FROM ordered_product_ids o
    LEFT JOIN {{ ref('stg_products') }} p ON o.product_id = p.product_id
    WHERE p.product_id IS NULL
)
SELECT 
    p.product_id,
    COALESCE(t.product_category_name_english, 'Missing Catalog Data') AS product_category_name_english
FROM final_base_products p
LEFT JOIN {{ ref('stg_product_category_name_translation') }} t
    ON p.product_category_name = t.product_category_name
```

### 2. Resolving Multi-Location Tracking for Moving Customers via Window Functions
* **The Challenge:** In the Olist dataset, a single unique human (`customer_unique_id`) can have multiple `customer_id` tokens if they made purchases from different addresses over time. Joining these directly to orders causes row duplication and incorrectly splits a single customer's Lifetime Value (CLV) across multiple historical locations.

* **The Solution:** Applied a `ROW_NUMBER()` window function in dim_customers.sql. By partitioning the data by the unique human grain (`customer_unique_id`) and ordering by their latest transactional timestamp (`order_purchase_at DESC NULLS LAST`), the model filters for `location_rank = 1`. This isolates their absolute latest known geography, collapsing the dimension cleanly to a strict 1:1 human grain while retaining accurate, consolidated CLV metrics.

```sql
-- Snippet from dim_customers.sql resolving customer history changes
WITH ranked_customer_geography AS (
    SELECT
        c.customer_unique_id,
        c.customer_state,
        c.customer_city,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id 
            ORDER BY o.order_purchase_at DESC NULLS LAST, c.customer_id DESC
        ) AS location_rank
    FROM {{ ref('fct_orders') }} o
    RIGHT JOIN {{ ref('stg_customers') }} c 
        ON o.customer_id = c.customer_id
)
SELECT 
    customer_unique_id,
    customer_state,
    customer_city
FROM ranked_customer_geography
WHERE location_rank = 1
```
---

## 🚀 Quick Start & Execution Roadmap

This platform is fully decoupled into isolated infrastructure layers. To initialize, configure, or run specific components of the pipeline, follow the step-by-step guides inside their respective directories:

1. **Incorporate Ingestion (`./mds_project`):** 
   Contains the `meltano.yml` definitions, bulk-loading parameters, and instructions for extracting raw CSVs into the DuckDB warehouse layer. 
   👉 [View Ingestion Setup & Execution Guide](./mds_project/README.md)

2. **Incorporate Transformations (`./olist_transform`):** 
   Contains the dbt Core architecture, custom macros, data quality testing suites, and star schema dimensional models. 
   👉 [View Transformation & Modeling Guide](./olist_transform/README.md)

3. **Incorporate Presentation (`./dashboard`):** 
   Contains the compiled interactive Power BI semantic model (`olist_visualization.pbix`) and visual artifacts mapping executive business metrics.

---

## 💻 Development Environment

| Software | Version |
|----------|---------|
| Python | 3.10 |
| Meltano | 4.2.1 |
| dbt Core | 1.11.11 |
| dbt-duckdb | 1.10.1 |
| DuckDB CLI | 1.5.3 |
| DuckDB Python | 1.5.3 |

---

## 📜 License

This project is licensed under the MIT License. See the `LICENSE` file for details.

---

## 👨‍💻 Author

**Hu Jian Jin**

- GitHub: https://github.com/HJJ1981
- LinkedIn: https://www.linkedin.com/in/jian-jin-hu-69951243/

---

## ⭐ Support

If you found this project helpful, consider giving it a ⭐ on GitHub. It helps others discover the project and motivates continued development.