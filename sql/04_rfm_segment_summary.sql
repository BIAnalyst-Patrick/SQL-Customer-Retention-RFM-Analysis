-- Rolls up the per-customer RFM segmentation into segment-level size and
-- revenue contribution, for an executive-level view.
WITH order_agg AS (
    SELECT
        o.customer_id,
        MAX(o.order_date) AS last_order_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.quantity * oi.unit_price) AS monetary
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY o.customer_id
),
rfm_base AS (
    SELECT
        customer_id,
        CAST(julianday('2024-12-31') - julianday(last_order_date) AS INTEGER) AS recency_days,
        frequency,
        monetary
    FROM order_agg
),
rfm_scored AS (
    SELECT
        customer_id,
        monetary,
        NTILE(4) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(4) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(4) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
),
rfm_segmented AS (
    SELECT
        customer_id,
        monetary,
        CASE
            WHEN (r_score + f_score + m_score) >= 11 THEN 'Champions'
            WHEN (r_score + f_score + m_score) >= 9  THEN 'Loyal Customers'
            WHEN (r_score + f_score + m_score) >= 6  THEN 'At Risk'
            ELSE 'Lost / Inactive'
        END AS segment
    FROM rfm_scored
)
SELECT
    segment,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM rfm_segmented), 1) AS pct_of_customers,
    ROUND(SUM(monetary), 2) AS total_revenue,
    ROUND(100.0 * SUM(monetary) / (SELECT SUM(monetary) FROM rfm_segmented), 1) AS pct_of_revenue
FROM rfm_segmented
GROUP BY segment
ORDER BY total_revenue DESC;
