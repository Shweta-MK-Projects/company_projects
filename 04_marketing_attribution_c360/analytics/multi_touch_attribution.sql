-- SQL Multi-Touch Marketing Attribution Models
-- Implements First-Touch, Last-Touch, Linear, and Time-Decay (7-day half-life) models via CTEs and Window Functions

-- View analyzing touchpoints leading to conversion orders
CREATE OR REPLACE VIEW view_marketing_attribution_models AS
WITH order_conversions AS (
    -- Fetch conversion events (Ecommerce orders)
    SELECT 
        order_id,
        customer_id,
        order_timestamp,
        total_order_amount
    FROM ecommerce_orders
),
relevant_touchpoints AS (
    -- Find all marketing touchpoints occurring BEFORE the order conversion date (within a 30-day window)
    SELECT 
        oc.order_id,
        oc.customer_id,
        oc.order_timestamp,
        oc.total_order_amount,
        ct.channel_id,
        mc.channel_name,
        ct.touchpoint_timestamp,
        -- Sequence number from first to last
        ROW_NUMBER() OVER(
            PARTITION BY oc.order_id 
            ORDER BY ct.touchpoint_timestamp ASC
        ) AS touch_sequence_asc,
        -- Sequence number from last to first
        ROW_NUMBER() OVER(
            PARTITION BY oc.order_id 
            ORDER BY ct.touchpoint_timestamp DESC
        ) AS touch_sequence_desc,
        -- Count total touchpoints prior to order
        COUNT(ct.touchpoint_id) OVER(
            PARTITION BY oc.order_id
        ) AS total_touchpoints
    FROM order_conversions oc
    JOIN customer_touchpoints ct ON oc.customer_id = ct.customer_id
    JOIN marketing_channels mc ON ct.channel_id = mc.channel_id
    WHERE ct.touchpoint_timestamp <= oc.order_timestamp
      AND ct.touchpoint_timestamp >= oc.order_timestamp - INTERVAL '30 days'
),
attribution_weights AS (
    -- Calculate attribution weights for each model
    SELECT 
        order_id,
        channel_name,
        total_order_amount,
        total_touchpoints,
        
        -- 1. First-Touch Model: 100% credit to the initial touchpoint
        CASE WHEN touch_sequence_asc = 1 THEN 1.0 ELSE 0.0 END AS weight_first_touch,
        
        -- 2. Last-Touch Model: 100% credit to the final touchpoint prior to checkout
        CASE WHEN touch_sequence_desc = 1 THEN 1.0 ELSE 0.0 END AS weight_last_touch,
        
        -- 3. Linear Model: Equal division of credit across all touchpoints
        (1.0 / total_touchpoints) AS weight_linear,
        
        -- 4. Time-Decay Model: Exponential decay with a 7-day half-life
        -- Weight = 2 ^ (-DaysSinceTouchpoint / 7)
        -- We calculate relative decay weights and will normalize them in the next step
        EXP( -LN(2) * (EXTRACT(EPOCH FROM (order_timestamp - touchpoint_timestamp)) / 604800.0) ) AS raw_decay_weight
    FROM relevant_touchpoints
),
decay_normalizer AS (
    -- Sum the raw decay weights per order to normalize them to sum to 1.0
    SELECT 
        order_id,
        SUM(raw_decay_weight) AS sum_raw_decay_weights
    FROM attribution_weights
    GROUP BY order_id
),
final_normalized_weights AS (
    -- Merge back decay sums to normalize decay models
    SELECT 
        aw.order_id,
        aw.channel_name,
        aw.total_order_amount,
        aw.weight_first_touch,
        aw.weight_last_touch,
        aw.weight_linear,
        -- Normalized Time-Decay weight: raw / sum
        CASE 
            WHEN dn.sum_raw_decay_weights = 0 THEN 0.0
            ELSE aw.raw_decay_weight / dn.sum_raw_decay_weights 
        END AS weight_time_decay
    FROM attribution_weights aw
    JOIN decay_normalizer dn ON aw.order_id = dn.order_id
)
-- Aggregate credited revenues at the Channel level for comparison
SELECT 
    channel_name,
    -- First Touch Revenue
    SUM(weight_first_touch * total_order_amount)::DECIMAL(15,2) AS revenue_first_touch,
    -- Last Touch Revenue
    SUM(weight_last_touch * total_order_amount)::DECIMAL(15,2) AS revenue_last_touch,
    -- Linear Revenue
    SUM(weight_linear * total_order_amount)::DECIMAL(15,2) AS revenue_linear,
    -- Time-Decay Revenue
    SUM(weight_time_decay * total_order_amount)::DECIMAL(15,2) AS revenue_time_decay
FROM final_normalized_weights
GROUP BY channel_name;
