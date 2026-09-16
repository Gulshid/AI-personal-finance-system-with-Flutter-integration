"""
Detects unusual transactions using Isolation Forest.

Key design choice: raw amount alone isn't a good anomaly signal (a $500 rent
payment is normal, a $500 coffee purchase isn't). So we engineer a
"relative deviation" feature per user+category: how far is this transaction's
amount from that user's typical spend in that category (in std deviations)?
This makes the model personalized instead of using one global threshold.
"""

import pandas as pd
import numpy as np
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import LabelEncoder
import joblib

import os
_HERE = os.path.dirname(os.path.abspath(__file__))
_ROOT = os.path.dirname(_HERE)
DATA_PATH = os.path.join(_ROOT, "data", "transactions.csv")
MODEL_DIR = os.path.join(_ROOT, "models")


def engineer_features(df):
    df = df.copy()
    df["date"] = pd.to_datetime(df["date"])
    df["day_of_week"] = df["date"].dt.dayofweek

    # Per-user-per-category mean/std, used to compute how "off" a transaction is
    stats = df.groupby(["user_id", "category"])["amount"].agg(["mean", "std"]).reset_index()
    stats.columns = ["user_id", "category", "cat_mean", "cat_std"]
    stats["cat_std"] = stats["cat_std"].fillna(1).replace(0, 1)  # avoid div-by-zero

    df = df.merge(stats, on=["user_id", "category"], how="left")
    df["deviation"] = (df["amount"] - df["cat_mean"]) / df["cat_std"]

    category_encoder = LabelEncoder()
    df["category_encoded"] = category_encoder.fit_transform(df["category"])

    features = df[["amount", "deviation", "day_of_week", "category_encoded"]].values
    return features, df, category_encoder, stats


def main():
    df = pd.read_csv(DATA_PATH)
    X, df_enriched, category_encoder, user_cat_stats = engineer_features(df)

    # contamination = expected proportion of anomalies (we injected ~1%, add margin)
    model = IsolationForest(
        n_estimators=200,
        contamination=0.02,
        random_state=42,
        n_jobs=-1,
    )
    model.fit(X)

    df_enriched["anomaly_score"] = model.decision_function(X)  # lower = more anomalous
    df_enriched["predicted_anomaly"] = model.predict(X) == -1  # -1 = anomaly, 1 = normal

    # Sanity check against the ground-truth anomalies we injected in data generation
    if "is_anomaly_synthetic" in df_enriched.columns:
        true_pos = ((df_enriched["predicted_anomaly"]) & (df_enriched["is_anomaly_synthetic"])).sum()
        total_true = df_enriched["is_anomaly_synthetic"].sum()
        total_flagged = df_enriched["predicted_anomaly"].sum()
        print(f"Injected anomalies: {total_true}")
        print(f"Flagged as anomalies: {total_flagged}")
        print(f"Correctly caught: {true_pos} ({true_pos/total_true:.1%} recall)")

    print("\nSample flagged anomalies:")
    print(df_enriched[df_enriched["predicted_anomaly"]][
        ["user_id", "merchant", "category", "amount", "cat_mean", "deviation"]
    ].head(10).to_string(index=False))

    joblib.dump(model, f"{MODEL_DIR}/anomaly_model.joblib")
    joblib.dump(category_encoder, f"{MODEL_DIR}/anomaly_category_encoder.joblib")
    user_cat_stats.to_csv(f"{MODEL_DIR}/user_category_stats.csv", index=False)
    print(f"\nSaved anomaly model + user stats to {MODEL_DIR}/")


if __name__ == "__main__":
    main()
