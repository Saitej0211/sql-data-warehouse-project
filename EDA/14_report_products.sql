/*
=========================================================================================
📦 CREATE VIEW: GOLD.REPORT_PRODUCTS
-----------------------------------------------------------------------------------------
Purpose:
- This report consolidates key product metrics and behaviors.

Highlights:
1. Gathers essential fields such as product name, category, subcategory, and cost.
2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
3. Aggregates product-level metrics:
- total orders
- total sales
- total quantity sold
- total customers (unique)
- lifespan (in months)
4. Calculates valuable KPIs:
recency (months since last sale)
- average order revenue (AOR)
- average monthly revenue
============================================================================================
/*==============================================================================
1) Base Query: Retrieves core columns from tables
==============================================================================*/
WITH BASE_QUERY AS (
	SELECT
		P.PRODUCT_KEY,
		P.PRODUCT_NAME,
		P.CATEGORY,
		P.SUB_CATEGORY,
		P.COST,
		F.ORDER_NUMBER,
		F.CUSTOMER_KEY,
		F.ORDER_DATE,
		F.SALES_AMOUNT,
		F.QUANTITY
	FROM GOLD.FACT_SALES F
	LEFT JOIN GOLD.DIM_PRODUCTS P ON P.PRODUCT_KEY = F.PRODUCT_KEY
	WHERE F.ORDER_DATE IS NOT NULL
),
/*==============================================================================
2) Product Aggregations: Summarizes key metrics at the Product level
==============================================================================*/
PRODUCT_AGGREGATIONS AS (
	SELECT
		PRODUCT_KEY,
		PRODUCT_NAME,
		CATEGORY,
		SUB_CATEGORY,
		(
			EXTRACT(YEAR FROM AGE(MAX(ORDER_DATE), MIN(ORDER_DATE))) * 12 +
			EXTRACT(MONTH FROM AGE(MAX(ORDER_DATE), MIN(ORDER_DATE)))
		) AS LIFE_SPAN,
		MAX(ORDER_DATE) AS LAST_SALE_DATE,
		COUNT(DISTINCT ORDER_NUMBER) AS TOTAL_ORDERS,
		COUNT(DISTINCT CUSTOMER_KEY) AS TOTAL_CUSTOMERS,
		SUM(SALES_AMOUNT) AS TOTAL_SALES,
		SUM(QUANTITY) AS TOTAL_QUANTITY,
		-- ⚡ Average Selling Price (ASP)
		ROUND(AVG(CAST(SALES_AMOUNT AS NUMERIC) / NULLIF(QUANTITY, 0)), 1) AS AVG_SELLING_PRICE
	FROM BASE_QUERY
	GROUP BY PRODUCT_KEY, PRODUCT_NAME, CATEGORY, SUB_CATEGORY
)
SELECT
	PRODUCT_KEY,
	PRODUCT_NAME,
	CATEGORY,
	SUB_CATEGORY,
	LIFE_SPAN,
	LAST_SALE_DATE,
	-- ⚡ Recency in months since last sale
	(EXTRACT(YEAR FROM AGE(CURRENT_DATE, LAST_SALE_DATE)) * 12 +
	 EXTRACT(MONTH FROM AGE(CURRENT_DATE, LAST_SALE_DATE))) AS RECENCY_IN_MONTHS,
	-- ⚡ Segment products by revenue performance
	CASE
		WHEN TOTAL_SALES > 50000 THEN 'High-Performer'
		WHEN TOTAL_SALES BETWEEN 10000 AND 50000 THEN 'Mid-Range'
		ELSE 'Low-Performer'
	END AS PRODUCT_SEGMENT,
	TOTAL_ORDERS,
	TOTAL_SALES,
	TOTAL_CUSTOMERS,
	TOTAL_QUANTITY,
	AVG_SELLING_PRICE,
	-- ⚡ Average Order Revenue (AOR)
	CASE WHEN TOTAL_ORDERS = 0 THEN 0 ELSE ROUND(TOTAL_SALES / TOTAL_ORDERS, 2) END AS AVG_ORDER_REVENUE,
	-- ⚡ Average Monthly Revenue
	CASE WHEN LIFE_SPAN = 0 THEN ROUND(TOTAL_SALES, 2) ELSE ROUND(TOTAL_SALES / LIFE_SPAN, 2) END AS AVG_MONTHLY_REVENUE
FROM PRODUCT_AGGREGATIONS;
