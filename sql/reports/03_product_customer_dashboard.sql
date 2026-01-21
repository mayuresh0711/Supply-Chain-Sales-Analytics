/*
===============================================================================
File: 03_product_customer_dashboard.sql
Schema: reports
View: v_dashboard_product_customer
Dashboard: Product & Customer Deep Dive (Page 3)

Purpose:
- Powers:
  • Product performance tables
  • Category & product treemap
  • Combo charts (Sales vs Customers)
  • Quantity & pricing trends by month

Design Decisions:
- Includes BOTH Year and Month
- Month is numeric for correct sorting
- Month_name is textual for display
- Data is aggregated at:
    Year × Month × Department × Category × Product

Grain:
- One row per product per month per year

Important Notes:
- Power BI visuals rely on column names as-is
- No renaming allowed without visual updates
- Uses warehouse.fact_order_items as the single source of truth

===============================================================================
*/

DROP VIEW IF EXISTS reports.v_dashboard_product_customer CASCADE;

CREATE OR REPLACE VIEW reports.v_dashboard_product_customer AS
SELECT
    /* =========================
       Time Dimensions
       ========================= */
    d.year,
    d.month,              -- numeric (1–12) for sorting
    d.month_name,         -- text (Jan, Feb...) for axis display

    /* =========================
       Product Dimensions
       ========================= */
    p.department_name,
    p.category_name,
    p.product_name,

    /* =========================
       Volume & Sales Metrics
       ========================= */
    SUM(f.order_item_quantity)                 AS total_quantity,
    ROUND(SUM(f.sales), 2)                     AS total_sales,
    ROUND(SUM(f.order_profit_per_order), 2)    AS total_profit,

    /* =========================
       Customer Metrics
       ========================= */
    COUNT(DISTINCT f.customer_key)             AS distinct_buyers,

    /* =========================
       Average Metrics
       ========================= */
    ROUND(AVG(f.order_item_quantity), 2)       AS avg_order_quantity,
    ROUND(AVG(f.order_item_product_price), 2)  AS avg_product_price,
    ROUND(AVG(f.order_item_discount), 2)       AS avg_discount,
    ROUND(AVG(f.order_profit_per_order), 2)    AS avg_profit

FROM warehouse.fact_order_items f

JOIN warehouse.dim_date d
    ON f.order_date_id = d.date_id

JOIN warehouse.dim_product p
    ON f.product_key = p.product_key

GROUP BY
    d.year,
    d.month,
    d.month_name,
    p.department_name,
    p.category_name,
    p.product_name;

/* ---------------------------------------------------------------------------
Validation Queries (Optional – dev only)
--------------------------------------------------------------------------- */
-- SELECT * FROM reports.v_dashboard_product_customer LIMIT 50;
-- SELECT year, month, SUM(total_sales)
-- FROM reports.v_dashboard_product_customer
-- GROUP BY year, month
-- ORDER BY year, month;
