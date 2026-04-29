# ShopFast E-Commerce Customer Analytics Platform

## Problem
ShopFast is seeing declining repeat purchase rates. The executive team needs insights on customer behavior across channels, products, geography, and the impact of the 20% discount promo campaign + new recommendation engine (rolled out to 30% of users in March 2024).

**Analysis Period**: Oct 2023 – Mar 2024 (6 months)

## Project Deliverables
- Cleaned customer master table with RFM metrics & churn flag
- Predictive churn model (Random Forest)
- RFM segmentation & cohort analysis
- Executive Power BI dashboard
- Actionable recommendations to improve retention & LTV

**Tech Stack**: MySQL, Python (scikit-learn, pandas), Power BI


> Questions answered:
1. Total revenue per customers:
<img width="264" height="106" alt="image" src="https://github.com/user-attachments/assets/75b751b5-5dd5-4e67-94e8-2a6436d5c232" />

2. Average Order Value:
<img width="106" height="37" alt="image" src="https://github.com/user-attachments/assets/1f9c881f-092c-4d7e-be73-07308e412d35" />

3.Created master customer table:
```
SELECT 
    c.customer_id,
    MAX(c.registration_date) AS registration_date,
    COUNT(t.transaction_id) AS total_transactions,
    SUM(t.total_amount) AS total_revenue,
    MIN(t.transaction_date) AS first_purchase_date,
    MAX(t.transaction_date) AS last_purchase_date,
    DATEDIFF(MIN(t.transaction_date), MAX(c.registration_date)) AS days_to_first_purchase,
    DATEDIFF(MAX(t.transaction_date), MAX(c.registration_date)) AS customer_lifetime_days,
    DATEDIFF((SELECT MAX(transaction_date) FROM transactions_clean), MAX(t.transaction_date)) AS recency_days,
    SUM(t.total_amount) / NULLIF(COUNT(t.transaction_id), 0) AS avg_order_value,
    CASE WHEN COUNT(t.transaction_id) > 1 THEN 1 ELSE 0
    END AS is_repeat_customer
FROM customers_clean c
LEFT JOIN transactions_clean t
ON c.customer_id = t.customer_id
GROUP BY c.customer_id;
```
