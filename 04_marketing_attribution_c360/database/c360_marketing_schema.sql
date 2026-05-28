-- DDL for Multi-Touch Marketing Attribution & Customer 360 Database
-- Architecture: Customer-centric Unified Schema
-- Target RDBMS: PostgreSQL or SQL Server

-- 1. Unified Customer Profile (CRM Base)
CREATE TABLE c360_customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    signup_date DATE NOT NULL,
    gender VARCHAR(10),
    age INT,
    preferred_language VARCHAR(20) DEFAULT 'English',
    acquisition_channel VARCHAR(30), -- Organic, Paid Search, Referral
    lifetime_value DECIMAL(15, 2) DEFAULT 0.00
);

-- 2. Marketing Channels Definition
CREATE TABLE marketing_channels (
    channel_id INT PRIMARY KEY,
    channel_name VARCHAR(50) UNIQUE NOT NULL, -- e.g., Google Ads, Facebook Ads, Email, Direct, Organic Search
    medium VARCHAR(20) NOT NULL, -- Paid Search, Paid Social, Email, SEO, None
    cost_per_click DECIMAL(8, 4) NOT NULL DEFAULT 0.00
);

-- 3. Customer Digital Touchpoint Logs (Clickstream / Funnel Steps)
CREATE TABLE customer_touchpoints (
    touchpoint_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) REFERENCES c360_customers(customer_id) ON DELETE CASCADE,
    channel_id INT REFERENCES marketing_channels(channel_id),
    session_id VARCHAR(50) NOT NULL,
    touchpoint_timestamp TIMESTAMP NOT NULL,
    utm_source VARCHAR(50),
    utm_medium VARCHAR(50),
    utm_campaign VARCHAR(100),
    landing_page VARCHAR(255),
    device_category VARCHAR(20), -- Mobile, Desktop, Tablet
    duration_seconds INT
);

-- 4. E-commerce Transaction Facts (Orders)
CREATE TABLE ecommerce_orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) REFERENCES c360_customers(customer_id) ON DELETE CASCADE,
    session_id VARCHAR(50),
    order_timestamp TIMESTAMP NOT NULL,
    subtotal_amount DECIMAL(12, 2) NOT NULL,
    tax_amount DECIMAL(10, 2) DEFAULT 0.00,
    discount_amount DECIMAL(10, 2) DEFAULT 0.00,
    total_order_amount DECIMAL(12, 2) NOT NULL, -- final price paid
    payment_method VARCHAR(30) -- Credit Card, UPI, PayPal, NetBanking
);

-- 5. Customer Support Tickets (Engagement logs)
CREATE TABLE customer_support_tickets (
    ticket_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) REFERENCES c360_customers(customer_id) ON DELETE CASCADE,
    created_timestamp TIMESTAMP NOT NULL,
    issue_category VARCHAR(50) NOT NULL, -- Delivery, Payment, Refund, Account
    ticket_status VARCHAR(20) DEFAULT 'Open', -- Open, In Progress, Resolved
    customer_sentiment_rating INT CHECK (customer_sentiment_rating BETWEEN 1 AND 5)
);


-- --- INDEXING STRATEGY FOR FASTER PATH AND FUNNEL ANALYSIS ---

-- Index on touchpoint timestamps to optimize funnel sequence calculations
CREATE INDEX idx_touchpoint_chronology ON customer_touchpoints(customer_id, touchpoint_timestamp ASC);

-- Index on channel cost parameters
CREATE INDEX idx_touchpoint_channel ON customer_touchpoints(channel_id);

-- Index on order dates and values
CREATE INDEX idx_orders_timestamp ON ecommerce_orders(order_timestamp);
CREATE INDEX idx_orders_customer ON ecommerce_orders(customer_id);
