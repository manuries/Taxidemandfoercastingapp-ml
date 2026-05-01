from fastapi import FastAPI
from pydantic import BaseModel
import joblib
import pandas as pd
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Taxi Demand Forecast API")

# ✅ Enable CORS for Flutter frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ Load models safely
try:
    rf_model = joblib.load("rf_model.pkl")
except:
    rf_model = None

try:
    prophet_model = joblib.load("prophet_model.pkl")
except:
    prophet_model = None

# ✅ Load dataset globally (trip data, not used for zones)
try:
    zone_forecast_df = pd.read_csv("yellow_tripdata_small.csv")
    zone_forecast_df['tpep_pickup_datetime'] = pd.to_datetime(zone_forecast_df['tpep_pickup_datetime'])
    zone_forecast_df['pickup_hour'] = zone_forecast_df['tpep_pickup_datetime'].dt.hour
    zone_forecast_df['pickup_day'] = zone_forecast_df['tpep_pickup_datetime'].dt.day_name()
    zone_forecast_df['is_weekend'] = zone_forecast_df['pickup_day'].isin(['Saturday','Sunday']).astype(int)
except Exception as e:
    print("Error loading dataset:", e)
    zone_forecast_df = None


# ✅ Request model for /predict
class PredictRequest(BaseModel):
    pickup_hour: int
    is_weekend: int
    role: str  # "driver" or "manager"


# ✅ Predict endpoint
@app.post("/predict")
def predict(request: PredictRequest):
    X = pd.DataFrame([[request.pickup_hour, request.is_weekend]], columns=["pickup_hour", "is_weekend"])
    demand_value = float(rf_model.predict(X)[0]) if rf_model else 0.0
    demand_level = "HIGH" if demand_value > 120 else "MEDIUM" if demand_value > 60 else "LOW"
    trips = int(demand_value)
    earnings = round(trips * 10, 2)
    alerts = "Peak demand expected" if trips > 150 else "Normal demand"

    if request.role == "driver":
        return {
            "role": "driver",
            "pickup_hour": request.pickup_hour,
            "demand": demand_level,
            "trips": trips,
            "earnings": earnings,
            "alerts": alerts
        }

    elif request.role == "manager":
        if prophet_model is not None:
            future = pd.DataFrame({"ds": pd.date_range(start="2020-01-01", periods=24, freq="h")})
            forecast = prophet_model.predict(future)
            return {
                "role": "manager",
                "forecast": forecast[["ds","yhat"]].to_dict(orient="records")
            }
        return {"error": "Prophet model not available"}


# ✅ Forecast endpoint (Prophet)
@app.get("/forecast")
def forecast(hours: int = 24):
    if prophet_model is not None:
        future = pd.DataFrame({"ds": pd.date_range(start="2020-01-01", periods=hours, freq="h")})
        forecast = prophet_model.predict(future)
        return forecast[["ds","yhat"]].to_dict(orient="records")
    return {"error": "Prophet model not available"}


# ✅ Zone forecast endpoint
@app.get("/zone_forecast")
def zone_forecast(hours: int = 24, pickup_hour: int = None, is_weekend: int = None, date: str = None):
    df = pd.read_csv("zone_forecast.csv")
    df["date"] = pd.to_datetime(df["date"])
    df["pickup_day"] = df["date"].dt.day_name()
    df["is_weekend"] = df["pickup_day"].isin(["Saturday","Sunday"]).astype(int)

    # Apply filters
    if pickup_hour is not None:
        df = df[df["pickup_hour"] == pickup_hour]
    if is_weekend is not None:
        df = df[df["is_weekend"] == is_weekend]
    if date is not None:
        df = df[df["date"] == pd.to_datetime(date)]

    # ✅ Fixed zone list
    all_zones = ["Midtown","Downtown","Uptown","Queens","Brooklyn"]

    # Group and reindex
    grouped = df.groupby("zone_name")["demand"].sum()
    grouped = grouped.reindex(all_zones, fill_value=0).reset_index()
    grouped.rename(columns={"demand":"trips"}, inplace=True)
    grouped["earnings"] = grouped["trips"] * 10

    enriched = []
    for _, rec in grouped.iterrows():
        demand_value = rec["trips"]
        demand_level = "HIGH" if demand_value > 120 else "MEDIUM" if demand_value > 60 else "LOW"
        enriched.append({
            "zone": rec["zone_name"],
            "pickup_hour": pickup_hour,
            "is_weekend": is_weekend,
            "demand": demand_level,
            "trips": int(demand_value),
            "earnings": float(rec["earnings"]),
        })
    return enriched
