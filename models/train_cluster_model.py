"""
Groups users into spending "personas" (clusters) based on their aggregate
spending behavior — not individual transactions. This powers a feature like
"users like you typically spend less on dining" or persona-based budget tips.

Feature engineering: for each user, compute:
  - % of total spend in each category (spending mix, robust to income level)
  - total monthly spend
  - transaction frequency
  - average transaction size
"""

import pandas as pd
import numpy as np
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA
from sklearn.metrics import silhouette_score
import joblib

import os
_HERE = os.path.dirname(os.path.abspath(__file__))
_ROOT = os.path.dirname(_HERE)
DATA_PATH = os.path.join(_ROOT, "data", "transactions.csv")
MODEL_DIR = os.path.join(_ROOT, "models")


def build_user_profiles(df):
    df = df.copy()
    df["date"] = pd.to_datetime(df["date"])
    months_span = max(1, (df["date"].max() - df["date"].min()).days / 30)

    # Category spend mix (% of total, per user)
    cat_totals = df.pivot_table(index="user_id", columns="category", values="amount",
                                 aggfunc="sum", fill_value=0)
    cat_pct = cat_totals.div(cat_totals.sum(axis=1), axis=0)
    cat_pct.columns = [f"pct_{c}" for c in cat_pct.columns]

    # Behavioral aggregates
    agg = df.groupby("user_id").agg(
        total_spend=("amount", "sum"),
        avg_transaction=("amount", "mean"),
        transaction_count=("amount", "count"),
    )
    agg["monthly_spend"] = agg["total_spend"] / months_span
    agg["monthly_tx_count"] = agg["transaction_count"] / months_span

    profiles = cat_pct.join(agg[["monthly_spend", "avg_transaction", "monthly_tx_count"]])
    return profiles


def main():
    df = pd.read_csv(DATA_PATH)
    profiles = build_user_profiles(df)
    feature_cols = profiles.columns.tolist()

    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(profiles.values)

    # Try a small range of k and pick the best by silhouette score
    best_k, best_score = 3, -1
    for k in range(3, 7):
        km = KMeans(n_clusters=k, random_state=42, n_init=10)
        labels = km.fit_predict(X_scaled)
        score = silhouette_score(X_scaled, labels)
        print(f"k={k}: silhouette={score:.4f}")
        if score > best_score:
            best_k, best_score = k, score

    print(f"\nBest k: {best_k} (silhouette={best_score:.4f})")
    model = KMeans(n_clusters=best_k, random_state=42, n_init=10)
    profiles["cluster"] = model.fit_predict(X_scaled)

    print("\nCluster profiles (avg spend mix by cluster):")
    cluster_summary = profiles.groupby("cluster")[
        [c for c in feature_cols if c.startswith("pct_")] + ["monthly_spend"]
    ].mean().round(3)
    print(cluster_summary.to_string())

    print("\nUsers per cluster:")
    print(profiles["cluster"].value_counts().sort_index())

    joblib.dump(model, f"{MODEL_DIR}/cluster_model.joblib")
    joblib.dump(scaler, f"{MODEL_DIR}/cluster_scaler.joblib")
    joblib.dump(feature_cols, f"{MODEL_DIR}/cluster_feature_cols.joblib")
    profiles.to_csv(f"{MODEL_DIR}/user_profiles_with_clusters.csv")
    print(f"\nSaved cluster model + user profiles to {MODEL_DIR}/")


if __name__ == "__main__":
    main()
