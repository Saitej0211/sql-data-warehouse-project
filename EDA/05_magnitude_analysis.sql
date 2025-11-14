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
