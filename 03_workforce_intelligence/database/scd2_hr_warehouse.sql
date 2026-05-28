-- DDL for Workforce Intelligence HR Data Warehouse
-- Architecture: Slowly Changing Dimension (SCD Type 2) history tracking
-- Target RDBMS: PostgreSQL or SQL Server

-- 1. Base Employees Dimension (SCD Type 2 Tracker)
CREATE TABLE dim_employee_history (
    employee_key SERIAL PRIMARY KEY,
    employee_id VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    department VARCHAR(50) NOT NULL,
    role_family VARCHAR(50) NOT NULL, -- e.g., Engineering, Sales, HR
    job_level VARCHAR(10) NOT NULL, -- e.g., L1, L2, L3, L4
    manager_employee_id VARCHAR(50),
    location VARCHAR(100) NOT NULL,
    compensation_band_percentile DECIMAL(5, 2) NOT NULL, -- 0.00 to 100.00
    engagement_score INT, -- 1 to 5
    
    -- SCD Type 2 Attributes
    valid_from DATE NOT NULL,
    valid_to DATE,
    is_current BOOLEAN DEFAULT TRUE,
    change_reason VARCHAR(100) -- Promotion, Transfer, Salary Revision, Manager Shift
);

-- 2. Daily HR Snapshot Fact (Workforce Health Logs)
CREATE TABLE fact_employee_status_daily (
    snapshot_key BIGSERIAL PRIMARY KEY,
    date_key INT NOT NULL, -- references dim_date calendar
    employee_key INT REFERENCES dim_employee_history(employee_key),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    training_hours_completed DECIMAL(5, 2) DEFAULT 0.00,
    tenure_days INT NOT NULL,
    promotion_lag_months INT NOT NULL DEFAULT 0,
    performance_score INT -- 1 to 5
);

-- 3. Attrition Logs Table (Target Labels)
CREATE TABLE employee_attrition_events (
    attrition_id SERIAL PRIMARY KEY,
    employee_id VARCHAR(50) NOT NULL,
    termination_date DATE NOT NULL,
    attrition_type VARCHAR(30) NOT NULL, -- Voluntary, Involuntary
    primary_reason VARCHAR(100), -- Compensation, Manager relations, Career growth, Relocation
    exit_interview_satisfaction_score INT -- 1 to 5
);


-- --- INDEXES FOR TEMPORAL AND SCD TYPE 2 QUERY PERFORMANCE ---

-- Index on SCD temporal columns to speed up point-in-time joins
CREATE INDEX idx_emp_history_scd_temporal ON dim_employee_history(employee_id, valid_from, valid_to);
CREATE INDEX idx_emp_history_is_current ON dim_employee_history(employee_id) WHERE is_current = TRUE;

-- Index on daily snapshots
CREATE INDEX idx_hr_daily_emp_key ON fact_employee_status_daily(employee_key);


-- --- SCD TYPE 2 INSERT/UPDATE LOGIC IN SQL (DEMONSTRATION QUERY) ---

-- Procedure pattern to record an employee's career shift (e.g. Promotion)
-- 1. Invalidate old active record
-- 2. Insert new record with valid_from starting today
CREATE OR REPLACE PROCEDURE pr_process_employee_role_change(
    p_employee_id VARCHAR,
    p_first_name VARCHAR,
    p_last_name VARCHAR,
    p_email VARCHAR,
    p_department VARCHAR,
    p_role_family VARCHAR,
    p_job_level VARCHAR,
    p_manager_id VARCHAR,
    p_location VARCHAR,
    p_compensation DECIMAL,
    p_engagement INT,
    p_change_reason VARCHAR,
    p_effective_date DATE
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Step A: Invalidate the current active row for the employee
    UPDATE dim_employee_history
    SET 
        valid_to = p_effective_date - INTERVAL '1 day',
        is_current = FALSE
    WHERE employee_id = p_employee_id 
      AND is_current = TRUE;

    -- Step B: Insert the new active record
    INSERT INTO dim_employee_history (
        employee_id, first_name, last_name, email, department, role_family, 
        job_level, manager_employee_id, location, compensation_band_percentile, 
        engagement_score, valid_from, valid_to, is_current, change_reason
    ) VALUES (
        p_employee_id, p_first_name, p_last_name, p_email, p_department, p_role_family,
        p_job_level, p_manager_id, p_location, p_compensation, p_engagement,
        p_effective_date, NULL, TRUE, p_change_reason
    );
END;
$$;
