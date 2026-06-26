-- Month-3 retention rate by acquisition channel: which channels bring
-- customers who stick around, versus one-and-done buyers?
WITH cohort AS (
    SELECT
        customer_id,
        acquisition_channel,
        CAST(strftime('%Y', signup_date) AS INTEGER) * 12
            + CAST(strftime('%m', signup_date) AS INTEGER) AS cohort_month_idx
    FROM customers
),
activity AS (
    SELECT
        o.customer_id,
        c.acquisition_channel,
        (CAST(strftime('%Y', o.order_date) AS INTEGER) * 12
            + CAST(strftime('%m', o.order_date) AS INTEGER)) - c.cohort_month_idx AS month_offset
    FROM orders o
    JOIN cohort c ON c.customer_id = o.customer_id
),
channel_size AS (
    SELECT acquisition_channel, COUNT(*) AS channel_customers
    FROM cohort
    GROUP BY acquisition_channel
),
month3_active AS (
    SELECT acquisition_channel, COUNT(DISTINCT customer_id) AS active_at_month3
    FROM activity
    WHERE month_offset = 3
    GROUP BY acquisition_channel
)
SELECT
    cs.acquisition_channel,
    cs.channel_customers,
    COALESCE(m3.active_at_month3, 0) AS active_at_month3,
    ROUND(100.0 * COALESCE(m3.active_at_month3, 0) / cs.channel_customers, 1) AS month3_retention_pct
FROM channel_size cs
LEFT JOIN month3_active m3 ON m3.acquisition_channel = cs.acquisition_channel
ORDER BY month3_retention_pct DESC;
