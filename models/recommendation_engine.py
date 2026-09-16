"""
Combines signals from the category, anomaly, cluster, and forecast models
into human-readable budgeting recommendations for a given user.

This is intentionally rule-based glue logic on top of the ML outputs, not
another model — recommendation TEXT generation from numeric signals is a
classic case where simple, explainable rules beat a black-box model, and
your Flutter app needs deterministic, debuggable output anyway.
"""

import pandas as pd
import joblib

MODEL_DIR = "/home/claude/finance_ai/models"


class RecommendationEngine:
    def __init__(self):
        self.user_profiles = pd.read_csv(f"{MODEL_DIR}/user_profiles_with_clusters.csv", index_col="user_id")
        self.user_cat_stats = pd.read_csv(f"{MODEL_DIR}/user_category_stats.csv")
        self.monthly_series = pd.read_csv(f"{MODEL_DIR}/monthly_spend_series.csv")

        # Cluster benchmark: average spend mix per cluster, used to compare a user against peers
        pct_cols = [c for c in self.user_profiles.columns if c.startswith("pct_")]
        self.cluster_benchmarks = self.user_profiles.groupby("cluster")[pct_cols].mean()

    def get_recommendations(self, user_id: int, recent_anomalies: list = None):
        recs = []

        if user_id not in self.user_profiles.index:
            return [{"type": "info", "message": "Not enough history yet to generate personalized recommendations."}]

        user_row = self.user_profiles.loc[user_id]
        cluster = int(user_row["cluster"])
        benchmark = self.cluster_benchmarks.loc[cluster]

        # 1. Compare user's category spend mix vs their cluster's average
        pct_cols = [c for c in self.user_profiles.columns if c.startswith("pct_")]
        for col in pct_cols:
            category = col.replace("pct_", "")
            user_pct = user_row[col]
            peer_pct = benchmark[col]
            if peer_pct > 0.02 and user_pct > peer_pct * 1.4:  # meaningfully overspending vs peers
                recs.append({
                    "type": "overspend_vs_peers",
                    "category": category,
                    "message": f"You spend {user_pct:.0%} of your budget on {category}, "
                               f"vs {peer_pct:.0%} for similar users. Consider setting a limit here.",
                })

        # 2. Flag categories with rising trend (last month vs prior month)
        user_monthly = self.monthly_series[self.monthly_series["user_id"] == user_id]
        for category, grp in user_monthly.groupby("category"):
            grp = grp.sort_values("year_month")
            if len(grp) >= 2:
                last, prev = grp["amount"].iloc[-1], grp["amount"].iloc[-2]
                if prev > 0 and last > prev * 1.3:
                    recs.append({
                        "type": "rising_trend",
                        "category": category,
                        "message": f"Your {category} spend rose {((last/prev)-1):.0%} last month "
                                   f"(${prev:.0f} -> ${last:.0f}). Worth a look.",
                    })

        # 3. Surface recent anomalies (passed in from the anomaly-detection endpoint)
        if recent_anomalies:
            for a in recent_anomalies:
                recs.append({
                    "type": "anomaly",
                    "category": a.get("category"),
                    "message": f"Unusual transaction: ${a.get('amount'):.2f} at {a.get('merchant')} "
                               f"({a.get('category')}) — this is much higher than your usual spend here.",
                })

        if not recs:
            recs.append({"type": "on_track", "message": "Your spending looks consistent with your usual pattern. Nice work!"})

        return recs


if __name__ == "__main__":
    engine = RecommendationEngine()
    for uid in [1, 2, 3]:
        print(f"\n--- Recommendations for user {uid} ---")
        for rec in engine.get_recommendations(uid):
            print(f"[{rec['type']}] {rec['message']}")
