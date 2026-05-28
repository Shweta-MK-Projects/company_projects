#!/usr/bin/env python3
"""
Synthetic Data Generator for Retail Demand Forecasting & Inventory Optimization.
Generates CSV files for SKU, Store, Supplier, Date, Weather dimensions and
Sales, Inventory facts matching the Star Schema architecture.
"""

import os
import csv
import random
from datetime import datetime, timedelta

# Constants
NUM_SKUS = 150
NUM_STORES = 15
NUM_SUPPLIERS = 10
DAYS_HISTORY = 90  # 3 months of historical records

START_DATE = datetime(2026, 2, 26)
END_DATE = datetime(2026, 5, 27)

def generate_retail_dw():
    print("Generating synthetic retail data warehouse...")
    output_dir = os.path.join(os.path.dirname(__file__), "output")
    os.makedirs(output_dir, exist_ok=True)

    # 1. Date Dimension (Pre-populated calendar index)
    dates = []
    current = START_DATE
    while current <= END_DATE:
        date_key = int(current.strftime("%Y%m%d"))
        dates.append({
            "date_key": date_key,
            "full_date": current.strftime("%Y-%m-%d"),
            "day_of_week": current.isoweekday(),
            "day_name": current.strftime("%A"),
            "day_of_month": current.day,
            "month_number": current.month,
            "month_name": current.strftime("%B"),
            "quarter": (current.month - 1) // 3 + 1,
            "year": current.year,
            "is_weekend": current.isoweekday() in [6, 7],
            "is_holiday": current.month == 5 and current.day == 1, # May Day placeholder
            "holiday_name": "May Day" if (current.month == 5 and current.day == 1) else "None"
        })
        current += timedelta(days=1)

    with open(os.path.join(output_dir, "dim_date.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=dates[0].keys())
        writer.writeheader()
        writer.writerows(dates)

    # 2. SKU Dimension (Products)
    skus = []
    categories = ["Grocery", "Beverages", "Electronics", "Apparel", "Home Decor"]
    sub_cats = {
        "Grocery": ["Organic Rice", "Wheat Flour", "Cooking Oil", "Spices"],
        "Beverages": ["Soft Drinks", "Fruit Juices", "Green Tea", "Mineral Water"],
        "Electronics": ["USB Cables", "Power Banks", "Earphones", "Smart plugs"],
        "Apparel": ["T-Shirts", "Socks", "Denims", "Caps"],
        "Home Decor": ["Cushions", "LED bulbs", "Wall Clocks", "Vases"]
    }
    brands = ["PureDrop", "ElectroMax", "FitWear", "HomeCraft", "SuperFoods"]

    for i in range(1, NUM_SKUS + 1):
        cat = random.choice(categories)
        sub = random.choice(sub_cats[cat])
        cost = round(random.uniform(20.0, 500.0), 2)
        price = round(cost * random.uniform(1.2, 1.8), 2)
        skus.append({
            "sku_key": i,
            "sku_id": f"SKU_{i:05d}",
            "product_name": f"{sub} {random.randint(100, 999)}",
            "category": cat,
            "sub_category": sub,
            "brand": random.choice(brands),
            "unit_cost": cost,
            "unit_price": price,
            "reorder_point": random.randint(30, 80),
            "safety_stock_level": random.randint(10, 25)
        })

    with open(os.path.join(output_dir, "dim_sku.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=skus[0].keys())
        writer.writeheader()
        writer.writerows(skus)

    # 3. Store Dimension (Locations)
    stores = []
    cities = ["Bengaluru", "Mangaluru", "Mysuru", "Hubballi", "Belagavi"]
    regions = ["South", "West", "East", "North"]

    for i in range(1, NUM_STORES + 1):
        stores.append({
            "store_key": i,
            "store_id": f"STORE_{i:03d}",
            "store_name": f"KSSC Store {cities[i % len(cities)]} #{i}",
            "city": cities[i % len(cities)],
            "state": "Karnataka",
            "region": random.choice(regions),
            "store_type": random.choice(["Supermarket", "Express", "Hypermarket"]),
            "floor_size_sqft": random.choice([2500, 5000, 10000, 15000])
        })

    with open(os.path.join(output_dir, "dim_store.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=stores[0].keys())
        writer.writeheader()
        writer.writerows(stores)

    # 4. Supplier Dimension
    suppliers = []
    for i in range(1, NUM_SUPPLIERS + 1):
        suppliers.append({
            "supplier_key": i,
            "supplier_id": f"SUPPLIER_{i:03d}",
            "supplier_name": f"Enterprise Distributors {i}",
            "contact_email": f"supply_{i}@ent-dist.com",
            "lead_time_days": random.randint(3, 14),
            "reliability_score": round(random.uniform(0.80, 0.99), 2)
        })

    with open(os.path.join(output_dir, "dim_supplier.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=suppliers[0].keys())
        writer.writeheader()
        writer.writerows(suppliers)

    # 5. Weather Dimension
    weathers = []
    w_conditions = ["Sunny", "Rainy", "Overcast"]
    weather_key = 1
    for d in dates:
        for r in regions:
            weathers.append({
                "weather_key": weather_key,
                "date_key": d["date_key"],
                "region": r,
                "avg_temperature_c": round(random.uniform(22.0, 36.0), 1),
                "precipitation_mm": round(random.expovariate(1.0 / 1.5), 2) if random.random() < 0.2 else 0.00,
                "weather_condition": random.choice(w_conditions)
            })
            weather_key += 1

    with open(os.path.join(output_dir, "dim_weather.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=weathers[0].keys())
        writer.writeheader()
        writer.writerows(weathers)

    # 6. Sales Fact & Daily Inventory Fact
    sales_facts = []
    inventory_facts = []
    sales_key_counter = 1
    inventory_key_counter = 1

    # Keep track of stock level per Store & SKU
    stock_levels = {}
    for st in stores:
        for sk in skus:
            stock_levels[(st["store_key"], sk["sku_key"])] = random.randint(100, 300)

    for d in dates:
        dt_key = d["date_key"]
        day_of_week = d["day_of_week"]
        
        for st in stores:
            for sk in skus:
                st_key = st["store_key"]
                sk_key = sk["sku_key"]
                
                # Check current stock
                current_stock = stock_levels[(st_key, sk_key)]
                
                # Base sales probability
                sales_prob = 0.3 if day_of_week in [6, 7] else 0.15
                if current_stock == 0:
                    sales_prob = 0.0 # No stock, no sales

                # Generate Sale
                if random.random() < sales_prob and current_stock > 0:
                    qty = random.randint(1, min(10, current_stock))
                    stock_levels[(st_key, sk_key)] -= qty
                    
                    price = sk["unit_price"]
                    discount = round(price * qty * 0.1, 2) if random.random() < 0.1 else 0.00
                    comp_price = round(price * random.uniform(0.9, 1.1), 2)
                    
                    sales_facts.append({
                        "sales_key": sales_key_counter,
                        "date_key": dt_key,
                        "sku_key": sk_key,
                        "store_key": st_key,
                        "supplier_key": random.choice(suppliers)["supplier_key"],
                        "quantity_sold": qty,
                        "unit_selling_price": price,
                        "discount_applied": discount,
                        "is_promotion_active": discount > 0,
                        "competitor_price": comp_price
                    })
                    sales_key_counter += 1

                # Re-stocking trigger simulation
                transit_stock = 0
                if stock_levels[(st_key, sk_key)] <= sk["reorder_point"]:
                    # order triggered, will arrive in a few days
                    if random.random() < 0.15:
                        transit_stock = random.choice([50, 100, 150])
                        stock_levels[(st_key, sk_key)] += transit_stock # restock immediately in model for simplification
                
                # Inventory daily log
                final_stock = stock_levels[(st_key, sk_key)]
                is_out_of_stock = final_stock == 0
                
                inventory_facts.append({
                    "inventory_key": inventory_key_counter,
                    "date_key": dt_key,
                    "sku_key": sk_key,
                    "store_key": st_key,
                    "stock_on_hand": final_stock,
                    "stock_in_transit": transit_stock if random.random() < 0.2 else 0,
                    "allocated_stock": int(final_stock * 0.05),
                    "stock_out_flag": is_out_of_stock,
                    "days_out_of_stock": 1 if is_out_of_stock else 0
                })
                inventory_key_counter += 1

    with open(os.path.join(output_dir, "fact_sales.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=[
            "sales_key", "date_key", "sku_key", "store_key", "supplier_key", 
            "quantity_sold", "unit_selling_price", "discount_applied", 
            "is_promotion_active", "competitor_price"
        ])
        writer.writeheader()
        writer.writerows(sales_facts)

    with open(os.path.join(output_dir, "fact_inventory.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=inventory_facts[0].keys())
        writer.writeheader()
        writer.writerows(inventory_facts)

    print(f"Star-Schema Data Warehouse generation completed. Saved files in {output_dir}.")

if __name__ == "__main__":
    generate_retail_dw()
