#!/usr/bin/env python3
"""
Marketing Multi-Touch Attribution & Customer 360 Data Generator.
Generates CSV records for unified customer profiles, clickstream touchpoint lists,
marketing cost files, order logs, and support interactions.
"""

import os
import csv
import random
from datetime import datetime, timedelta

# Constants
NUM_CUSTOMERS = 1000
NUM_TOUCHPOINTS = 18000
NUM_ORDERS = 1500
NUM_TICKETS = 400

START_DATE = datetime(2026, 1, 1)
END_DATE = datetime(2026, 5, 27)

def generate_marketing_data():
    print("Generating synthetic Customer 360 marketing dataset...")
    output_dir = os.path.join(os.path.dirname(__file__), "output")
    os.makedirs(output_dir, exist_ok=True)

    # 1. Marketing Channels
    channels = [
        {"channel_id": 1, "channel_name": "Google Ads", "medium": "Paid Search", "cost_per_click": 1.25},
        {"channel_id": 2, "channel_name": "Facebook Ads", "medium": "Paid Social", "cost_per_click": 0.85},
        {"channel_id": 3, "channel_name": "Newsletter", "medium": "Email", "cost_per_click": 0.05},
        {"channel_id": 4, "channel_name": "Direct Traffic", "medium": "Direct", "cost_per_click": 0.00},
        {"channel_id": 5, "channel_name": "Organic Search", "medium": "SEO", "cost_per_click": 0.00},
        {"channel_id": 6, "channel_name": "LinkedIn Ads", "medium": "Paid Social", "cost_per_click": 3.50},
        {"channel_id": 7, "channel_name": "Affiliate Network", "medium": "Referral", "cost_per_click": 0.50}
    ]

    with open(os.path.join(output_dir, "marketing_channels.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=channels[0].keys())
        writer.writeheader()
        writer.writerows(channels)

    # 2. Customers
    customers = []
    first_names = ["Shweta", "Amit", "Meera", "Rohan", "Pooja", "Vikram", "Sneha", "Karan", "Divya", "Arjun"]
    last_names = ["Kumbari", "Gupta", "Sharma", "Nair", "Patel", "Verma", "Rao", "Joshi", "Das", "Singh"]
    acquisition_channels = ["Organic Search", "Google Ads", "Facebook Ads", "Direct Traffic"]

    for i in range(1, NUM_CUSTOMERS + 1):
        cust_id = f"CUST_{i:04d}"
        signup = START_DATE + timedelta(days=random.randint(0, 100))
        customers.append({
            "customer_id": cust_id,
            "first_name": random.choice(first_names),
            "last_name": random.choice(last_names),
            "email": f"{cust_id.lower()}@customer-c360.com",
            "signup_date": signup.strftime("%Y-%m-%d"),
            "gender": random.choice(["Male", "Female", "Other"]),
            "age": random.randint(18, 65),
            "preferred_language": "English",
            "acquisition_channel": random.choice(acquisition_channels),
            "lifetime_value": 0.00 # calculated from orders later
        })

    # 3. Touchpoints & Orders (Interlinked)
    touchpoints = []
    orders = []
    
    tp_counter = 1
    order_counter = 1
    
    # Store customer signup reference
    for cust in customers:
        cust_id = cust["customer_id"]
        signup_dt = datetime.strptime(cust["signup_date"], "%Y-%m-%d")
        
        # Simulating customer journeys
        # A customer can have 1 or more order conversion paths
        num_journeys = random.randint(0, 3)
        
        for journey in range(num_journeys):
            # Generate clickstream sessions prior to an order
            session_id = f"SESS_{random.randint(100000, 999999)}"
            order_time = signup_dt + timedelta(days=random.randint(1, 40) + journey * 30)
            
            if order_time > END_DATE:
                continue
                
            # Number of touchpoints leading to this order
            num_clicks = random.randint(1, 5)
            journey_touchpoints = []
            
            for click in range(num_clicks):
                click_time = order_time - timedelta(days=random.randint(0, 14), hours=random.randint(0, 23))
                ch = random.choice(channels)
                
                tp_id = f"TP_{tp_counter:06d}"
                touchpoint = {
                    "touchpoint_id": tp_id,
                    "customer_id": cust_id,
                    "channel_id": ch["channel_id"],
                    "session_id": session_id,
                    "touchpoint_timestamp": click_time.strftime("%Y-%m-%d %H:%M:%S"),
                    "utm_source": ch["channel_name"].replace(" ", "").lower(),
                    "utm_medium": ch["medium"].replace(" ", "").lower(),
                    "utm_campaign": f"Campaign_Promo_{random.choice(['Summer', 'Winter', 'Brand', 'Retarget'])}",
                    "landing_page": f"/promo-deals/page_{random.randint(1, 10)}",
                    "device_category": random.choices(["Mobile", "Desktop", "Tablet"], weights=[0.60, 0.30, 0.10])[0],
                    "duration_seconds": random.randint(10, 600)
                }
                touchpoints.append(touchpoint)
                journey_touchpoints.append(touchpoint)
                tp_counter += 1

            # Order Conversion event
            subtotal = round(random.uniform(250.0, 12000.0), 2)
            discount = round(subtotal * 0.15, 2) if random.random() < 0.2 else 0.00
            tax = round((subtotal - discount) * 0.05, 2)
            total = round((subtotal - discount) + tax, 2)
            
            orders.append({
                "order_id": f"ORDER_{order_counter:05d}",
                "customer_id": cust_id,
                "session_id": session_id,
                "order_timestamp": order_time.strftime("%Y-%m-%d %H:%M:%S"),
                "subtotal_amount": subtotal,
                "tax_amount": tax,
                "discount_amount": discount,
                "total_order_amount": total,
                "payment_method": random.choice(["Credit Card", "UPI", "PayPal", "NetBanking"])
            })
            
            # Update customer LTV
            cust["lifetime_value"] = round(cust["lifetime_value"] + total, 2)
            order_counter += 1

    # Save customers with LTV updated
    with open(os.path.join(output_dir, "c360_customers.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=customers[0].keys())
        writer.writeheader()
        writer.writerows(customers)

    with open(os.path.join(output_dir, "customer_touchpoints.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=touchpoints[0].keys())
        writer.writeheader()
        writer.writerows(touchpoints)

    with open(os.path.join(output_dir, "ecommerce_orders.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=orders[0].keys())
        writer.writeheader()
        writer.writerows(orders)

    # 4. Support Tickets
    tickets = []
    ticket_categories = ["Delivery Delay", "Payment Failed", "Refund Status", "Account Lock"]
    statuses = ["Resolved", "In Progress", "Open"]

    for i in range(1, NUM_TICKETS + 1):
        cust = random.choice(customers)
        created = START_DATE + timedelta(days=random.randint(40, 140))
        tickets.append({
            "ticket_id": f"TICKET_{i:04d}",
            "customer_id": cust["customer_id"],
            "created_timestamp": created.strftime("%Y-%m-%d %H:%M:%S"),
            "issue_category": random.choice(ticket_categories),
            "ticket_status": random.choices(statuses, weights=[0.85, 0.10, 0.05])[0],
            "customer_sentiment_rating": random.randint(1, 5)
        })

    with open(os.path.join(output_dir, "customer_support_tickets.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=tickets[0].keys())
        writer.writeheader()
        writer.writerows(tickets)

    print(f"Customer-360 Marketing generation completed. Output written to {output_dir}.")

if __name__ == "__main__":
    generate_marketing_data()
