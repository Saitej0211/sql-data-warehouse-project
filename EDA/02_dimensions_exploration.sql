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
