-- DDL for Retail Demand Forecasting & Inventory Optimization Data Warehouse
-- Architecture: Star Schema (optimized for analytical querying)
-- Target RDBMS: PostgreSQL or SQL Server

-- --- DIMENSION TABLES ---

-- 1. SKU Dimension (Products)
CREATE TABLE dim_sku (
    sku_key SERIAL PRIMARY KEY,
    sku_id VARCHAR(50) UNIQUE NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    sub_category VARCHAR(50),
    brand VARCHAR(50),
    unit_cost DECIMAL(10, 2) NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    reorder_point INT NOT NULL DEFAULT 50,
    safety_stock_level INT NOT NULL DEFAULT 20,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Store Dimension (Locations)
CREATE TABLE dim_store (
    store_key SERIAL PRIMARY KEY,
    store_id VARCHAR(50) UNIQUE NOT NULL,
    store_name VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    region VARCHAR(30) NOT NULL, -- North, South, East, West
    store_type VARCHAR(30) NOT NULL, -- Supermarket, Express, Hypermarket
    floor_size_sqft INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Supplier Dimension
CREATE TABLE dim_supplier (
    supplier_key SERIAL PRIMARY KEY,
    supplier_id VARCHAR(50) UNIQUE NOT NULL,
    supplier_name VARCHAR(100) NOT NULL,
    contact_email VARCHAR(100),
    lead_time_days INT NOT NULL, -- Supplier shipping delay
    reliability_score DECIMAL(3, 2) NOT NULL DEFAULT 1.00 -- Range: 0.00 to 1.00
);

-- 4. Date Dimension
CREATE TABLE dim_date (
    date_key INT PRIMARY KEY, -- format YYYYMMDD
    full_date DATE UNIQUE NOT NULL,
    day_of_week INT NOT NULL,
    day_name VARCHAR(15) NOT NULL,
    day_of_month INT NOT NULL,
    month_number INT NOT NULL,
    month_name VARCHAR(15) NOT NULL,
    quarter INT NOT NULL,
    year INT NOT NULL,
    is_weekend BOOLEAN NOT NULL,
    is_holiday BOOLEAN NOT NULL,
    holiday_name VARCHAR(50)
);

-- 5. Weather Dimension
CREATE TABLE dim_weather (
    weather_key SERIAL PRIMARY KEY,
    date_key INT REFERENCES dim_date(date_key),
    region VARCHAR(30) NOT NULL,
    avg_temperature_c DECIMAL(4, 1),
    precipitation_mm DECIMAL(5, 2),
    weather_condition VARCHAR(50) -- Sunny, Rainy, Snow, Overcast
);


-- --- FACT TABLES ---

-- 6. Sales Fact Table
CREATE TABLE fact_sales (
    sales_key BIGSERIAL PRIMARY KEY,
    date_key INT REFERENCES dim_date(date_key),
    sku_key INT REFERENCES dim_sku(sku_key),
    store_key INT REFERENCES dim_store(store_key),
    supplier_key INT REFERENCES dim_supplier(supplier_key),
    quantity_sold INT NOT NULL,
    unit_selling_price DECIMAL(10, 2) NOT NULL,
    discount_applied DECIMAL(10, 2) DEFAULT 0.00,
    gross_revenue DECIMAL(12, 2) GENERATED ALWAYS AS (quantity_sold * unit_selling_price) STORED,
    net_revenue DECIMAL(12, 2) GENERATED ALWAYS AS ((quantity_sold * unit_selling_price) - discount_applied) STORED,
    is_promotion_active BOOLEAN DEFAULT FALSE,
    competitor_price DECIMAL(10, 2)
);

-- 7. Inventory Fact Table (Daily Snapshots)
CREATE TABLE fact_inventory (
    inventory_key BIGSERIAL PRIMARY KEY,
    date_key INT REFERENCES dim_date(date_key),
    sku_key INT REFERENCES dim_sku(sku_key),
    store_key INT REFERENCES dim_store(store_key),
    stock_on_hand INT NOT NULL,
    stock_in_transit INT NOT NULL DEFAULT 0,
    allocated_stock INT NOT NULL DEFAULT 0,
    stock_out_flag BOOLEAN DEFAULT FALSE,
    days_out_of_stock INT DEFAULT 0
);


-- --- INDEXING STRATEGY FOR DATA WAREHOUSE PERFORMANCE ---

-- Fact Sales queries are heavily partitioned by dates, stores, and SKUs
CREATE INDEX idx_fact_sales_date ON fact_sales(date_key);
CREATE INDEX idx_fact_sales_sku ON fact_sales(sku_key);
CREATE INDEX idx_fact_sales_store ON fact_sales(store_key);
CREATE INDEX idx_fact_sales_composite ON fact_sales(date_key, store_key, sku_key);

-- Fact Inventory daily tracking index
CREATE INDEX idx_fact_inventory_composite ON fact_inventory(date_key, store_key, sku_key);

-- Dimensions are small but queried frequently via keys
CREATE INDEX idx_dim_sku_id ON dim_sku(sku_id);
CREATE INDEX idx_dim_store_id ON dim_store(store_id);
