# Workforce Intelligence & Attrition Risk Prediction Platform

## Project Overview
This project contains a database model and predictive scoring framework for analyzing employee career trajectories, evaluating cohort-based survival trends, and flagging high-risk employees before they resign. It implements a Slowly Changing Dimension (SCD Type 2) historical schema, survival attrition analyses, and risk evaluation scripts.

## Core Features
1. **SCD Type 2 Career Tracking:** Structured SQL schema to capture employee department transfers, job grade changes, and salary revisions, maintaining start/end bounds and current record flags.
2. **Survival Attrition Analysis:** Cohort models grouping employee durations into tenure slices (0-36 months) to determine survival probability vectors.
3. **Multi-Factor Risk Scoring:** Weighted index combining 14 career, salary, and satisfaction metrics (such as compensation percentile, manager span of control, engagement, and promotion lag).
4. **Time-Travel Organization Charts:** Structured SQL procedure updating active history fields and enabling historical organization chart rebuilds.
5. **AI Narrative Reporter:** Generates descriptive monthly workforce intelligence briefs summarizing high-risk focus zones and strategic recommendations.

---

## Directory Architecture
```text
03_workforce_intelligence/
├── database/
│   └── scd2_hr_warehouse.sql (SCD Type 2 schemas, procedures, and indices)
├── analytics/
│   ├── cohort_attrition_survival.sql (Cohort retention and location hazard indexes)
│   ├── attrition_risk_scoring.sql (Weighted SQL risk scoring over 14 variables)
│   └── narrative_reporter.py (Automated executive report generator)
├── dashboards/
│   └── workforce_dashboard_specs.md (Power BI page metrics & dynamic field parameters)
└── data_simulation/
    └── hr_data_generator.py (Generates 5-year longitudinal HR databases as CSVs)
```

---

## Technical Details

### SCD Type 2 Query Pattern
The historical state of an employee at any given point-in-time `X` can be fetched by filtering on start/end bounds:
```sql
SELECT * 
FROM dim_employee_history 
WHERE employee_id = 'EMP_0045'
  AND '2024-06-15' BETWEEN valid_from AND COALESCE(valid_to, '9999-12-31');
```

### Risk Index Logic (Max 100 Points)
* **Engagement Score $\le$ 2:** 35 points
* **Compensation Percentile $<$ 30%:** 25 points
* **Promotion Stagnation $>$ 24 Months:** 15 points
* **Tenure in Critical Window (1-2 Years):** 10 points
* **Manager Span of Control $>$ 12 direct reports:** 5 points
* **Low Enablement / Training Hours $<$ 10.0:** 5 points
* **Low Performance Score $<$ 2.5:** 5 points

---

## Run Data Simulation
To generate the longitudinal datasets:
```bash
python data_simulation/hr_data_generator.py
```
This writes three CSV files inside `data_simulation/output/`:
* `dim_employee_history.csv`
* `fact_employee_status_daily.csv`
* `employee_attrition_events.csv`
