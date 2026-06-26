-- Finds the smallest % of customers (ranked by lifetime value) whose
-- combined revenue crosses 80% of total revenue -- the actual 80/20 split.
WITH customer_value AS (
    SELECT
        c.customer_id,
        SUM(oi.quantity * oi.unit_price) AS lifetime_value
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY c.customer_id
),
ranked AS (
    SELECT
        customer_id,
        lifetime_value,
        ROW_NUMBER() OVER (ORDER BY lifetime_value DESC) AS rn,
        COUNT(*) OVER () AS total_customers,
        SUM(lifetime_value) OVER (ORDER BY lifetime_value DESC) AS cumulative_value,
        SUM(lifetime_value) OVER () AS total_value
    FROM customer_value
)
SELECT MIN(rn) AS customers_needed,
       MIN(total_customers) AS total_customers,
       ROUND(100.0 * MIN(rn) / MIN(total_customers), 1) AS pct_of_customers
FROM ranked
WHERE cumulative_value >= 0.8 * total_value;
