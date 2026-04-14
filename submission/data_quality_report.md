#  Data Quality Report

## Missing Values

- phone → ~3% missing → kept as NULL
- churn_date → ~81% missing → expected (non-churn users)
- discount_code → ~66% missing → treated as no discount

---

## Data Issues Found

### 1. Invalid Dates
- Future registration dates detected
- Action: removed records

### 2. Negative / Zero Values
- quantity <= 0
- unit_price = 0 (failed transactions)
- Action: filtered out

### 3. Inconsistent Data
- acquisition_channel standardized
- date formats converted

---

## Decisions Made

| Issue | Action |
|------|-------|
| Missing phone | Ignored |
| Missing churn_date | Treated as active |
| Invalid transactions | Removed |
| Discount ambiguity | Not assumed |

---
