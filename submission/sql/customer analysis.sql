Create database ecommerce_db;
use ecommerce_db;

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

##########################################################

# Task:2
select * from master_customer_sql;
# RFM table:
CREATE TABLE rfm AS
SELECT 
    customer_id,
    recency_days,
    total_transactions AS frequency,
    total_revenue AS monetary
FROM master_customer_sql
WHERE recency_days IS NOT NULL;
/*
Recency: low is better
Frequeny: High is better
Monetary: High is better
*/

# RFM scores:
create table rfm_table as 
SELECT 
    customer_id,
    NTILE(5) OVER (ORDER BY recency_days ASC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency DESC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary DESC) AS m_score
FROM rfm;

# RFM segments:
/*
Recency: low is better
Frequeny: High is better
Monetary: High is better
*/
CREATE TABLE rfm_segments AS
SELECT 
    customer_id,r_score,f_score, m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_score,
    CASE 
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 3 AND f_score >= 2 THEN 'Potential Loyalists'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        ELSE 'Lost Customers'
    END AS segment
FROM rfm_table ;

# product and rfm segment table:
CREATE TABLE rfm_analysis AS
SELECT 
    s.customer_id,
    s.segment,
    c.acquisition_channel,
    c.country,
    p.category,
    t.total_amount,
    t.discount_code
FROM rfm_segments s
LEFT JOIN customers_clean c 
ON s.customer_id = c.customer_id
LEFT JOIN transactions_clean t 
ON s.customer_id = t.customer_id
LEFT JOIN products_clean p 
ON t.product_id = p.product_id;

/* Q1. Which acquisition channels bring the highest-value customers? -> organic search */
SELECT 
    acquisition_channel,
    AVG(total_amount) AS avg_revenue,
    COUNT(DISTINCT customer_id) AS customers
FROM rfm_analysis
GROUP BY acquisition_channel
ORDER BY avg_revenue DESC;

/*Q2. Are discount-acquired customers less loyal?*/
SELECT  
    CASE 
        WHEN discount_code IS NOT NULL THEN 'Discount Users'
        ELSE 'Non-Discount Users'
    END AS discount_group,
    AVG(total_amount) AS avg_revenue,
    COUNT(DISTINCT customer_id) AS customers
FROM rfm_analysis
where segment = 'Loyal Customers'
GROUP BY discount_group;

/* Q3. Segment Distribution by Acquisition Channel*/
SELECT 
    segment,
    acquisition_channel,
    COUNT(DISTINCT customer_id) AS customers
FROM rfm_analysis
GROUP BY segment, acquisition_channel
ORDER BY segment;

/*Product Category Preference*/
SELECT 
    segment,
    category,
    COUNT(*) AS purchases
FROM rfm_analysis
GROUP BY segment, category
ORDER BY purchases DESC;

/*Q5. Country wise distribution:*/
SELECT 
    segment,
    country,
    COUNT(DISTINCT customer_id) AS customers
FROM rfm_analysis
GROUP BY segment, country;

/* First purchases and its LTV*/
select * from master_customer_sql;
SELECT 
    CASE 
        WHEN days_to_first_purchase <= 1 THEN 'Immediate'
        WHEN days_to_first_purchase <= 7 THEN 'Early'
        ELSE 'Late'
    END AS purchase_speed, round(AVG(total_revenue),2) AS avg_ltv
FROM master_customer_sql
GROUP BY purchase_speed;


# Task 3: Cohort Retention analysis:
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

#############################################################

# Task 4: 
/*
Calculate CTR (click-through rate) for control vs. treatment
Measure conversion impact (exposure → purchase within 7 days)
Analyze revenue impact per user group
Test statistical significance (use appropriate test)
Segment analysis: Does the treatment effect vary by customer segment?
*/

-- 1: CTR: 
select * from recommendation_clean;
SELECT 
    algorithm,
    COUNT(*) AS total_exposures,
    SUM(clicked) AS total_clicks,
    SUM(clicked) / COUNT(*) AS ctr
FROM recommendation_clean
GROUP BY algorithm;

-- 2: 
SELECT 
    r.algorithm,
    COUNT(*) AS total_exposures,
    COUNT(DISTINCT CASE WHEN t.transaction_id IS NOT NULL 
    THEN r.exposure_id END) AS conversions_7d,
    COUNT(DISTINCT CASE WHEN t.transaction_id IS NOT NULL 
    THEN r.exposure_id END) / COUNT(*) AS conversion_rate_7d
FROM recommendation_clean r
LEFT JOIN transactions_clean t
ON r.customer_id = t.customer_id
AND t.transaction_date >= r.exposure_date
AND t.transaction_date <= DATE_ADD(r.exposure_date, INTERVAL 7 DAY)
GROUP BY r.algorithm;

-- 3: Revenue impact:
SELECT 
    r.algorithm,
    COUNT(DISTINCT r.customer_id) AS users,
    SUM(t.total_amount) AS total_revenue,
    SUM(t.total_amount) / COUNT(DISTINCT r.customer_id) AS revenue_per_user
FROM recommendation_clean r
LEFT JOIN transactions_clean t
ON r.customer_id = t.customer_id
AND t.transaction_date >= r.exposure_date
GROUP BY r.algorithm;

WITH user_revenue AS (
SELECT 
	r.customer_id,
	r.algorithm,
	SUM(t.total_amount) AS revenue_7d
FROM recommendation_clean r
LEFT JOIN transactions_clean t
ON r.customer_id = t.customer_id
AND t.transaction_date BETWEEN r.exposure_date 
AND DATE_ADD(r.exposure_date, INTERVAL 7 DAY)
GROUP BY r.customer_id, r.algorithm
)
SELECT 
    algorithm,
    COUNT(*) AS users,
    SUM(revenue_7d) AS total_revenue,
    AVG(revenue_7d) AS revenue_per_user
FROM user_revenue
GROUP BY algorithm;

-- 5. Segment level analysis:
SELECT 
    c.segment,
    r.algorithm,
    COUNT(*) AS exposures,
    SUM(r.clicked) / COUNT(*) AS ctr,
    SUM(r.purchased) / COUNT(*) AS conversion_rate
FROM recommendation_clean r
JOIN rfm_segments c
ON r.customer_id = c.customer_id
GROUP BY c.segment, r.algorithm
ORDER BY c.segment;

------------------------------------------------------------------------------
# Bonus qustions:


# Churn data:
select * from master_customers;
SELECT 
    customer_id,
    total_transactions,
    total_revenue,
    avg_order_value,
    recency_days,
    customer_lifetime_days,
    is_repeat_customer,
    is_churned
FROM master_customers;


/* Marketing Channel Attribution
Multi-touch attribution: customers who appear in multiple channels
Calculate incrementality of each channel
*/
SELECT 
    customer_id,
    COUNT(DISTINCT acquisition_channel) AS channel_count
FROM customers_clean
GROUP BY customer_id
;
# Revenue per channel
SELECT 
    c.acquisition_channel,
    SUM(t.total_amount) AS revenue
FROM customers_clean c
JOIN transactions_clean t
ON c.customer_id = t.customer_id
GROUP BY c.acquisition_channel;
