-- RFM segmentation: score every customer on Recency, Frequency, and Monetary
-- value (quartiles via NTILE), then label them into actionable segments.
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
        recency_days,
        frequency,
        monetary,
        NTILE(4) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(4) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(4) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
),
rfm_final AS (
    SELECT
        *,
        (r_score + f_score + m_score) AS rfm_total
    FROM rfm_scored
)
SELECT
    customer_id,
    recency_days,
    frequency,
    ROUND(monetary, 2) AS monetary,
    r_score,
    f_score,
    m_score,
    rfm_total,
    CASE
        WHEN rfm_total >= 11 THEN 'Champions'
        WHEN rfm_total >= 9  THEN 'Loyal Customers'
        WHEN rfm_total >= 6  THEN 'At Risk'
        ELSE 'Lost / Inactive'
    END AS segment
FROM rfm_final
ORDER BY rfm_total DESC;
