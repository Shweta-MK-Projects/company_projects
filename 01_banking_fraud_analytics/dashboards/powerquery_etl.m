/*
    ====================================================================================
    POWER QUERY M CODE - TRANSACTION INGESTION & DATA CLEANING PIPELINE
    Domain: Banking Fraud & Customer Risk Analytics
    ====================================================================================
*/

let
    // 1. Source Connection - Ingest transactions from Database schema
    Source = Sql.Database("localhost", "banking_analytics_db", [Query="SELECT * FROM transactions"]),
    
    // 2. Filter out corrupted rows where card_id or account_id is empty
    FilterNullKeys = Table.SelectRows(Source, each ([card_id] <> null) and ([account_id] <> null)),
    
    // 3. Format Date/Time types
    ChangeDateTypes = Table.TransformColumnTypes(FilterNullKeys, {{"transaction_timestamp", type datetime}}),
    
    // 4. Handle Nulls in IP Address with placeholder mapping
    ReplaceNullIP = Table.ReplaceValue(ChangeDateTypes, null, "0.0.0.0", Replacer.ReplaceValue, {"ip_address"}),
    
    // 5. Clean up amount values: Ensure positive decimal amounts
    FilterZeroAmounts = Table.SelectRows(ReplaceNullIP, each [amount] > 0),
    ChangeAmountTypes = Table.TransformColumnTypes(FilterZeroAmounts, {{"amount", type number}}),
    
    // 6. Split transaction timestamp into Date and Time parts for dimensional separation (Optimization)
    AddTransactionDate = Table.AddColumn(ChangeAmountTypes, "Transaction_Date", each DateTime.Date([transaction_timestamp]), type date),
    AddTransactionTime = Table.AddColumn(AddTransactionDate, "Transaction_Time", each DateTime.Time([transaction_timestamp]), type time),
    
    // 7. Standardize Card network and uppercase values
    UppercaseChannel = Table.TransformColumns(AddTransactionTime, {{"channel", Text.Upper, type text}}),
    
    // 8. Re-order and select operational fields
    CleanedColumns = Table.SelectColumns(UppercaseChannel, {
        "transaction_id", 
        "card_id", 
        "account_id", 
        "terminal_id", 
        "amount", 
        "currency", 
        "transaction_timestamp", 
        "Transaction_Date", 
        "Transaction_Time", 
        "transaction_type", 
        "response_code", 
        "channel", 
        "ip_address", 
        "is_fraud"
    })
in
    CleanedColumns
