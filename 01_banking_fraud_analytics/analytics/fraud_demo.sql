-- Demo Fraud Detection SQL
-- Creates a simplified transactions table and a fraud scoring view
CREATE TABLE dbo.Transactions (
    TransactionID INT PRIMARY KEY,
    AccountID INT NOT NULL,
    TransactionDate DATETIME NOT NULL,
    Amount DECIMAL(12,2) NOT NULL,
    MerchantCategory VARCHAR(50),
    MerchantCountry VARCHAR(2)
);

-- Sample data (placeholder for demo)
INSERT INTO dbo.Transactions (TransactionID, AccountID, TransactionDate, Amount, MerchantCategory, MerchantCountry)
VALUES (1, 1001, GETDATE(), 250.00, 'Electronics', 'IN'),
       (2, 1002, DATEADD(day, -1, GETDATE()), 1200.00, 'Travel', 'US');

-- Fraud score view using window functions and simple rule‑based logic
CREATE VIEW dbo.FraudScore AS
SELECT
    t.TransactionID,
    t.AccountID,
    t.TransactionDate,
    t.Amount,
    CASE
        WHEN t.Amount > 1000 THEN 0.9
        WHEN t.Amount > 500 THEN 0.6
        ELSE 0.2
    END AS AmountRisk,
    CASE
        WHEN t.MerchantCountry <> 'IN' THEN 0.7
        ELSE 0.1
    END AS GeoRisk,
    (CASE WHEN t.Amount > 1000 THEN 0.9 ELSE 0.1 END + CASE WHEN t.MerchantCountry <> 'IN' THEN 0.7 ELSE 0.1 END) / 2.0 AS FraudScore
FROM dbo.Transactions t;

-- Query to fetch high‑risk transactions
SELECT * FROM dbo.FraudScore WHERE FraudScore > 0.7;
