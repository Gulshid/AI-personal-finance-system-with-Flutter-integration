"""
Trains a model to predict transaction CATEGORY from merchant + amount + payment_method.
This mirrors the real-world use case: your Flutter app sends a raw transaction
(merchant name, amount, payment method) and the API returns the predicted category,
so the user doesn't have to manually categorize every expense.

Saves the trained model + label encoders to disk for the API to load later.
"""

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics import classification_report, accuracy_score
from xgboost import XGBClassifier
import joblib
import scipy.sparse as sp

DATA_PATH = "/home/claude/finance_ai/data/transactions.csv"
MODEL_DIR = "/home/claude/finance_ai/models"

def build_features(df, merchant_vectorizer=None, payment_encoder=None, fit=True):
    """
    Feature set:
      - merchant name -> TF-IDF (character n-grams, so it generalizes to new/unseen merchant names)
      - amount (numeric)
      - payment_method -> one-hot via LabelEncoder + dummy-style handling
      - day_of_week (numeric, from date)
    """
    df = df.copy()
    df["date"] = pd.to_datetime(df["date"])
    df["day_of_week"] = df["date"].dt.dayofweek

    if fit:
        merchant_vectorizer = TfidfVectorizer(analyzer="char_wb", ngram_range=(2, 4), max_features=200)
        merchant_features = merchant_vectorizer.fit_transform(df["merchant"])
        payment_encoder = LabelEncoder()
        payment_encoded = payment_encoder.fit_transform(df["payment_method"])
    else:
        merchant_features = merchant_vectorizer.transform(df["merchant"])
        payment_encoded = payment_encoder.transform(df["payment_method"])

    numeric_features = np.column_stack([
        df["amount"].values,
        df["day_of_week"].values,
        payment_encoded,
    ])

    X = sp.hstack([merchant_features, sp.csr_matrix(numeric_features)]).tocsr()
    return X, merchant_vectorizer, payment_encoder


def main():
    df = pd.read_csv(DATA_PATH)
    print(f"Loaded {len(df)} transactions")

    label_encoder = LabelEncoder()
    y = label_encoder.fit_transform(df["category"])

    X_train_df, X_test_df, y_train, y_test = train_test_split(
        df, y, test_size=0.2, random_state=42, stratify=y
    )

    X_train, merchant_vec, payment_enc = build_features(X_train_df, fit=True)
    X_test, _, _ = build_features(X_test_df, merchant_vec, payment_enc, fit=False)

    print("\n--- Random Forest ---")
    rf = RandomForestClassifier(n_estimators=200, max_depth=15, random_state=42, n_jobs=-1)
    rf.fit(X_train, y_train)
    rf_preds = rf.predict(X_test)
    print(f"Accuracy: {accuracy_score(y_test, rf_preds):.4f}")

    print("\n--- XGBoost ---")
    xgb = XGBClassifier(n_estimators=200, max_depth=6, learning_rate=0.1,
                         random_state=42, eval_metric="mlogloss")
    xgb.fit(X_train, y_train)
    xgb_preds = xgb.predict(X_test)
    print(f"Accuracy: {accuracy_score(y_test, xgb_preds):.4f}")

    # Pick the better model
    best_model, best_preds, best_name = (
        (xgb, xgb_preds, "xgboost") if accuracy_score(y_test, xgb_preds) >= accuracy_score(y_test, rf_preds)
        else (rf, rf_preds, "random_forest")
    )
    print(f"\nBest model: {best_name}")
    print("\nClassification report:")
    print(classification_report(y_test, best_preds, target_names=label_encoder.classes_))

    # Save everything the API will need
    joblib.dump(best_model, f"{MODEL_DIR}/category_model.joblib")
    joblib.dump(merchant_vec, f"{MODEL_DIR}/merchant_vectorizer.joblib")
    joblib.dump(payment_enc, f"{MODEL_DIR}/payment_encoder.joblib")
    joblib.dump(label_encoder, f"{MODEL_DIR}/category_label_encoder.joblib")
    print(f"\nSaved model artifacts to {MODEL_DIR}/")


if __name__ == "__main__":
    main()
