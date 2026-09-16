"""
Predicts a user's NEXT MONTH spend, per category.

NOTE ON APPROACH: With only 6 months of history per user, there isn't enough
sequence length to train an LSTM/GRU without severe overfitting (a neural net
needs far more timesteps per sequence than that to learn anything real).
Instead we use "time series as regression": build lag features (last month's
spend, 2-month rolling average, month-over-month trend) and pool the data
across ALL users and categories into one training set. This is the standard
practical fix for short/sparse time series and is what most real fintech
products do for early-history users. As you collect more months of real data
per user, this can later be upgraded to a proper sequence model (LSTM/GRU or
a Temporal Fusion Transformer) without changing the API contract.
"""

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error, r2_score
from xgboost import XGBRegressor
import joblib

DATA_PATH = "/home/claude/finance_ai/data/transactions.csv"
MODEL_DIR = "/home/claude/finance_ai/models"


def build_monthly_series(df):
    df = df.copy()
    df["date"] = pd.to_datetime(df["date"])
    df["year_month"] = df["date"].dt.to_period("M")

    monthly = df.groupby(["user_id", "category", "year_month"])["amount"].sum().reset_index()
    monthly = monthly.sort_values(["user_id", "category", "year_month"])
    return monthly


def build_lag_features(monthly):
    """For each (user, category) series, build lag-1, lag-2, rolling mean, and trend
    as features, with the target being that month's actual spend."""
    rows = []
    for (user_id, category), grp in monthly.groupby(["user_id", "category"]):
        grp = grp.sort_values("year_month").reset_index(drop=True)
        amounts = grp["amount"].values
        for i in range(2, len(amounts)):  # need at least 2 prior months
            lag1 = amounts[i - 1]
            lag2 = amounts[i - 2]
            rolling_mean = np.mean(amounts[max(0, i - 3):i])
            trend = lag1 - lag2
            target = amounts[i]
            rows.append({
                "user_id": user_id, "category": category,
                "lag1": lag1, "lag2": lag2, "rolling_mean": rolling_mean, "trend": trend,
                "target": target,
            })
    return pd.DataFrame(rows)


def main():
    df = pd.read_csv(DATA_PATH)
    monthly = build_monthly_series(df)
    print(f"Built monthly series: {monthly['user_id'].nunique()} users x "
          f"{monthly['category'].nunique()} categories, "
          f"{monthly['year_month'].nunique()} months")

    features_df = build_lag_features(monthly)
    print(f"Training rows (user-category-month combos with enough history): {len(features_df)}")

    if len(features_df) < 50:
        print("WARNING: very little training data — consider generating more months in generate_data.py")

    category_dummies = pd.get_dummies(features_df["category"], prefix="cat")
    X = pd.concat([features_df[["lag1", "lag2", "rolling_mean", "trend"]], category_dummies], axis=1)
    y = features_df["target"]

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    model = XGBRegressor(n_estimators=150, max_depth=4, learning_rate=0.1, random_state=42)
    model.fit(X_train, y_train)
    preds = model.predict(X_test)

    mae = mean_absolute_error(y_test, preds)
    r2 = r2_score(y_test, preds)
    print(f"\nMAE: ${mae:.2f}")
    print(f"R^2: {r2:.4f}")
    print(f"(For reference, average target value: ${y_test.mean():.2f})")

    joblib.dump(model, f"{MODEL_DIR}/forecast_model.joblib")
    joblib.dump(list(X.columns), f"{MODEL_DIR}/forecast_feature_cols.joblib")
    monthly.to_csv(f"{MODEL_DIR}/monthly_spend_series.csv", index=False)
    print(f"\nSaved forecast model to {MODEL_DIR}/")


if __name__ == "__main__":
    main()
