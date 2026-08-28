# GOODIE AI — Retail Demand Forecasting

GOODIE AI is a full-stack machine-learning prototype that forecasts retail product demand and converts each forecast into practical inventory guidance. It combines a Flutter application, a Flask REST API, and a scikit-learn Random Forest pipeline.

## Features

- Forecast demand for a selected store and product.
- Recommend inventory and safety-stock levels.
- Calculate restock and surplus quantities.
- Classify stock-out risk and stock health.
- Explain demand factors such as promotions, discounts, holidays, weekends, weather, and competitor pricing.
- Display prediction, inventory, dashboard, and analytics views in Flutter.

## Architecture

```text
Flutter application
        |
        | POST /predict
        v
Flask REST API
        |
        v
scikit-learn preprocessing + Random Forest
        |
        v
Demand forecast + inventory recommendation
```

## Technology stack

**Frontend:** Flutter, Dart, Provider, fl_chart, HTTP

**Backend and ML:** Python, Flask, Pandas, NumPy, scikit-learn, Random Forest Regressor, Joblib

## Repository structure

```text
GOODIE_AI/
├── backend/
│   ├── app.py
│   ├── train_model.py
│   ├── goodie_dataset.csv
│   └── requirements.txt
├── lib/
│   ├── core/
│   ├── models/
│   ├── providers/
│   ├── screens/
│   ├── widgets/
│   └── main.dart
├── test/
├── pubspec.yaml
└── README.md
```

## Run the backend

The following commands are for Windows Command Prompt:

```cmd
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python train_model.py
python app.py
```

Training creates `backend/goodie_model.pkl`. The generated model is approximately 245 MB and is intentionally excluded from GitHub's normal file storage. Regenerate it from the included dataset before starting the API.

The API runs at `http://localhost:5000`.

## Run the Flutter application

From the repository root:

```cmd
flutter pub get
flutter analyze
flutter test
flutter run
```

The Android emulator client uses `http://10.0.2.2:5000/predict` to reach the host computer. For a physical Android phone, replace that host with the computer's LAN IP address, connect both devices to the same network, and allow port 5000 through the firewall.

## Machine-learning workflow

1. Load and clean `goodie_dataset.csv`.
2. Parse dates and derive year and day features.
3. One-hot encode categorical variables.
4. Train a Random Forest regressor inside a reusable preprocessing pipeline.
5. Evaluate using MAE, RMSE, and R².
6. Save the fitted pipeline, ordered feature list, and metrics with Joblib.
7. Load the artifact in Flask and serve forecasts through `POST /predict`.

## Prediction output

The API returns expected demand, recommended inventory, safety stock, restock or surplus quantity, stock status, risk level, demand change, relevant demand factors, and an inventory recommendation.

## Current prototype limitations

- Dashboard, inventory, and analytics views currently contain disclosed demonstration data; the prediction screen calls the live Flask endpoint.
- Training uses a reproducible random 80/20 split. A production forecasting system should use time-aware validation and test future periods across stores and products.
- Displayed confidence is derived from global validation R²; it is not calibrated uncertainty for an individual prediction.
- Flask currently uses a local development server and permissive CORS. Production deployment needs authentication, restricted origins, rate limiting, persistent storage, monitoring, and scheduled retraining.
- Real deployment requires regularly refreshed and properly licensed retail data.

## Reproducibility

Training uses `random_state=42`. Run `python train_model.py` to regenerate the model using the included dataset and pinned dependency versions.

## Author

Developed by [AKIRA-7997](https://github.com/AKIRA-7997).
