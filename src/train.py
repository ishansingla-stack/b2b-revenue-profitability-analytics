"""
============================================================
ML PIPELINE: Predict Deteriorating B2B Accounts
============================================================

Objective:
----------
Predict whether a B2B account is likely to deteriorate
based on recent financial, usage, and support behavior.

Target Variable:
----------------
deteriorating_label
- 1 = Account is deteriorating
- 0 = Stable / improving

Data Source:
------------
PostgreSQL VIEW: ml_account_training_data

Models:
-------
1. Logistic Regression (interpretable baseline)
2. Random Forest (nonlinear, higher performance)

============================================================
"""


import pandas as pd
from sqlalchemy import create_engine
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = int(os.getenv("DB_PORT", 5432))

engine = create_engine(
    f"postgresql+psycopg://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

# Load ML training data (VIEW)
query = "SELECT * FROM ml_account_training_data"
df = pd.read_sql(query, engine)

print(df.head())
print(df.dtypes)


from sklearn.model_selection import train_test_split

# Select features
FEATURES = [
    "revenue",
    "profit",
    "support_cost",
    "margin",
    "active_users",
    "api_calls"
]

TARGET = "deteriorating_label"

X = df[FEATURES].fillna(0)
y = df[TARGET]

# Train / test split
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.25, random_state=42, stratify=y
)

print("Train size:", X_train.shape)
print("Test size:", X_test.shape)


from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report

log_reg = LogisticRegression(max_iter=1000)

log_reg.fit(X_train, y_train)

y_pred_lr = log_reg.predict(X_test)

print("Logistic Regression Results:")
print(classification_report(y_test, y_pred_lr))


from sklearn.ensemble import RandomForestClassifier

rf = RandomForestClassifier(
    n_estimators=200,
    max_depth=6,
    random_state=42
)

rf.fit(X_train, y_train)

y_pred_rf = rf.predict(X_test)

print("Random Forest Results:")
print(classification_report(y_test, y_pred_rf))


import pandas as pd

feature_importance = pd.DataFrame({
    "feature": FEATURES,
    "importance": rf.feature_importances_
}).sort_values(by="importance", ascending=False)

print(feature_importance)
