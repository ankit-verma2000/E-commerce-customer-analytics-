# Statistical test:

query = """
SELECT 
    algorithm,SUM(clicked) AS clicks, COUNT(*) AS exposures
FROM recommendation_clean
GROUP BY algorithm
"""

df = pd.read_sql(query, engine)
df['ctr'] = df['clicks'] / df['exposures']
df.sort_values('ctr', ascending=False)


from scipy.stats import chi2_contingency

'''
H0: all algorithm have same ctr
HA: at leat 1 algorithm has diffrent ctr
'''

# clicks and non-clicks
clicks = df['clicks'].values
non_clicks = df['exposures'] - df['clicks']

# contingency table
contingency_table = np.array([clicks, non_clicks])
print(contingency_table)

chi2, p_value, dof, expected = chi2_contingency(contingency_table)

print("Chi-square stat:", chi2)
print("P-value:", p_value)

if p_value < 0.05: # CI = 95%
    print("Reject H0,Statistically significant difference across algorithms")
else:
    print("No significant difference")
