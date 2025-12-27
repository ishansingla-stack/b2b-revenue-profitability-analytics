-- =========================================================
-- B2B Revenue, Pricing & Customer Profitability Analytics
-- Database Schema (PostgreSQL)
-- =========================================================

-- =========================
-- 1. ACCOUNTS (B2B CUSTOMERS)
-- =========================
-- Represents client companies (not individual users)

CREATE TABLE accounts (
    account_id      SERIAL PRIMARY KEY,
    account_name    TEXT NOT NULL,
    industry        TEXT,
    company_size    INTEGER,          -- number of employees
    region          TEXT,
    contract_type   TEXT CHECK (contract_type IN ('monthly', 'annual')),
    signup_date     DATE,
    status          TEXT CHECK (status IN ('active', 'churned'))
);

CREATE INDEX idx_accounts_region ON accounts(region);
CREATE INDEX idx_accounts_industry ON accounts(industry);

-- =========================
-- 2. PLANS (PRICING STRUCTURE)
-- =========================
-- Defines standard pricing tiers

CREATE TABLE plans (
    plan_id          SERIAL PRIMARY KEY,
    plan_name        TEXT NOT NULL,
    base_price       NUMERIC(10,2) NOT NULL,
    included_users   INTEGER,
    overage_price    NUMERIC(10,2)
);

-- =========================
-- 3. SUBSCRIPTIONS
-- =========================
-- Connects accounts to plans and captures discounts

CREATE TABLE subscriptions (
    subscription_id  SERIAL PRIMARY KEY,
    account_id       INTEGER REFERENCES accounts(account_id),
    plan_id          INTEGER REFERENCES plans(plan_id),
    discount_pct     NUMERIC(5,2) CHECK (discount_pct >= 0 AND discount_pct <= 100),
    start_date       DATE,
    end_date         DATE,
    status           TEXT CHECK (status IN ('active', 'cancelled'))
);

CREATE INDEX idx_subscriptions_account ON subscriptions(account_id);

-- =========================
-- 4. INVOICES (REVENUE)
-- =========================
-- Actual billed revenue by month

CREATE TABLE invoices (
    invoice_id      SERIAL PRIMARY KEY,
    account_id      INTEGER REFERENCES accounts(account_id),
    billing_month   DATE NOT NULL,
    amount_billed   NUMERIC(12,2) NOT NULL
);

CREATE INDEX idx_invoices_account_month 
ON invoices(account_id, billing_month);

-- =========================
-- 5. USAGE METRICS
-- =========================
-- Captures how intensively customers use the product

CREATE TABLE usage_metrics (
    account_id      INTEGER REFERENCES accounts(account_id),
    usage_month     DATE,
    active_users    INTEGER,
    api_calls       INTEGER,
    feature_events  INTEGER,
    PRIMARY KEY (account_id, usage_month)
);

-- =========================
-- 6. SUPPORT COSTS
-- =========================
-- Tracks operational burden per account

CREATE TABLE support_costs (
    account_id      INTEGER REFERENCES accounts(account_id),
    support_month   DATE,
    tickets         INTEGER,
    support_hours   NUMERIC(8,2),
    cost            NUMERIC(10,2),
    PRIMARY KEY (account_id, support_month)
);

-- =========================
-- 7. ACCOUNT PROFITABILITY (ANALYTICS TABLE)
-- =========================
-- Derived table created via ETL
-- This is the main table used for ML and dashboards

CREATE TABLE account_profitability (
    account_id      INTEGER REFERENCES accounts(account_id),
    month           DATE,
    revenue         NUMERIC(12,2),
    support_cost    NUMERIC(10,2),
    discount_amount NUMERIC(10,2),
    profit          NUMERIC(12,2),
    margin_pct      NUMERIC(5,2),
    PRIMARY KEY (account_id, month)
);

-- =========================================================
-- END OF SCHEMA
-- =========================================================
