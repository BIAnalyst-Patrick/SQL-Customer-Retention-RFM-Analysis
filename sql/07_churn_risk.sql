-- Flags previously active customers who have gone quiet (no order in 90+
-- days), prioritized by value tier so retention outreach targets the
-- highest-value accounts first.
SELECT
    c.customer_id,
    c.region,
    c.acquisition_channel,
    c.value_tier,
    MAX(o.order_date) AS last_order_date,
    CAST(julianday('2024-12-31') - julianday(MAX(o.order_date)) AS INTEGER) AS days_since_last_order
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id
HAVING days_since_last_order > 90
ORDER BY
    CASE c.value_tier WHEN 'high' THEN 1 WHEN 'mid' THEN 2 ELSE 3 END,
    days_since_last_order DESC;
