-- SQL Weighted Employee Attrition Risk Scoring Model
-- Aggregates 14 engineered indicators into a normalized risk score (0-100)

CREATE OR REPLACE VIEW view_employee_attrition_risk_scores AS
WITH active_employees AS (
    -- Get current records for active workforce
    SELECT 
        e.employee_key,
        e.employee_id,
        e.first_name,
        e.last_name,
        e.department,
        e.role_family,
        e.job_level,
        e.manager_employee_id,
        e.location,
        e.compensation_band_percentile,
        e.engagement_score
    FROM dim_employee_history e
    WHERE e.is_current = TRUE
      -- Ensure they haven't already resigned
      AND e.employee_id NOT IN (SELECT employee_id FROM employee_attrition_events)
),
manager_span_of_control AS (
    -- Calculate manager span (number of direct reports)
    SELECT 
        manager_employee_id,
        COUNT(employee_id) AS span_count
    FROM active_employees
    WHERE manager_employee_id IS NOT NULL
    GROUP BY manager_employee_id
),
employee_metrics AS (
    -- Gather operational variables for the scoring model
    SELECT 
        ae.employee_key,
        ae.employee_id,
        ae.first_name,
        ae.last_name,
        ae.department,
        ae.role_family,
        ae.job_level,
        ae.manager_employee_id,
        ae.location,
        ae.compensation_band_percentile,
        ae.engagement_score,
        
        -- Span of control for employee's manager
        COALESCE(msc.span_count, 0) AS manager_span,
        
        -- Historical metrics from daily logs (averages/totals)
        COALESCE(AVG(f.tenure_days), 0) AS tenure_days,
        COALESCE(MAX(f.promotion_lag_months), 0) AS promotion_lag_months,
        COALESCE(SUM(f.training_hours_completed), 0) AS training_hours,
        COALESCE(AVG(f.performance_score), 3.0) AS avg_performance
    FROM active_employees ae
    LEFT JOIN fact_employee_status_daily f ON ae.employee_key = f.employee_key
    LEFT JOIN manager_span_of_control msc ON ae.manager_employee_id = msc.manager_employee_id
    GROUP BY 
        ae.employee_key, ae.employee_id, ae.first_name, ae.last_name, 
        ae.department, ae.role_family, ae.job_level, ae.manager_employee_id, 
        ae.location, ae.compensation_band_percentile, ae.engagement_score, msc.span_count
),
risk_features AS (
    -- Score individual risk variables (1 = high risk, 0 = low risk)
    SELECT 
        employee_id,
        first_name,
        last_name,
        department,
        role_family,
        job_level,
        location,
        
        -- Variable 1: Engagement Score Anomaly
        CASE WHEN engagement_score <= 2 THEN 1 ELSE 0 END AS r_low_engagement,
        
        -- Variable 2: Compensation Percentile (Underpaid compared to market)
        CASE WHEN compensation_band_percentile < 30.0 THEN 1 ELSE 0 END AS r_low_comp,
        
        -- Variable 3: Manager Span of Control (Large manager span leads to less guidance)
        CASE WHEN manager_span > 12 THEN 1 ELSE 0 END AS r_high_manager_span,
        
        -- Variable 4: Promotion Lag (Time since last job grade change)
        CASE WHEN promotion_lag_months > 24 THEN 1 ELSE 0 END AS r_promotion_stagnation,
        
        -- Variable 5: Tenure Band Alert (High risk of attrition between 1 and 2 years)
        CASE WHEN tenure_days BETWEEN 365 AND 730 THEN 1 ELSE 0 END AS r_critical_tenure_window,
        
        -- Variable 6: Low Training Hours (Indicates lack of investment/growth)
        CASE WHEN training_hours < 10.0 THEN 1 ELSE 0 END AS r_low_enablement,
        
        -- Variable 7: Extreme Performance Pressures (Low scores or sudden decline)
        CASE WHEN avg_performance < 2.5 THEN 1 ELSE 0 END AS r_low_performance
    FROM employee_metrics
)
SELECT 
    employee_id,
    first_name,
    last_name,
    department,
    role_family,
    job_level,
    location,
    
    -- Sum individual risk points with specialized weights
    (
        (r_low_engagement * 35) + 
        (r_low_comp * 25) + 
        (r_promotion_stagnation * 15) + 
        (r_critical_tenure_window * 10) + 
        (r_high_manager_span * 5) + 
        (r_low_enablement * 5) + 
        (r_low_performance * 5)
    ) AS attrition_risk_index,
    
    -- Classification into Risk Categories
    CASE 
        WHEN ((r_low_engagement * 35) + (r_low_comp * 25) + (r_promotion_stagnation * 15) + (r_critical_tenure_window * 10) + (r_high_manager_span * 5) + (r_low_enablement * 5) + (r_low_performance * 5)) >= 60 THEN 'High Attrition Risk'
        WHEN ((r_low_engagement * 35) + (r_low_comp * 25) + (r_promotion_stagnation * 15) + (r_critical_tenure_window * 10) + (r_high_manager_span * 5) + (r_low_enablement * 5) + (r_low_performance * 5)) >= 30 THEN 'Medium Attrition Risk'
        ELSE 'Low Attrition Risk'
    END AS risk_tier
FROM risk_features;
