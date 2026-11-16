
/*
==================================================
Create Gold View: dim_products
==================================================
Purpose:
    Create a business-friendly product dimension
    by integrating CRM product information with
    ERP product category information.

Sources:
    silver.crm_prd_info
    silver.erp_px_cat_g1v2
==================================================
*/

CREATE OR REPLACE VIEW gold.dim_products AS

SELECT
    ROW_NUMBER() OVER (
        ORDER BY pi.prd_start_dt, pi.prd_key
    ) AS product_key,

    pi.prd_id AS product_id,
    pi.prd_key AS product_number,
    pi.prd_name AS product_name,
    pi.prd_cat_id AS category_id,
    pc.cat AS category,
    pc.subcat AS subcategory,
    pc.maintenance AS maintenance,
    pi.prd_cost AS cost,
    pi.prd_line AS product_line,
    pi.prd_start_dt AS start_date,
    pi.prd_end_dt AS end_date

FROM silver.crm_prd_info AS pi

LEFT JOIN silver.erp_px_cat_g1v2 AS pc
    ON pi.prd_cat_id = pc.id;
