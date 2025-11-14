/*
==============================================================================
🥧 PART-TO-WHOLE ANALYSIS
------------------------------------------------------------------------------
Purpose:
- Show contribution of each product category to total sales.
==============================================================================
*/

WITH CATEGORY_SALES AS (
    SELECT
        P.CATEGORY,
        SUM(F.SALES_AMOUNT) AS TOTAL_SALES
    FROM GOLD.FACT_SALES F
    LEFT JOIN GOLD.DIM_PRODUCTS P ON P.PRODUCT_KEY = F.PRODUCT_KEY
    GROUP BY CATEGORY
)
SELECT
    CATEGORY,
    TOTAL_SALES,
    SUM(TOTAL_SALES) OVER () AS OVERALL_SALES,
    TO_CHAR((TOTAL_SALES * 100.0 / SUM(TOTAL_SALES) OVER ()), 'FM90.00%') AS PERCENTAGE_OF_TOTAL
FROM CATEGORY_SALES;
