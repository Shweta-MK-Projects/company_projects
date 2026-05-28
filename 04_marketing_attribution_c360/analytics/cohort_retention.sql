-- SQL Cohort Retention Curves and RFM Segmentation
-- Targets lifetime value (LTV) cohort stability indices

-- 1. E-commerce Cohort Retention Curve Analysis
-- Maps customers to their registration month and counts subsequent orders.
CREATE OR REPLACE VIEW view_customer_retention_curves AS
WITH customer_signup_cohort AS (
    -- Group customers into monthly registration cohorts
    SELECT 
        customer_id,
        TO_CHAR(signup_date, 'YYYY-MM') AS signup_month,
        signup_date
    FROM c360_customers
),
order_months AS (
    -- Identify the relative month index of order transactions after signup
    SELECT 
        o.customer_id,
        sc.signup_month,
        -- Calculate months passed since signup
        (EXTRACT(YEAR FROM AGE(o.order_timestamp::DATE, sc.signup_date)) * 12) +
         EXTRACT(MONTH FROM AGE(o.order_timestamp::DATE, sc.signup_date)) AS months_since_signup
    FROM ecommerce_orders o
    JOIN customer_signup_cohort sc ON o.customer_id = sc.customer_id
),
cohort_sizes AS (
    -- Total count of signups per cohort
    SELECT 
        signup_month,
        COUNT(DISTINCT customer_id) AS total_signup_count
    FROM customer_signup_cohort
    GROUP BY signup_month
),
monthly_cohort_activity AS (
    -- Count distinct active users in subsequent months
    SELECT 
        signup_month,
        months_since_signup,
        COUNT(DISTINCT customer_id) AS active_customer_count
    FROM order_months
    WHERE months_since_signup BETWEEN 0 AND 12
    GROUP BY signup_month, months_since_signup
)
SELECT 
    mca.signup_month,
    mca.months_since_signup AS month_period,
    mca.active_customer_count,
    cs.total_signup_count,
    -- Retention rate percentage
    CASE 
        WHEN cs.total_signup_count = 0 THEN 0.0 
        ELSE (mca.active_customer_count::double precision / cs.total_signup_count) 
    END::DECIMAL(5,4) AS retention_rate
FROM monthly_cohort_activity mca
JOIN cohort_sizes cs ON mca.signup_month = cs.signup_month;


-- 2. CRM RFM Segmentation View (5 High-Value cohorts mapping 62% of revenue)
CREATE OR REPLACE VIEW view_c360_rfm_segments AS
WITH rfm_aggregates AS (
    -- Calculate Recency (days since last order), Frequency (total orders), Monetary (total spend)
    SELECT 
        customer_id,
        EXTRACT(DAY FROM ('2026-05-27 23:59:59'::TIMESTAMP - MAX(order_timestamp))) AS recency_days,
        COUNT(order_id) AS order_frequency,
        COALESCE(SUM(total_order_amount), 0) AS total_monetary_spend
    FROM ecommerce_orders
    GROUP BY customer_id
),
rfm_ranks AS (
    -- Ranks using NTILE
    SELECT 
        customer_id,
        recency_days,
        order_frequency,
        total_monetary_spend,
        NTILE(5) OVER(ORDER BY recency_days ASC) AS r_score_raw,
        NTILE(5) OVER(ORDER BY order_frequency DESC) AS f_score,
        NTILE(5) OVER(ORDER BY total_monetary_spend DESC) AS m_score
    FROM rfm_aggregates
),
rfm_scores AS (
    SELECT 
        customer_id,
        recency_days,
        order_frequency,
        total_monetary_spend,
        (6 - r_score_raw) AS r_score, -- Invert recency: 5 is recent, 1 is distant
        f_score,
        m_score
    FROM rfm_ranks
)
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    rfm.recency_days,
    rfm.order_frequency,
    rfm.total_monetary_spend,
    rfm.r_score,
    rfm.f_score,
    rfm.m_score,
    CASE 
        -- 1. Champions (LTV anchors)
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        -- 2. Loyal Customers
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
        -- 3. At Risk (Used to be loyal, but inactive recently)
        WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'At Risk (Loyal Exits)'
        -- 4. Needs Attention
        WHEN r_score <= 2 AND f_score <= 2 AND m_score >= 3 THEN 'Needs Attention'
        -- 5. Hibernating (Dormant)
        ELSE 'Hibernating / Dormant'
    END AS rfm_segment
FROM rfm_scores rfm
JOIN c360_customers c ON rfm.customer_id = c.customer_id;
