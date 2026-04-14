-- Task 3: Cohort Retention analysis:

-- create monthly cohort:
CREATE TABLE cohort as 
SELECT 
    customer_id,
    DATE_FORMAT(registration_date, '%Y-%m-01') AS cohort_month,
    registration_date
FROM customers_clean
WHERE registration_date IS NOT NULL;

-- Customer activity(as per transactions): 
CREATE TABLE cohort_transactions AS
SELECT 
    c.customer_id,
    c.cohort_month,
    t.transaction_date,
    DATEDIFF(t.transaction_date, c.registration_date) AS days_since_signup,
    t.total_amount
FROM cohort c
LEFT JOIN transactions_clean t
ON c.customer_id = t.customer_id
and t.transaction_date >= c.registration_date;

-- create retention bucket:
CREATE TABLE cohort_retention AS
SELECT 
    cohort_month,
    COUNT(DISTINCT customer_id) AS cohort_size,
    COUNT(DISTINCT CASE WHEN days_since_signup <= 30 THEN customer_id END) AS d30,
    COUNT(DISTINCT CASE WHEN days_since_signup <= 60 THEN customer_id END) AS d60,
    COUNT(DISTINCT CASE WHEN days_since_signup <= 90 THEN customer_id END) AS d90,
    COUNT(DISTINCT CASE WHEN days_since_signup <= 120 THEN customer_id END) AS d120,
    COUNT(DISTINCT CASE WHEN days_since_signup <= 150 THEN customer_id END) AS d150,
    COUNT(DISTINCT CASE WHEN days_since_signup <= 180 THEN customer_id END) AS d180
FROM cohort_transactions
GROUP BY cohort_month;

-- Convert to Retention Rates (%)
SELECT 
    cohort_month,
    cohort_size,
    d30 / cohort_size AS retention_30,
    d60 / cohort_size AS retention_60,
    d90 / cohort_size AS retention_90,
    d120 / cohort_size AS retention_120,
    d150 / cohort_size AS retention_150,
    d180 / cohort_size AS retention_180
FROM cohort_retention
ORDER BY cohort_month;

-- Cohort-specific AOV (average order value) trends
select * from cohort_transactions;
SELECT 
    cohort_month, AVG(total_amount) AS aov
FROM cohort_transactions
GROUP BY cohort_month
ORDER BY cohort_month;

-- Repeat purchase rates by cohort
With cohort_group as (
SELECT customer_id,
        cohort_month,
        COUNT(transaction_date) AS txn_count
    FROM cohort_transactions
    GROUP BY customer_id, cohort_month)
SELECT 
    cohort_month,
    COUNT(DISTINCT customer_id) AS total_customers,
    COUNT(DISTINCT CASE WHEN txn_count > 1 THEN customer_id END) AS repeat_customers,
    COUNT(DISTINCT CASE WHEN txn_count > 1 THEN customer_id END) / COUNT(DISTINCT customer_id) AS repeat_rate
FROM cohort_group
GROUP BY cohort_month;

-- Revenue per cohort over time
SELECT 
    cohort_month,
    SUM(total_amount) AS total_revenue
FROM cohort_transactions
GROUP BY cohort_month
ORDER BY total_revenue desc;
