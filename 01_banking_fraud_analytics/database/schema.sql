-- DDL Schema for Banking Fraud Detection & Customer Risk Analytics Platform
-- Target RDBMS: PostgreSQL (or standard SQL Server compatible)

-- Enable extension for UUIDs if required
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Customers Table
CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone_number VARCHAR(20),
    dob DATE NOT NULL,
    street_address VARCHAR(150),
    city VARCHAR(100),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50) DEFAULT 'India',
    risk_score_segment VARCHAR(20) DEFAULT 'Low', -- Low, Medium, High
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Customer Accounts Table
CREATE TABLE accounts (
    account_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) REFERENCES customers(customer_id) ON DELETE CASCADE,
    account_type VARCHAR(20) NOT NULL, -- Savings, Current, CreditCard
    balance DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    currency VARCHAR(10) DEFAULT 'INR',
    status VARCHAR(20) DEFAULT 'Active', -- Active, Suspended, Frozen, Closed
    kyc_status VARCHAR(20) DEFAULT 'Verified', -- Verified, Pending, Failed
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Cards Table
CREATE TABLE cards (
    card_id VARCHAR(50) PRIMARY KEY,
    account_id VARCHAR(50) REFERENCES accounts(account_id) ON DELETE CASCADE,
    card_number_masked VARCHAR(20) NOT NULL,
    card_type VARCHAR(20) NOT NULL, -- Debit, Credit
    card_network VARCHAR(20) NOT NULL, -- Visa, Mastercard, RuPay, Amex
    expiry_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'Active', -- Active, Blocked, Expired
    daily_limit DECIMAL(12, 2) DEFAULT 100000.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Merchant Terminals Table
CREATE TABLE terminals (
    terminal_id VARCHAR(50) PRIMARY KEY,
    merchant_name VARCHAR(100) NOT NULL,
    merchant_category_code VARCHAR(10) NOT NULL,
    city VARCHAR(100),
    country VARCHAR(50) DEFAULT 'India',
    latitude DECIMAL(9, 6),
    longitude DECIMAL(9, 6),
    is_high_risk_flag BOOLEAN DEFAULT FALSE
);

-- 5. Transactions Table
CREATE TABLE transactions (
    transaction_id VARCHAR(50) PRIMARY KEY,
    card_id VARCHAR(50) REFERENCES cards(card_id),
    account_id VARCHAR(50) REFERENCES accounts(account_id),
    terminal_id VARCHAR(50) REFERENCES terminals(terminal_id),
    amount DECIMAL(15, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'INR',
    transaction_timestamp TIMESTAMP NOT NULL,
    transaction_type VARCHAR(20) NOT NULL, -- POS, Online, ATM, Transfer
    response_code VARCHAR(5) DEFAULT '00', -- '00' = Success, '51' = Insufficient Funds, etc.
    channel VARCHAR(20) NOT NULL, -- Swipe, Chip-and-PIN, Contactless, CNP (Card Not Present)
    ip_address VARCHAR(45),
    is_fraud BOOLEAN DEFAULT FALSE,
    fraud_label_method VARCHAR(50) -- Rules Engine, Manual Flag, Model Prediction
);

-- 6. Fraud Alerts Table
CREATE TABLE fraud_alerts (
    alert_id SERIAL PRIMARY KEY,
    transaction_id VARCHAR(50) REFERENCES transactions(transaction_id) ON DELETE CASCADE,
    triggered_rules TEXT[], -- List of rules violated
    risk_score DECIMAL(5, 2) NOT NULL, -- calculated z-score or probability percent
    status VARCHAR(20) DEFAULT 'New', -- New, Under Investigation, Confirmed Fraud, False Positive
    assigned_analyst VARCHAR(50),
    resolution_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP
);

-- 7. Account Relationships (For Customer Graph Network / Ownership Webs)
CREATE TABLE account_relationships (
    relationship_id SERIAL PRIMARY KEY,
    source_account_id VARCHAR(50) REFERENCES accounts(account_id),
    destination_account_id VARCHAR(50) REFERENCES accounts(account_id),
    relationship_type VARCHAR(30) NOT NULL, -- Co-owner, Guarantor, TransferRecipient
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- --- INDEXING STRATEGY FOR HIGH-VELOCITY QUERY OPTIMIZATION ---

-- Index on transaction timestamp to optimize chronological queries and sliding time-windows
CREATE INDEX idx_transactions_timestamp ON transactions(transaction_timestamp DESC);

-- Index on transaction amounts to facilitate quick lookup of extreme value thresholds (Z-scores)
CREATE INDEX idx_transactions_amount ON transactions(amount);

-- Index on card_id and account_id for standard customer history aggregations
CREATE INDEX idx_transactions_card_id ON transactions(card_id);
CREATE INDEX idx_transactions_account_id ON transactions(account_id);

-- Composite Index for velocity calculations (Card + Timestamp)
CREATE INDEX idx_card_timestamp_composite ON transactions(card_id, transaction_timestamp DESC);

-- Index on merchant category and risk status for fast joins
CREATE INDEX idx_terminals_mcc ON terminals(mcc);
CREATE INDEX idx_terminals_high_risk ON terminals(is_high_risk_flag) WHERE is_high_risk_flag = TRUE;

-- Index on transaction fraud label
CREATE INDEX idx_transactions_is_fraud ON transactions(is_fraud) WHERE is_fraud = TRUE;
