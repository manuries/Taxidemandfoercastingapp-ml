import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from prophet import Prophet
from sklearn.linear_model import LinearRegression
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import TimeSeriesSplit, GridSearchCV
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
import joblib

def exploratory_data_analysis(filepath):
    df = pd.read_csv(filepath)
    print("Dataset shape:", df.shape)
    print(df.info())
    print(df.describe())
    print("Missing values:\n", df.isnull().sum())

    plt.figure(figsize=(10,5))
    sns.histplot(df['tpep_pickup_datetime'], bins=30, kde=False)
    plt.title("Pickup datetime distribution")
    plt.savefig("pickup_datetime_distribution.png")
    plt.close()
    return df

def preprocess_data(df):
    df['tpep_pickup_datetime'] = pd.to_datetime(df['tpep_pickup_datetime'])
    df['pickup_hour'] = df['tpep_pickup_datetime'].dt.hour
    df['pickup_day'] = df['tpep_pickup_datetime'].dt.day_name()
    df['is_weekend'] = df['pickup_day'].isin(['Saturday','Sunday']).astype(int)
    demand = df.groupby(['pickup_hour','is_weekend']).size().reset_index(name='trip_count')
    return df, demand

def train_models(demand):
    X = demand[['pickup_hour','is_weekend']]
    y = demand['trip_count']

    lr_model = LinearRegression().fit(X, y)
    joblib.dump(lr_model, "linear_model.pkl")

    rf_model = RandomForestRegressor(random_state=42).fit(X, y)
    joblib.dump(rf_model, "rf_model.pkl")

    ts = demand.groupby('pickup_hour').sum().reset_index()
    ts['ds'] = pd.date_range(start='2020-01-01', periods=len(ts), freq='h')
    ts.rename(columns={'trip_count':'y'}, inplace=True)
    prophet_model = Prophet()
    prophet_model.fit(ts[['ds','y']])
    joblib.dump(prophet_model, "prophet_model.pkl")

    for name, model in {'Linear Regression': lr_model, 'Random Forest': rf_model}.items():
        y_pred = model.predict(X)
        mse = mean_squared_error(y, y_pred)
        rmse = np.sqrt(mse)
        mae = mean_absolute_error(y, y_pred)
        r2 = r2_score(y, y_pred)
        print(f"{name} RMSE:", rmse)
        print(f"{name} MAE:", mae)
        print(f"{name} R2:", r2)

    return lr_model, rf_model, prophet_model

def tune_random_forest(X, y):
    tscv = TimeSeriesSplit(n_splits=3)
    param_grid = {'n_estimators': [50, 100], 'max_depth': [5, 10, None], 'min_samples_split': [2, 5]}
    grid = GridSearchCV(RandomForestRegressor(random_state=42), param_grid, cv=tscv, scoring='neg_mean_squared_error')
    grid.fit(X, y)
    print("Best RF Params:", grid.best_params_)
    print("Best RF Score:", -grid.best_score_)
    joblib.dump(grid.best_estimator_, "rf_tuned.pkl")
    return grid.best_estimator_

def run_pipeline():
    df = exploratory_data_analysis("yellow_tripdata_small.csv")
    df, demand = preprocess_data(df)
    lr, rf, prophet = train_models(demand)
    tuned_rf = tune_random_forest(demand[['pickup_hour','is_weekend']], demand['trip_count'])
    print("✅ Models trained and saved: linear_model.pkl, rf_model.pkl, prophet_model.pkl, rf_tuned.pkl")

if __name__ == "__main__":
    run_pipeline()
