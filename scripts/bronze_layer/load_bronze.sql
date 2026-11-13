/*
=========================================================
Load Data into Bronze Layer
=========================================================

Purpose:
    Full refresh of all Bronze layer tables.

Process:
    1. Clear existing records from all six tables.
    2. Load fresh data from source CSV files.
    3. Commit all changes together.

Important:
    Replace the file paths with your local CSV directory.
    PostgreSQL server must have permission to read these files.

=========================================================
*/

BEGIN;

-- =============================================
-- 1. Clear Existing Records
-- =============================================

TRUNCATE TABLE
    bronze.crm_cust_info,
    bronze.crm_prd_info,
    bronze.crm_sales_details,
    bronze.erp_cust_az12,
    bronze.erp_loc_a101,
    bronze.erp_px_cat_g1v2;


-- =============================================
-- 2. Load CRM Tables
-- =============================================

-- Load crm_cust_info
COPY bronze.crm_cust_info (
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date
)
FROM 'C:/REPLACE_WITH_YOUR_LOCAL_DATA_DIRECTORY/source_crm/cust_info.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);


-- Load crm_prd_info
COPY bronze.crm_prd_info (
    prd_id,
    prd_key,
    prd_name,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
)
FROM 'C:/REPLACE_WITH_YOUR_LOCAL_DATA_DIRECTORY/source_crm/prd_info.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);


-- Load crm_sales_details
COPY bronze.crm_sales_details (
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
FROM 'C:/REPLACE_WITH_YOUR_LOCAL_DATA_DIRECTORY/source_crm/sales_details.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);


-- =============================================
-- 3. Load ERP Tables
-- =============================================

-- Load erp_cust_az12
COPY bronze.erp_cust_az12 (
    cid,
    bdate,
    gen
)
FROM 'C:/REPLACE_WITH_YOUR_LOCAL_DATA_DIRECTORY/source_erp/cust_az12.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);


-- Load erp_loc_a101
COPY bronze.erp_loc_a101 (
    cid,
    cntry
)
FROM 'C:/REPLACE_WITH_YOUR_LOCAL_DATA_DIRECTORY/source_erp/loc_a101.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);


-- Load erp_px_cat_g1v2
COPY bronze.erp_px_cat_g1v2 (
    id,
    cat,
    subcat,
    maintenance
)
FROM 'C:/REPLACE_WITH_YOUR_LOCAL_DATA_DIRECTORY/source_erp/px_cat_g1v2.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);


COMMIT;
