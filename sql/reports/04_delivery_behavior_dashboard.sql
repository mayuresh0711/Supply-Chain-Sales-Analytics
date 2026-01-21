/*
===============================================================================
File: 04_delivery_behavior_dashboard.sql
Schema: reports
View: v_dashboard_delivery
Dashboard: Delivery Habit & Customer Behaviour (Page 4)

Purpose:
- Powers:
  • Delivery Status Pie Chart
  • Revenue by Payment Method (Bar Chart)
  • Late Delivery Risk Donut
  • Customer Segmentation Pie
  • Avg Order Price Trend by Year
  • KPI Cards (Avg Order Value, Late Delivery Rate)

Grain:
- Year × Customer Segment × Delivery Status × Payment Type

Key Assumptions (CONFIRMED):
- late_delivery_risk: 1 = late, 0 = on-time
- payment_type comes from staging.dataco_clean.type
- delivery_status is already standardized in fact table
- One row in fact = one order item

No renaming of columns used by Power BI visuals.
===============================================================================
*/

DROP VIEW IF EXISTS reports.v_dashboard_delivery CASCADE;

CREATE OR REPLACE VIEW reports.v_dashboard_delivery AS
SELECT
    /* =========================
       Time Dimension
       ========================= */
    d.year,

    /* =========================
       Customer Dimension
       ========================= */
    c.customer_segment,

    /* =========================
       Delivery & Payment
       ========================= */
    f.delivery_status,
    f.payment_type,

    /* =========================
       Order Metrics
       ========================= */
    COUNT(DISTINCT f.order_id)                AS total_orders,
    COUNT(*)                                  AS total_order_items,

    /* =========================
       Revenue Metrics
       ========================= */
    ROUND(SUM(f.sales), 2)                    AS total_sales,
    ROUND(AVG(f.order_item_product_price), 2) AS avg_order_price,

    /* =========================
       Delivery Risk Metrics
       ========================= */
    SUM(f.late_delivery_risk)                 AS late_delivery_orders,
    COUNT(*) - SUM(f.late_delivery_risk)      AS ontime_orders

FROM warehouse.fact_order_items f

JOIN warehouse.dim_date d
    ON f.order_date_id = d.date_id

JOIN warehouse.dim_customer c
    ON f.customer_key = c.customer_key

GROUP BY
    d.year,
    c.customer_segment,
    f.delivery_status,
    f.payment_type;

/* ---------------------------------------------------------------------------
Validation Queries (Optional – Dev Only)
--------------------------------------------------------------------------- */

-- Delivery status sanity
-- SELECT delivery_status, COUNT(*) 
-- FROM reports.v_dashboard_delivery
-- GROUP BY delivery_status;

-- Payment method sanity
-- SELECT payment_type, COUNT(*) 
-- FROM reports.v_dashboard_delivery
-- GROUP BY payment_type;

-- Late vs on-time distribution
-- SELECT
--     SUM(late_delivery_orders) AS late,
--     SUM(ontime_orders)        AS ontime
-- FROM reports.v_dashboard_delivery;
