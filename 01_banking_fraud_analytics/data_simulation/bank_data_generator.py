#!/usr/bin/env python3
"""
Synthetic Data Generator for Banking Fraud & Customer Risk Analytics.
Generates CSV files containing realistic tables for customers, accounts, cards,
terminals, transactions, and fraud alerts.
"""

import os
import csv
import random
from datetime import datetime, timedelta

# Constants
NUM_CUSTOMERS = 1000
NUM_ACCOUNTS = 1200
NUM_CARDS = 1300
NUM_TERMINALS = 300
NUM_TRANSACTIONS = 15000

START_DATE = datetime(2026, 4, 1)
END_DATE = datetime(2026, 5, 27)

def random_date(start, end):
    delta = end - start
    int_delta = (delta.days * 24 * 60 * 60) + delta.seconds
    random_second = random.randrange(int_delta)
    return start + timedelta(seconds=random_second)

def generate_data():
    print("Generating synthetic BFSI dataset...")
    output_dir = os.path.join(os.path.dirname(__file__), "output")
    os.makedirs(output_dir, exist_ok=True)

    # 1. Generate Customers
    customers = []
    first_names = ["Shweta", "Ramesh", "Priya", "Amit", "Sneha", "Vikram", "Anjali", "Suresh", "Neha", "Rahul", "Deepa", "Vijay"]
    last_names = ["Kumbari", "Sharma", "Patel", "Verma", "Joshi", "Rao", "Nair", "Gupta", "Singh", "Reddy", "Mehta", "Das"]
    cities = ["Bengaluru", "Mumbai", "Delhi", "Hyderabad", "Chennai", "Pune", "Kolkata", "Ahmedabad"]
    states = ["Karnataka", "Maharashtra", "Delhi", "Telangana", "Tamil Nadu", "Maharashtra", "West Bengal", "Gujarat"]

    for i in range(1, NUM_CUSTOMERS + 1):
        cust_id = f"CUST_{i:04d}"
        idx = random.randint(0, len(cities) - 1)
        dob = datetime(1960, 1, 1) + timedelta(days=random.randint(0, 15000))
        risk = random.choices(["Low", "Medium", "High"], weights=[0.85, 0.12, 0.03])[0]
        customers.append({
            "customer_id": cust_id,
            "first_name": random.choice(first_names),
            "last_name": random.choice(last_names),
            "email": f"{cust_id.lower()}@example-bank.com",
            "phone_number": f"+91 {random.randint(6000000000, 9999999999)}",
            "dob": dob.strftime("%Y-%m-%d"),
            "street_address": f"Flat {random.randint(1, 500)}, Block {random.choice(['A', 'B', 'C', 'D'])}",
            "city": cities[idx],
            "state": states[idx],
            "postal_code": f"{random.randint(110001, 850000)}",
            "country": "India",
            "risk_score_segment": risk,
            "created_at": random_date(START_DATE - timedelta(days=365), START_DATE).strftime("%Y-%m-%d %H:%M:%S")
        })

    # Save Customers CSV
    with open(os.path.join(output_dir, "customers.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=customers[0].keys())
        writer.writeheader()
        writer.writerows(customers)

    # 2. Generate Accounts
    accounts = []
    for i in range(1, NUM_ACCOUNTS + 1):
        acc_id = f"ACC_{i:04d}"
        cust = random.choice(customers)
        acc_type = random.choice(["Savings", "Current", "CreditCard"])
        balance = round(random.uniform(500.0, 1500000.0), 2)
        accounts.append({
            "account_id": acc_id,
            "customer_id": cust["customer_id"],
            "account_type": acc_type,
            "balance": balance,
            "currency": "INR",
            "status": "Active",
            "kyc_status": "Verified",
            "created_at": cust["created_at"]
        })

    with open(os.path.join(output_dir, "accounts.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=accounts[0].keys())
        writer.writeheader()
        writer.writerows(accounts)

    # 3. Generate Cards
    cards = []
    for i in range(1, NUM_CARDS + 1):
        card_id = f"CARD_{i:04d}"
        acc = random.choice(accounts)
        card_type = "Credit" if acc["account_type"] == "CreditCard" else "Debit"
        network = random.choice(["Visa", "Mastercard", "RuPay", "Amex"])
        expiry = datetime.now() + timedelta(days=random.randint(30, 1500))
        cards.append({
            "card_id": card_id,
            "account_id": acc["account_id"],
            "card_number_masked": f"xxxx-xxxx-xxxx-{random.randint(1000, 9999)}",
            "card_type": card_type,
            "card_network": network,
            "expiry_date": expiry.strftime("%Y-%m-%d"),
            "status": "Active",
            "daily_limit": 100000.00
        })

    with open(os.path.join(output_dir, "cards.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=cards[0].keys())
        writer.writeheader()
        writer.writerows(cards)

    # 4. Generate Terminals (Merchants)
    terminals = []
    mcc_list = ["5411", "5812", "5814", "4829", "5942", "7996", "5311", "6011"] # ATM, Grocery, Restaurants, Wire Transfer, etc.
    merchant_names = {
        "5411": ["Big Bazaar", "Reliance Fresh", "D-Mart", "More Retail"],
        "5812": ["Toscano", "Barbeque Nation", "Punjab Grill", "Windmills Craftworks"],
        "5814": ["McDonalds", "KFC", "Starbucks", "Cafe Coffee Day"],
        "4829": ["Western Union", "Paytm Money", "Instamojo", "Razorpay Transfer"],
        "5942": ["Sapna Book House", "Crossword", "Blossom Book House"],
        "7996": ["Wonderla", "Innovative Film City", "PVR Cinemas"],
        "5311": ["Shoppers Stop", "Lifestyle", "Westside", "Decathlon"],
        "6011": ["SBI ATM", "HDFC ATM", "ICICI ATM", "Axis ATM"]
    }
    
    for i in range(1, NUM_TERMINALS + 1):
        term_id = f"TERM_{i:04d}"
        mcc = random.choice(mcc_list)
        name = random.choice(merchant_names[mcc]) + f" #{random.randint(10, 99)}"
        idx = random.randint(0, len(cities) - 1)
        is_high_risk = mcc in ["4829", "6011"] and random.random() < 0.25
        
        terminals.append({
            "terminal_id": term_id,
            "merchant_name": name,
            "merchant_category_code": mcc,
            "city": cities[idx],
            "country": "India",
            "latitude": round(random.uniform(12.8, 13.1), 6), # Bengaluru region
            "longitude": round(random.uniform(77.5, 77.8), 6),
            "is_high_risk_flag": is_high_risk
        })

    with open(os.path.join(output_dir, "terminals.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=terminals[0].keys())
        writer.writeheader()
        writer.writerows(terminals)

    # 5. Generate Transactions & Fraud
    transactions = []
    fraud_alerts = []
    alert_counter = 1

    for i in range(1, NUM_TRANSACTIONS + 1):
        txn_id = f"TXN_{i:07d}"
        card = random.choice(cards)
        acc_id = card["account_id"]
        term = random.choice(terminals)
        amount = round(random.expovariate(1.0 / 1500.0) + 10, 2)
        # Inject deliberate high-amount transactions to trigger risk thresholds
        if random.random() < 0.015:
            amount = round(random.uniform(45000.0, 95000.0), 2)
        
        timestamp = random_date(START_DATE, END_DATE)
        txn_type = "ATM" if term["merchant_category_code"] == "6011" else ("POS" if random.random() < 0.6 else "Online")
        if term["merchant_category_code"] == "4829":
            txn_type = "Transfer"
            
        resp = random.choices(["00", "51", "05"], weights=[0.96, 0.03, 0.01])[0] # 51=NSF, 05=Do Not Honor
        channel = "Swipe" if txn_type == "POS" else ("CNP" if txn_type == "Online" else "Chip-and-PIN")
        ip = f"192.168.{random.randint(1, 254)}.{random.randint(1, 254)}" if txn_type == "Online" else "0.0.0.0"

        # Simulating standard fraud flags
        is_fraud = False
        method = ""
        # Rule anomalies
        if term["is_high_risk_flag"] and amount > 45000:
            is_fraud = True
            method = "Rules Engine"
        elif txn_type == "Online" and amount > 85000 and random.random() < 0.7:
            is_fraud = True
            method = "Rules Engine"
            
        # Ensure it fits the response codes
        if is_fraud:
            resp = "00"

        transactions.append({
            "transaction_id": txn_id,
            "card_id": card["card_id"],
            "account_id": acc_id,
            "terminal_id": term["terminal_id"],
            "amount": amount,
            "currency": "INR",
            "transaction_timestamp": timestamp.strftime("%Y-%m-%d %H:%M:%S"),
            "transaction_type": txn_type,
            "response_code": resp,
            "channel": channel,
            "ip_address": ip,
            "is_fraud": is_fraud,
            "fraud_label_method": method if is_fraud else "None"
        })

        # Generate alert if rules violated or fraud flagged
        if is_fraud or (amount > 50000 and random.random() < 0.1):
            risk_score = round(random.uniform(50.0, 99.9), 2) if is_fraud else round(random.uniform(10.0, 49.9), 2)
            rules = ["Velocity Check Violated"]
            if amount > 50000:
                rules.append("Extreme Amount Z-Score")
            if term["is_high_risk_flag"]:
                rules.append("High Risk MCC Check")
                
            fraud_alerts.append({
                "alert_id": alert_counter,
                "transaction_id": txn_id,
                "triggered_rules": "{" + ",".join([f'"{r}"' for r in rules]) + "}",
                "risk_score": risk_score,
                "status": "Confirmed Fraud" if is_fraud else "False Positive",
                "assigned_analyst": "Shweta M K" if is_fraud else "Unassigned",
                "resolution_notes": "Blocked transaction, marked card suspended" if is_fraud else "Legitimate customer purchase verified",
                "created_at": timestamp.strftime("%Y-%m-%d %H:%M:%S"),
                "resolved_at": (timestamp + timedelta(hours=random.randint(1, 24))).strftime("%Y-%m-%d %H:%M:%S")
            })
            alert_counter += 1

    with open(os.path.join(output_dir, "transactions.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=transactions[0].keys())
        writer.writeheader()
        writer.writerows(transactions)

    alert_fields = ["alert_id", "transaction_id", "triggered_rules", "risk_score", "status", "assigned_analyst", "resolution_notes", "created_at", "resolved_at"]
    with open(os.path.join(output_dir, "fraud_alerts.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=alert_fields)
        writer.writeheader()
        writer.writerows(fraud_alerts)

    print(f"Generated {NUM_CUSTOMERS} customers, {NUM_TRANSACTIONS} transactions, and {len(fraud_alerts)} alerts in the 'output' directory.")

if __name__ == "__main__":
    generate_data()
