/*
===============================================================================
File: 06_materialized_views.sql
Schema: reports
Objects:
  • mv_advanced_rfm
  • mv_product_abc_analysis

Purpose:
- Materialize computationally expensive analytics
- Improve Power BI performance
- Centralize advanced business logic

Refresh Strategy:
- Manual REFRESH MATERIALIZED VIEW
- Can be scheduled externally (cron / Airflow / pgAgent)

Important:
- Power BI should query ONLY these materialized views
- Corresponding non-materialized views must NOT exist
===============================================================================
*/

CREATE SCHEMA IF NOT EXISTS reports;

/* ============================================================================
   1. ADVANCED RFM ANALYSIS (Materialized)
============================================================================ */

DROP MATERIALIZED VIEW IF EXISTS reports.mv_advanced_rfm CASCADE;

CREATE MATERIALIZED VIEW reports.mv_advanced_rfm AS
WITH rfm_base AS (
    SELECT
        c.customer_key,
        c.customer_fname,
        c.customer_lname,
        c.customer_segment,

        MAX(d.date_id)                       AS last_order_date,
        COUNT(DISTINCT f.order_id)           AS frequency,
        ROUND(SUM(f.sales), 2)               AS monetary_value,

        -- Recency calculated from dataset max date (2018-01-31)
        (DATE '2018-01-31' - MAX(d.date_id)) AS recency_days
    FROM warehouse.fact_order_items f
    JOIN warehouse.dim_date d
        ON f.order_date_id = d.date_id
    JOIN warehouse.dim_customer c
        ON f.customer_key = c.customer_key
    GROUP BY
        c.customer_key,
        c.customer_fname,
        c.customer_lname,
        c.customer_segment
),
rfm_scores AS (
    SELECT
        *,
        NTILE(4) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(4) OVER (ORDER BY frequency ASC)     AS f_score,
        NTILE(4) OVER (ORDER BY monetary_value ASC) AS m_score
    FROM rfm_base
)
SELECT
    customer_key,
    customer_fname,
    customer_lname,
    customer_segment,
    last_order_date,
    recency_days,
    frequency,
    monetary_value,

    r_score,
    f_score,
    m_score,

    CAST(r_score AS text)
        || CAST(f_score AS text)
        || CAST(m_score AS text)                   AS rfm_cell,

    CASE
        WHEN (r_score + f_score + m_score) >= 10 THEN 'Loyal Customer'
        WHEN (r_score + f_score + m_score) >= 7  THEN 'Potential Loyalist'
        WHEN (r_score + f_score + m_score) >= 4  THEN 'Needs Attention'
        ELSE 'At Risk / Lost'
    END AS rfm_segment_name
FROM rfm_scores;

-- Index for fast Power BI lookups
CREATE UNIQUE INDEX idx_mv_rfm_customer_key
ON reports.mv_advanced_rfm (customer_key);


/* ============================================================================
   2. PRODUCT ABC (PARETO) ANALYSIS (Materialized)
============================================================================ */

DROP MATERIALIZED VIEW IF EXISTS reports.mv_product_abc_analysis CASCADE;

CREATE MATERIALIZED VIEW reports.mv_product_abc_analysis AS
WITH product_sales AS (
    SELECT
        p.product_key,
        p.product_name,
        ROUND(SUM(f.sales), 2) AS product_revenue
    FROM warehouse.fact_order_items f
    JOIN warehouse.dim_product p
        ON f.product_key = p.product_key
    GROUP BY
        p.product_key,
        p.product_name
),
cumulative_calc AS (
    SELECT
        *,
        SUM(product_revenue) OVER ()                               AS total_revenue_all,
        SUM(product_revenue) OVER (ORDER BY product_revenue DESC)  AS running_total
    FROM product_sales
)
SELECT
    product_key,
    product_name,
    product_revenue,
    ROUND((running_total / total_revenue_all) * 100, 2) AS cumulative_pct,
    CASE
        WHEN (running_total / total_revenue_all) <= 0.80 THEN 'A - High Value'
        WHEN (running_total / total_revenue_all) <= 0.95 THEN 'B - Medium Value'
        ELSE 'C - Low Value'
    END AS abc_class
FROM cumulative_calc;

-- Index for sorting & filtering in Power BI
CREATE UNIQUE INDEX idx_mv_abc_product_key
ON reports.mv_product_abc_analysis (product_key);


/* ============================================================================
   3. REFRESH COMMANDS (Manual / Scheduled)
============================================================================ */

-- Refresh both materialized views when data changes
-- REFRESH MATERIALIZED VIEW reports.mv_advanced_rfm;
-- REFRESH MATERIALIZED VIEW reports.mv_product_abc_analysis;
