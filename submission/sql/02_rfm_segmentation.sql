-- Task 2: Customer Segmentation Analysis 

Perform RFM (Recency, Frequency, Monetary) segmentation:
Calculate RFM scores for each customer (scale 1-5)
Create 5 distinct customer segments with business-friendly names
Analyze segment composition by:
Acquisition channel
Product category preference
Geographic distribution

Average discount dependency
Key questions to answer:
Which acquisition channels bring the highest-value customers?
Are discount-acquired customers less loyal?
What's the relationship between first-purchase timing and lifetime value?
---------------------------------------------------------------

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
