/*
===============================================================================
Quality Checks – Gold Layer Validation
===============================================================================
Script Purpose:
    This script performs quality checks to validate the integrity, consistency, 
    and accuracy of the Gold Layer in the data warehouse. These checks ensure:
    - Uniqueness of surrogate keys in dimension tables.
    - Referential integrity between fact and dimension tables.
    - Validation of relationships in the data model for analytical purposes.

Usage Notes:
    - Run this script after the Gold views are created.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

-- ====================================================================
-- Check 1: Uniqueness of Customer Key in gold.dim_customers
-- ====================================================================
-- Expectation: No rows should be returned (each customer_key must be unique)
SELECT 
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;


-- ====================================================================
-- Check 2: Uniqueness of Product Key in gold.dim_products
-- ====================================================================
-- Expectation: No rows should be returned (each product_key must be unique)
SELECT 
    product_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;


-- ====================================================================
-- Check 3: Referential Integrity between gold.fact_sales and Dimensions
-- ====================================================================
-- Expectation: No rows should be returned (all fact records should match
-- corresponding dimension keys)
SELECT 
    f.order_number,
    f.product_key,
    f.customer_key,
    CASE WHEN p.product_key IS NULL THEN 'Missing Product Reference' END AS product_issue,
    CASE WHEN c.customer_key IS NULL THEN 'Missing Customer Reference' END AS customer_issue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON f.customer_key = c.customer_key
LEFT JOIN gold.dim_products p  ON f.product_key  = p.product_key
WHERE p.product_key IS NULL OR c.customer_key IS NULL;
