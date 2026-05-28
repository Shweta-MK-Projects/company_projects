-- SQL Analytics & Customer-360 view construction
-- Leverage Recursive CTEs, Window Functions, and Partitioned Aggregations

-- 1. Recursive CTE: Detect Circular Money Transfer Networks (Money Mule Detection)
-- Traces transfer relationships across multiple hops (up to 5 levels) to detect loops.
CREATE OR REPLACE VIEW view_circular_transfer_loops AS
WITH RECURSIVE transfer_path AS (
    -- Anchor member: Initial transaction transfers between accounts
    SELECT 
        t.account_id AS source_account,
        c.account_id AS destination_account,
        t.transaction_timestamp AS initial_time,
        t.amount,
        1 AS path_depth,
        ARRAY[t.account_id::text, c.account_id::text] AS path_route,
        FALSE AS is_loop
    FROM transactions t
    JOIN cards card ON t.card_id = card.card_id
    JOIN accounts c ON t.terminal_id = c.account_id -- assuming P2P transfer destination is mapped to terminal_id for this flow
    WHERE t.transaction_type = 'Transfer'
      AND t.response_code = '00'

    UNION ALL

    -- Recursive member: Add hops to the path
    SELECT 
        tp.source_account,
        next_t.account_id AS destination_account,
        next_t.transaction_timestamp,
        next_t.amount,
        tp.path_depth + 1,
        tp.path_route || next_t.account_id::text,
        (next_t.account_id = tp.source_account) AS is_loop
    FROM transfer_path tp
    JOIN transactions next_t ON tp.destination_account = next_t.account_id
    WHERE next_t.transaction_type = 'Transfer'
      AND next_t.response_code = '00'
      AND next_t.transaction_timestamp > tp.initial_time
      -- Limit transaction search to a 24-hour window from the start of the chain
      AND next_t.transaction_timestamp <= tp.initial_time + INTERVAL '24 hours'
      AND tp.path_depth < 5
      AND tp.is_loop = FALSE
)
SELECT 
    source_account,
    destination_account,
    initial_time,
    amount,
    path_depth,
    path_route,
    is_loop
FROM transfer_path
WHERE is_loop = TRUE;


-- 2. Customer 360 View: Aggregate Customer Profile and Behavior Metrics
-- Combines window functions to derive transaction habits, velocity statistics, and risk-tier segmentation.
CREATE OR REPLACE VIEW view_customer_360 AS
WITH customer_txn_stats AS (
    SELECT 
        c.customer_id,
        a.account_id,
        card.card_id,
        t.transaction_id,
        t.amount,
        t.transaction_timestamp,
        t.is_fraud,
        t.response_code,
        term.is_high_risk_flag,
        -- Window function to calculate running customer transaction average (last 10 txns)
        AVG(t.amount) OVER(
            PARTITION BY c.customer_id 
            ORDER BY t.transaction_timestamp 
            ROWS BETWEEN 9 PRECEDING AND CURRENT ROW
        ) AS avg_amount_last_10_txns,
        -- Lead and Lag to compute time difference between successive transactions (velocity checks)
        LAG(t.transaction_timestamp) OVER(
            PARTITION BY card.card_id 
            ORDER BY t.transaction_timestamp
        ) AS prev_txn_timestamp,
        LAG(term.latitude) OVER(
            PARTITION BY card.card_id 
            ORDER BY t.transaction_timestamp
        ) AS prev_txn_lat,
        LAG(term.longitude) OVER(
            PARTITION BY card.card_id 
            ORDER BY t.transaction_timestamp
        ) AS prev_txn_lon,
        -- Window function to get ranking of transactions by amount for each customer
        ROW_NUMBER() OVER(
            PARTITION BY c.customer_id 
            ORDER BY t.amount DESC
        ) AS txn_rank_by_amount
    FROM customers c
    JOIN accounts a ON c.customer_id = a.customer_id
    LEFT JOIN cards card ON a.account_id = card.account_id
    LEFT JOIN transactions t ON card.card_id = t.card_id
    LEFT JOIN terminals term ON t.terminal_id = term.terminal_id
),
customer_aggregates AS (
    SELECT 
        customer_id,
        COUNT(transaction_id) AS total_transactions_count,
        COALESCE(SUM(amount), 0) AS total_transaction_volume,
        COALESCE(AVG(amount), 0) AS avg_transaction_amount,
        COALESCE(STDDEV(amount), 0) AS stddev_transaction_amount,
        COUNT(CASE WHEN is_fraud = TRUE THEN 1 END) AS total_fraud_incidents,
        COUNT(CASE WHEN response_code = '51' THEN 1 END) AS total_nsf_declines, -- Insufficient Funds
        COUNT(CASE WHEN is_high_risk_flag = TRUE THEN 1 END) AS transactions_at_high_risk_merchants,
        -- RFM style cohort segmentation: Division into deciles using NTILE
        NTILE(5) OVER(ORDER BY COALESCE(SUM(amount), 0) DESC) AS customer_monetary_quintile
    FROM customer_txn_stats
    GROUP BY customer_id
)
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.risk_score_segment,
    c.created_at AS member_since,
    agg.total_transactions_count,
    agg.total_transaction_volume,
    agg.avg_transaction_amount,
    agg.stddev_transaction_amount,
    agg.total_fraud_incidents,
    agg.total_nsf_declines,
    agg.transactions_at_high_risk_merchants,
    agg.customer_monetary_quintile,
    -- Label customer value segments based on quintiles
    CASE 
        WHEN agg.customer_monetary_quintile = 1 THEN 'Tier 1 - High Value'
        WHEN agg.customer_monetary_quintile = 2 THEN 'Tier 2 - Medium-High Value'
        WHEN agg.customer_monetary_quintile = 3 THEN 'Tier 3 - Medium Value'
        ELSE 'Tier 4 - Standard Value'
    END AS customer_value_segment
FROM customers c
JOIN customer_aggregates agg ON c.customer_id = agg.customer_id;
