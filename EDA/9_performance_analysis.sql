/*
==============================================================================
📈 CUMULATIVE ANALYSIS
------------------------------------------------------------------------------
Purpose:
- Show cumulative (running total) sales across months and years.
==============================================================================
*/

-- Compute cumulative sales per year
SELECT
    ORDER_DATE,
    TOTAL_SALES,
    SUM(TOTAL_SALES) OVER (
        PARTITION BY DATE_TRUNC('Year', ORDER_DATE)
        ORDER BY ORDER_DATE
    ) AS RUNNING_TOTAL_SALES
FROM (
    SELECT
        DATE_TRUNC('month', ORDER_DATE) AS ORDER_DATE,
        SUM(SALES_AMOUNT) AS TOTAL_SALES
    FROM GOLD.FACT_SALES
    WHERE ORDER_DATE IS NOT NULL
    GROUP BY DATE_TRUNC('month', ORDER_DATE)
    ORDER BY DATE_TRUNC('month', ORDER_DATE)
) sub;

-- Add moving average to monitor sales trends over time
SELECT
    ORDER_DATE,
    TOTAL_SALES,
    SUM(TOTAL_SALES) OVER (ORDER BY ORDER_DATE) AS RUNNING_TOTAL_SALES,
    ROUND(AVG_PRICE, 2) AS AVG_PRICE,
    AVG(AVG_PRICE) OVER (ORDER BY ORDER_DATE) AS MOVING_AVG_PRICE
FROM (
    SELECT
        DATE_TRUNC('Year', ORDER_DATE) AS ORDER_DATE,
        SUM(SALES_AMOUNT) AS TOTAL_SALES,
        AVG(PRICE) AS AVG_PRICE
    FROM GOLD.FACT_SALES
    WHERE ORDER_DATE IS NOT NULL
    GROUP BY DATE_TRUNC('Year', ORDER_DATE)
) sub;
