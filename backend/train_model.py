from pathlib import Path

import joblib
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder


BASE_DIR = Path(__file__).resolve().parent
DATASET_PATH = BASE_DIR / "goodie_dataset.csv"
MODEL_PATH = BASE_DIR / "goodie_model.pkl"


def main() -> None:
    print("Loading dataset...")

    if not DATASET_PATH.exists():
        raise FileNotFoundError(
            f"Dataset not found: {DATASET_PATH}\n"
            "Place goodie_dataset.csv inside the backend folder."
        )

    df = pd.read_csv(DATASET_PATH)

    print(f"Rows: {len(df)}")
    print(f"Columns: {len(df.columns)}")

    # Missing promotion means no active promotion.
    df["Promotion"] = df["Promotion"].fillna("None")

    # Convert date into useful numerical features.
    df["Date"] = pd.to_datetime(df["Date"], errors="coerce")
    df["Year"] = df["Date"].dt.year
    df["Day"] = df["Date"].dt.day

    # Remove rows with invalid dates or missing target values.
    df = df.dropna(subset=["Date", "Demand"])

    features = [
        "Store",
        "Store_Type",
        "Product",
        "Category",
        "Price",
        "Cost_Price",
        "Discount",
        "Holiday",
        "Weekend",
        "Day_of_Week",
        "Month",
        "Season",
        "Temperature",
        "Rainfall_mm",
        "Promotion",
        "Competitor_Price",
        "Inventory",
        "Previous_Week_Sales",
        "Previous_Month_Sales",
        "Year",
        "Day",
    ]

    target = "Demand"

    X = df[features]
    y = df[target]

    categorical_features = [
        "Store",
        "Store_Type",
        "Product",
        "Category",
        "Holiday",
        "Weekend",
        "Day_of_Week",
        "Season",
        "Promotion",
    ]

    numerical_features = [
        column for column in features
        if column not in categorical_features
    ]

    preprocessor = ColumnTransformer(
        transformers=[
            (
                "categorical",
                OneHotEncoder(
                    handle_unknown="ignore",
                    sparse_output=True,
                ),
                categorical_features,
            ),
            (
                "numerical",
                "passthrough",
                numerical_features,
            ),
        ]
    )

    model = RandomForestRegressor(
        n_estimators=120,
        max_depth=18,
        min_samples_split=4,
        random_state=42,
        n_jobs=-1,
    )

    pipeline = Pipeline(
        steps=[
            ("preprocessor", preprocessor),
            ("model", model),
        ]
    )

    X_train, X_test, y_train, y_test = train_test_split(
        X,
        y,
        test_size=0.20,
        random_state=42,
    )

    print("Training model...")
    pipeline.fit(X_train, y_train)

    print("Evaluating model...")
    predictions = pipeline.predict(X_test)

    mae = mean_absolute_error(y_test, predictions)
    rmse = mean_squared_error(y_test, predictions) ** 0.5
    r2 = r2_score(y_test, predictions)

    print("\nMODEL RESULTS")
    print(f"MAE  : {mae:.2f}")
    print(f"RMSE : {rmse:.2f}")
    print(f"R²   : {r2:.4f}")

    artifact = {
        "pipeline": pipeline,
        "features": features,
        "metrics": {
            "mae": mae,
            "rmse": rmse,
            "r2": r2,
        },
    }

    joblib.dump(artifact, MODEL_PATH)

    print(f"\nModel saved successfully:")
    print(MODEL_PATH)


if __name__ == "__main__":
    main()