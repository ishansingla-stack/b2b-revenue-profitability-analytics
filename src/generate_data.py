import pandas as pd
import numpy as np
from datetime import datetime
import random
import os

np.random.seed(42)
random.seed(42)

# ---------------------------
# CONFIG
# ---------------------------
N_ACCOUNTS = 200
START_DATE = "2023-01-01"
END_DATE = "2024-12-01"
DATA_DIR = "data/raw"

os.makedirs(DATA_DIR, exist_ok=True)

months = pd.date_range(start=START_DATE, end=END_DATE, freq="MS")

# ---------------------------
# 1. ACCOUNTS
# ---------------------------
industries = ["Manufacturing", "Logistics", "Retail", "Healthcare", "Technology"]
regions = ["North America", "Europe", "APAC"]
contract_types = ["monthly", "annual"]

accounts = []

for i in range(N_ACCOUNTS):
    accounts.append({
        "account_id": i + 1,
        "account_name": f"Account_{i+1}",
        "industry": random.choice(industries),
        "company_size": random.randint(20, 500),
        "region": random.choice(regions),
        "contract_type": random.choice(contract_types),
        "signup_date": pd.to_datetime("2022-01-01") + pd.to_timedelta(random.randint(0, 365), unit="D"),
        "status": "active"
    })

accounts_df = pd.DataFrame(accounts)

# ---------------------------
# 2. PLANS
# ---------------------------
plans_df = pd.DataFrame([
    {"plan_id": 1, "plan_name": "Basic", "base_price": 500, "included_users": 10, "overage_price": 20},
    {"plan_id": 2, "plan_name": "Pro", "base_price": 1200, "included_users": 25, "overage_price": 18},
    {"plan_id": 3, "plan_name": "Enterprise", "base_price": 3000, "included_users": 75, "overage_price": 15},
])

# ---------------------------
# 3. SUBSCRIPTIONS
# ---------------------------
subscriptions = []

for acc in accounts:
    plan = random.choice(plans_df["plan_id"])
    discount = np.clip(np.random.normal(10, 10), 0, 40)

    subscriptions.append({
        "subscription_id": acc["account_id"],
        "account_id": acc["account_id"],
        "plan_id": plan,
        "discount_pct": round(discount, 2),
        "start_date": acc["signup_date"],
        "end_date": None,
        "status": "active"
    })

subscriptions_df = pd.DataFrame(subscriptions)

# ---------------------------
# 4. INVOICES
# ---------------------------
invoices = []

for _, sub in subscriptions_df.iterrows():
    plan_price = plans_df.loc[
        plans_df.plan_id == sub.plan_id, "base_price"
    ].values[0]

    for m in months:
        discounted_price = plan_price * (1 - sub.discount_pct / 100)
        noise = np.random.normal(0, 50)

        invoices.append({
            "invoice_id": len(invoices) + 1,
            "account_id": sub.account_id,
            "billing_month": m,
            "amount_billed": round(max(discounted_price + noise, 100), 2)
        })

invoices_df = pd.DataFrame(invoices)

# ---------------------------
# 5. USAGE METRICS
# ---------------------------
usage = []

for acc in accounts:
    base_users = random.randint(5, 80)

    for m in months:
        usage.append({
            "account_id": acc["account_id"],
            "usage_month": m,
            "active_users": max(1, int(np.random.normal(base_users, 5))),
            "api_calls": int(np.random.normal(10000, 3000)),
            "feature_events": int(np.random.normal(5000, 1200))
        })

usage_df = pd.DataFrame(usage)

# ---------------------------
# 6. SUPPORT COSTS
# ---------------------------
support = []

for acc in accounts:
    support_intensity = np.random.choice([0.5, 1, 2], p=[0.5, 0.3, 0.2])

    for m in months:
        tickets = int(np.random.poisson(3 * support_intensity))
        hours = tickets * np.random.uniform(0.5, 1.5)

        support.append({
            "account_id": acc["account_id"],
            "support_month": m,
            "tickets": tickets,
            "support_hours": round(hours, 2),
            "cost": round(hours * 60, 2)  # $60/hr support
        })

support_df = pd.DataFrame(support)

# ---------------------------
# SAVE FILES
# ---------------------------
accounts_df.to_csv(f"{DATA_DIR}/accounts.csv", index=False)
plans_df.to_csv(f"{DATA_DIR}/plans.csv", index=False)
subscriptions_df.to_csv(f"{DATA_DIR}/subscriptions.csv", index=False)
invoices_df.to_csv(f"{DATA_DIR}/invoices.csv", index=False)
usage_df.to_csv(f"{DATA_DIR}/usage_metrics.csv", index=False)
support_df.to_csv(f"{DATA_DIR}/support_costs.csv", index=False)

print("✅ Synthetic data generated successfully.")
