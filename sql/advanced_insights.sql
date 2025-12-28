/* ============================================================
   ADVANCED PROFITABILITY & MARGIN ANALYTICS
   ------------------------------------------------------------
   Purpose:
   - Identify high-value customers
   - Detect margin leakage
   - Surface cost pressure from support
   - Enable executive decision-making
   ------------------------------------------------------------
   Data Source:
   - account_profitability (derived fact table)
   ============================================================ */


/* ------------------------------------------------------------
   1. TOP 10 MOST PROFITABLE ACCOUNTS (ALL-TIME)
   ------------------------------------------------------------
   Business Question:
   - Which customers generate the most absolute profit?

   Why it matters:
   - Revenue alone is misleading
   - These accounts are ideal for upsell, retention, and priority support
------------------------------------------------------------- */
SELECT
    account_id,
    SUM(revenue) AS total_revenue,
    SUM(profit) AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(revenue), 0), 4) AS profit_margin
FROM account_profitability
GROUP BY account_id
ORDER BY total_profit DESC
LIMIT 10;


/* ------------------------------------------------------------
   2. BOTTOM 10 ACCOUNTS BY PROFIT (LOSS MAKERS)
   ------------------------------------------------------------
   Business Question:
   - Which customers are draining profitability?

   Why it matters:
   - Candidates for repricing, support reduction, or churn
   - Often hidden behind moderate revenue numbers
------------------------------------------------------------- */
SELECT
    account_id,
    SUM(revenue) AS total_revenue,
    SUM(profit) AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(revenue), 0), 4) AS profit_margin
FROM account_profitability
GROUP BY account_id
ORDER BY total_profit ASC
LIMIT 10;


/* ------------------------------------------------------------
   3. HIGH REVENUE BUT LOW MARGIN (MARGIN LEAKAGE)
   ------------------------------------------------------------
   Business Question:
   - Which accounts look strong on revenue dashboards
     but underperform on margins?

   Logic:
   - Revenue above average
   - Profit margin below 10%

   Why it matters:
   - Indicates pricing, discounting, or cost structure issues
------------------------------------------------------------- */
SELECT
    account_id,
    SUM(revenue) AS total_revenue,
    SUM(profit) AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(revenue), 0), 4) AS profit_margin
FROM account_profitability
GROUP BY account_id
HAVING
    SUM(revenue) >
        (
            SELECT AVG(account_revenue)
            FROM (
                SELECT SUM(revenue) AS account_revenue
                FROM account_profitability
                GROUP BY account_id
            ) sub
        )
    AND
    ROUND(SUM(profit) / NULLIF(SUM(revenue), 0), 4) < 0.10
ORDER BY profit_margin ASC;


/* ------------------------------------------------------------
   4. SUPPORT COST PRESSURE ANALYSIS
   ------------------------------------------------------------
   Business Question:
   - Are support costs disproportionately high for certain customers?

   Metric:
   - Support cost as a % of revenue

   Why it matters:
   - Identifies automation candidates
   - Highlights onboarding or product usability issues
------------------------------------------------------------- */
SELECT
    account_id,
    SUM(support_cost) AS total_support_cost,
    SUM(revenue) AS total_revenue,
    ROUND(SUM(support_cost) / NULLIF(SUM(revenue), 0), 4) AS support_cost_ratio
FROM account_profitability
GROUP BY account_id
ORDER BY support_cost_ratio DESC
LIMIT 10;


/* ------------------------------------------------------------
   5. MONTHLY PROFIT DETERIORATION (RISK SIGNAL)
   ------------------------------------------------------------
   Business Question:
   - Which accounts are experiencing dangerously low margins recently?

   Logic:
   - Margin below 5% in any month

   Why it matters:
   - Early warning system for churn or losses
------------------------------------------------------------- */
SELECT
    account_id,
    month,
    revenue,
    profit,
    margin_pct
FROM account_profitability
WHERE margin_pct < 0.05
ORDER BY month DESC, margin_pct ASC;


 /* ------------------------------------------------------------
   6. EXECUTIVE ACCOUNT SEGMENTATION (UPDATED THRESHOLD)
   ------------------------------------------------------------
   Business Question:
   - How should leadership act on each account?

   Updated Logic:
   - Grow        → Profitable accounts with revenue > 50,000
   - Maintain    → Profitable accounts with revenue ≤ 50,000
   - Fix or Exit → Loss-making accounts

   Why it matters:
   - Better reflects SMB / mid-market B2B realities
------------------------------------------------------------- */
SELECT
    account_id,
    SUM(revenue) AS total_revenue,
    SUM(profit) AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(revenue), 0), 4) AS margin,
    CASE
        WHEN SUM(profit) > 0 AND SUM(revenue) > 50000 THEN 'Grow'
        WHEN SUM(profit) > 0 AND SUM(revenue) <= 50000 THEN 'Maintain'
        WHEN SUM(profit) <= 0 THEN 'Fix or Exit'
    END AS account_strategy
FROM account_profitability
GROUP BY account_id
ORDER BY total_profit DESC;




-- Time-based segmentation

/* ------------------------------------------------------------
   RECENT PERFORMANCE (LAST 3 MONTHS — DATA-DRIVEN)
   ------------------------------------------------------------
   Purpose:
   - Measure current account health based on latest available data
------------------------------------------------------------- */
WITH max_month AS (
    SELECT MAX(month) AS max_month
    FROM account_profitability
)
SELECT
    ap.account_id,
    SUM(ap.revenue) AS recent_revenue,
    SUM(ap.profit) AS recent_profit,
    ROUND(SUM(ap.profit) / NULLIF(SUM(ap.revenue), 0), 4) AS recent_margin
FROM account_profitability ap
CROSS JOIN max_month m
WHERE ap.month >= (m.max_month - INTERVAL '3 months')
GROUP BY ap.account_id;




/* ------------------------------------------------------------
   HISTORICAL PERFORMANCE (BEFORE LAST 3 MONTHS)
   ------------------------------------------------------------
   Purpose:
   - Establish baseline profitability
------------------------------------------------------------- */
SELECT
    account_id,
    SUM(revenue) AS historical_revenue,
    SUM(profit) AS historical_profit,
    ROUND(SUM(profit) / NULLIF(SUM(revenue), 0), 4) AS historical_margin
FROM account_profitability
WHERE month < (CURRENT_DATE - INTERVAL '3 months')
GROUP BY account_id;


/* ------------------------------------------------------------
   PROFITABILITY TREND ANALYSIS
   ------------------------------------------------------------
   Business Question:
   - Is account profitability improving or declining?

   Logic:
   - Compare recent margin vs historical margin
------------------------------------------------------------- */
WITH max_month AS (
    SELECT MAX(month) AS max_month
    FROM account_profitability
),
recent AS (
    SELECT
        account_id,
        SUM(revenue) AS recent_revenue,
        SUM(profit) AS recent_profit,
        ROUND(SUM(profit) / NULLIF(SUM(revenue), 0), 4) AS recent_margin
    FROM account_profitability, max_month
    WHERE month >= (max_month - INTERVAL '3 months')
    GROUP BY account_id
),
historical AS (
    SELECT
        account_id,
        SUM(revenue) AS historical_revenue,
        SUM(profit) AS historical_profit,
        ROUND(SUM(profit) / NULLIF(SUM(revenue), 0), 4) AS historical_margin
    FROM account_profitability, max_month
    WHERE month < (max_month - INTERVAL '3 months')
    GROUP BY account_id
)
SELECT
    r.account_id,
    r.recent_revenue,
    r.recent_profit,
    r.recent_margin,
    h.historical_margin,
    CASE
        WHEN h.historical_margin IS NULL THEN 'No History'
        WHEN r.recent_margin > h.historical_margin THEN 'Improving'
        WHEN r.recent_margin < h.historical_margin THEN 'Deteriorating'
        ELSE 'Stable'
    END AS trend_status
FROM recent r
LEFT JOIN historical h
    ON r.account_id = h.account_id
ORDER BY r.recent_margin ASC;




/* ------------------------------------------------------------
   TIME-BASED EXECUTIVE ACTION SEGMENTATION
   ------------------------------------------------------------
   Purpose:
   - Flag accounts needing immediate attention
------------------------------------------------------------- */
WITH max_month AS (
    SELECT MAX(month) AS max_month
    FROM account_profitability
),
recent AS (
    SELECT
        account_id,
        SUM(revenue) AS recent_revenue,
        SUM(profit) AS recent_profit,
        ROUND(SUM(profit) / NULLIF(SUM(revenue), 0), 4) AS recent_margin
    FROM account_profitability, max_month
    WHERE month >= (max_month - INTERVAL '3 months')
    GROUP BY account_id
)
SELECT
    account_id,
    recent_revenue,
    recent_profit,
    recent_margin,
    CASE
        WHEN recent_margin < 0 THEN 'Urgent Risk'
        WHEN recent_margin BETWEEN 0 AND 0.05 THEN 'Watch Closely'
        WHEN recent_margin > 0.05 THEN 'Healthy'
    END AS recent_status
FROM recent
ORDER BY recent_margin ASC;
