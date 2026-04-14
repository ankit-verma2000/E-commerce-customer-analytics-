SELECT * FROM transactions_clean;

# Total revenue per customers:
SELECT 
    customer_id,
    COUNT(transaction_id) AS total_transactions,
    round(SUM(total_amount),2) AS total_revenue
FROM
    transactions_clean
GROUP BY customer_id;

# Average Order Value
SELECT 
    customer_id,
    SUM(total_amount) / COUNT(transaction_id) AS avg_order_value
FROM transactions_clean
GROUP BY customer_id;

# Repeat Customers
SELECT 
    customer_id,
		CASE 
        WHEN COUNT(transaction_id) > 1 THEN 1 
        ELSE 0 
    END AS is_repeat_customer
FROM transactions_clean
GROUP BY customer_id;

# Recency date:
SELECT MAX(transaction_date) 
FROM transactions_clean;

# Recency of customers:
SELECT 
    customer_id,
    DATEDIFF(
    (SELECT MAX(transaction_date) FROM transactions_clean),
    MAX(transaction_date)
) AS recency_days
    #DATEDIFF('2024-03-31', MAX(transaction_date)) AS recency_days
FROM transactions_clean
GROUP BY customer_id;

CREATE TABLE master_customer_sql AS
SELECT 
    c.customer_id,
    MAX(c.registration_date) AS registration_date,
    COUNT(t.transaction_id) AS total_transactions,
    SUM(t.total_amount) AS total_revenue,
    MIN(t.transaction_date) AS first_purchase_date,
    MAX(t.transaction_date) AS last_purchase_date,
    DATEDIFF(MIN(t.transaction_date),
            MAX(c.registration_date)) AS days_to_first_purchase,
    DATEDIFF(MAX(t.transaction_date),
            MAX(c.registration_date)) AS customer_lifetime_days,
    DATEDIFF((SELECT MAX(transaction_date) FROM transactions_clean),
            MAX(t.transaction_date)) AS recency_days,
    SUM(t.total_amount) / NULLIF(COUNT(t.transaction_id), 0) AS avg_order_value,
    CASE
        WHEN COUNT(t.transaction_id) > 1 THEN 1
        ELSE 0
    END AS is_repeat_customer
FROM customers_clean c
LEFT JOIN transactions_clean t
ON c.customer_id = t.customer_id
GROUP BY c.customer_id;
