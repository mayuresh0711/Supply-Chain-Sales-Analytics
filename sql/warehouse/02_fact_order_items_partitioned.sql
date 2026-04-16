/* ============================================================================
   FILE: 02_fact_order_items_partitioned.sql
   LAYER: Warehouse
   PURPOSE:
     - Create partitioned fact table (order_item grain)
     - Load data from staging with surrogate key resolution
     - Partition by order_date_id (YEAR-based range partitions)

   GRAIN:
     One row = ONE order_item

   NOTE:
     - Fact table is partitioned by design (not optional)
     - No non-partitioned base table exists in final state
============================================================================ */


/* ============================================================================
   1. FACT TABLE (PARENT) — PARTITIONED
============================================================================ */

DROP TABLE IF EXISTS warehouse.fact_order_items CASCADE;

CREATE TABLE warehouse.fact_order_items (
    order_item_key              serial PRIMARY KEY,

    -- Surrogate keys
    customer_key                int REFERENCES warehouse.dim_customer(customer_key),
    product_key                 int REFERENCES warehouse.dim_product(product_key),
    order_date_id               date NOT NULL REFERENCES warehouse.dim_date(date_id),
    shipping_date_id            date REFERENCES warehouse.dim_date(date_id),

    -- Timestamps
    order_datetime              timestamp,
    shipping_datetime           timestamp,

    -- Business identifiers
    order_id                    text,
    order_item_id               text,

    -- Measures
    order_item_quantity         int,
    order_item_product_price    numeric(12,2),
    order_item_discount         numeric(12,2),
    order_item_discount_rate    numeric(10,4),
    order_item_total            numeric(12,2),
    order_item_profit_ratio     numeric(10,4),
    order_profit_per_order      numeric(12,2),
    benefit_per_order           numeric(12,2),
    sales_per_customer          numeric(12,2),
    sales                       numeric(12,2),

    -- Delivery metrics
    late_delivery_risk          int,
    delivery_status             text,
    days_for_shipping_real      int,
    days_for_shipment_scheduled int,

    -- Geography & market
    order_city                  text,
    order_state                 text,
    order_country               text,
    order_region                text,
    market                      text,

    -- Payment & shipping
    payment_type                text,
    shipping_mode               text,
    order_status                text

) PARTITION BY RANGE (order_date_id);



/* ============================================================================
   2. YEAR PARTITIONS
============================================================================ */

CREATE TABLE warehouse.fact_order_items_2015
    PARTITION OF warehouse.fact_order_items
    FOR VALUES FROM ('2015-01-01') TO ('2016-01-01');

CREATE TABLE warehouse.fact_order_items_2016
    PARTITION OF warehouse.fact_order_items
    FOR VALUES FROM ('2016-01-01') TO ('2017-01-01');

CREATE TABLE warehouse.fact_order_items_2017
    PARTITION OF warehouse.fact_order_items
    FOR VALUES FROM ('2017-01-01') TO ('2018-01-01');

CREATE TABLE warehouse.fact_order_items_2018
    PARTITION OF warehouse.fact_order_items
    FOR VALUES FROM ('2018-01-01') TO ('2019-01-01');


/* ============================================================================
   3. LOAD FACT DATA (STAGING → WAREHOUSE)
============================================================================ */

INSERT INTO warehouse.fact_order_items (
    customer_key,
    product_key,
    order_date_id,
    shipping_date_id,
    order_datetime,
    shipping_datetime,
    order_id,
    order_item_id,
    order_item_quantity,
    order_item_product_price,
    order_item_discount,
    order_item_discount_rate,
    order_item_total,
    order_item_profit_ratio,
    order_profit_per_order,
    benefit_per_order,
    sales_per_customer,
    sales,
    late_delivery_risk,
    delivery_status,
    days_for_shipping_real,
    days_for_shipment_scheduled,
    order_city,
    order_state,
    order_country,
    order_region,
    market,
    payment_type,
    shipping_mode,
    order_status
)
SELECT
    c.customer_key,
    p.product_key,
    o.order_datetime::date,
    o.shipping_datetime::date,
    o.order_datetime,
    o.shipping_datetime,
    o.order_id,
    o.order_item_id,
    o.order_item_quantity,
    o.order_item_product_price,
    o.order_item_discount,
    o.order_item_discount_rate,
    o.order_item_total,
    o.order_item_profit_ratio,
    o.order_profit_per_order,
    o.benefit_per_order,
    o.sales_per_customer,
    o.sales,
    o.late_delivery_risk,
    o.delivery_status,
    o.days_for_shipping_real,
    o.days_for_shipment_scheduled,
    o.order_city,
    o.order_state,
    o.order_country,
    o.order_region,
    o.market,
    o.type,              -- payment_type
    o.shipping_mode,
    o.order_status
FROM staging.dataco_clean o
LEFT JOIN warehouse.dim_customer c
    ON o.customer_id = c.customer_id
LEFT JOIN warehouse.dim_product p
    ON o.product_card_id = p.product_card_id
WHERE o.order_datetime IS NOT NULL;



/* ============================================================================
   4. POST-LOAD VALIDATION
============================================================================ */
--Validation Query

select * from warehouse.fact_order_items limit 100;


SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'warehouse'
  AND table_name = 'fact_order_items'
ORDER BY ordinal_position;

-- Total fact rows
SELECT COUNT(*) AS fact_row_count
FROM warehouse.fact_order_items;

-- Check for missing surrogate keys (should be ZERO)
SELECT COUNT(*) AS missing_keys
FROM warehouse.fact_order_items
WHERE customer_key IS NULL
   OR product_key IS NULL;

-- Partition distribution check
SELECT
    tableoid::regclass AS partition_name,
    COUNT(*)           AS rows_in_partition
FROM warehouse.fact_order_items
GROUP BY tableoid
ORDER BY partition_name;
