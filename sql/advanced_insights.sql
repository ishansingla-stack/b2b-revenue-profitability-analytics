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