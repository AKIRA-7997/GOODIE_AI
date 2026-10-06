# GOODIE AI

Retail inventory and demand planning for a single-device business workspace.

## Workspace

- Create your business and add products for your own branches.
- Add, edit, delete and search inventory; filter by branch or reorder threshold.
- Overview totals come from saved inventory, including units, stock cost and low-stock products.
- Enter prices, sales history and forecast conditions for each product. No sales figures or model inputs are fabricated.
- Generate forecasts through the Flask service. Results are saved per product and cleared when its inputs change.
- Settings contains the business name, forecast service address, storage location and version.

## Run

Use a current stable Flutter SDK:

```sh
flutter pub get
flutter run --dart-define=GOODIE_API_URL=https://your-forecast-service.example
```

The URL can also be set in Settings. Release Android builds require HTTPS. For local desktop/web development, run Flask on loopback and configure the matching service URL. A physical phone needs a reachable service, not the phone's localhost. The Android app includes Internet permission.

```sh
python -m venv .venv
# Activate the virtual environment for your shell.
pip install -r backend/requirements.txt
python backend/train_model.py
python backend/app.py
```

The model artifact is not committed. A missing artifact leaves the API running but forecasts return 503. Set `GOODIE_HOST` explicitly to expose the service on your network. For web clients, set `GOODIE_ALLOWED_ORIGINS` to a comma-separated list of permitted origins (default `http://localhost:8080`).

## Forecast contract

POST `/predict` accepts the existing 21 model fields. Calendar fields must agree with a real date; quantities must be non-negative whole units; numeric values must be finite. Promotion levels match the training vocabulary (`None`, `Low`, `Medium`, `High`). Use the dataset's category, store-type and season labels for known categories. New branch and product names can be entered, but the existing encoder ignores unseen categories; model retraining is required to learn their effects.

Forecast results contain demand, safety stock, target stock, suggested order quantity and the forecast date. The old global R²-based “confidence” and speculative demand-factor explanations were removed. The model still requires temporal validation and a clearly validated demand horizon before operational ordering decisions.

## Data and deployment boundaries

The workspace currently uses device-local preferences; it has no account system, cloud sync or multi-user access. The previous screen accepted arbitrary passwords and was removed. Local preferences are not a durable inventory ledger: clearing app data removes the workspace. Add a transactional database, backup/export and authenticated server persistence before using this as a business system of record. The Flask service must sit behind authentication, TLS and a production WSGI server before public deployment. This revision improves product workflows and removes demo data; it does not claim a production deployment.

## Checks

```sh
flutter analyze
flutter test
flutter build web
python -m unittest discover -s backend/tests -v
```

API tests use an explicit predictor fixture and do not claim to measure trained-model accuracy.
