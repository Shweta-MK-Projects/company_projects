#!/usr/bin/env python3
"""
Retail Demand Forecasting & Inventory Optimization Engine.
Performs linear regression (LINEST/TREND equivalent) and triple exponential smoothing
(FORECAST.ETS equivalent) to project 12-month SKU demand at the store level.
"""

import os
import pandas as pd
import numpy as np
from datetime import datetime

# Triple Exponential Smoothing (Holt-Winters) implementation
# Built natively using NumPy to keep it lightweight and self-contained
def triple_exponential_smoothing(series, seasonal_periods, alpha, beta, gamma, n_preds):
    """
    Simulates Excel's FORECAST.ETS algorithm.
    """
    result = []
    
    # 1. Initialize levels, trends, and seasonal components
    def initial_trend(series, slen):
        sum_val = 0.0
        for i in range(slen):
            sum_val += float(series[i+slen] - series[i]) / slen
        return sum_val / slen

    def initial_seasonal_factors(series, slen):
        seasonals = {}
        n_seasons = int(len(series)/slen)
        # compute season averages
        season_averages = []
        for j in range(n_seasons):
            season_averages.append(sum(series[slen*j:slen*j+slen])/float(slen))
        # compute initial factors
        for i in range(slen):
            sum_of_vals_over_avg = 0.0
            for j in range(n_seasons):
                sum_of_vals_over_avg += series[slen*j+i]-season_averages[j]
            seasonals[i] = sum_of_vals_over_avg/n_seasons
        return seasonals

    slen = seasonal_periods
    if len(series) < 2 * slen:
        # Fallback to linear projection if there isn't enough seasonal history
        return list(np.interp(np.arange(len(series), len(series) + n_preds), np.arange(len(series)), series))

    seasonals = initial_seasonal_factors(series, slen)
    
    # Holt-Winters iterations
    levels = []
    trends = []
    
    level = series[0]
    trend = initial_trend(series, slen)
    levels.append(level)
    trends.append(trend)
    
    for i in range(len(series)):
        val = series[i]
        last_level = level
        last_trend = trend
        
        # Level update
        level = alpha * (val - seasonals[i % slen]) + (1 - alpha) * (last_level + last_trend)
        # Trend update
        trend = beta * (level - last_level) + (1 - beta) * last_trend
        # Seasonal update
        seasonals[i % slen] = gamma * (val - level) + (1 - gamma) * seasonals[i % slen]
        
        levels.append(level)
        trends.append(trend)
        result.append(level + trend + seasonals[i % slen])
        
    # Forecasting step
    for i in range(n_preds):
        m = i + 1
        val_pred = (level + m * trend) + seasonals[(len(series) + i) % slen]
        result.append(val_pred)
        
    return result[-n_preds:]

# Linear Regression (LINEST/TREND equivalent)
def linear_trend(y_series, n_preds):
    """
    Fits a linear regression model and returns projections.
    """
    x = np.arange(len(y_series))
    y = np.array(y_series)
    
    # Least squares formula
    slope, intercept = np.polyfit(x, y, 1)
    
    # Forecast future values
    future_x = np.arange(len(y_series), len(y_series) + n_preds)
    forecast = slope * future_x + intercept
    return list(np.maximum(0, forecast)), slope, intercept

def forecast_demand_flow():
    print("Initializing demand forecasting engine...")
    data_dir = os.path.join(os.path.dirname(__file__), "..", "data_simulation", "output")
    sales_file = os.path.join(data_dir, "fact_sales.csv")
    sku_file = os.path.join(data_dir, "dim_sku.csv")
    
    if not (os.path.exists(sales_file) and os.path.exists(sku_file)):
        print("Error: Simulated sales or product datasets not found. Run generator script first.")
        return

    # Load simulated datasets
    df_sales = pd.read_csv(sales_file)
    df_sku = pd.read_csv(sku_file)
    
    # Parse date key to date strings
    df_sales["date_parsed"] = pd.to_datetime(df_sales["date_key"].astype(str), format="%Y%m%d")
    
    # Group sales to monthly level for reliable seasonal models
    df_sales["month_period"] = df_sales["date_parsed"].dt.to_period("M")
    monthly_sales = df_sales.groupby(["sku_key", "month_period"])["quantity_sold"].sum().reset_index()
    
    forecasts = []
    
    # Iterate through unique SKUs to project demand
    unique_skus = monthly_sales["sku_key"].unique()
    
    for sku in unique_skus:
        sku_data = monthly_sales[monthly_sales["sku_key"] == sku].sort_values("month_period")
        sales_history = sku_data["quantity_sold"].tolist()
        
        # We need a minimum amount of data to forecast
        if len(sales_history) < 3:
            continue
            
        # 1. Triple Exponential Smoothing (12 months forecast, 12 months seasonality)
        ets_forecast = triple_exponential_smoothing(
            series=sales_history,
            seasonal_periods=3,  # Scaled down to match shorter simulation history
            alpha=0.4,
            beta=0.2,
            gamma=0.3,
            n_preds=12
        )
        
        # 2. Linear Regression (LINEST/TREND)
        trend_forecast, slope, intercept = linear_trend(sales_history, 12)
        
        # Combine models using a simple ensemble weight (70% ETS, 30% Trend)
        ensemble_forecast = [round(0.7 * e + 0.3 * t, 1) for e, t in zip(ets_forecast, trend_forecast)]
        
        # Get SKU Details
        sku_info = df_sku[df_sku["sku_key"] == sku].iloc[0]
        
        forecasts.append({
            "sku_key": sku,
            "product_name": sku_info["product_name"],
            "category": sku_info["category"],
            "historical_mean": round(np.mean(sales_history), 1),
            "linest_slope": round(slope, 2),
            "forecast_12m_sum": round(sum(ensemble_forecast), 1),
            "monthly_forecast_distribution": ensemble_forecast
        })
        
    # Write forecasts to CSV
    output_df = pd.DataFrame(forecasts)
    output_path = os.path.join(os.path.dirname(__file__), "..", "dashboards", "demand_forecast_outputs.csv")
    output_df.to_csv(output_path, index=False)
    print(f"Demand Forecasting completed. Projections saved to: {os.path.abspath(output_path)}")

if __name__ == "__main__":
    forecast_demand_flow()
