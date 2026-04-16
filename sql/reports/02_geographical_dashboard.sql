/*
===============================================================================
File: 02_geographical_dashboard.sql
Schema: reports
View: v_dashboard_geo
Dashboard: Geographical Analysis (Page 2)

Purpose:
- Powers the Geographical Analysis dashboard in Power BI
- Supports:
  • Map visual (Country / State / City)
  • Market-wise Sales & Profit
  • Region-wise comparison
  • KPI cards for geo-level performance

Design Decision:
- NO time dimension by design
- Geography analysis is lifetime-based (all years combined)
- Prevents misleading geo trends caused by sparse yearly data

Grain:
- Market × Region × Country × State × City

Important Notes:
- Power BI uses ONLY the reports schema
- Column names are contractually locked for visuals
- No date joins are required here

===============================================================================
*/

DROP VIEW IF EXISTS reports.v_dashboard_geo CASCADE;

CREATE OR REPLACE VIEW reports.v_dashboard_geo AS
SELECT
    /* =========================
       Geography Dimensions
       ========================= */
    f.market,
    f.order_region,
    f.order_country        AS country,
    f.order_state          AS state,
    f.order_city           AS city,

    /* =========================
       Core Metrics
       ========================= */
    COUNT(DISTINCT f.order_id)          AS total_orders,
    ROUND(SUM(f.sales), 2)              AS total_sales,
    ROUND(SUM(f.order_profit_per_order), 2) AS total_profit,

    /* =========================
       Profitability Metric
       ========================= */
    CASE
        WHEN SUM(f.sales) = 0 THEN 0
        ELSE ROUND(
            SUM(f.order_profit_per_order) / SUM(f.sales),
            4
        )
    END AS profit_margin_pct

FROM warehouse.fact_order_items f

GROUP BY
    f.market,
    f.order_region,
    f.order_country,
    f.order_state,
    f.order_city;

/* ---------------------------------------------------------------------------
Validation Queries (Optional – dev only)
--------------------------------------------------------------------------- */
SELECT * FROM reports.v_dashboard_geo LIMIT 50;
SELECT market, SUM(total_sales) FROM reports.v_dashboard_geo GROUP BY market;
SELECT order_region, SUM(total_orders) FROM reports.v_dashboard_geo GROUP BY order_region;
