# SQl-Data-Warehouse-Project: From Raw CRM & ERP Data to Analytics-Ready Models

An end-to-end data warehouse built in **SQL Server** using the **Medallion Architecture** (Bronze → Silver → Gold). It consolidates sales data from two disconnected source systems (CRM and ERP) into a clean **star schema** that analysts can query directly for reporting.
---

## 📌 Business Problem

A company stores customer, product, and sales data across two separate systems, a **CRM** and an **ERP**. The data has several problems:

- **Inconsistent and duplicated records** — the same customer appears in both systems with different formats and keys.
- **Dirty data** — null values, extra whitespace, invalid dates, and abbreviated codes (e.g. `M`/`F`, `S`/`M`) that are not report-friendly.
- **No single source of truth**
  
**Goal:** to build a reliable, documented warehouse that integrates both sources, cleans and standardizes the data, and exposes a business-ready model for **sales, customer, and product analytics**.

---

## 🏗️ Architecture

The warehouse follows the **Medallion Architecture** with three layers:

| Layer | Purpose | Object Type | Load Method | Transformations |
|---|---|---|---|---|
| **Bronze** | Raw, unaltered copy of source data | Tables | Full load (truncate & insert) via `BULK INSERT` | None |
| **Silver** | Cleaned, standardized, integrated data | Tables | Full load (truncate & insert) | Cleansing, standardization, normalization, enrichment, derived columns |
| **Gold** | Business-ready data for reporting | Views | None (views over Silver) | Integration, aggregation, business logic, star-schema modeling |

>  ![Data Flow Diagram](docs/Data%20Flow%20Diagram.png)

**Data flow:** `CRM + ERP (CSV files)` → **Bronze** → **Silver** → **Gold** → `BI tools / SQL queries / ad-hoc analysis`

---

## 📂 Data Sources

Two source systems, delivered as CSV files:

| Source | Files | Content |
|---|---|---|
| **CRM** | `cust_info`, `prd_info`, `sales_details` | Customer info, product info, sales transactions |
| **ERP** | `CUST_AZ12`, `LOC_A101`, `PX_CAT_G1V2` | Customer birthdate/gender, customer country, product categories |

---

## ⭐ Gold Layer: Data Model (Star Schema)

| Table | Type | Description |
|---|---|---|
| `gold.dim_customers` | Dimension | Unified customer profile (CRM + ERP): name, gender, marital status, country, birthdate |
| `gold.dim_products` | Dimension | Product details with category, subcategory, cost, and product line |
| `gold.fact_sales` | Fact | Sales transactions linked to customers and products via surrogate keys: order, ship and due dates, sales amount, quantity, price |

> ![Data Mart](docs/Data%20Mart.png)

---

## 🔧 What I Built

### 1. Bronze Layer: Ingestion
- Created DDL scripts for the raw tables.
- Loaded CSV files with `BULK INSERT` inside a **stored procedure** (`bronze.load_bronze`).
- Added **load-duration logging** and `TRY...CATCH` error handling.

### 2. Silver Layer: Cleansing & Standardization
- **Removed duplicates** using `ROW_NUMBER()` and kept the latest record per key.
- **Trimmed** unwanted whitespace in string fields.
- **Standardized** coded values into readable labels (e.g. `M` → `Male`, `S` → `Single`, country codes → country names).
- **Handled nulls and invalid values**, including bad dates and negative or zero sales/prices.
- **Recalculated derived fields** such as `sales = quantity × price` where source values were inconsistent.
- **Derived new columns**, including product end dates using `LEAD()`.
- Wrapped the load in a stored procedure (`silver.load_silver`).

### 3. Gold Layer: Business Model
- Joined CRM and ERP data to create integrated dimensions.
- Resolved conflicting fields (e.g. gender from CRM vs. ERP) with clear precedence rules.
- Generated **surrogate keys** with `ROW_NUMBER()`.
- Built the **fact table** by linking sales to dimension surrogate keys.
- Exposed everything as **views** for flexible, always-current access.

---

## 🛠️ Tech Stack

- **Database:** Microsoft SQL Server
- **Language:** T-SQL (stored procedures, CTEs, window functions, views, `BULK INSERT`)
- **Tools:** SQL Server Management Studio (SSMS), Draw.io (architecture & model diagrams), Git/GitHub
- **Concepts:** ETL, Medallion Architecture, dimensional modeling, star schema, data quality, data cataloging

---


## 📁 Repository Structure

```
sql-data-warehouse-project/
│
├── docs/                     # Architecture, data flow, data model diagrams
├── scripts/
│   ├── init_database.sql     # Creates the database and bronze/silver/gold schemas
│   ├── bronze/               # DDL + bronze load procedure
│   ├── silver/               # DDL + silver cleansing/load procedure
│   └── gold/                 # Gold views (dimensions & fact)
├── tests/                    # Data quality check scripts
└── README.md
```

---

## 💡 Key Learnings

- Designing a **layered architecture** that separates raw, cleaned, and business-ready data.
- Integrating **multiple source systems** with overlapping and conflicting records.
- Applying **data-quality rules** systematically instead of ad hoc fixes.
- Modeling a **star schema** and generating surrogate keys.
- Documenting a warehouse so other analysts can use it without guessing.

---

## 🙏 Acknowledgements

This project was built by following the **SQL Data Warehouse from Scratch** tutorial series by [Data with Baraa]. I implemented the full pipeline myself and documented it here as part of my analytics portfolio.
