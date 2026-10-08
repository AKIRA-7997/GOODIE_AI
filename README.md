# GOODIE AI

## Retailer workflow update

Sold / Received buttons update on-hand stock directly and retain the latest 20
stock movements per product. Sales cannot exceed available stock. Each movement
clears the previous estimate so the next order uses current stock. These entries
do not update the manually supplied seven-day sales figure; the sale dialog
states this explicitly. This is a local activity list, not a complete audit ledger.

Main navigation: My shop, Products, Stock plan. Product forms include branch
locality and the last seven days' sales. Location is organizational context only;
no population, footfall or local purchasing pattern is inferred from an area name.

Calculate order is an offline **sales-based baseline**, not the trained model:
next-seven-day sales = entered last-seven-day units; target = ceil(sales * 1.2);
order = max(0, target - stock). The 20% buffer is visible in the interface.
Stockouts, lead times and seasonality are not accounted for. Advanced forecast
retains the existing experimental model service and requires its full inputs.

Try 3 sample products adds clearly tagged, fictional A/B/C products in a Sample
branch. It never replaces real products or the business name. Remove deletes
only tagged sample products. Repeat loading does not duplicate existing samples.
Sample totals are included while samples are present; a banner makes this visible.
Saved products and forecasts remain device-local. This update is not a claim of
production readiness or validated purchasing recommendations.

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

## This laptop: PR 1 checkout

The complete pre-PR project source, local data and deliverables were preserved at
`C:\Users\gowth\OneDrive\Desktop\ML PROJECT-backup-20261006-before-PR1`.
`original-active-files` contains the original replaced folders, including the old
backend database and model. Generated caches were not copied. Existing legacy
`ml`, `docs`, `outputs` and `backups` folders are retained but do not describe this
branch's current model or UI. The old SQLite shop data is not automatically
converted into the new device-local inventory schema.

Use two terminals from this project root:

```powershell
.\.venv-review\Scripts\python.exe backend\app.py
```

```powershell
flutter pub get
flutter run -d emulator-5554 --dart-define=GOODIE_API_URL=http://10.0.2.2:5000
```

The emulator ID may differ; use `flutter devices` to check. Debug builds allow
HTTP only for emulator-host/loopback addresses; release configuration remains
unchanged. If a workspace already has an endpoint saved, update it in Settings.
The local model was rebuilt using this branch's 100,000-row dataset and training
script. Its random-split evaluation is not a temporal/generalization guarantee.
