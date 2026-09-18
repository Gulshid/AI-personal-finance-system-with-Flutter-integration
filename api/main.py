"""
FastAPI service exposing the Personal Finance AI models as REST endpoints
for the Flutter app to consume.

Run locally with:
    uvicorn main:app --reload --host 0.0.0.0 --port 8000

Then Flutter (on a real device/emulator) hits it via your machine's LAN IP,
e.g. http://192.168.x.x:8000  (NOT localhost — see the README for details).

Interactive API docs are auto-generated at /docs once running.
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import Optional
import pandas as pd
import numpy as np
import joblib
import scipy.sparse as sp
from datetime import datetime
import os
import sys

sys.path.append(os.path.dirname(__file__) + "/../models")
from recommendation_engine import RecommendationEngine  # noqa: E402

MODEL_DIR = os.path.join(os.path.dirname(__file__), "..", "models")

app = FastAPI(
    title="AI Personal Finance & Expense Intelligence API",
    description="Category prediction, anomaly detection, spending clusters, forecasting, and recommendations.",
    version="1.0.0",
)

category_model = joblib.load(f"{MODEL_DIR}/category_model.joblib")
merchant_vectorizer = joblib.load(f"{MODEL_DIR}/merchant_vectorizer.joblib")
payment_encoder = joblib.load(f"{MODEL_DIR}/payment_encoder.joblib")
category_label_encoder = joblib.load(f"{MODEL_DIR}/category_label_encoder.joblib")

anomaly_model = joblib.load(f"{MODEL_DIR}/anomaly_model.joblib")
anomaly_category_encoder = joblib.load(f"{MODEL_DIR}/anomaly_category_encoder.joblib")
user_category_stats = pd.read_csv(f"{MODEL_DIR}/user_category_stats.csv")

cluster_model = joblib.load(f"{MODEL_DIR}/cluster_model.joblib")
cluster_scaler = joblib.load(f"{MODEL_DIR}/cluster_scaler.joblib")
user_profiles = pd.read_csv(f"{MODEL_DIR}/user_profiles_with_clusters.csv", index_col="user_id")

forecast_model = joblib.load(f"{MODEL_DIR}/forecast_model.joblib")
forecast_feature_cols = joblib.load(f"{MODEL_DIR}/forecast_feature_cols.joblib")
monthly_series = pd.read_csv(f"{MODEL_DIR}/monthly_spend_series.csv")

recommendation_engine = RecommendationEngine()



class TransactionInput(BaseModel):
    merchant: str = Field(..., example="Starbucks")
    amount: float = Field(..., example=12.50)
    payment_method: str = Field(..., example="Credit Card")
    date: Optional[str] = Field(None, example="2026-09-15")


class CategoryPredictionResponse(BaseModel):
    predicted_category: str
    confidence: float


class AnomalyCheckInput(BaseModel):
    user_id: int
    category: str
    merchant: str
    amount: float
    date: Optional[str] = None


class AnomalyCheckResponse(BaseModel):
    is_anomaly: bool
    anomaly_score: float
    user_typical_amount: Optional[float]
    deviation_std: Optional[float]



@app.get("/")
def root():
    return {"status": "ok", "service": "AI Personal Finance API", "endpoints": [
        "/predict-category", "/check-anomaly", "/user/{user_id}/cluster",
        "/user/{user_id}/forecast", "/user/{user_id}/recommendations"
    ]}


@app.post("/predict-category", response_model=CategoryPredictionResponse)
def predict_category(tx: TransactionInput):
    """Predict the spending category for a raw transaction."""
    date = pd.to_datetime(tx.date) if tx.date else pd.Timestamp.now()
    day_of_week = date.dayofweek

    merchant_feat = merchant_vectorizer.transform([tx.merchant])
    try:
        payment_enc = payment_encoder.transform([tx.payment_method])[0]
    except ValueError:
        raise HTTPException(status_code=400, detail=f"Unknown payment_method: {tx.payment_method}")

    numeric_feat = np.array([[tx.amount, day_of_week, payment_enc]])
    X = sp.hstack([merchant_feat, sp.csr_matrix(numeric_feat)]).tocsr()

    pred_idx = category_model.predict(X)[0]
    probs = category_model.predict_proba(X)[0]
    category = category_label_encoder.inverse_transform([pred_idx])[0]

    return CategoryPredictionResponse(predicted_category=category, confidence=float(probs.max()))


@app.post("/check-anomaly", response_model=AnomalyCheckResponse)
def check_anomaly(tx: AnomalyCheckInput):
    """Check whether a transaction is unusual for this user, given their history."""
    date = pd.to_datetime(tx.date) if tx.date else pd.Timestamp.now()
    day_of_week = date.dayofweek

    stats_row = user_category_stats[
        (user_category_stats["user_id"] == tx.user_id) & (user_category_stats["category"] == tx.category)
    ]
    if stats_row.empty:
        cat_mean, cat_std = tx.amount, 1.0  # no history yet -> treat as baseline
    else:
        cat_mean = stats_row["cat_mean"].values[0]
        cat_std = stats_row["cat_std"].values[0] or 1.0

    deviation = (tx.amount - cat_mean) / cat_std

    try:
        category_enc = anomaly_category_encoder.transform([tx.category])[0]
    except ValueError:
        raise HTTPException(status_code=400, detail=f"Unknown category: {tx.category}")

    X = np.array([[tx.amount, deviation, day_of_week, category_enc]])
    score = anomaly_model.decision_function(X)[0]
    is_anomaly = anomaly_model.predict(X)[0] == -1

    return AnomalyCheckResponse(
        is_anomaly=bool(is_anomaly),
        anomaly_score=float(score),
        user_typical_amount=float(cat_mean),
        deviation_std=float(deviation),
    )


@app.get("/user/{user_id}/cluster")
def get_user_cluster(user_id: int):
    """Get the spending persona (cluster) for a user, plus their spend-mix profile."""
    if user_id not in user_profiles.index:
        raise HTTPException(status_code=404, detail="User not found or insufficient history")
    row = user_profiles.loc[user_id]
    pct_cols = [c for c in user_profiles.columns if c.startswith("pct_")]
    return {
        "user_id": user_id,
        "cluster": int(row["cluster"]),
        "monthly_spend": float(row["monthly_spend"]),
        "spend_mix": {c.replace("pct_", ""): round(float(row[c]), 3) for c in pct_cols},
    }


@app.get("/user/{user_id}/forecast")
def get_user_forecast(user_id: int):
    """Forecast next month's spend per category for a user, based on recent trend."""
    user_monthly = monthly_series[monthly_series["user_id"] == user_id]
    if user_monthly.empty:
        raise HTTPException(status_code=404, detail="User not found or insufficient history")

    forecasts = {}
    for category, grp in user_monthly.groupby("category"):
        grp = grp.sort_values("year_month")
        if len(grp) < 2:
            continue
        amounts = grp["amount"].values
        lag1, lag2 = amounts[-1], amounts[-2]
        rolling_mean = np.mean(amounts[-3:])
        trend = lag1 - lag2

        row = pd.DataFrame([{
            "lag1": lag1, "lag2": lag2, "rolling_mean": rolling_mean, "trend": trend,
        }])
        for col in forecast_feature_cols:
            if col.startswith("cat_"):
                row[col] = 1 if col == f"cat_{category}" else 0
        row = row[forecast_feature_cols]

        pred = forecast_model.predict(row)[0]
        forecasts[category] = round(float(pred), 2)

    return {"user_id": user_id, "forecast_next_month": forecasts}


@app.get("/user/{user_id}/recommendations")
def get_user_recommendations(user_id: int):
    """Get personalized budgeting recommendations for a user."""
    recs = recommendation_engine.get_recommendations(user_id)
    return {"user_id": user_id, "recommendations": recs}
