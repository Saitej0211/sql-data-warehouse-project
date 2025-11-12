/* =====================================================================
 🏗️ DATABASE EXPLORATION
===================================================================== */

-- Explore all tables in the database (excluding system schemas)
SELECT
    *
FROM information_schema.tables
WHERE table_schema NOT IN ('pg_catalog', 'information_schema');

-- Explore all columns of a specific table
SELECT
    *
FROM information_schema.columns
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
  AND table_name = 'dim_customers';

-- Explore all columns in the 'gold' schema
SELECT
    *
FROM information_schema.columns
WHERE table_schema = 'gold';


/* =====================================================================
 🌍 DIMENSIONS EXPLORATION
===================================================================== */

-- List all distinct countries our customers come from
SELECT DISTINCT
    country
FROM gold.dim_customers;

-- List all product categories and subcategories
SELECT DISTINCT
    category,
    sub_category,
    product_name
FROM gold.dim_products
ORDER BY category, sub_category, product_name;


/* =====================================================================
 📅 DATE EXPLORATION
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


/* =====================================================================
 💰 MEASURES EXPLORATION
===================================================================== */

-- Find total sales
SELECT SUM(sales_amount) AS total_sales
FROM gold.fact_sales;

-- Find total quantity of items sold
SELECT SUM(quantity) AS total_items_sold
FROM gold.fact_sales;

-- Find average selling price
SELECT ROUND(AVG(price), 2) AS avg_selling_price
FROM gold.fact_sales;

-- Find total number of orders (including duplicates)
SELECT COUNT(order_number) AS total_no_orders
FROM gold.fact_sales;

-- Find total number of unique orders
SELECT COUNT(DISTINCT order_number) AS total_no_orders
FROM gold.fact_sales;

-- Find total number of products
SELECT COUNT(DISTINCT product_key) AS total_no_products
FROM gold.dim_products;

-- Find total number of customers
SELECT COUNT(DISTINCT customer_key) AS total_no_customers
FROM gold.dim_customers;

-- Find number of customers who have placed at least one order
SELECT COUNT(DISTINCT customer_key) AS active_customers
FROM gold.fact_sales;

-- Generate a report showing all key business metrics
SELECT 'Total Sales' AS metric, SUM(sales_amount) AS value
FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity', SUM(quantity)
FROM gold.fact_sales
UNION ALL
SELECT 'Average Price', ROUND(AVG(price), 2)
FROM gold.fact_sales
UNION ALL
SELECT 'Total Orders', COUNT(DISTINCT order_number)
FROM gold.fact_sales
UNION ALL
SELECT 'Total Products', COUNT(DISTINCT product_name)
FROM gold.dim_products
UNION ALL
SELECT 'Total Customers', COUNT(DISTINCT customer_key)
FROM gold.dim_customers;


/* =====================================================================
 📊 MAGNITUDE ANALYSIS
===================================================================== */

-- Total customers by country
SELECT
    country,
    COUNT(DISTINCT customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;

-- Total customers by gender
SELECT
    gender,
    COUNT(DISTINCT customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC;

-- Total products by category
SELECT
    category,
    COUNT(DISTINCT product_key) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC;

-- Average cost by category
SELECT
    category,
    ROUND(AVG(cost), 2) AS avg_costs
FROM gold.dim_products
GROUP BY category
ORDER BY avg_costs DESC;

-- Total revenue per category
SELECT
    p.category,
    ROUND(SUM(f.sales_amount), 2) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;

-- Total revenue per customer
SELECT
    c.customer_key,
    c.first_name,
    c.last_name,
    ROUND(SUM(f.sales_amount), 2) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON c.customer_key = f.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_revenue DESC, c.first_name ASC;

-- Distribution of sold items across countries
SELECT
    c.country,
    SUM(f.quantity) AS total_sold_items
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON c.customer_key = f.customer_key
GROUP BY c.country
ORDER BY total_sold_items DESC;


/* =====================================================================
 🏆 RANKING ANALYSIS
===================================================================== */

-- Top 5 products by total revenue
SELECT
    p.product_name,
    ROUND(SUM(f.sales_amount), 2) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC
LIMIT 5;

-- Top 5 products using ROW_NUMBER
SELECT
    product_name,
    total_revenue
FROM (
    SELECT
        p.product_name,
        ROUND(SUM(f.sales_amount), 2) AS total_revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(f.sales_amount) DESC) AS rank_products
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p ON p.product_key = f.product_key
    GROUP BY p.product_name
) t
WHERE rank_products <= 5;

-- Bottom 5 products by revenue
SELECT
    p.product_name,
    ROUND(SUM(f.sales_amount), 2) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue ASC
LIMIT 5;

-- Top 10 customers by revenue
SELECT
    customer_key,
    CONCAT(t.first_name, ' ', t.last_name) AS customer_name,
    total_revenue
FROM (
    SELECT
        c.customer_key,
        c.first_name,
        c.last_name,
        SUM(f.sales_amount) AS total_revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(f.sales_amount) DESC) AS rank_customers
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c ON c.customer_key = f.customer_key
    GROUP BY c.customer_key, c.first_name, c.last_name
) t
WHERE rank_customers <= 10;

-- Bottom 3 customers by revenue
SELECT
    customer_key,
    CONCAT(t.first_name, ' ', t.last_name) AS customer_name,
    total_revenue
FROM (
    SELECT
        c.customer_key,
        c.first_name,
        c.last_name,
        SUM(f.sales_amount) AS total_revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(f.sales_amount) ASC) AS rank_customers
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c ON c.customer_key = f.customer_key
    GROUP BY c.customer_key, c.first_name, c.last_name
) t
WHERE rank_customers <= 3;

-- 3 customers with the fewest orders placed
SELECT
    customer_key,
    CONCAT(t.first_name, ' ', t.last_name) AS customer_name,
    total_orders
FROM (
    SELECT
        c.customer_key,
        c.first_name,
        c.last_name,
        COUNT(DISTINCT f.order_number) AS total_orders,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT f.order_number) ASC, c.customer_key ASC) AS rank_customers
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c ON c.customer_key = f.customer_key
    GROUP BY c.customer_key, c.first_name, c.last_name
) t
WHERE rank_customers <= 3;
