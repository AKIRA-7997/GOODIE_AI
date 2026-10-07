"""Evaluate every model on one shared holdout and build an offline dashboard."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json
import time
import platform
import numpy as np
import pandas as pd
import sklearn
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.pipeline import Pipeline
from sklearn.model_selection import train_test_split
from sklearn.dummy import DummyRegressor
from sklearn.linear_model import LinearRegression
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor
from threadpoolctl import threadpool_limits
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

ROOT = Path(__file__).resolve().parent

def main():
    path = ROOT.parent / 'backend' / 'goodie_dataset.csv'
    cfg = json.loads((ROOT / 'features.json').read_text())
    features, cats = cfg['features'], cfg['categorical_features']
    nums = [c for c in features if c not in cats]
    df = pd.read_csv(path)
    raw_rows = len(df)
    missing_promotion = int(df.Promotion.isna().sum())
    df['Promotion'] = df.Promotion.fillna('None')
    df['Date'] = pd.to_datetime(df.Date, errors='coerce')
    df['Year'], df['Day'] = df.Date.dt.year, df.Date.dt.day
    df = df.dropna(subset=['Date', 'Demand'])
    Xtr, Xte, ytr, yte = train_test_split(df[features], df.Demand, test_size=.2, random_state=42)
    models = [
        ('Mean baseline', DummyRegressor(strategy='mean')),
        ('Linear Regression', LinearRegression()),
        ('Decision Tree', DecisionTreeRegressor(max_depth=18, min_samples_split=4, random_state=42)),
        ('Random Forest', RandomForestRegressor(n_estimators=120, max_depth=18, min_samples_split=4, random_state=42, n_jobs=2)),
    ]
    sample = np.sort(np.random.default_rng(42).choice(len(yte), 500, replace=False))
    out = dict(created=datetime.now(timezone.utc).isoformat(), rows=len(df), raw_rows=raw_rows,
        train_rows=len(ytr), test_rows=len(yte), feature_count=len(features), stores=int(df.Store.nunique()),
        products=int(df.Product.nunique()), categories=int(df.Category.nunique()),
        start=str(df.Date.min().date()), end=str(df.Date.max().date()), missing_promotion=missing_promotion,
        sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
        versions=dict(python=platform.python_version(), sklearn=sklearn.__version__, pandas=pd.__version__, numpy=np.__version__),
        split='Random holdout · 80/20 · seed 42', models=[])
    for name, model in models:
        print('Training:', name, flush=True)
        pre = ColumnTransformer([('categorical', OneHotEncoder(handle_unknown='ignore', sparse_output=True), cats),
                                 ('numerical', StandardScaler() if name == 'Linear Regression' else 'passthrough', nums)])
        pipe = Pipeline([('preprocessor', pre), ('model', model)])
        t = time.perf_counter(); pipe.fit(Xtr,ytr); train_seconds = time.perf_counter()-t
        t = time.perf_counter(); pred = pipe.predict(Xte); predict_seconds=time.perf_counter()-t
        residual = yte.to_numpy()-pred
        hist, edges = np.histogram(residual, bins=30)
        importance=[]
        if hasattr(model,'feature_importances_'):
            vals=model.feature_importances_; enc=pre.named_transformers_['categorical']; i=0
            for col, labels in zip(cats,enc.categories_):
                importance.append(dict(feature=col,value=float(vals[i:i+len(labels)].sum()))); i+=len(labels)
            importance += [dict(feature=c,value=float(v)) for c,v in zip(nums,vals[i:])]
            importance.sort(key=lambda x:x['value'],reverse=True)
        result=dict(name=name,mae=float(mean_absolute_error(yte,pred)),rmse=float(mean_squared_error(yte,pred)**.5),
            r2=float(r2_score(yte,pred)),train_seconds=train_seconds,predict_seconds=predict_seconds,
            train_mae=float(mean_absolute_error(ytr,pipe.predict(Xtr))),
            points=[[float(yte.iloc[i]),float(pred[i])] for i in sample],
            histogram=dict(counts=hist.tolist(),edges=edges.tolist()), importance=importance,
            parameters={k:v for k,v in model.get_params().items() if isinstance(v,(str,int,float,bool,type(None)))})
        out['models'].append(result)
        (ROOT/'results.json').write_text(json.dumps(out,indent=2,allow_nan=False))
        print(name, 'MAE', round(result['mae'],4), 'RMSE', round(result['rmse'],4), 'R2',round(result['r2'],6), flush=True)
    template=(ROOT/'template.html').read_text()
    (ROOT/'GOODIE_AI_Dashboard.html').write_text(template.replace('__RESULTS_JSON__',json.dumps(out,allow_nan=False).replace('<','\\u003c')))
    print('Dashboard ready', flush=True)

if __name__ == '__main__':
    with threadpool_limits(limits=1):
        main()
