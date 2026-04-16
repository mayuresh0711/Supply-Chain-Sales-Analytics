/*
===============================================================================
File: 01_sales_dashboard.sql
Schema: reports
View: v_dashboard_sales
Dashboard: Sales Overview (Page 1)

Purpose:
- Powers Sales Overview dashboard in Power BI
- Supports:
  • Line chart: Orders by Month
  • Pie chart: Sales by Category
  • Bar chart: Sales vs Profit by Department
  • KPIs:
      - Total Sales
      - Total Profit
      - Total Orders
      - Avg Shipment Duration
      - Avg Sales per Customer
- Enables slicers:
  • Year
  • Department

Grain:
- Month × Category × Department

Important Notes:
- This view is the ONLY data source for Page 1
- Power BI depends on column names and logic here
- Do NOT rename columns without updating Power BI

===============================================================================
*/

DROP VIEW IF EXISTS reports.v_dashboard_sales CASCADE;

CREATE OR REPLACE VIEW reports.v_dashboard_sales AS
SELECT
    /* =========================
       Time Dimensions
       ========================= */
    d.year,
    d.month,            -- numeric (1–12) → sorting
    d.month_name,       -- text (Jan, Feb…) → display
    d.date_id,

    /* =========================
       Product Hierarchy
       ========================= */
    p.department_name,
    p.category_name,

    /* =========================
       Core Metrics
       ========================= */
    COUNT(DISTINCT f.order_id)                         AS total_orders,
    ROUND(SUM(f.sales), 2)                             AS total_sales,
    ROUND(SUM(f.order_profit_per_order), 2)            AS total_profit,

    /* =========================
       Operational KPIs
       ========================= */
    ROUND(AVG(f.days_for_shipping_real), 2)            AS avg_shipment_duration,

    /* =========================
       Customer Metrics
       ========================= */
    COUNT(DISTINCT f.customer_key)                     AS unique_customers,

    CASE
        WHEN COUNT(DISTINCT f.customer_key) = 0 THEN 0
        ELSE ROUND(
            SUM(f.sales) / COUNT(DISTINCT f.customer_key),
            2
        )
    END                                                AS avg_sales_per_customer

FROM warehouse.fact_order_items f
JOIN warehouse.dim_date d
    ON f.order_date_id = d.date_id
JOIN warehouse.dim_product p
    ON f.product_key = p.product_key

GROUP BY
    d.year,
    d.month,
    d.month_name,
    d.date_id,
    p.department_name,
    p.category_name;

/* ---------------------------------------------------------------------------
Validation Queries (Optional – use during development only)
--------------------------------------------------------------------------- */
SELECT * FROM reports.v_dashboard_sales LIMIT 50;
SELECT year, SUM(total_sales) FROM reports.v_dashboard_sales GROUP BY year;
