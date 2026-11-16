
/*
==================================================
Create Gold View: fact_sales
==================================================
Purpose:
    Create a sales fact view by integrating sales
    transactions with customer and product dimensions.

Sources:
    silver.crm_sales_details
    gold.dim_products
    gold.dim_customer

Grain:
    One row per sales order-product line.
==================================================
*/

CREATE OR REPLACE VIEW gold.fact_sales AS

SELECT
    sd.sls_ord_num AS order_number,
    dp.product_key,
    dc.customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS shipping_date,
    sd.sls_due_dt AS due_date,
    sd.sls_sales AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price AS price

FROM silver.crm_sales_details AS sd

LEFT JOIN gold.dim_products AS dp
    ON sd.sls_prd_key = dp.product_number

LEFT JOIN gold.dim_customer AS dc
    ON sd.sls_cust_id = dc.customer_id;
