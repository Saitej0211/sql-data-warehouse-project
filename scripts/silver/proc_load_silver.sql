/*
===============================================================================
Stored Procedure: silver.load_silver
===============================================================================
Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process 
    to populate the 'silver' schema tables using cleaned and standardized data 
    from the 'bronze' schema.

Actions Performed:
    - Truncates Silver tables before each load.
    - Applies data transformation and cleansing logic on Bronze tables.
    - Inserts validated and standardized records into corresponding Silver tables.
    - Logs timing and load status for each table using RAISE NOTICE messages.

Key Transformations:
    - CRM tables:
        * Deduplicate customer records.
        * Standardize text fields (gender, marital status, etc.).
        * Derive category IDs and compute product end dates.
        * Validate and correct sales, quantity, and pricing.
    - ERP tables:
        * Clean customer and location data.
        * Standardize country and gender fields.
        * Normalize product category hierarchy.

Parameters:
    None.
    This stored procedure does not accept parameters or return values.

Usage Example:
    CALL silver.load_silver();

Schema Dependencies:
    - Source: bronze.crm_cust_info, bronze.crm_prd_info, bronze.crm_sales_details,
              bronze.erp_cust_az12, bronze.erp_loc_a101, bronze.erp_px_cat_g1v2
    - Target: silver.crm_cust_info, silver.crm_prd_info, silver.crm_sales_details,
              silver.erp_cust_az12, silver.erp_loc_a101, silver.erp_px_cat_g1v2

===============================================================================
*/
-- ===========================
-- Load and Transform Silver Tables
-- ===========================

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE
    start_time TIMESTAMP;        -- Tracks start time for each table load
    end_time   TIMESTAMP;        -- Tracks end time for each table load
    load_time  NUMERIC;          -- Stores total duration (in seconds) for each table load
	row_count  BIGINT;			  -- Tracks overall number of rows loaded for each table load
	batch_start_time TIMESTAMP;  -- Tracks overall start time of the Silver load process
	batch_end_time   TIMESTAMP;  -- Tracks overall end time of the Silver load process
BEGIN
	-- Mark start of entire Silver Layer loading process
	batch_start_time := CURRENT_TIMESTAMP;
    RAISE NOTICE '==================================';
    RAISE NOTICE 'Starting Silver Layer Load';
    RAISE NOTICE '==================================';

    -- =====================================================
    -- CRM TABLES
    -- =====================================================
    RAISE NOTICE '--------------------------------------------';
    RAISE NOTICE 'Loading CRM Tables into Silver Layer';
    RAISE NOTICE '--------------------------------------------';

    -- =====================================================
    -- CRM Customer Information
    -- =====================================================
    start_time := CURRENT_TIMESTAMP;
    TRUNCATE TABLE silver.crm_cust_info;  -- Clear previous data before loading new
    RAISE NOTICE '>> Transforming & Loading Table: silver.crm_cust_info';

    -- Insert cleaned and standardized customer data into the Silver Layer
	INSERT INTO silver.crm_cust_info (
	    cst_id, 
	    cst_key, 
	    cst_firstname, 
	    cst_lastname, 
	    cst_marital_status, 
	    cst_gndr, 
	    cst_create_date
	)
	SELECT
	    cst_id, 
	    cst_key, 
	    TRIM(cst_firstname) AS cst_firstname,          -- Removes extra spaces
	    TRIM(cst_lastname) AS cst_lastname,            -- Removes extra spaces
	    CASE                                           
	        WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'     -- Standardize marital status
	        WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
	        ELSE 'n/a'
	    END AS cst_marital_status,
	    CASE
	        WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'               -- Standardize gender
	        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
	        ELSE 'n/a'
	    END AS cst_gndr,
	    cst_create_date
	FROM (
	    SELECT 
	        *,
	        ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
	        -- Keep only the most recent record per customer ID
	    FROM bronze.crm_cust_info
	) t
	WHERE flag_last = 1;

    end_time := CURRENT_TIMESTAMP;
    SELECT COUNT(*) INTO row_count FROM silver.crm_cust_info;
    load_time := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> silver.crm_cust_info Loaded | Rows: % | Duration: % seconds', row_count, load_time;

    -- =====================================================
    -- CRM Product Information
    -- =====================================================
    start_time := CURRENT_TIMESTAMP;
    TRUNCATE TABLE silver.crm_prd_info;
    RAISE NOTICE '>> Transforming & Loading Table: silver.crm_prd_info';

    -- Insert transformed product data into the Silver Layer
	INSERT INTO silver.crm_prd_info (
	    prd_id, 
	    cat_id, 
	    prd_key, 
	    prd_nm, 
	    prd_cost, 
	    prd_line, 
	    prd_start_dt, 
	    prd_end_dt
	)
	SELECT
	    PRD_ID,
	    REPLACE(SUBSTRING(PRD_KEY FROM 1 FOR 5), '-', '_') AS cat_id,  -- Derive category ID from PRD_KEY
	    SUBSTRING(PRD_KEY FROM 7) AS prd_key,                          -- Extract clean product key
	    PRD_NM,
	    COALESCE(PRD_COST, 0) AS prd_cost,                             -- Replace NULL cost with 0
	    CASE UPPER(TRIM(prd_line))                                     -- Standardize product line, Map product line codes to descriptive values
	        WHEN 'M' THEN 'Mountain'
	        WHEN 'R' THEN 'Road'
	        WHEN 'S' THEN 'Other Sales'
	        WHEN 'T' THEN 'Touring'
	        ELSE 'n/a'
	    END AS prd_line,
	    CAST(PRD_START_DT AS DATE) AS prd_start_dt,                    -- Ensure proper date type
	    CAST(LEAD(PRD_START_DT) OVER (
	            PARTITION BY prd_key 
	            ORDER BY prd_start_dt
	        ) - INTERVAL '1 day' AS DATE) AS prd_end_dt                -- Calculate end date as one day before the next start date
	FROM
	    bronze.crm_prd_info;
    end_time := CURRENT_TIMESTAMP;
    SELECT COUNT(*) INTO row_count FROM silver.crm_prd_info;
    load_time := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> silver.crm_prd_info Loaded | Rows: % | Duration: % seconds', row_count, load_time;


    -- =====================================================
    -- CRM Sales Details
    -- =====================================================
    start_time := CURRENT_TIMESTAMP;
    TRUNCATE TABLE silver.crm_sales_details;
    RAISE NOTICE '>> Transforming & Loading Table: silver.crm_sales_details';

    -- Insert cleaned and validated sales data into the Silver Layer
	INSERT INTO silver.crm_sales_details (
	    sls_ord_num,
	    sls_prd_key,
	    sls_cust_id,
	    sls_order_dt,
	    sls_ship_dt,
	    sls_due_dt,
	    sls_sales,
	    sls_quantity,
	    sls_price
	)
	SELECT
	    SLS_ORD_NUM,
	    SLS_PRD_KEY,
	    SLS_CUST_ID,
	    -- Clean and validate ORDER DATE:
	    -- Convert only if date is 8 digits (e.g., 20231022) and non-zero, otherwise set to NULL
	    CASE 
	        WHEN SLS_ORDER_DT = 0 OR LENGTH(SLS_ORDER_DT::text) != 8 THEN NULL
	        ELSE CAST(CAST(SLS_ORDER_DT AS VARCHAR) AS DATE)
	    END AS SLS_ORDER_DT,
	    -- Clean and validate SHIP DATE:
	    CASE 
	        WHEN SLS_SHIP_DT = 0 OR LENGTH(SLS_SHIP_DT::text) != 8 THEN NULL
	        ELSE CAST(CAST(SLS_SHIP_DT AS VARCHAR) AS DATE)
	    END AS SLS_SHIP_DT,
	    -- Clean and validate DUE DATE:
	    CASE 
	        WHEN SLS_DUE_DT = 0 OR LENGTH(SLS_DUE_DT::text) != 8 THEN NULL
	        ELSE CAST(CAST(SLS_DUE_DT AS VARCHAR) AS DATE)
	    END AS SLS_DUE_DT,
	    -- Correct SALES amount:
	    -- If missing, invalid, or inconsistent with (quantity × price),
	    -- then recompute sales as quantity × |price|
	    CASE
	        WHEN SLS_SALES IS NULL OR SLS_SALES <= 0 OR SLS_SALES != SLS_QUANTITY * ABS(SLS_PRICE)
	            THEN SLS_QUANTITY * ABS(SLS_PRICE)
	        ELSE SLS_SALES
	    END AS SLS_SALES,
	    -- Retain quantity as-is
	    SLS_QUANTITY,
	    -- Correct PRICE value:
	    -- If price is missing or invalid (≤ 0),
	    -- then compute price as sales ÷ quantity (avoid division by zero)
	    CASE
	        WHEN SLS_PRICE IS NULL OR SLS_PRICE <= 0
	            THEN SLS_SALES / NULLIF(SLS_QUANTITY, 0)
	        ELSE SLS_PRICE
	    END AS SLS_PRICE
	FROM
	    bronze.crm_sales_details;
    end_time := CURRENT_TIMESTAMP;
    SELECT COUNT(*) INTO row_count FROM silver.crm_sales_details;
    load_time := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> silver.crm_sales_details Loaded | Rows: % | Duration: % seconds', row_count, load_time;

    -- =====================================================
    -- ERP TABLES
    -- =====================================================
    RAISE NOTICE '--------------------------------------------';
    RAISE NOTICE 'Loading ERP Tables into Silver Layer';
    RAISE NOTICE '--------------------------------------------';

    -- =====================================================
    -- ERP Customer Table
    -- =====================================================
    start_time := CURRENT_TIMESTAMP;
    TRUNCATE TABLE silver.erp_cust_az12;
    RAISE NOTICE '>> Transforming & Loading Table: silver.erp_cust_az12';

    -- Insert cleaned and standardized ERP customer data into the Silver Layer
	INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
	SELECT 
	    -- Standardize Customer ID:
	    -- Remove 'NAS' prefix if present, keeping only the numeric or meaningful part
	    CASE 
	        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid FROM 4)
	        ELSE cid
	    END AS cid,
	
	    -- Validate Birth Date:
	    -- If the birth date is greater than the current date (future date), replace it with NULL
	    CASE 
	        WHEN bdate > CURRENT_DATE THEN NULL
	        ELSE bdate
	    END AS bdate,
	
	    -- Standardize Gender:
	    -- Normalize gender values into 'Male', 'Female', or 'n/a' for undefined entries
	    CASE
	        WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
	        WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
	        ELSE 'n/a'
	    END AS gen
	FROM 
	    bronze.erp_cust_az12;
    end_time := CURRENT_TIMESTAMP;
    SELECT COUNT(*) INTO row_count FROM silver.erp_cust_az12;
    load_time := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> silver.erp_cust_az12 Loaded | Rows: % | Duration: % seconds', row_count, load_time;

    -- =====================================================
    -- ERP Location Table
    -- =====================================================
    start_time := CURRENT_TIMESTAMP;
    TRUNCATE TABLE silver.erp_loc_a101;
    RAISE NOTICE '>> Transforming & Loading Table: silver.erp_loc_a101';

    -- Insert cleaned and standardized location data into the Silver Layer
	INSERT INTO silver.erp_loc_a101 (cid, cntry)
	SELECT 
	    -- Clean Customer ID:
	    -- Remove hyphens (‘-’) from the customer ID for consistent formatting
	    REPLACE(cid, '-', '') AS cid,
	    -- Standardize Country Names:
	    CASE 
	        WHEN TRIM(cntry) = 'DE' THEN 'Germany'              -- Convert DE → Germany
	        WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States' -- Convert US/USA → United States
	        WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'   -- Handle missing or empty country values
	        ELSE TRIM(cntry)                                    -- Keep existing cleaned country name
	    END AS cntry
	FROM 
	    bronze.erp_loc_a101;
    end_time := CURRENT_TIMESTAMP;
    SELECT COUNT(*) INTO row_count FROM silver.erp_loc_a101;
    load_time := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> silver.erp_loc_a101 Loaded | Rows: % | Duration: % seconds', row_count, load_time;

    -- =====================================================
    -- ERP Product Category Table
    -- =====================================================
    start_time := CURRENT_TIMESTAMP;
    TRUNCATE TABLE silver.erp_px_cat_g1v2;
    RAISE NOTICE '>> Loading Table: silver.erp_px_cat_g1v2';

    -- Load ERP Product Category data from Bronze to Silver Layer
	INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
	SELECT 
	    id,              -- Unique identifier for the record
	    cat,             -- Product category (e.g., Electronics, Apparel)
	    subcat,          -- Product subcategory (e.g., Phones, Shoes)
	    maintenance      -- Maintenance-related attribute or flag
	FROM 
	    bronze.erp_px_cat_g1v2;
    end_time := CURRENT_TIMESTAMP;
    SELECT COUNT(*) INTO row_count FROM silver.erp_px_cat_g1v2;
    load_time := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> silver.erp_px_cat_g1v2 Loaded | Rows: % | Duration: % seconds', row_count, load_time;

    -- =====================================================
    -- Completion Message
    -- =====================================================
    batch_end_time := CURRENT_TIMESTAMP;
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Silver Layer Loading Completed Successfully';
    RAISE NOTICE 'Total Duration: % seconds', EXTRACT(EPOCH FROM (batch_end_time - batch_start_time));
    RAISE NOTICE '==============================================';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '==================================';
        RAISE NOTICE 'ERROR OCCURRED DURING SILVER LOAD';
        RAISE NOTICE 'ERROR MESSAGE: %', SQLERRM;
        RAISE NOTICE '==================================';
END;
$$;

-- Execute the procedure
CALL silver.load_silver();
