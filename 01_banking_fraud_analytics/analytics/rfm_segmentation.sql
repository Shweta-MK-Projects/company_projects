-- SQL Script for RFM (Recency, Frequency, Monetary) Customer Segmentation
-- Grouping customer accounts into 7 actionable cohorts.

CREATE OR REPLACE VIEW view_customer_rfm_cohorts AS
WITH customer_txn_timeline AS (
    -- Get base variables for RFM: Max transaction timestamp, count of transactions, total volume
    SELECT 
        c.customer_id,
        MAX(t.transaction_timestamp) AS last_txn_date,
        COUNT(t.transaction_id) AS transaction_frequency,
        COALESCE(SUM(t.amount), 0) AS total_monetary_value,
        -- Reference timestamp for Recency calculation (assume current analysis date is 2026-05-27)
        '2026-05-27 23:59:59'::TIMESTAMP AS analysis_anchor_date
    FROM customers c
    LEFT JOIN accounts a ON c.customer_id = a.customer_id
    LEFT JOIN cards card ON a.account_id = card.account_id
    LEFT JOIN transactions t ON card.card_id = t.card_id AND t.response_code = '00' -- successful txns only
    GROUP BY c.customer_id
),
rfm_base_metrics AS (
    -- Calculate Recency in days
    SELECT 
        customer_id,
        EXTRACT(DAY FROM (analysis_anchor_date - last_txn_date)) AS recency_days,
        transaction_frequency,
        total_monetary_value
    FROM customer_txn_timeline
),
rfm_scores AS (
    -- Score Recency, Frequency, and Monetary on a scale of 1 to 5 using NTILE
    -- For Recency: lower days is better (gives higher score)
    SELECT 
        customer_id,
        recency_days,
        transaction_frequency,
        total_monetary_value,
        NTILE(5) OVER(ORDER BY recency_days ASC) AS r_score_raw, -- 1 is far, 5 is recent
        NTILE(5) OVER(ORDER BY transaction_frequency DESC) AS f_score, -- 5 is high frequency
        NTILE(5) OVER(ORDER BY total_monetary_value DESC) AS m_score -- 5 is high monetary volume
    FROM rfm_base_metrics
),
rfm_scores_adjusted AS (
    -- Recency NTILE is ordered ASC, so 1 is most recent. Let's invert it: 5 is most recent, 1 is oldest.
    SELECT 
        customer_id,
        recency_days,
        transaction_frequency,
        total_monetary_value,
        (6 - r_score_raw) AS r_score,
        f_score,
        m_score
    FROM rfm_scores
),
rfm_combined AS (
    -- Combine scores into an index
    SELECT 
        customer_id,
        recency_days,
        transaction_frequency,
        total_monetary_value,
        r_score,
        f_score,
        m_score,
        (r_score * 100 + f_score * 10 + m_score) AS rfm_index,
        (r_score + f_score + m_score) / 3.0 AS rfm_average_score
    FROM rfm_scores_adjusted
)
-- Segment into 7 Cohorts based on scores
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    rfm.recency_days,
    rfm.transaction_frequency,
    rfm.total_monetary_value,
    rfm.r_score,
    rfm.f_score,
    rfm.m_score,
    rfm.rfm_index,
    CASE 
        -- 1. Champions: Recent, frequent, and high spending
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        
        -- 2. Loyalists: Spend regularly, responsive to promotions
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyalists'
        
        -- 3. Promising: Recent transactions, but not frequent yet
        WHEN r_score >= 4 AND f_score < 3 THEN 'Promising New'
        
        -- 4. Potential Loyalists: Average recency & frequency, good spending
        WHEN r_score >= 3 AND f_score >= 3 AND m_score < 3 THEN 'Potential Loyalists'
        
        -- 5. At Risk: Haven't transacted recently, but spent a lot and frequently before
        WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'At Risk (High Value)'
        
        -- 6. Needs Attention: Below average recency, frequency, and monetary scores
        WHEN r_score <= 2 AND f_score <= 2 AND m_score >= 3 THEN 'Needs Attention'
        
        -- 7. Hibernating / Dormant: Out of touch, low transaction count, low volume
        ELSE 'Hibernating / Dormant'
    END AS customer_rfm_cohort
FROM rfm_combined rfm
JOIN customers c ON rfm.customer_id = c.customer_id;
