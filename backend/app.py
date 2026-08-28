from pathlib import Path

import joblib
import pandas as pd
from flask import Flask, jsonify, request
from flask_cors import CORS

BASE_DIR = Path(__file__).resolve().parent
MODEL_PATH = BASE_DIR / "goodie_model.pkl"

app = Flask(__name__)
CORS(app)

if not MODEL_PATH.exists():
    raise FileNotFoundError(
        f"Model not found: {MODEL_PATH}\n"
        "Run train_model.py first."
    )

artifact = joblib.load(MODEL_PATH)

pipeline = artifact["pipeline"]
features = artifact["features"]
metrics = artifact["metrics"]


@app.get("/")
def home():
    return jsonify(
        {
            "status": "running",
            "service": "GOODIE AI Demand Forecasting API",
            "model_metrics": metrics,
        }
    )


@app.post("/predict")
def predict():
    try:
        data = request.get_json(silent=True)

        if not data:
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

        expected_demand = max(
            0,
            round(raw_prediction),
        )

        current_inventory = int(data["inventory"])
        previous_week_sales = int(
            data["previous_week_sales"]
        )
        discount = float(data["discount"])
        promotion = str(data["promotion"])
        competitor_price = float(
            data["competitor_price"]
        )
        price = float(data["price"])

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

        demand_factors = []

        if promotion == "Active":
            demand_factors.append(
                "An active promotion may increase customer demand."
            )

        if discount >= 20:
            demand_factors.append(
                "The large discount may produce a strong demand increase."
            )
        elif discount > 0:
            demand_factors.append(
                "The current discount may provide a moderate demand boost."
            )

        if price > competitor_price:
            demand_factors.append(
                "The product costs more than the competitor price, which may reduce demand."
            )
        elif price < competitor_price:
            demand_factors.append(
                "The product is cheaper than the competitor price, which may improve demand."
            )

        if str(data["holiday"]) == "Yes":
            demand_factors.append(
                "Holiday shopping behaviour may affect demand."
            )

        if str(data["weekend"]) == "Yes":
            demand_factors.append(
                "Weekend customer traffic may increase sales."
            )

        if not demand_factors:
            demand_factors.append(
                "Demand is mainly influenced by historical sales and normal market conditions."
            )

        if stock_status == "Critical":
            business_advice = (
                f"Restock at least {restock_quantity} units immediately. "
                "Current inventory is far below the recommended level."
            )
        elif stock_status == "Low":
            business_advice = (
                f"Order approximately {restock_quantity} additional units "
                "to reduce the risk of a stock-out."
            )
        elif surplus_quantity > expected_demand:
            business_advice = (
                "Inventory is considerably above predicted demand. "
                "Avoid ordering more stock and consider promoting "
                f"the surplus {surplus_quantity} units."
            )
        else:
            business_advice = (
                "Current inventory is sufficient for the predicted demand. "
                "Continue monitoring sales before placing another order."
            )

        confidence = max(
            0.0,
            min(
                0.99,
                float(metrics.get("r2", 0.0)),
            ),
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
                "demand_factors": demand_factors,
                "confidence": confidence,
            }
        ), 200

    except (TypeError, ValueError, KeyError) as error:
        return jsonify(
            {
                "error": f"Invalid input: {error}",
            }
        ), 400

    except Exception as error:
        app.logger.exception("Prediction failed")

        return jsonify(
            {
                "error": str(error),
            }
        ), 500


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=5000,
        debug=False,
        use_reloader=False,
    )