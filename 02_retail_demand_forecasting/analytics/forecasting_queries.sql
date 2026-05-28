-- SQL window functions evaluating historical sales trends and demand indices
-- Optimizes historical cuts for ingestion into forecast pipelines

-- 1. Rolling 13-Week Average Sales by Store and SKU
-- Deploys sliding partition windows to evaluate local baseline demand.
CREATE OR REPLACE VIEW view_rolling_weekly_sku_sales AS
WITH weekly_aggregated_sales AS (
    SELECT 
        d.year,
        -- Get ISO week number
        EXTRACT(WEEK FROM d.full_date) AS week_number,
        fs.store_key,
        fs.sku_key,
        SUM(fs.quantity_sold) AS weekly_quantity_sold,
        SUM(fs.net_revenue) AS weekly_net_revenue
    FROM fact_sales fs
    JOIN dim_date d ON fs.date_key = d.date_key
    GROUP BY d.year, EXTRACT(WEEK FROM d.full_date), fs.store_key, fs.sku_key
)
SELECT 
    year,
    week_number,
    store_key,
    sku_key,
    weekly_quantity_sold,
    weekly_net_revenue,
    -- 13-week simple moving average (SMA) of quantities sold
    AVG(weekly_quantity_sold) OVER(
        PARTITION BY store_key, sku_key
        ORDER BY year, week_number
        ROWS BETWEEN 12 PRECEDING AND CURRENT ROW
    ) AS rolling_13_week_avg_qty
FROM weekly_aggregated_sales;


-- 2. Year-over-Year (YoY) and Quarter-over-Quarter (QoQ) Growth Analysis
-- Compares sales metrics across identical calendar periods using LAG window values.
CREATE OR REPLACE VIEW view_retail_growth_performance AS
WITH monthly_sales AS (
    SELECT 
        d.year,
        d.month_number,
        fs.store_key,
        SUM(fs.net_revenue) AS monthly_revenue,
        SUM(fs.quantity_sold) AS monthly_qty
    FROM fact_sales fs
    JOIN dim_date d ON fs.date_key = d.date_key
    GROUP BY d.year, d.month_number, fs.store_key
)
SELECT 
    year,
    month_number,
    store_key,
    monthly_revenue,
    -- Lag of 12 months to fetch prior year revenue
    LAG(monthly_revenue, 12) OVER(
        PARTITION BY store_key 
        ORDER BY year, month_number
    ) AS prior_year_revenue,
    -- Lag of 3 months to fetch prior quarter revenue
    LAG(monthly_revenue, 3) OVER(
        PARTITION BY store_key 
        ORDER BY year, month_number
    ) AS prior_quarter_revenue
FROM monthly_sales;


-- 3. Stockout Risk Diagnostics
-- Identifies critical inventory discrepancies using partition indicators.
CREATE OR REPLACE VIEW view_stockout_risk_warnings AS
SELECT 
    fi.date_key,
    d.full_date,
    fi.store_key,
    s.store_name,
    fi.sku_key,
    p.product_name,
    fi.stock_on_hand,
    p.reorder_point,
    p.safety_stock_level,
    -- Risk status: Red Alert (Below Safety), Warning (Below Reorder Point), Healthy
    CASE 
        WHEN fi.stock_on_hand <= p.safety_stock_level THEN 'CRITICAL: Below Safety Stock'
        WHEN fi.stock_on_hand <= p.reorder_point THEN 'WARNING: Reorder Triggered'
        ELSE 'HEALTHY'
    END AS inventory_health_status
FROM fact_inventory fi
JOIN dim_date d ON fi.date_key = d.date_key
JOIN dim_store s ON fi.store_key = s.store_key
JOIN dim_sku p ON fi.sku_key = p.sku_key
WHERE fi.stock_on_hand <= p.reorder_point;
