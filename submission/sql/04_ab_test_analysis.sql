/*
1. Calculate CTR (click-through rate) for control vs. treatment
2. Measure conversion impact (exposure → purchase within 7 days)
3. Analyze revenue impact per user group
4. Test statistical significance (use appropriate test)
5. Segment analysis: Does the treatment effect vary by customer segment?
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

-- 2:  Measure conversion impact (exposure → purchase within 7 days)
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
