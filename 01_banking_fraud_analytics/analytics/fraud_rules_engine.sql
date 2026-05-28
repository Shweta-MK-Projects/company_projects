-- SQL Rules-Based Fraud Detection Engine
-- Incorporates transaction velocity, geo-anomalies (Haversine distance), and amount Z-scores.

CREATE OR REPLACE VIEW view_fraud_rule_violations AS
WITH transaction_lags AS (
    -- Fetch current and previous transaction info for comparison
    SELECT 
        t.transaction_id,
        t.card_id,
        t.amount,
        t.transaction_timestamp,
        t.ip_address,
        t.channel,
        term.latitude AS current_lat,
        term.longitude AS current_lon,
        term.merchant_category_code,
        term.is_high_risk_flag,
        
        -- Lagged values for velocity and distance calculations
        LAG(t.transaction_timestamp) OVER(PARTITION BY t.card_id ORDER BY t.transaction_timestamp) AS prev_timestamp,
        LAG(term.latitude) OVER(PARTITION BY t.card_id ORDER BY t.transaction_timestamp) AS prev_lat,
        LAG(term.longitude) OVER(PARTITION BY t.card_id ORDER BY t.transaction_timestamp) AS prev_lon,
        
        -- Historical metrics for Z-score calculation
        AVG(t.amount) OVER(
            PARTITION BY t.card_id 
            ORDER BY t.transaction_timestamp 
            RANGE BETWEEN INTERVAL '30 days' PRECEDING AND INTERVAL '1 second' PRECEDING
        ) AS avg_amount_30d,
        COALESCE(STDDEV(t.amount) OVER(
            PARTITION BY t.card_id 
            ORDER BY t.transaction_timestamp 
            RANGE BETWEEN INTERVAL '30 days' PRECEDING AND INTERVAL '1 second' PRECEDING
        ), 1.0) AS stddev_amount_30d
    FROM transactions t
    JOIN terminals term ON t.terminal_id = term.terminal_id
),
rule_evaluations AS (
    SELECT 
        transaction_id,
        card_id,
        amount,
        transaction_timestamp,
        
        -- Rule 1: High Transaction Velocity (Frequency)
        -- Checks if the user performed more than 3 transactions in the last 15 minutes
        COUNT(transaction_id) OVER(
            PARTITION BY card_id 
            ORDER BY transaction_timestamp 
            RANGE BETWEEN INTERVAL '15 minutes' PRECEDING AND CURRENT ROW
        ) AS txns_last_15_mins,
        
        -- Rule 2: Amount Z-Score
        -- Calculates how many standard deviations the transaction is from the historical average
        CASE 
            WHEN avg_amount_30d IS NOT NULL AND stddev_amount_30d > 0 
            THEN (amount - avg_amount_30d) / stddev_amount_30d
            ELSE 0 
        END AS amount_z_score,

        -- Rule 3: Geographic Impossibility (Speed Check using Haversine formula approximation)
        -- Haversine formula approximation: 3959 * acos(cos(radians(lat1)) * cos(radians(lat2)) * cos(radians(lon2) - radians(lon1)) + sin(radians(lat1)) * sin(radians(lat2)))
        -- We estimate speed in miles per hour. If speed > 600 mph (flight speed limits), it's physically anomalous.
        CASE 
            WHEN prev_timestamp IS NOT NULL AND current_lat IS NOT NULL AND prev_lat IS NOT NULL
                 AND (EXTRACT(EPOCH FROM (transaction_timestamp - prev_timestamp)) / 60.0) > 0 -- avoid division by zero
            THEN (
                3959 * acos(
                    LEAST(1.0, GREATEST(-1.0, 
                        cos(radians(prev_lat)) * cos(radians(current_lat)) * 
                        cos(radians(current_lon) - radians(prev_lon)) + 
                        sin(radians(prev_lat)) * sin(radians(current_lat))
                    ))
                )
            ) / (EXTRACT(EPOCH FROM (transaction_timestamp - prev_timestamp)) / 3600.0) -- Distance divided by Hours
            ELSE 0 
        END AS implied_speed_mph,
        
        EXTRACT(EPOCH FROM (transaction_timestamp - prev_timestamp)) AS seconds_since_prev_txn,
        is_high_risk_flag
    FROM transaction_lags
)
SELECT 
    transaction_id,
    card_id,
    amount,
    transaction_timestamp,
    txns_last_15_mins,
    amount_z_score,
    implied_speed_mph,
    is_high_risk_flag,
    
    -- Risk Rules Logic Compilation
    CASE WHEN txns_last_15_mins > 3 THEN 1 ELSE 0 END AS rule_velocity_violated,
    CASE WHEN amount_z_score > 3.0 THEN 1 ELSE 0 END AS rule_zscore_violated,
    CASE WHEN implied_speed_mph > 600.0 AND seconds_since_prev_txn < 7200 THEN 1 ELSE 0 END AS rule_geo_impossible_violated,
    CASE WHEN is_high_risk_flag = TRUE AND amount > 50000.0 THEN 1 ELSE 0 END AS rule_high_risk_merchant_violated,
    
    -- Final aggregated fraud risk score (percentage scale: 0-100)
    (
        (CASE WHEN txns_last_15_mins > 3 THEN 25 ELSE 0 END) +
        (CASE WHEN amount_z_score > 3.0 THEN 30 ELSE 0 END) +
        (CASE WHEN implied_speed_mph > 600.0 AND seconds_since_prev_txn < 7200 THEN 35 ELSE 0 END) +
        (CASE WHEN is_high_risk_flag = TRUE AND amount > 50000.0 THEN 10 ELSE 0 END)
    )::DECIMAL(5,2) AS combined_risk_score
FROM rule_evaluations;
