#!/usr/bin/env python3
"""
Workforce Health Narrative Reporter.
Generates AI-augmented summaries of employee retention, survival cohorts,
and prioritized risk hotspots based on organizational data.
"""

import os
import json
from datetime import datetime

def generate_hr_summary(data: dict) -> str:
    """
    Formulates a descriptive HR intelligence brief.
    Simulates LLM orchestration on dashboard aggregate exports.
    """
    high_risk_count = data["high_risk_headcount"]
    total_active = data["total_active_headcount"]
    risk_ratio = (high_risk_count / total_active * 100) if total_active > 0 else 0
    
    report = f"""# WORKFORCE INTELLIGENCE EXECUTIVE SUMMARY REPORT
**Focus:** Retention Risk & Cohort Stability Analysis  
**Reporting Date:** {datetime.now().strftime('%B %Y')} (AI-Assisted Operations Support)

---

### 1. Executive Retention Summary
The organization maintains a current active headcount of **{total_active:,} employees**. Predictive risk indicators have flagged **{high_risk_count:,} team members** as holding a **High Attrition Risk** status, representing **{risk_ratio:.1f}%** of the total workforce. Operationally, the average tenure for active resources remains at **{data['avg_tenure_months']} months**, and the annual voluntary attrition rate sits at **{data['voluntary_attrition_rate']:.1f}%**.

### 2. Attrition Risk Hotspots
A multi-dimensional cohort analysis indicates that exits are heavily concentrated in three key clusters:
* **The Critical 1-2 Year Tenure Band:** Accounts for **{data['critical_cohort_pct']}%** of all voluntary departures, indicating a need to re-evaluate onboarding-to-integration handoffs.
* **Functional Roles:** `{data['high_risk_role_family']}` and `{data['high_risk_department']}` exhibit elevated hazard ratios, strongly correlated with a high manager span of control (averaging `{data['critical_manager_span']}` direct reports).
* **Location Deviations:** `{data['high_risk_location']}` logged a **{data['location_attrition_delta']}%** increase in exits compared to the national average, primarily driven by competitive salary discrepancies.

### 3. Weighted Risk Factors Analysis
The weighted risk-scoring engine evaluated 14 features across the active population. The top contributing vectors to high risk tiers were:
1. **Low Engagement Scores (Weight 35%):** Present in {data['factor_engagement_pct']}% of high-risk files.
2. **Compensation Stagnation (Weight 25%):** Employees falling below the 30th percentile in their respective grade brackets.
3. **Promotion Stagnation (Weight 15%):** Job level lag exceeding 24 months without job grade adjustments.

### 4. Strategic Retention Recommendations
1. **Targeted Comp Adjustments:** Initiate compensation reviews for the `{data['high_risk_role_family']}` cohort positioned below the 30th percentile to mitigate immediate market-churn risks.
2. **Manager Span Reductions:** Introduce team subdivisions in the `{data['high_risk_department']}` department where manager span of control exceeds 12 direct reports.
3. **Engagement Interventions:** Direct HR Business Partners to conduct proactive interviews with the {high_risk_count} employees in the High Risk category.
"""
    return report

def main():
    # Simulated aggregate dataset from Power BI dashboard metrics
    metrics = {
        "total_active_headcount": 12450,
        "high_risk_headcount": 218,
        "avg_tenure_months": 28.4,
        "voluntary_attrition_rate": 14.2,
        "critical_cohort_pct": 68,
        "high_risk_role_family": "Engineering (Software Engineers)",
        "high_risk_department": "Customer Success & Support",
        "critical_manager_span": 14.5,
        "high_risk_location": "Bengaluru Office",
        "location_attrition_delta": 22.0,
        "factor_engagement_pct": 82
    }

    report = generate_hr_summary(metrics)
    
    # Save output
    output_path = os.path.join(os.path.dirname(__file__), "..", "dashboards", "monthly_hr_narrative.md")
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    with open(output_path, "w") as f:
        f.write(report)
        
    print(f"Monthly workforce narrative summary successfully written to: {os.path.abspath(output_path)}")

if __name__ == "__main__":
    main()
