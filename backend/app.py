from pathlib import Path
from datetime import date
import math
import os

import joblib
import pandas as pd
from flask import Flask, jsonify, request
from flask_cors import CORS

BASE_DIR = Path(__file__).resolve().parent
MODEL_PATH = BASE_DIR / "goodie_model.pkl"

app = Flask(__name__)
CORS(app, origins=os.environ.get('GOODIE_ALLOWED_ORIGINS', 'http://localhost:8080').split(','))

artifact = joblib.load(MODEL_PATH) if MODEL_PATH.exists() else None
pipeline = artifact["pipeline"] if artifact else None
features = artifact["features"] if artifact else []
metrics = artifact["metrics"] if artifact else {}


@app.get("/")
def home():
    return jsonify(
        {
            "status": "ready" if pipeline is not None else "model_unavailable",
            "service": "GOODIE AI Demand Forecasting API",
            "model_metrics": metrics,
        }
    )


@app.post("/predict")
def predict():
    try:
        data = request.get_json(silent=True)

        if not isinstance(data, dict) or not data:
            return jsonify(
                {
                    "error": "JSON body is required",
                }
            ), 400

        required_fields = [
            "store",
            "store_type",
            "product",
            "category",
            "price",
            "cost_price",
            "discount",
            "holiday",
            "weekend",
            "day_of_week",
            "month",
            "season",
            "temperature",
            "rainfall_mm",
            "promotion",
            "competitor_price",
            "inventory",
            "previous_week_sales",
            "previous_month_sales",
            "year",
            "day",
        ]

        missing_fields = [
            field
            for field in required_fields
            if field not in data
        ]

        if missing_fields:
            return jsonify(
                {
                    "error": "Missing required fields",
                    "missing_fields": missing_fields,
                }
            ), 400

        numeric_fields = ["price", "cost_price", "discount", "temperature", "rainfall_mm",
                          "competitor_price", "inventory", "previous_week_sales",
                          "previous_month_sales", "year", "month", "day"]
        whole_fields = {"inventory", "previous_week_sales", "previous_month_sales", "year", "month", "day"}
        for field in numeric_fields:
            value = data[field]
            if isinstance(value, bool):
                raise ValueError(f"{field} must be numeric")
            number = float(value)
            if not math.isfinite(number) or (field != "temperature" and number < 0):
                raise ValueError(f"{field} is out of range")
            if field in whole_fields and not number.is_integer():
                raise ValueError(f"{field} must be a whole number")
        if not 0 <= float(data["discount"]) <= 100:
            raise ValueError("discount must be between 0 and 100")
        if not -60 <= float(data["temperature"]) <= 60:
            raise ValueError("temperature must be between -60 and 60")
        forecast_date = date(int(data["year"]), int(data["month"]), int(data["day"]))
        if data["day_of_week"] != forecast_date.strftime("%A"):
            raise ValueError("day_of_week does not match the date")
        if data["weekend"] != ("Yes" if forecast_date.weekday() >= 5 else "No"):
            raise ValueError("weekend does not match the date")
        for field in set(required_fields) - set(numeric_fields):
            if not isinstance(data[field], str) or not data[field].strip() or len(data[field]) > 200:
                raise ValueError(f"{field} is required")
        if data["holiday"] not in ("Yes", "No") or data["promotion"] not in ("None", "Low", "Medium", "High"):
            raise ValueError("Invalid holiday or promotion")
        if pipeline is None:
            return jsonify({"error": "Forecast service is unavailable"}), 503

        input_values = {
            "Store": str(data["store"]),
            "Store_Type": str(data["store_type"]),
            "Product": str(data["product"]),
            "Category": str(data["category"]),
            "Price": float(data["price"]),
            "Cost_Price": float(data["cost_price"]),
            "Discount": float(data["discount"]),
            "Holiday": str(data["holiday"]),
            "Weekend": str(data["weekend"]),
            "Day_of_Week": str(data["day_of_week"]),
            "Month": int(data["month"]),
            "Season": str(data["season"]),
            "Temperature": float(data["temperature"]),
            "Rainfall_mm": float(data["rainfall_mm"]),
            "Promotion": str(data["promotion"] or "None"),
            "Competitor_Price": float(data["competitor_price"]),
            "Inventory": int(data["inventory"]),
            "Previous_Week_Sales": int(
                data["previous_week_sales"]
            ),
            "Previous_Month_Sales": int(
                data["previous_month_sales"]
            ),
            "Year": int(data["year"]),
            "Day": int(data["day"]),
        }

        input_row = pd.DataFrame(
            [input_values],
            columns=features,
        )

        raw_prediction = float(
            pipeline.predict(input_row)[0]
        )

        if not math.isfinite(raw_prediction):
            raise RuntimeError("Non-finite model output")

        expected_demand = max(
            0,
            round(raw_prediction),
        )

        current_inventory = int(data["inventory"])
        previous_week_sales = int(
            data["previous_week_sales"]
        )
        safety_stock = max(
            5,
            round(expected_demand * 0.12),
        )

        recommended_inventory = (
            expected_demand + safety_stock
        )

        restock_quantity = max(
            0,
            recommended_inventory - current_inventory,
        )

        surplus_quantity = max(
            0,
            current_inventory - recommended_inventory,
        )

        if expected_demand > 0:
            inventory_coverage = (
                current_inventory / expected_demand
            )
        else:
            inventory_coverage = float("inf")

        if inventory_coverage < 0.75:
            stock_status = "Critical"
            risk_level = "High"
        elif inventory_coverage < 1.0:
            stock_status = "Low"
            risk_level = "High"
        elif inventory_coverage < 1.25:
            stock_status = "Adequate"
            risk_level = "Medium"
        else:
            stock_status = "Healthy"
            risk_level = "Low"

        demand_change = (
            expected_demand - previous_week_sales
        )

        if previous_week_sales > 0:
            demand_change_percentage = round(
                (
                    demand_change
                    / previous_week_sales
                )
                * 100,
                2,
            )
        else:
            demand_change_percentage = 0.0

        business_advice = (
            f"Order {restock_quantity} units." if restock_quantity > 0
            else "No additional stock required."
        )

        return jsonify(
            {
                "expected_demand": expected_demand,
                "current_inventory": current_inventory,
                "safety_stock": safety_stock,
                "recommended_inventory": recommended_inventory,
                "restock_quantity": restock_quantity,
                "surplus_quantity": surplus_quantity,
                "stock_status": stock_status,
                "risk_level": risk_level,
                "demand_change": demand_change,
                "demand_change_percentage": demand_change_percentage,
                "business_advice": business_advice,
                "forecast_date": forecast_date.isoformat(),
            }
        ), 200

    except (TypeError, ValueError, KeyError, OverflowError) as error:
        return jsonify(
            {
                "error": f"Invalid input: {error}",
            }
        ), 400

    except Exception as error:
        app.logger.exception("Prediction failed")

        return jsonify(
            {
                "error": "Forecast service is unavailable",
            }
        ), 500


if __name__ == "__main__":
    app.run(
        host=os.environ.get("GOODIE_HOST", "127.0.0.1"),
        port=int(os.environ.get("PORT", "5000")),
        debug=False,
        use_reloader=False,
    )