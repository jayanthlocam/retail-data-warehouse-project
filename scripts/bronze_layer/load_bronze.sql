/*
===============================================================================
Stored Procedure: bronze.load_bronze
===============================================================================

Purpose:
    Loads source CRM and ERP data from CSV files into the Bronze layer tables
    of the Retail Data Warehouse.

Procedure Parameters:
    p_source_crm_dir : Directory path containing CRM source CSV files.
    p_source_erp_dir : Directory path containing ERP source CSV files.

Loading Process:
    1. Validates the input directory paths to ensure they are not NULL or empty.
    2. Truncates all existing records from the six Bronze layer tables.
    3. Loads CRM data from the following source files:
          - cust_info.csv
          - prd_info.csv
          - sales_details.csv
    4. Loads ERP data from the following source files:
          - cust_az12.csv
          - loc_a101.csv
          - px_cat_g1v2.csv
    5. Captures the number of rows loaded into each table using GET DIAGNOSTICS.
    6. Displays loading progress and completion messages using RAISE NOTICE.

Loading Strategy:
    Full Refresh - Existing records are removed before loading fresh data.
    All loading operations execute within the transaction of the CALL statement.
    If an error occurs, the failed CALL is rolled back when the error is unhandled.

Prerequisites:
    - The datawarehouse database and Bronze schema must already exist.
    - All six Bronze tables must be created before executing this procedure.
    - Source CSV files must be available in the specified directories.
    - The PostgreSQL server process must have permission to read the CSV files.
    - CSV column order and data types must match the target table definitions.

Execution:
    CALL bronze.load_bronze(
        'C:/path/to/source_crm',
        'C:/path/to/source_erp'
    );

===============================================================================
*/
CREATE OR REPLACE PROCEDURE bronze.load_bronze(
	p_source_crm_dir TEXT,
	p_source_erp_dir TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
	v_rows BIGINT;
	v_start_time TIMESTAMPTZ;
    v_table_start_time TIMESTAMPTZ;
    v_table_end_time TIMESTAMPTZ;
    v_table_elapsed NUMERIC;
    v_total_elapsed NUMERIC;
BEGIN 
	-- Start the overall procedure timer
    v_start_time := clock_timestamp();
	
	--1.Validate the Input Parameters
	IF p_source_crm_dir IS NULL OR BTRIM(p_source_crm_dir)='' THEN 
		RAISE EXCEPTION 'CRM Directory Should not be empty';
	END IF;

	IF p_source_erp_dir IS NULL OR BTRIM(p_source_erp_dir)='' THEN 
		RAISE EXCEPTION 'ERP Directory Should not be empty';
	END IF;
	
	--2.Truncate Existing Records
	TRUNCATE TABLE
		bronze.crm_cust_info,
	    bronze.crm_prd_info,
	    bronze.crm_sales_details,
	    bronze.erp_cust_az12,
	    bronze.erp_loc_a101,
	    bronze.erp_px_cat_g1v2;

	--3.Load CRM tables
	--A.load Cust_info
	v_table_start_time := clock_timestamp();

	EXECUTE FORMAT(
		$copy$
			COPY bronze.crm_cust_info
			FROM %L
			WITH(FORMAT CSV,HEADER True,DELIMITER ',')
		$copy$,
		RTRIM(p_source_crm_dir,'/') || '/cust_info.csv'
	);
	v_table_end_time := clock_timestamp();
	GET DIAGNOSTICS v_rows=ROW_COUNT;
	v_table_elapsed := EXTRACT(
        EPOCH FROM (v_table_end_time - v_table_start_time)
    );
	RAISE NOTICE 'Loaded % records into bronze.crm_cust_info in % seconds',v_rows, ROUND(v_table_elapsed, 3);
	
	--B.load prd_info
	v_table_start_time := clock_timestamp();
	EXECUTE FORMAT(
		$copy$
			COPY bronze.crm_prd_info
			FROM %L
			WITH(FORMAT CSV,HEADER True,DELIMITER ',')
		$copy$,
		RTRIM(p_source_crm_dir,'/') || '/prd_info.csv'
	);
	v_table_end_time := clock_timestamp();
    GET DIAGNOSTICS v_rows = ROW_COUNT;

    v_table_elapsed := EXTRACT(
        EPOCH FROM (v_table_end_time - v_table_start_time)
    );

    RAISE NOTICE 'Loaded % records into bronze.crm_prd_info in % seconds',v_rows, ROUND(v_table_elapsed, 3);
	
	--C.Load sales_details
	v_table_start_time := clock_timestamp();
	EXECUTE FORMAT(
		$copy$
			COPY bronze.crm_sales_details 
			FROM %L
			WITH(FORMAT CSV,HEADER True,DELIMITER ',')
		$copy$,
		RTRIM(p_source_crm_dir,'/') || '/sales_details.csv'
	);
	 v_table_end_time := clock_timestamp();
    GET DIAGNOSTICS v_rows = ROW_COUNT;

    v_table_elapsed := EXTRACT(
        EPOCH FROM (v_table_end_time - v_table_start_time)
    );

    RAISE NOTICE 'Loaded % records into bronze.crm_sales_details in % seconds',v_rows, ROUND(v_table_elapsed, 3);
	
	--4.Load ERP tables
	--A.load cust_az12
	v_table_start_time := clock_timestamp();
	EXECUTE FORMAT(
		$copy$
			COPY bronze.erp_cust_az12
			FROM %L
			WITH(FORMAT CSV,HEADER True,DELIMITER ',')
		$copy$,
		RTRIM(p_source_erp_dir,'/') || '/cust_az12.csv'
	);
	v_table_end_time := clock_timestamp();
    GET DIAGNOSTICS v_rows = ROW_COUNT;

    v_table_elapsed := EXTRACT(
        EPOCH FROM (v_table_end_time - v_table_start_time)
    );

    RAISE NOTICE 'Loaded % records into bronze.erp_cust_az12 in % seconds',v_rows, ROUND(v_table_elapsed, 3);
	
	--B.load loc_a101
	v_table_start_time := clock_timestamp();
	EXECUTE FORMAT(
		$copy$
			COPY bronze.erp_loc_a101
			FROM %L
			WITH(FORMAT CSV,HEADER True,DELIMITER ',')
		$copy$,
		RTRIM(p_source_erp_dir,'/') || '/loc_a101.csv'
	);
	v_table_end_time := clock_timestamp();
    GET DIAGNOSTICS v_rows = ROW_COUNT;

    v_table_elapsed := EXTRACT(
        EPOCH FROM (v_table_end_time - v_table_start_time)
    );

    RAISE NOTICE 'Loaded % records into bronze.erp_loc_a101 in % seconds',v_rows, ROUND(v_table_elapsed, 3);
	
	--C.load px_cat_g1v2
	v_table_start_time := clock_timestamp();
	EXECUTE FORMAT(
		$copy$
			COPY bronze.erp_px_cat_g1v2
			FROM %L
			WITH(FORMAT CSV,HEADER True,DELIMITER ',')
		$copy$,
		RTRIM(p_source_erp_dir,'/') || '/px_cat_g1v2.csv'
	);
	v_table_end_time := clock_timestamp();
    GET DIAGNOSTICS v_rows = ROW_COUNT;

    v_table_elapsed := EXTRACT(
        EPOCH FROM (v_table_end_time - v_table_start_time)
    );

    RAISE NOTICE 'Loaded % records into bronze.erp_px_cat_g1v2 in % seconds',v_rows, ROUND(v_table_elapsed, 3);

	--5.Display Completion message
	RAISE NOTICE 'Bronze Layer Loading Successfully Completed';

    -- Calculate total procedure execution time
    v_total_elapsed := EXTRACT(
        EPOCH FROM (clock_timestamp() - v_start_time)
    );

    RAISE NOTICE 'Total Bronze Layer Execution Time: % seconds',ROUND(v_total_elapsed, 3);
		
END;
$$
