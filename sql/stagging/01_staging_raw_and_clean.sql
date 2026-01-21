/* ============================================================================
   FILE: 01_staging_raw_and_clean.sql
   LAYER: Staging
   PURPOSE:
     - Create raw ingestion table (all TEXT)
     - Create typed, cleaned staging table
     - Perform safe type casting and datetime parsing
     - Preserve order-item grain (1 row = 1 order_item)

   GRAIN:
     One row represents ONE order item (order_item_id)


============================================================================ */


/* ============================================================================
   1. DATABASE & SCHEMA SETUP
============================================================================ */

-- Create database (run once)
CREATE DATABASE dataco_supply_chain;

-- Connect to the database before continuing
-- \c dataco_supply_chain

-- Create staging schema
CREATE SCHEMA IF NOT EXISTS staging;


/* ============================================================================
   2. RAW INGESTION TABLE (ALL COLUMNS AS TEXT)
============================================================================ */

DROP TABLE IF EXISTS staging.dataco_raw;

CREATE TABLE staging.dataco_raw (
    type text,
    days_for_shipping_real text,
    days_for_shipment_scheduled text,
    benefit_per_order text,
    sales_per_customer text,
    delivery_status text,
    late_delivery_risk text,
    category_id text,
    category_name text,
    customer_city text,
    customer_country text,
    customer_email text,
    customer_fname text,
    customer_id text,
    customer_lname text,
    customer_password text,
    customer_segment text,
    customer_state text,
    customer_street text,
    customer_zipcode text,
    department_id text,
    department_name text,
    latitude text,
    longitude text,
    market text,
    order_city text,
    order_country text,
    order_customer_id text,
    order_date text,
    order_id text,
    order_item_cardprod_id text,
    order_item_discount text,
    order_item_discount_rate text,
    order_item_id text,
    order_item_product_price text,
    order_item_profit_ratio text,
    order_item_quantity text,
    sales text,
    order_item_total text,
    order_profit_per_order text,
    order_region text,
    order_state text,
    order_status text,
    order_zipcode text,
    product_card_id text,
    product_category_id text,
    product_description text,
    product_image text,
    product_name text,
    product_price text,
    product_status text,
    shipping_date text,
    shipping_mode text
);

-- DATA LOADING NOTE:
-- Raw data is expected to be loaded externally (COPY / pgAdmin / ETL tool)


/* ============================================================================
   3. BASIC RAW DATA VALIDATION (OPTIONAL, READ-ONLY)
============================================================================ */

-- Row count
SELECT COUNT(*) AS raw_row_count FROM staging.dataco_raw;

-- Distinct identifiers (cardinality check)
SELECT
    COUNT(DISTINCT customer_id) AS distinct_customers,
    COUNT(DISTINCT product_name) AS distinct_products,
    COUNT(DISTINCT order_id) AS distinct_orders
FROM staging.dataco_raw;

-- Delivery & order status distribution
SELECT delivery_status, COUNT(*) AS cnt
FROM staging.dataco_raw
GROUP BY delivery_status
ORDER BY cnt DESC;

SELECT order_status, COUNT(*) AS cnt
FROM staging.dataco_raw
GROUP BY order_status
ORDER BY cnt DESC;


/* ============================================================================
   4. TYPED CLEAN STAGING TABLE
============================================================================ */

DROP TABLE IF EXISTS staging.dataco_clean;

CREATE TABLE staging.dataco_clean (
    type text,
    days_for_shipping_real integer,
    days_for_shipment_scheduled integer,
    benefit_per_order numeric(12,2),
    sales_per_customer numeric(12,2),
    delivery_status text,
    late_delivery_risk integer,        -- 1 = Late risk, 0 = On-time
    category_id text,
    category_name text,
    customer_city text,
    customer_country text,
    customer_email text,
    customer_fname text,
    customer_id text,
    customer_lname text,
    customer_password text,
    customer_segment text,
    customer_state text,
    customer_street text,
    customer_zipcode text,
    department_id text,
    department_name text,
    latitude numeric(10,6),
    longitude numeric(10,6),
    market text,
    order_city text,
    order_country text,
    order_customer_id text,
    order_datetime timestamp,
    order_id text,
    order_item_cardprod_id text,
    order_item_discount numeric(12,2),
    order_item_discount_rate numeric(10,4),
    order_item_id text,
    order_item_product_price numeric(12,2),
    order_item_profit_ratio numeric(10,4),
    order_item_quantity integer,
    sales numeric(12,2),
    order_item_total numeric(12,2),
    order_profit_per_order numeric(12,2),
    order_region text,
    order_state text,
    order_status text,
    order_zipcode text,
    product_card_id text,
    product_category_id text,
    product_description text,
    product_image text,
    product_name text,
    product_price numeric(12,2),
    product_status text,
    shipping_datetime timestamp,
    shipping_mode text
);


/* ============================================================================
   5. DATA TRANSFORMATION: RAW → CLEAN
============================================================================ */

INSERT INTO staging.dataco_clean
SELECT
    type,
    days_for_shipping_real::integer,
    days_for_shipment_scheduled::integer,
    benefit_per_order::numeric(12,2),
    sales_per_customer::numeric(12,2),
    delivery_status,
    late_delivery_risk::integer,
    category_id,
    category_name,
    customer_city,
    customer_country,
    customer_email,
    customer_fname,
    customer_id,
    customer_lname,
    customer_password,
    customer_segment,
    customer_state,
    customer_street,
    customer_zipcode,
    department_id,
    department_name,
    latitude::numeric(10,6),
    longitude::numeric(10,6),
    market,
    order_city,
    order_country,
    order_customer_id,
    COALESCE(
        to_timestamp(order_date, 'MM/DD/YYYY HH24:MI'),
        to_timestamp(order_date, 'MM-DD-YYYY HH24:MI')
    ) AS order_datetime,
    order_id,
    order_item_cardprod_id,
    order_item_discount::numeric(12,2),
    order_item_discount_rate::numeric(10,4),
    order_item_id,
    order_item_product_price::numeric(12,2),
    order_item_profit_ratio::numeric(10,4),
    order_item_quantity::integer,
    sales::numeric(12,2),
    order_item_total::numeric(12,2),
    order_profit_per_order::numeric(12,2),
    order_region,
    order_state,
    order_status,
    order_zipcode,
    product_card_id,
    product_category_id,
    product_description,
    product_image,
    product_name,
    product_price::numeric(12,2),
    product_status,
    COALESCE(
        to_timestamp(shipping_date, 'MM/DD/YYYY HH24:MI'),
        to_timestamp(shipping_date, 'MM-DD-YYYY HH24:MI')
    ) AS shipping_datetime,
    shipping_mode
FROM staging.dataco_raw;


/* ============================================================================
   6. POST-LOAD VALIDATION
============================================================================ */

-- Row count consistency
SELECT
    (SELECT COUNT(*) FROM staging.dataco_raw)   AS raw_rows,
    (SELECT COUNT(*) FROM staging.dataco_clean) AS clean_rows;

-- Timestamp sanity checks
SELECT * FROM staging.dataco_clean
WHERE order_datetime IS NULL
LIMIT 20;

SELECT * FROM staging.dataco_clean
WHERE shipping_datetime IS NULL
LIMIT 20;
