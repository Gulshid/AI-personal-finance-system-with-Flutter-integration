# AI Personal Finance & Expense Intelligence System

ML models → FastAPI → Flutter app.

## Structure
```
.
├── data/
│   ├── generate_data.py          # synthetic transaction generator
│   └── transactions.csv          # 11K transactions, 50 users
├── models/
│   ├── train_category_model.py   # classification: category from transaction
│   ├── train_anomaly_model.py    # Isolation Forest: unusual transactions
│   ├── train_cluster_model.py    # K-Means: spending personas
│   ├── train_forecast_model.py   # XGBoost: next month's spend
│   ├── recommendation_engine.py  # rule-based glue over the 4 models
│   └── *.joblib, *.csv           # saved model artifacts
├── api/
│   └── main.py                   # FastAPI service (5 endpoints)
├── flutter_integration/
│   └── finance_ai_service.dart   # Dart client for the API
└── requirements.txt
```

## 1. Run the backend
```bash
python -m venv .venv
# Windows:  .venv\Scripts\activate
# Mac/Linux: source .venv/bin/activate
pip install -r requirements.txt

cd api
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```
Open http://localhost:8000/docs and test every endpoint in the browser
before touching Flutter.

## 2. (Optional) Retrain from scratch
```bash
cd data   && python generate_data.py
cd ../models && python train_category_model.py
python train_anomaly_model.py
python train_cluster_model.py
python train_forecast_model.py
```
All scripts now use paths relative to the repo, so they work on any machine.

## 3. Connect Flutter
- Copy `flutter_integration/finance_ai_service.dart` into `lib/services/`
- Add `http: ^1.2.0` to `pubspec.yaml`, run `flutter pub get`
- Set `baseUrl`:
  - Android emulator → `http://10.0.2.2:8000`
  - iOS simulator → `http://localhost:8000`
  - Real phone → `http://<your-PC-LAN-IP>:8000` (same Wi-Fi, allow port 8000 in firewall)

## Endpoints
| Method | Endpoint | Purpose |
|---|---|---|
| POST | `/predict-category` | predict category for a transaction |
| POST | `/check-anomaly` | flag unusual transaction for a user |
| GET | `/user/{id}/cluster` | spending persona + spend mix |
| GET | `/user/{id}/forecast` | next month's spend per category |
| GET | `/user/{id}/recommendations` | budgeting suggestions |
