# Power BI Workforce Health Dashboard Specifications

This document outlines the visual layout, interaction paradigms, and page structures for the 6-page interactive **Workforce Health Dashboard** built from our SCD Type 2 HR warehouse.

---

## Page-by-Page Specifications

### Page 1: Headcount & Demographics Overview
* **Goal:** High-level operational summary of active workforce.
* **Key KPIs:** Active Headcount, Average Tenure (Months), Average Compensation Percentile, Average Engagement Rating.
* **Visuals:**
  * Card metrics displaying main KPIs.
  * Clustered column chart: Headcount by Department and Job Level.
  * Filled Map: Employee distribution by Location.
  * Table: Top 10 managers by direct report spans (Span of Control).

### Page 2: Attrition Diagnostics
* **Goal:** Historical analysis of voluntary vs. involuntary exits.
* **Key KPIs:** Annualized Attrition Rate, Total Exits, Exit Rate Delta (YoY).
* **Visuals:**
  * Line chart: Monthly attrition rate vs. quarterly moving average.
  * Treemap: Exits categorized by exit reasons (e.g., compensation, manager conflict).
  * Donut chart: Exit splits by tenure bands (e.g., <6m, 6m-12m, 1y-2y, >2y).

### Page 3: SCD Career & Role Transitions (Time Machine)
* **Goal:** Tracking promotions, lateral shifts, and salary adjustments over time.
* **Key KPIs:** Promotion Velocity (average months between promotions), Internal Mobility Rate, Salary Adjustment Count.
* **Visuals:**
  * Matrix Visual: Employee role paths (Initial Job Level $\rightarrow$ Current Job Level).
  * Stacked Bar Chart: Change reasons (Promotion vs. Transfer) by department.
  * Slicer: Historical date filter allowing point-in-time organization chart reconstructions (exploiting `valid_from` & `valid_to` SQL attributes).

### Page 4: Cohort & Survival Retention Curves
* **Goal:** Evaluating long-term survival probability.
* **Visuals:**
  * **Line Chart (Cohort Retention Curves):** X-axis shows months since hire (0 to 36). Y-axis shows retention rate %. Legend shows Hire Cohorts (e.g. 2024-Q1, 2024-Q2).
  * Slicers: Role Family, Department, location.

### Page 5: Predictive Attrition Risk Scoring
* **Goal:** Forecast employee exits before they happen.
* **Key KPIs:** Count of High-Risk Employees, Median Risk Score, Critical Retention Alert Flag.
* **Visuals:**
  * **Conditional Formatted Risk Heatmap:** Matrix visual listing employees on rows, risk factors on columns. Cells color-coded using HSL gradients: Low Risk (Green), Medium Risk (Yellow), High Risk (Red).
  * Scatter plot: Tenure (days) vs. Attrition Risk Score, sized by manager span.
  * Drill-through: Forensic view of single employee profile details.

### Page 6: Exit Survey Deep-Dive
* **Goal:** Analyzing feedback from exiting employees.
* **Key KPIs:** Exit Survey Satisfaction Score, Career Growth NPS.
* **Visuals:**
  * Bar Chart: Exit satisfaction scores by department.
  * Word Cloud: Common terms in exit interview notes.

---

## Field Parameter Implementation

To enable dynamic switching of chart dimensions without duplicate visuals, we define a Field Parameter:
```dax
Dynamic_Dimension_Slicer = {
    ("Department", NAMEOF(dim_employee_history[department]), 0),
    ("Role Family", NAMEOF(dim_employee_history[role_family]), 1),
    ("Location", NAMEOF(dim_employee_history[location]), 2),
    ("Job Level", NAMEOF(dim_employee_history[job_level]), 3)
}
```
* **Usage:** Drop this parameter onto the X-axis of our main attrition charts and link it to a slicer to let category leads toggle dimensions dynamically.
