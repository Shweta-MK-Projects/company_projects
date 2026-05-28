-- SQL Cohort and Survival Attrition Analysis
-- Uncover trends by partition groupings: location, role_family, and tenure bands

-- 1. Historical Cohort Retention Rate Analysis
-- Groups employees into cohorts based on hire year/quarter and tracks retention over time.
CREATE OR REPLACE VIEW view_hr_cohort_retention AS
WITH employee_hire_dates AS (
    -- Identify initial entry point for each employee
    SELECT 
        employee_id,
        MIN(valid_from) AS hire_date,
        -- Extract Hire Cohort Name: e.g., "2024-Q1"
        TO_CHAR(MIN(valid_from), 'YYYY-"Q"Q') AS hire_cohort
    FROM dim_employee_history
    GROUP BY employee_id
),
cohort_sizes AS (
    -- Count total employees in each hiring cohort
    SELECT 
        hire_cohort,
        COUNT(DISTINCT employee_id) AS cohort_starting_size
    FROM employee_hire_dates
    GROUP BY hire_cohort
),
employee_active_durations AS (
    -- Find termination date if they left
    SELECT 
        hd.employee_id,
        hd.hire_cohort,
        hd.hire_date,
        ae.termination_date,
        -- If still active, assume present date (2026-05-27)
        COALESCE(ae.termination_date, '2026-05-27'::DATE) AS end_date,
        -- Total months of survival
        (EXTRACT(YEAR FROM AGE(COALESCE(ae.termination_date, '2026-05-27'::DATE), hd.hire_date)) * 12) +
         EXTRACT(MONTH FROM AGE(COALESCE(ae.termination_date, '2026-05-27'::DATE), hd.hire_date)) AS survival_months
    FROM employee_hire_dates hd
    LEFT JOIN employee_attrition_events ae ON hd.employee_id = ae.employee_id
),
monthly_survival_counts AS (
    -- Count how many employees in each cohort survived past X months
    SELECT 
        hire_cohort,
        month_index,
        COUNT(DISTINCT employee_id) AS active_employee_count
    FROM employee_active_durations
    -- Generate series of months to check
    CROSS JOIN generate_series(0, 36) AS month_index
    WHERE survival_months >= month_index
    GROUP BY hire_cohort, month_index
)
SELECT 
    msc.hire_cohort,
    msc.month_index,
    msc.active_employee_count,
    cs.cohort_starting_size,
    -- Retention rate percentage
    CASE WHEN cs.cohort_starting_size = 0 THEN 0 ELSE (msc.active_employee_count::double precision / cs.cohort_starting_size) END::DECIMAL(5,4) AS retention_rate
FROM monthly_survival_counts msc
JOIN cohort_sizes cs ON msc.hire_cohort = cs.hire_cohort;


-- 2. Role and Location Survival Hazard Indicators
-- Identifies attrition hazard densities across job classifications.
CREATE OR REPLACE VIEW view_hr_survival_hazards AS
WITH employee_lifecycle AS (
    SELECT 
        emp.employee_id,
        emp.role_family,
        emp.location,
        emp.department,
        (EXTRACT(YEAR FROM AGE(COALESCE(ae.termination_date, '2026-05-27'::DATE), MIN(emp.valid_from))) * 12) +
         EXTRACT(MONTH FROM AGE(COALESCE(ae.termination_date, '2026-05-27'::DATE), MIN(emp.valid_from))) AS tenure_months,
        CASE WHEN ae.employee_id IS NOT NULL THEN 1 ELSE 0 END AS has_terminated
    FROM dim_employee_history emp
    LEFT JOIN employee_attrition_events ae ON emp.employee_id = ae.employee_id
    GROUP BY emp.employee_id, emp.role_family, emp.location, emp.department, ae.employee_id, ae.termination_date
)
SELECT 
    role_family,
    location,
    COUNT(employee_id) AS total_headcount,
    SUM(has_terminated) AS total_attrition,
    AVG(tenure_months)::DECIMAL(5,2) AS average_tenure_months,
    -- Attrition Rate by Cut
    CASE WHEN COUNT(employee_id) = 0 THEN 0 ELSE (SUM(has_terminated)::double precision / COUNT(employee_id)) END::DECIMAL(5,4) AS historical_attrition_rate
FROM employee_lifecycle
GROUP BY role_family, location;
