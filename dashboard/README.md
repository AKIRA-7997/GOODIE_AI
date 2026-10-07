# GOODIE AI model performance dashboard

A self-contained browser dashboard with genuine holdout measurements for Mean baseline, Linear Regression, Decision Tree and Random Forest. Includes metric export, print support, model selection, actual/predicted and residual plots, grouped tree feature importance, and a manual inventory-policy calculator.

## Rebuild

From the repository root, using Python with numpy, pandas, scipy and scikit-learn installed:

```bash
python dashboard/evaluate.py
```

Open `dashboard/GOODIE_AI_Dashboard.html` in a browser. No server, API key, internet connection or Flutter build is required. Results are embedded in the file. The evaluation also writes `dashboard/results.json`. Re-run the script after changing data or models; the dashboard is an evaluation snapshot, not a live inference service.

## Protocol

- Uses `backend/goodie_dataset.csv`, all valid rows, and the same 21 inputs as the original training script.
- Shared 80/20 random holdout, seed 42. Fit preprocessing on training rows only.
- One-hot categorical inputs; numeric inputs pass through, except Linear Regression scales them using training statistics.
- Tree: maximum depth 18, minimum split 4, seed 42.
- Forest: 120 trees, maximum depth 18, minimum split 4, seed 42; two worker threads for this evaluation.
- All test rows determine metrics. Plots share a deterministic 500-row sample. Training times include preprocessing and depend on hardware.
- Feature importance sums impurity importance over each original categorical feature's one-hot columns. It is not causal evidence.
- R² is not classification accuracy or prediction confidence. Random holdout does not establish future performance; chronological evaluation is still needed.
- Dataset publisher and collection method are not verified. Dataset hash, runtime versions and evaluation timestamp are included.
- The stock calculator accepts demand manually and uses the application's fixed safety-stock policy. It does not invoke the trained model.

The script does not overwrite the application's saved prediction model.
