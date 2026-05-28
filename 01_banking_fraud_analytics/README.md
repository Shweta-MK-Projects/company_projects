# Banking Fraud Detection & Customer Risk Analytics Platform

## Project Overview
This project targets BFSI (Banking, Financial Services, and Insurance) transaction security and customer profiling. It integrates advanced SQL database schemas, real-time rules-based fraud indicators, recursive loops detection for tracing laundering networks, dynamic DAX KPIs, and AI-generated operational reports.

## Core Features
1. **Customer-360 View:** Consolidates multi-source customer records, historical card behaviors, NSF decline frequencies, and risk segment indicators.
2. **Circular Mule-Network Detection:** Implements recursive CTE queries tracing transfer paths (up to 5 hops) to expose laundering networks and circular fund routing.
3. **Multi-Vector Rules Engine:** Evaluates velocity (txn frequency in moving windows), Z-scores (deviations from card historical averages), and Haversine speed limits to detect geographical impossibilities.
4. **Interactive Dashboard Measures:** Deploys DAX metrics tracking `Fraud Loss Ratio`, `Approval-to-Chargeback Ratio`, and a multi-factor `Customer Risk Index`.
5. **AI Narrative Generator:** Integrates LLM prompting to convert raw operational metrics (alerts, false positive counts) into executive summary briefs.

---

## Directory Architecture
```text
01_banking_fraud_analytics/
├── database/
│   ├── schema.sql (DDL defining relational schemas and indices)
│   └── customer_360_view.sql (Recursive loops and customer profile aggregations)
├── analytics/
│   ├── fraud_rules_engine.sql (SQL engine for velocity, Z-scores, and speeds)
│   ├── rfm_segmentation.sql (7-cohort customer RFM logic)
│   └── ai_narrative_generator.py (LLM automated narrative reporting script)
├── dashboards/
│   ├── dax_measures.dax (DAX formulas & dynamic RLS filter definitions)
│   └── powerquery_etl.m (Ingestion, date-time formatting, and geolocation cleanups)
└── data_simulation/
    └── bank_data_generator.py (Generates synthetic test database records as CSVs)
```

---

## Technical Details

### Database Indexes for Query Optimization
To optimize search speeds over millions of transaction rows, the following indexes are defined:
* `idx_transactions_timestamp` (descending on timestamp) - accelerates chronological queries.
* `idx_transactions_amount` (B-tree) - speeds up range filter evaluations for Z-scores.
* `idx_card_timestamp_composite` (composite) - powers instantaneous rolling card-level aggregations.

### Simulated Fraud Flag Logic
The data simulation rules flag transactions as high-risk or fraudulent under two main conditions:
1. **Merchant MCC & Amount:** Transfers/ATM transactions exceeding INR 45,000 at terminals marked `is_high_risk_flag = TRUE`.
2. **Online Card-Not-Present Anomaly:** Online CNP transaction values exceeding INR 85,000.

---

## Run Data Simulation
To generate the relational test datasets as CSVs:
```bash
python data_simulation/bank_data_generator.py
```
This produces six files under `data_simulation/output/`:
* `customers.csv`
* `accounts.csv`
* `cards.csv`
* `terminals.csv`
* `transactions.csv`
* `fraud_alerts.csv`
