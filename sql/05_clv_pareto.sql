-- Customer lifetime value ranking with a running cumulative-revenue share,
-- used to test the 80/20 rule: what % of customers drive 80% of revenue?
WITH customer_value AS (
    SELECT
        c.customer_id,
        c.region,
        c.acquisition_channel,
        c.value_tier,
        SUM(oi.quantity * oi.unit_price) AS lifetime_value
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY c.customer_id
),
ranked AS (
    SELECT
        *,
        RANK() OVER (ORDER BY lifetime_value DESC) AS value_rank,
        SUM(lifetime_value) OVER (ORDER BY lifetime_value DESC) AS cumulative_value,
        SUM(lifetime_value) OVER () AS total_value
    FROM customer_value
)
SELECT
    value_rank,
    customer_id,
    region,
    acquisition_channel,
    value_tier,
    ROUND(lifetime_value, 2) AS lifetime_value,
    ROUND(100.0 * cumulative_value / total_value, 1) AS cumulative_pct_of_revenue
FROM ranked
ORDER BY value_rank
LIMIT 20;
