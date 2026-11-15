
/*
==================================================
Silver Layer - Full Refresh Data Loading
==================================================

1. Truncate existing Silver tables.
2. Transform and cleanse data from Bronze.
3. Insert transformed data into Silver tables.
4. Log records loaded and execution time per table.
5. Display total execution time.
==================================================
Execute Silver Layer Loading Procedure
==================================================


CALL silver.load_silver();
==================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$

DECLARE
    v_start_time        TIMESTAMPTZ;
    v_step_start_time   TIMESTAMPTZ;
    v_step_end_time     TIMESTAMPTZ;
    v_table_start_time  TIMESTAMPTZ;
    v_table_end_time    TIMESTAMPTZ;

    v_row_count         BIGINT;
    v_step_elapsed      NUMERIC;
    v_table_elapsed     NUMERIC;
    v_total_elapsed     NUMERIC;

BEGIN

    v_start_time := clock_timestamp();

    RAISE NOTICE '===============STARTING SILVER LAYER FULL REFRESH===============';


    /*
    ==================================================
    STEP 1: Truncate Existing Silver Tables
    ==================================================
    */

    v_step_start_time := clock_timestamp();

    RAISE NOTICE '===============STEP 1: Truncate Existing Silver Tables===============';

    TRUNCATE TABLE
        silver.crm_cust_info,
        silver.crm_prd_info,
        silver.crm_sales_details,
        silver.erp_cust_az12,
        silver.erp_loc_a101,
        silver.erp_px_cat_g1v2;

    v_step_end_time := clock_timestamp();

    v_step_elapsed := EXTRACT(
        EPOCH FROM (v_step_end_time - v_step_start_time)
    );

    RAISE NOTICE 'Silver tables truncated in % seconds',
        ROUND(v_step_elapsed, 3);


    /*
    ==================================================
    STEP 2: Load CRM Customer Information
    ==================================================
    */

    v_table_start_time := clock_timestamp();

    RAISE NOTICE '===============STEP 2: Load CRM Customer Information===============';

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

        -- Remove unwanted spaces and handle empty strings
        NULLIF(TRIM(cst_firstname), '') AS cst_firstname,
        NULLIF(TRIM(cst_lastname), '') AS cst_lastname,

        -- Standardize marital status
        CASE
            WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
            WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
            ELSE 'n/a'
        END AS cst_marital_status,

        -- Standardize gender
        CASE
            WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
            WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
            ELSE 'n/a'
        END AS cst_gndr,

        cst_create_date

    FROM (
        SELECT *,
            ROW_NUMBER() OVER (
                PARTITION BY cst_id
                ORDER BY cst_create_date DESC NULLS LAST
            ) AS flag_latest
        FROM bronze.crm_cust_info
        WHERE cst_id IS NOT NULL
    ) t
    WHERE flag_latest = 1;

    v_table_end_time := clock_timestamp();

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_table_elapsed := EXTRACT(
        EPOCH FROM (v_table_end_time - v_table_start_time)
    );

    RAISE NOTICE 'Loaded % records into silver.crm_cust_info in % seconds',
        v_row_count, ROUND(v_table_elapsed, 3);


    /*
    ==================================================
    STEP 3: Load CRM Product Information
    ==================================================
    */

    v_table_start_time := clock_timestamp();

    RAISE NOTICE '===============STEP 3: Load CRM Product Information===============';

    INSERT INTO silver.crm_prd_info (
        prd_id,
        prd_cat_id,
        prd_key,
        prd_name,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
    )
    SELECT
        prd_id,

        -- Extract product category ID
        REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS prd_cat_id,

        -- Extract product key
        SUBSTRING(prd_key FROM 7) AS prd_key,

        prd_name,

        -- Replace missing product cost
        COALESCE(prd_cost, 0) AS prd_cost,

        -- Standardize product line
        CASE UPPER(TRIM(prd_line))
            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'T' THEN 'Touring'
            ELSE 'n/a'
        END AS prd_line,

        -- Convert product start date
        prd_start_dt::DATE AS prd_start_dt,

        -- Calculate product end date using the next version's start date
        (
            LEAD(prd_start_dt::DATE) OVER (
                PARTITION BY prd_key
                ORDER BY prd_start_dt, prd_id
            ) - 1
        ) AS prd_end_dt

    FROM bronze.crm_prd_info;

    v_table_end_time := clock_timestamp();

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_table_elapsed := EXTRACT(
        EPOCH FROM (v_table_end_time - v_table_start_time)
    );

    RAISE NOTICE 'Loaded % records into silver.crm_prd_info in % seconds',
        v_row_count, ROUND(v_table_elapsed, 3);


    /*
    ==================================================
    STEP 4: Load CRM Sales Details
    ==================================================
    */

    v_table_start_time := clock_timestamp();

    RAISE NOTICE '===============STEP 4: Load CRM Sales Details===============';

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
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,

        -- Convert order date from YYYYMMDD integer to DATE
        CASE
            WHEN sls_order_dt IS NULL
              OR sls_order_dt = 0
              OR LENGTH(sls_order_dt::TEXT) <> 8
                THEN NULL
            ELSE TO_DATE(sls_order_dt::TEXT, 'YYYYMMDD')
        END AS sls_order_dt,

        -- Convert shipping date from YYYYMMDD integer to DATE
        CASE
            WHEN sls_ship_dt IS NULL
              OR sls_ship_dt = 0
              OR LENGTH(sls_ship_dt::TEXT) <> 8
                THEN NULL
            ELSE TO_DATE(sls_ship_dt::TEXT, 'YYYYMMDD')
        END AS sls_ship_dt,

        -- Convert due date from YYYYMMDD integer to DATE
        CASE
            WHEN sls_due_dt IS NULL
              OR sls_due_dt = 0
              OR LENGTH(sls_due_dt::TEXT) <> 8
                THEN NULL
            ELSE TO_DATE(sls_due_dt::TEXT, 'YYYYMMDD')
        END AS sls_due_dt,

        -- Recalculate sales when missing, non-positive or inconsistent
        CASE
            WHEN sls_sales IS NULL
              OR sls_sales <= 0
              OR (
                  sls_price IS NOT NULL
                  AND sls_sales <> sls_quantity * ABS(sls_price)
              )
                THEN COALESCE(
                    sls_quantity * ABS(sls_price),
                    sls_sales
                )
            ELSE sls_sales
        END AS sls_sales,

        sls_quantity,

        -- Recalculate price when missing or non-positive
        CASE
            WHEN sls_price IS NULL OR sls_price <= 0
                THEN ROUND(
                    sls_sales::NUMERIC / NULLIF(sls_quantity, 0)
                )::INT
            ELSE ABS(sls_price)
        END AS sls_price

    FROM bronze.crm_sales_details;

    v_table_end_time := clock_timestamp();

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_table_elapsed := EXTRACT(
        EPOCH FROM (v_table_end_time - v_table_start_time)
    );

    RAISE NOTICE 'Loaded % records into silver.crm_sales_details in % seconds',
        v_row_count, ROUND(v_table_elapsed, 3);


    /*
    ==================================================
    STEP 5: Load ERP Customer Information
    ==================================================
    */

    v_table_start_time := clock_timestamp();

    RAISE NOTICE '===============STEP 5: Load ERP Customer Information===============';

    INSERT INTO silver.erp_cust_az12 (
        cid,
        bdate,
        gen
    )
    SELECT
        -- Remove NAS prefix from customer ID
        CASE
            WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid FROM 4)
            ELSE cid
        END AS cid,

        bdate,

        -- Standardize gender
        CASE
            WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
            WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
            ELSE 'n/a'
        END AS gen

    FROM bronze.erp_cust_az12;

    v_table_end_time := clock_timestamp();

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_table_elapsed := EXTRACT(
        EPOCH FROM (v_table_end_time - v_table_start_time)
    );

    RAISE NOTICE 'Loaded % records into silver.erp_cust_az12 in % seconds',
        v_row_count, ROUND(v_table_elapsed, 3);


    /*
    ==================================================
    STEP 6: Load ERP Location Information
    ==================================================
    */

    v_table_start_time := clock_timestamp();

    RAISE NOTICE '===============STEP 6: Load ERP Location Information===============';

    INSERT INTO silver.erp_loc_a101 (
        cid,
        cntry
    )
    SELECT
        -- Remove unwanted hyphens from customer ID
        REPLACE(cid, '-', '') AS cid,

        -- Standardize country names
        CASE
            WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
            WHEN UPPER(TRIM(cntry)) IN ('US', 'USA') THEN 'United States'
            WHEN cntry IS NULL OR TRIM(cntry) = '' THEN 'n/a'
            ELSE TRIM(cntry)
        END AS cntry

    FROM bronze.erp_loc_a101;

    v_table_end_time := clock_timestamp();

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_table_elapsed := EXTRACT(
        EPOCH FROM (v_table_end_time - v_table_start_time)
    );

    RAISE NOTICE 'Loaded % records into silver.erp_loc_a101 in % seconds',
        v_row_count, ROUND(v_table_elapsed, 3);


    /*
    ==================================================
    STEP 7: Load ERP Product Category Information
    ==================================================
    */

    v_table_start_time := clock_timestamp();

    RAISE NOTICE '===============STEP 7: Load ERP Product Category Information===============';

    INSERT INTO silver.erp_px_cat_g1v2 (
        id,
        cat,
        subcat,
        maintenance
    )
    SELECT
        id,
        cat,
        subcat,
        maintenance

    FROM bronze.erp_px_cat_g1v2;

    v_table_end_time := clock_timestamp();

    GET DIAGNOSTICS v_row_count = ROW_COUNT;

    v_table_elapsed := EXTRACT(
        EPOCH FROM (v_table_end_time - v_table_start_time)
    );

    RAISE NOTICE 'Loaded % records into silver.erp_px_cat_g1v2 in % seconds',
        v_row_count, ROUND(v_table_elapsed, 3);


    /*
    ==================================================
    STEP 8: Total Execution Time
    ==================================================
    */

    v_total_elapsed := EXTRACT(
        EPOCH FROM (clock_timestamp() - v_start_time)
    );

    RAISE NOTICE '
==================================================
SILVER LAYER LOAD COMPLETED SUCCESSFULLY
==================================================
Total execution time: % seconds
==================================================
', ROUND(v_total_elapsed, 3);

END;
$$;
