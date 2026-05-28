# Retail Demand Forecasting & Inventory Optimization Engine

## Project Overview
This project contains a data warehouse and analytics engine designed to model retail inventory, predict consumer demand, and optimize safety stock thresholds. It implements a Star Schema data warehouse, dynamic pricing scenarios using price elasticity coefficients in DAX, and 12-month demand projections using triple exponential smoothing (Holt-Winters).

## Core Features
1. **Star-Schema Warehouse:** Features structured dimension tables (`dim_sku`, `dim_store`, `dim_supplier`, `dim_date`, `dim_weather`) feeding sales (`fact_sales`) and inventory daily snapshot (`fact_inventory`) fact tables.
2. **Double/Triple Exponential Smoothing (Holt-Winters):** Python forecasting engine simulating Excel's `FORECAST.ETS` method to predict SKU demand while accounting for seasonal fluctuations.
3. **Linear Regression (LINEST/TREND):** Fits least-squares trends to historical SKU volumes to capture macro growth gradients.
4. **What-If Pricing Simulations:** Power BI DAX expressions evaluating dynamic price adjustments against an elasticity coefficient parameter to optimize profit margins.
5. **Tableau LOD Calculations:** Level of Detail specifications mapping regional category contributions and store safety stock deviations.

---

## Directory Architecture
```text
02_retail_demand_forecasting/
├── database/
│   └── star_schema_dw.sql (DDL defining facts and dimensions for warehousing)
├── analytics/
│   ├── forecasting_queries.sql (SQL window functions for SMA and growth analysis)
│   └── demand_forecast_engine.py (Python regression and Holt-Winters forecasting tool)
├── dashboards/
│   ├── dax_pricing_simulation.dax (DAX elasticity calculations & what-if structures)
│   └── tableau_companion.md (Tableau LOD specs and category-manager prompts)
└── data_simulation/
    └── retail_data_generator.py (Generates synthetic star schema records as CSVs)
```

---

## Technical Details

### Demand Projections Model
The Python forecast engine calculates SKU demand by:
* Fitting a Linear Regression (`np.polyfit` slope and intercept) to evaluate long-term trends.
* Running a local implementation of Holt-Winters Triple Exponential Smoothing to capture seasonal factors.
* Blending predictions into an ensemble (70% ETS / 30% Trend) to generate final demand curves.

### Price Elasticity Simulation
The DAX dashboard measures simulate sales volume reductions/increases per adjustments to unit retail prices:
$$\text{Simulated Quantity} = \text{Base Quantity} \times (1 + (\text{Elasticity Coefficient} \times \text{Price Adjustment \%}))$$

---

## Run Data Simulation & Forecast Engine
To generate datasets and execute forecasting predictions:
1. Run data warehouse simulation:
   ```bash
   python data_simulation/retail_data_generator.py
   ```
2. Execute demand forecasting models:
   ```bash
   python analytics/demand_forecast_engine.py
   ```
This updates files inside `data_simulation/output/` and exports final forecasts as `dashboards/demand_forecast_outputs.csv`.
