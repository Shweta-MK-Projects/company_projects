# Multi-Touch Marketing Attribution & Customer 360 Analytics

## Project Overview
This project contains database structures and attribution analytics engines to evaluate advertising channel ROI, construct cohesive Customer-360 profiles, and model lifecycle retention curves. It implements SQL frameworks to score conversions across First-Touch, Last-Touch, Linear, and Time-Decay attribution models.

## Core Features
1. **Attribution Engine:** SQL queries mapping conversion values to specific channel sequences, factoring half-life decay weights.
2. **Customer-360 profile:** Unifies CRM demographics, transaction records, support histories, and clickstream sequences.
3. **Monthly Cohort Retention Curves:** Tracks registration cohorts over a 12-month timeline to evaluate lifecycle retention rates.
4. **Attribution comparison view:** Compares revenue margins across models (First-Touch vs. Last-Touch, etc.) to identify over-attribution risks.
5. **Interactive Dashboard Measures:** Deploys Power BI DAX formulas evaluating CAC (Customer Acquisition Cost) and ROI by marketing channel.

---

## Directory Architecture
```text
04_marketing_attribution_c360/
├── database/
│   └── c360_marketing_schema.sql (DDL defining profiles, touchpoints, orders, and tickets)
├── analytics/
│   ├── multi_touch_attribution.sql (First, Last, Linear, and Time-Decay SQL formulas)
│   └── cohort_retention.sql (SQL signup cohorts and RFM segmentation scoring)
├── dashboards/
│   ├── dax_cac_roi.dax (DAX measures for CAC, ROI, and Lifetime Value)
│   └── tableau_customer_journey.md (Sankey sequence flow design and stage drop-offs)
└── data_simulation/
    └── marketing_data_generator.py (Generates synthetic marketing databases as CSVs)
```

---

## Technical Details

### Attribution Models Calculations
1. **First-Touch:** Credit = 100% to the initial session click.
2. **Last-Touch:** Credit = 100% to the final session click before checkout.
3. **Linear:** Credit = $1 / N$ where $N$ represents the count of touchpoints inside the conversion window.
4. **Time-Decay:** Credit is computed exponentially based on hours elapsed:
   $$\text{Raw Weight} = 2^{-\frac{\Delta t}{7 \text{ days}}}$$
   Weights are then normalized to sum to $1.0$ per order.

### RFM Segments Categories
* **Champions:** Recency, Frequency, and Monetary scores $\ge$ 4.
* **Loyal Customers:** Recency, Frequency, and Monetary scores $\ge$ 3.
* **At Risk:** Recency score $\le$ 2, Frequency and Monetary scores $\ge$ 3.
* **Needs Attention:** Recency and Frequency scores $\le$ 2, Monetary score $\ge$ 3.
* **Hibernating:** Default segment.

---

## Run Data Simulation
To generate the multi-channel datasets:
```bash
python data_simulation/marketing_data_generator.py
```
This writes five CSV files inside `data_simulation/output/`:
* `marketing_channels.csv`
* `c360_customers.csv`
* `customer_touchpoints.csv`
* `ecommerce_orders.csv`
* `customer_support_tickets.csv`
