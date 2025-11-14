# 🧩 Exploratory Data Analysis (EDA) — Gold Layer

## 📘 Overview
This folder contains SQL scripts used for **Exploratory Data Analysis (EDA)** on the **Gold Layer** of the data warehouse.  
It focuses on analyzing the cleaned and transformed data (post-ETL), stored in the `gold` schema, to validate data integrity and extract business insights.

The SQL scripts are written for **PostgreSQL** and executed in **pgAdmin** or **DBeaver**.

---

## 🏗️ Schema Context
The **Gold Layer** represents the final, business-ready data layer derived from the **Silver Layer**.  
It contains:

- **Dimension Tables**
  - `gold.dim_customers`
  - `gold.dim_products`
- **Fact Table**
  - `gold.fact_sales`

These tables follow a **Star Schema** model, where the `fact_sales` table references the dimensions via surrogate keys.

---

## 📁 Script Structure

| Section | Description |
|----------|--------------|
| **1. Database Exploration** | Lists schemas, tables, and columns using `information_schema` to explore database metadata. |
| **2. Dimensions Exploration** | Explores categorical attributes like countries, product categories, and subcategories. |
| **3. Date Exploration** | Analyzes sales date ranges and customer age spans using date functions (`AGE()`, `EXTRACT()`). |
| **4. Measures Exploration** | Computes key performance metrics such as total sales, average prices, and order counts. |
| **5. Magnitude Analysis** | Aggregates business metrics like customers by region, revenue by category, and product counts. |
| **6. Ranking Analysis** | Ranks top and bottom performers — products and customers — using `ROW_NUMBER()` and `LIMIT`. |
| **7. Change Over Time** | Tracks monthly and yearly trends in total sales, customers, and quantity sold. |
| **8. Cumulative Analysis** | Calculates cumulative sales (running totals) and moving averages over time. |
| **9. Performance Analysis** | Compares product sales to averages and prior year performance (YoY). |
| **10. Part-to-Whole Analysis** | Determines category contribution to total revenue. |
| **11. Product Segmentation** | Groups products into cost ranges to identify pricing bands. |
| **12. Customer Segmentation** | Segments customers by loyalty and spending (VIP, Regular, New). |
| **13. Customer Report** | Creates a view summarizing customer KPIs like AOV, recency, and monthly spend. |
| **14. Product Report** | Creates a view consolidating product KPIs such as lifespan, performance, and revenue. |

---

## ⚙️ Prerequisites

- **PostgreSQL 18**
- **pgAdmin 4** or **DBeaver** for query execution
- A database schema named `gold` with the following tables:

| Table | Description |
|--------|-------------|
| `dim_customers` | Customer dimension with fields like `customer_key`, `first_name`, `last_name`, `country`, `gender`, `birth_date`. |
| `dim_products` | Product dimension with fields like `product_key`, `product_name`, `category`, `sub_category`, `cost`. |
| `fact_sales` | Fact table with fields like `order_number`, `order_date`, `product_key`, `customer_key`, `sales_amount`, `quantity`, `price`. |

---

## 🚀 How to Use

1. **Open pgAdmin or DBeaver.**
2. Connect to your PostgreSQL database that contains the `gold` schema.
3. Copy the full SQL script (`EDA.sql`) or run each numbered SQL file sequentially.
4. Execute section by section to analyze key metrics or run the entire workflow.
5. Review query outputs for data validation and insight generation.

---

## 📈 Key Insights Generated

- **Data Coverage**
  - Sales date range in years, months, and days.
  - Number of customers, products, and orders available.

- **Customer Insights**
  - Distribution by gender and country.
  - Youngest and oldest customer demographics.
  - Top and bottom customers by revenue and order count.

- **Product Insights**
  - Average cost by category.
  - Top 5 and bottom 5 products by revenue.
  - Product performance by category and line.

- **Sales Insights**
  - Total and average sales metrics.
  - Revenue contribution by category and customer.
  - Quantity sold per country.

---

## 📊 Sample Insights

| Insight | Output |
|----------|----------------|
| Total Sales | `$29M` |
| Active Customers | `18,484` |
| Top Product | `Bikes` |
| Highest Revenue Country | `United States` |
| Sales Range | `3 years, 30 days` |

---

## 🛠️ Highlights & Features

- Clean **PostgreSQL-compatible** syntax (`LIMIT`, `CONCAT()`, `AGE()`, `DATE_TRUNC()`).
- Modular structure with readable comments and section headers.
- Works across any **Star Schema** data warehouse design.
- Covers all aspects of **Exploratory Data Analysis (EDA)**:
  - Ranking
  - Aggregation
  - Segmentation
  - Trend and performance analysis
- Final **report views** (`report_customers`, `report_products`) serve as ready-made datasets for BI tools like Power BI or Tableau.

---

## 📚 Folder Preview
```
EDA/
│
├── 01_database_exploration.sql
├── 02_dimensions_exploration.sql
├── 03_date_range_exploration.sql
├── 04_measures_exploration.sql
├── 05_magnitude_analysis.sql
├── 06_ranking_analysis.sql
├── 07_change_over_time.sql
├── 08_cumulative_analysis.sql
├── 09_performance_analysis.sql
├── 10_part_to_whole_analysis.sql
├── 11_product_segmentation.sql
├── 12_customer_segmentation.sql
├── 13_report_customers.sql
├── 14_report_products.sql
└── readme.md
```

---

## 🧠 Next Steps

- Integrate the created SQL views (`report_customers`, `report_products`) with Power BI / Tableau dashboards.
- Extend scripts for **Year-over-Year growth**, **Forecasting**, and **Cohort Retention Analysis**.
- Connect with Python notebooks for automated validation and trend visualization.
