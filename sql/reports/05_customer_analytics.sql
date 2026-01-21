/*
===============================================================================
File: 05_customer_analytics.sql
Schema: reports
Views:
  • v_customer_churn_risk

Purpose:
- Supports customer lifecycle & churn analysis
- Used for:
  • Customer status distribution
  • Retention vs churn analysis
  • Geographic churn insights

Design Decisions:
- Lifetime-based logic (no slicer dependency)
- Business-rule churn definition (not ML-based)
- One row per customer

Grain:
- One row = One customer

Important Notes:
- This view is SAFE to use in Power BI
- No overlap with RFM or ABC logic
===============================================================================
*/

DROP VIEW IF EXISTS reports.v_customer_churn_risk CASCADE;

CREATE OR REPLACE VIEW reports.v_customer_churn_risk AS
SELECT
    /* =========================
       Customer Identity
       ========================= */
    c.customer_key,
    c.customer_city,
    c.customer_state,

    /* =========================
       Order History
       ========================= */
    MIN(d.date_id)                             AS first_order_date,
    MAX(d.date_id)                             AS last_order_date,
    COUNT(DISTINCT f.order_id)                 AS total_orders,
    ROUND(SUM(f.sales), 2)                     AS total_lifetime_value,

    /* =========================
       Customer Status Logic
       ========================= */
    CASE
        WHEN MAX(d.date_id) < DATE '2017-08-01'
            THEN 'Churned'
        WHEN COUNT(DISTINCT f.order_id) = 1
            THEN 'New / One-Time'
        ELSE 'Active / Returning'
    END AS customer_status

FROM warehouse.fact_order_items f

JOIN warehouse.dim_date d
    ON f.order_date_id = d.date_id

JOIN warehouse.dim_customer c
    ON f.customer_key = c.customer_key

GROUP BY
    c.customer_key,
    c.customer_city,
    c.customer_state;

/* ---------------------------------------------------------------------------
Validation Queries (Optional – Dev Only)
--------------------------------------------------------------------------- */
-- SELECT customer_status, COUNT(*) 
-- FROM reports.v_customer_churn_risk
-- GROUP BY customer_status;
