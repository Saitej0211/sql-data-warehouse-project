/* =====================================================================
 📅 DATE_RANGE EXPLORATION
===================================================================== */

-- Find how many years, months, and days of sales data are available
SELECT
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    EXTRACT(YEAR FROM AGE(MAX(order_date), MIN(order_date))) AS order_range_years,
    EXTRACT(YEAR FROM AGE(MAX(order_date), MIN(order_date))) * 12
        + EXTRACT(MONTH FROM AGE(MAX(order_date), MIN(order_date))) AS order_range_months,
    MAX(order_date) - MIN(order_date) AS order_range_days
FROM gold.fact_sales;

-- Get the exact difference between first and last order dates
SELECT
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    AGE(MAX(order_date), MIN(order_date)) AS order_range
FROM gold.fact_sales;

-- Find the youngest and oldest customers
SELECT
    MIN(birth_date) AS oldest_birthdate,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, MIN(birth_date))) AS oldest_customer_age,
    MAX(birth_date) AS youngest_birthdate,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, MAX(birth_date))) AS youngest_customer_age
FROM gold.dim_customers;
