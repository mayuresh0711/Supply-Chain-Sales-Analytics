/* ============================================================================
   FILE: 01_dimensions.sql
   LAYER: Warehouse
   PURPOSE:
     - Create all dimension tables
     - Populate dimensions from staging.dataco_clean
     - No fact data handled here

   NOTE:
     - Dimensions are loaded BEFORE fact table
============================================================================ */

CREATE SCHEMA IF NOT EXISTS warehouse;


/* ============================================================================
   1. DATE DIMENSION
============================================================================ */

DROP TABLE IF EXISTS warehouse.dim_date CASCADE;

CREATE TABLE warehouse.dim_date (
    date_id        date PRIMARY KEY,
    year           int,
    quarter        int,
    month          int,
    month_name     text,
    day            int,
    day_of_week    int,
    week_of_year   int,
    is_weekend     boolean
);

INSERT INTO warehouse.dim_date (
    date_id,
    year,
    quarter,
    month,
    month_name,
    day,
    day_of_week,
    week_of_year,
    is_weekend
)
SELECT
    dt,
    EXTRACT(YEAR FROM dt)::int,
    EXTRACT(QUARTER FROM dt)::int,
    EXTRACT(MONTH FROM dt)::int,
    TO_CHAR(dt, 'Month'),
    EXTRACT(DAY FROM dt)::int,
    EXTRACT(ISODOW FROM dt)::int,
    EXTRACT(WEEK FROM dt)::int,
    CASE WHEN EXTRACT(ISODOW FROM dt) IN (6,7) THEN TRUE ELSE FALSE END
FROM (
    SELECT DISTINCT order_datetime::date AS dt
    FROM staging.dataco_clean
    UNION
    SELECT DISTINCT shipping_datetime::date AS dt
    FROM staging.dataco_clean
) d
WHERE dt IS NOT NULL;

select * from warehouse.dim_date limit 100;
/* ============================================================================
   2. CUSTOMER DIMENSION
============================================================================ */

DROP TABLE IF EXISTS warehouse.dim_customer CASCADE;

CREATE TABLE warehouse.dim_customer (
    customer_key     serial PRIMARY KEY,
    customer_id      text UNIQUE,
    customer_fname   text,
    customer_lname   text,
    customer_email   text,
    customer_segment text,
    customer_country text,
    customer_state   text,
    customer_city    text,
    customer_zipcode text
);

INSERT INTO warehouse.dim_customer (
    customer_id,
    customer_fname,
    customer_lname,
    customer_email,
    customer_segment,
    customer_country,
    customer_state,
    customer_city,
    customer_zipcode
)
SELECT DISTINCT
    customer_id,
    customer_fname,
    customer_lname,
    customer_email,
    customer_segment,
    customer_country,
    customer_state,
    customer_city,
    customer_zipcode
FROM staging.dataco_clean
WHERE customer_id IS NOT NULL;

select * from warehouse.dim_customer limit 100;


/* ============================================================================
   3. PRODUCT DIMENSION
============================================================================ */

DROP TABLE IF EXISTS warehouse.dim_product CASCADE;

CREATE TABLE warehouse.dim_product (
    product_key          serial PRIMARY KEY,
    product_card_id      text UNIQUE,
    product_name         text,
    product_category_id  text,
    category_name        text,
    department_id        text,
    department_name      text,
    product_price        numeric(12,2),
    product_status       text
);

INSERT INTO warehouse.dim_product (
    product_card_id,
    product_name,
    product_category_id,
    category_name,
    department_id,
    department_name,
    product_price,
    product_status
)
SELECT DISTINCT
    product_card_id,
    product_name,
    product_category_id,
    category_name,
    department_id,
    department_name,
    product_price,
    product_status
FROM staging.dataco_clean
WHERE product_card_id IS NOT NULL;

select * from warehouse.dim_products limit 100;


