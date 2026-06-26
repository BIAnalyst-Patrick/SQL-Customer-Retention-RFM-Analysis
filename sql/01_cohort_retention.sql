-- Monthly cohort retention: of customers who signed up in a given month,
-- what % placed an order in each subsequent month (offset 0-6)?
WITH cohort AS (
    SELECT
        customer_id,
        strftime('%Y-%m', signup_date) AS cohort_month,
        CAST(strftime('%Y', signup_date) AS INTEGER) * 12
            + CAST(strftime('%m', signup_date) AS INTEGER) AS cohort_month_idx
    FROM customers
),
activity AS (
    SELECT
        o.customer_id,
        c.cohort_month,
        (CAST(strftime('%Y', o.order_date) AS INTEGER) * 12
            + CAST(strftime('%m', o.order_date) AS INTEGER)) - c.cohort_month_idx AS month_offset
    FROM orders o
    JOIN cohort c ON c.customer_id = o.customer_id
),
cohort_size AS (
    SELECT cohort_month, COUNT(*) AS cohort_customers
    FROM cohort
    GROUP BY cohort_month
),
retention AS (
    SELECT cohort_month, month_offset, COUNT(DISTINCT customer_id) AS active_customers
    FROM activity
    GROUP BY cohort_month, month_offset
)
SELECT
    r.cohort_month,
    cs.cohort_customers,
    r.month_offset,
    r.active_customers,
    ROUND(100.0 * r.active_customers / cs.cohort_customers, 1) AS retention_pct
FROM retention r
JOIN cohort_size cs ON cs.cohort_month = r.cohort_month
WHERE r.month_offset BETWEEN 0 AND 6
ORDER BY r.cohort_month, r.month_offset;
