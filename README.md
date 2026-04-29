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
**1. Total revenue per customers:**
<img width="264" height="106" alt="image" src="https://github.com/user-attachments/assets/75b751b5-5dd5-4e67-94e8-2a6436d5c232" />


**2. Average Order Value:**
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

4. Create rfm table:
```
SELECT 
    customer_id,
    recency_days,
    total_transactions AS frequency,
    total_revenue AS monetary
FROM master_customer_sql
WHERE recency_days IS NOT NULL;
```
<img width="343" height="242" alt="image" src="https://github.com/user-attachments/assets/3a7448ef-df9e-4615-875a-7027e440caa2" />
---------------------------------------------------
<img width="1116" height="481" alt="image" src="https://github.com/user-attachments/assets/2d7f985f-4d8c-47cb-b5fe-d6d6954b4b8f" />



**5. Which acquisition channels bring the highest-value customers?**
<img width="338" height="158" alt="image" src="https://github.com/user-attachments/assets/9abe6401-65bb-40a6-9827-1cb84c59456d" />

<img width="354" height="207" alt="image" src="https://github.com/user-attachments/assets/05b4329c-8367-450c-bd9f-6d29945d3592" />

**6.  Are discount-acquired customers less loyal?**
- Data clearly indicates that customers acquired through discounts are more price-sensitive and less likely to build long-term engagement.
- On the other hand, non-discount users show stronger organic loyalty and contribute more to the loyal customer base.
<img width="369" height="52" alt="image" src="https://github.com/user-attachments/assets/eaf8fd07-ab4a-443d-8586-b520e3a52194" />

- Discounts drive acquisition, but not loyalty, and the data clearly shows a lower conversion to loyal customers among discount users.

**7. Top 5 country with Higest contributing revenue?**
<img width="216" height="108" alt="image" src="https://github.com/user-attachments/assets/056fdb54-41a9-46d0-8631-aea5c4eede26" />

**8. First purchases and its LTV**
<img width="228" height="76" alt="image" src="https://github.com/user-attachments/assets/d1b3c00a-4cd5-44c9-9f03-5acad13bf34f" />

- Immediate purchasers have the highest LTV, i.e Customers who purchase within 1 day are extremely valuable
- Early purchasers also perform well (approx avg LTV: 12,766), i.e. Slightly lower than immediate, but still high-value customers
- Late purchasers have significantly lower LTV (Avg LTV approx 5,186), i.e. Less than half of immediate buyers → strong drop in value
  
So, the faster a customer makes their first purchase, the higher their lifetime value making early conversion a critical growth.

**Recommendations**: 
1. Focus on reducing time to first purchase
- impprove onboarding experience
- Offer first-time incentives (smartly)
2. Target high-intent users early
- Retarget users within first 24-48 hours
- Personalization for new users
- Guide them toward first purchase faster

--------------------------------------------------------------------------------------------------------------------------------

### Cohort table:
<img width="643" height="77" alt="image" src="https://github.com/user-attachments/assets/345bb303-6d4a-4b59-853c-83eb2e3ef167" />

Retention improves consistently over time across all cohorts, indicating that users who remain engaged early tend to stay long-term. 
- February cohort shows the strongest early and mid-term retention, means better onboarding or user experience during that period.
- However, January month cohort slightly outperforms in long-term retention, meaning users acquired earlier may have developed stronger long-term habits.

<img width="674" height="405" alt="image" src="https://github.com/user-attachments/assets/6b5e2ab6-3fb5-4e02-abc7-e126439e8785" />

**9. Cohort-specific AOV (average order value) trends** 

(amount spent per transaction)

<img width="135" height="70" alt="image" src="https://github.com/user-attachments/assets/3069a000-9f86-4821-b5ed-a11cb4c1746a" />

- Average order value remains fairly consistent across cohorts, indicates a stable customer spending behavior.
- The March cohort shows a slight improvement in AOV, which could be driven by better product mix or higher-value customers.

**Recommendations**
- Investigate March uplift :Check pricing, campaigns, or product changes
- Analyze the impact of discounts especially for February dip.

**10.  Repeat purchase rates by cohort**
<img width="359" height="72" alt="image" src="https://github.com/user-attachments/assets/de4b3833-c1b4-4557-941e-682970bb7823" />

Repeat purchase rates show a slight declining trend from January to March, indicating that newer cohorts are marginally less likely to make repeat purchases. While the drop is not drastic, it suggests a potential decline in customer quality, engagement, or post-purchase experience in recent months

**11. Revenue per cohort over time**
<img width="172" height="74" alt="image" src="https://github.com/user-attachments/assets/c6dd0b93-a475-4f18-b175-3188e52f7162" />

- January cohort generated the highest revenue ~25.88M (highest):
Indicates strongest overall performance (likely better retention + repeat purchases)
- March cohort is second, close to January ~24.90M (second high): 
aligns with your earlier insight of higher AOV in March
- February cohort has the lowest revenue ~23.95M (least):
Despite decent retention, overall revenue is lower.
**Reasons**: Lower AOV
Slightly fewer repeat purchases
- Revenue trend is relatively stable (in the 24M–26M range)
No drastic drop; business performance is consistent across cohorts

_So, Revenue is driven by a combination of AOV + retention + repeat behavior, not just one metric._


