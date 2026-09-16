"""
Generates realistic synthetic transaction data for N users over M months.
Designed to mimic the schema your Flutter app will eventually send:
    user_id, date, merchant, category, amount, payment_method

Categories and merchants are grouped so the category-prediction model
has a learnable signal (merchant -> category), while amount distributions
differ by category so anomaly detection has something real to catch.
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random

random.seed(42)
np.random.seed(42)

# ---- Category -> merchants + typical amount range (mean, std) ----
CATEGORY_MERCHANTS = {
    "Groceries": (["Walmart", "Carrefour", "Local Mart", "Fresh Foods"], (40, 15)),
    "Dining": (["McDonalds", "Starbucks", "Pizza Hut", "Local Cafe"], (18, 10)),
    "Transport": (["Uber", "Careem", "Shell Gas", "Metro Card"], (12, 8)),
    "Utilities": (["Electric Co", "Water Board", "Internet ISP", "Gas Company"], (60, 20)),
    "Entertainment": (["Netflix", "Spotify", "Cinema", "Steam"], (15, 10)),
    "Shopping": (["Amazon", "Daraz", "Zara", "IKEA"], (55, 40)),
    "Healthcare": (["Pharmacy", "Clinic", "Hospital", "Dental Care"], (35, 30)),
    "Rent": (["Landlord Transfer"], (500, 100)),
    "Travel": (["Airline Co", "Hotel Booking", "AirBnB"], (200, 150)),
    "Education": (["Udemy", "Coursera", "Bookstore", "Tuition Center"], (30, 25)),
}

PAYMENT_METHODS = ["Credit Card", "Debit Card", "Cash", "Mobile Wallet"]

# User personas -> category spending weight (probability of transacting in that category)
PERSONAS = {
    "student": {"Groceries": 0.2, "Dining": 0.25, "Transport": 0.15, "Entertainment": 0.15,
                "Shopping": 0.1, "Education": 0.1, "Utilities": 0.03, "Healthcare": 0.02},
    "young_professional": {"Groceries": 0.15, "Dining": 0.2, "Transport": 0.15, "Shopping": 0.15,
                            "Entertainment": 0.1, "Utilities": 0.08, "Rent": 0.1, "Travel": 0.05, "Healthcare": 0.02},
    "family": {"Groceries": 0.3, "Utilities": 0.15, "Healthcare": 0.1, "Shopping": 0.15,
               "Rent": 0.15, "Dining": 0.08, "Transport": 0.05, "Education": 0.02},
    "high_earner": {"Dining": 0.15, "Shopping": 0.2, "Travel": 0.2, "Entertainment": 0.1,
                     "Groceries": 0.1, "Rent": 0.15, "Utilities": 0.05, "Healthcare": 0.05},
}


def generate_transactions(n_users=50, months=6, min_tx_per_day=0, max_tx_per_day=4):
    rows = []
    end_date = datetime(2026, 9, 1)
    start_date = end_date - timedelta(days=30 * months)

    for user_id in range(1, n_users + 1):
        persona_name = random.choice(list(PERSONAS.keys()))
        weights = PERSONAS[persona_name]
        categories = list(weights.keys())
        probs = np.array(list(weights.values()))
        probs = probs / probs.sum()

        current = start_date
        while current <= end_date:
            n_tx = np.random.poisson(1.2)  # avg ~1.2 tx/day
            for _ in range(n_tx):
                category = np.random.choice(categories, p=probs)
                merchants, (mean_amt, std_amt) = CATEGORY_MERCHANTS[category]
                merchant = random.choice(merchants)
                amount = max(1, round(np.random.normal(mean_amt, std_amt), 2))

                # Inject occasional anomalies (rare, large, off-pattern transactions)
                is_anomaly = np.random.rand() < 0.01
                if is_anomaly:
                    amount = round(amount * random.uniform(5, 12), 2)

                rows.append({
                    "user_id": user_id,
                    "persona": persona_name,
                    "date": current.strftime("%Y-%m-%d"),
                    "merchant": merchant,
                    "category": category,
                    "amount": amount,
                    "payment_method": random.choice(PAYMENT_METHODS),
                    "is_anomaly_synthetic": is_anomaly,  # ground truth, for evaluation only
                })
            current += timedelta(days=1)

    df = pd.DataFrame(rows)
    return df


if __name__ == "__main__":
    df = generate_transactions(n_users=50, months=6)
    out_path = "/home/claude/finance_ai/data/transactions.csv"
    df.to_csv(out_path, index=False)
    print(f"Generated {len(df)} transactions for {df['user_id'].nunique()} users")
    print(f"Saved to {out_path}")
    print("\nCategory distribution:")
    print(df["category"].value_counts())
    print(f"\nSynthetic anomalies injected: {df['is_anomaly_synthetic'].sum()}")
