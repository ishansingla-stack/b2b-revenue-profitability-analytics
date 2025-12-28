WITH monthly_revenue AS (
    SELECT
        account_id,
        billing_month AS month,
        SUM(amount_billed) AS revenue
    FROM invoices
    GROUP BY account_id, billing_month
),

monthly_support AS (
    SELECT
        account_id,
        support_month AS month,
        SUM(cost) AS support_cost
    FROM support_costs
    GROUP BY account_id, support_month
),

discounts AS (
    SELECT
        i.account_id,
        i.billing_month AS month,
        p.base_price * (s.discount_pct / 100.0) AS discount_amount
    FROM invoices i
    JOIN subscriptions s ON i.account_id = s.account_id
    JOIN plans p ON s.plan_id = p.plan_id
)

SELECT
    r.account_id,
    r.month,
    r.revenue,
    COALESCE(s.support_cost, 0) AS support_cost,
    COALESCE(d.discount_amount, 0) AS discount_amount,
    (r.revenue - COALESCE(s.support_cost, 0) - COALESCE(d.discount_amount, 0)) AS profit,
    ROUND(
        (r.revenue - COALESCE(s.support_cost, 0) - COALESCE(d.discount_amount, 0))
        / NULLIF(r.revenue, 0),
        4
    ) AS margin_pct
FROM monthly_revenue r
LEFT JOIN monthly_support s
    ON r.account_id = s.account_id
   AND r.month = s.month
LEFT JOIN discounts d
    ON r.account_id = d.account_id
   AND r.month = d.month;
