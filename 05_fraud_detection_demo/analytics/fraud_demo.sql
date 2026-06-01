-- Fraud demo SQL schema and view
CREATE TABLE dbo.Transactions (
    TransactionID INT PRIMARY KEY,
    AccountID INT NOT NULL,
    TransactionDate DATETIME NOT NULL,
    Amount DECIMAL(12,2) NOT NULL,
    MerchantCategory VARCHAR(50),
    MerchantCountry VARCHAR(2)
);

CREATE VIEW dbo.FraudScore AS
SELECT
    TransactionID,
    AccountID,
    TransactionDate,
    Amount,
    CASE WHEN Amount > 1000 THEN 0.9 WHEN Amount > 500 THEN 0.6 ELSE 0.2 END AS AmountRisk,
    CASE WHEN MerchantCountry <> 'IN' THEN 0.7 ELSE 0.1 END AS GeoRisk,
    ((CASE WHEN Amount > 1000 THEN 0.9 ELSE 0.1 END) + (CASE WHEN MerchantCountry <> 'IN' THEN 0.7 ELSE 0.1 END)) / 2.0 AS FraudScore
FROM dbo.Transactions;
