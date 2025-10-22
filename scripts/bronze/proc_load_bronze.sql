/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `COPY` command to load data from csv Files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    CALL bronze.load_bronze;
===============================================================================
*/
-- ===========================
-- Load and Verify Bronze Tables
-- ===========================

CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $$
DECLARE
    start_time TIMESTAMP;
    end_time   TIMESTAMP;
    load_time  NUMERIC;
	batch_start_time TIMESTAMP;
	batch_end_time TIMESTAMP;
	batch_load_time NUMERIC;
BEGIN
	batch_start_time := CURRENT_TIMESTAMP;
    RAISE NOTICE '==================================';
    RAISE NOTICE 'Starting Bronze Layer Load';
    RAISE NOTICE '==================================';

    -- =====================================================
    -- CRM TABLES
    -- =====================================================
    RAISE NOTICE '--------------------------------------------';
    RAISE NOTICE 'Loading CRM Tables';
    RAISE NOTICE '--------------------------------------------';

    -- crm_cust_info
    start_time := CURRENT_TIMESTAMP;
    TRUNCATE TABLE bronze.crm_cust_info;
    RAISE NOTICE '>> Loading Table: bronze.crm_cust_info';
    COPY bronze.crm_cust_info(cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date)
    FROM '/tmp/postgres_csvs/source_crm/cust_info.csv'
    DELIMITER ',' CSV HEADER;
    end_time := CURRENT_TIMESTAMP;
    load_time := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> Rows Loaded: % | Load Duration: % seconds', (SELECT COUNT(*) FROM bronze.crm_cust_info), load_time;

    -- crm_prd_info
    start_time := CURRENT_TIMESTAMP;
    TRUNCATE TABLE bronze.crm_prd_info;
    RAISE NOTICE '>> Loading Table: bronze.crm_prd_info';
    COPY bronze.crm_prd_info(prd_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt)
    FROM '/tmp/postgres_csvs/source_crm/prd_info.csv'
    DELIMITER ',' CSV HEADER;
    end_time := CURRENT_TIMESTAMP;
    load_time := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> Rows Loaded: % | Load Duration: % seconds', (SELECT COUNT(*) FROM bronze.crm_prd_info), load_time;

    -- crm_sales_details
    start_time := CURRENT_TIMESTAMP;
    TRUNCATE TABLE bronze.crm_sales_details;
    RAISE NOTICE '>> Loading Table: bronze.crm_sales_details';
    COPY bronze.crm_sales_details(sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price)
    FROM '/tmp/postgres_csvs/source_crm/sales_details.csv'
    DELIMITER ',' CSV HEADER;
    end_time := CURRENT_TIMESTAMP;
    load_time := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> Rows Loaded: % | Load Duration: % seconds', (SELECT COUNT(*) FROM bronze.crm_sales_details), load_time;

    -- =====================================================
    -- ERP TABLES
    -- =====================================================
    RAISE NOTICE '--------------------------------------------';
    RAISE NOTICE 'Loading ERP Tables';
    RAISE NOTICE '--------------------------------------------';

    -- erp_loc_a101
    start_time := CURRENT_TIMESTAMP;
    TRUNCATE TABLE bronze.erp_loc_a101;
    RAISE NOTICE '>> Loading Table: bronze.erp_loc_a101';
    COPY bronze.erp_loc_a101(cid, cntry)
    FROM '/tmp/postgres_csvs/source_erp/loc_a101.csv'
    DELIMITER ',' CSV HEADER;
    end_time := CURRENT_TIMESTAMP;
    load_time := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> Rows Loaded: % | Load Duration: % seconds', (SELECT COUNT(*) FROM bronze.erp_loc_a101), load_time;

    -- erp_cust_az12
    start_time := CURRENT_TIMESTAMP;
    TRUNCATE TABLE bronze.erp_cust_az12;
    RAISE NOTICE '>> Loading Table: bronze.erp_cust_az12';
    COPY bronze.erp_cust_az12(cid, bdate, gen)
    FROM '/tmp/postgres_csvs/source_erp/cust_az12.csv'
    DELIMITER ',' CSV HEADER;
    end_time := CURRENT_TIMESTAMP;
    load_time := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> Rows Loaded: % | Load Duration: % seconds', (SELECT COUNT(*) FROM bronze.erp_cust_az12), load_time;

    -- erp_px_cat_g1v2
    start_time := CURRENT_TIMESTAMP;
    TRUNCATE TABLE bronze.erp_px_cat_g1v2;
    RAISE NOTICE '>> Loading Table: bronze.erp_px_cat_g1v2';
    COPY bronze.erp_px_cat_g1v2(id, cat, subcat, maintenance)
    FROM '/tmp/postgres_csvs/source_erp/px_cat_g1v2.csv'
    DELIMITER ',' CSV HEADER;
    end_time := CURRENT_TIMESTAMP;
    load_time := EXTRACT(EPOCH FROM (end_time - start_time));
    RAISE NOTICE '>> Rows Loaded: % | Load Duration: % seconds', (SELECT COUNT(*) FROM bronze.erp_px_cat_g1v2), load_time;

	batch_end_time := CURRENT_TIMESTAMP;
 	batch_load_time := EXTRACT(EPOCH FROM (batch_end_time - batch_start_time));	
    -- =====================================================
    -- Completion Message
    -- =====================================================
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Bronze Layer Loading Completed Successfully';
    RAISE NOTICE '==============================================';
	RAISE NOTICE '>> Total Bronze Layer Load Duration: % seconds', load_time;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '==================================';
        RAISE NOTICE 'ERROR OCCURRED DURING BRONZE LOAD';
        RAISE NOTICE 'ERROR MESSAGE: %', SQLERRM;
        RAISE NOTICE '==================================';
END;
$$;

-- Execute the procedure
CALL bronze.load_bronze();
