# README for AI‑Augmented Real‑Time Fraud Detection Demo

This demo showcases a minimal end‑to‑end fraud‑detection pipeline:

1. **SQL schema & demo view** – `analytics/fraud_demo.sql`
2. **Synthetic data generator** – `data_simulation/fraud_data_gen.py`
3. **Placeholder Power BI dashboard** – `dashboards/fraud_dashboard.pbix`
4. **Database DDL** – `database/fraud_schema.sql`

Run the Python script to create `transactions.csv`, then execute the SQL (e.g., in SQLite or SQL Server) to load the CSV and query the `FraudScore` view.

*All files are placeholders and can be expanded.*
