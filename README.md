full dataset:
https://www.kaggle.com/datasets/elemento/nyc-yellow-taxi-trip-data


# NYC Taxi Demand Forecasting App 🚖📊

## Overview
This project is an end‑to‑end machine learning application designed to forecast taxi demand in New York City using the **Yellow Taxi Trip dataset**.  
It integrates a **FastAPI backend** with a **Flutter mobile app frontend**, delivering real‑time demand predictions and visualizations for both drivers and fleet managers.

---

## ✨ Key Highlights
- **Machine Learning Pipeline**: Python‑based preprocessing, feature engineering, and demand forecasting models.
- **Backend Integration**: RESTful API built with **FastAPI**, serving predictions to the mobile app.
- **Frontend Dashboard**: Developed in **Flutter (Dart)**, featuring interactive charts and demand trend visualizations.
- **Role‑based Access**: Separate dashboards for **Drivers** and **Fleet Managers**.
- **Visualization**: Demand trend line charts and zone forecasts using **Matplotlib**, integrated into the app.
- **Version Control**: Git + GitHub for collaboration and reproducibility.
- **Dataset Handling**: Large datasets excluded from repo; linked externally for easy access.

---

## 🛠️ Tech Stack
| Layer        | Tools & Languages |
|--------------|-------------------|
| **Frontend (Mobile App)** | Flutter, Dart |
| **Backend (API)**  | FastAPI, Python |
| **ML/AI**    | scikit‑learn, pandas, NumPy, Matplotlib |
| **Collaboration** | Git, GitHub |
| **Data Source** | NYC Yellow Taxi Trip Dataset (Kaggle) |

---

## 📂 Dataset
The dataset is too large for GitHub storage.  
Download it directly from Kaggle:  
[NYC Taxi Demand Prediction Dataset] https://www.kaggle.com/datasets/elemento/nyc-yellow-taxi-trip-data

---

## 🚀 Getting Started

### Clone the repo
```bash
git clone https://github.com/<your-username>/<your-repo>.git
cd <your-repo>

backend setup-(in vscode)
pip install -r requirements.txt
uvicorn main:app --reload

        or

uvicorn main:app --host 0.0.0.0 --port 8000 --reload

frontend setup(android studio)
flutter clean
flutter pub get
flutter run -d chrome


or

flutter run

Dashboard Features
Driver Dashboard
Demand Level: Shows current demand in the driver’s zone.

Hotspot Zones: Highlights areas with high predicted demand.

Trips Today: Displays number of trips completed.

Earnings: Tracks daily earnings.

Alerts: Provides notifications about demand surges.

Fleet Manager Dashboard
Demand Trends: Line chart showing demand fluctuations over time.

Zone Forecasts: Predictive analytics for different NYC zones.

Fleet Overview: Summary of active drivers and trips.

Performance Metrics: Earnings and demand statistics across the fleet.

Alerts: Notifications for unusual demand patterns.
