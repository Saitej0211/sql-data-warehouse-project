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
