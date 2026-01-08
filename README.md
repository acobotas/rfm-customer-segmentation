# Customer Segmentation & RFM Analysis

![BigQuery](https://img.shields.io/badge/BigQuery-4285F4?style=for-the-badge&logo=google-bigquery&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-025E8C?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=for-the-badge&logo=microsoft-power-bi&logoColor=white)
![Analytics](https://img.shields.io/badge/Analytics-4682B4?style=for-the-badge)

An RFM-based customer segmentation project that identifies high-value, at-risk, and dormant customers, enabling targeted marketing and retention strategies.

---

![Dashboard](dashboard/dashboard_example.png)

---

## 🎯 Business Problem & Objectives

Mass marketing wastes resources. This project uses **RFM (Recency, Frequency, Monetary)** analysis to segment customers and optimize marketing strategies.

**Primary Objectives:**
- Identify high-value customer segments driving most revenue  
- Target marketing campaigns to specific customer groups  
- Improve retention by reactivating at-risk customers  
- Optimize marketing ROI by focusing on the most responsive customers

---

## ✨ Project Overview

RFM analysis assigns scores to each customer based on:

- **Recency (R):** How recently a customer made a purchase  
- **Frequency (F):** How often a customer buys  
- **Monetary (M):** How much a customer spends  

Customers are scored and grouped into **Champions, Recent Customers, Loyal Customers, Potential Loyalists, Promising, Can’t Lose Them, At Risk, Customers Needing Attention, Hibernating, Lost, Others** based on their RFM combination.  

The final deliverable is an interactive **Power BI dashboard** that provides a comprehensive view of customer behavior.

---

## 🛠️ Methodology

1. **Calculate Base Metrics:**  
   - Frequency: Number of distinct invoices per customer  
   - Monetary: Total spend (`Quantity * UnitPrice`)  
   - Last Purchase Date: Most recent invoice  

2. **Compute Recency:**  
   - Days since last purchase using reference date `'2011-12-01'`

3. **Determine Quartiles:**  
   - Calculate quartiles for Recency, Frequency, and Monetary values  
   - Flag potential outliers  

4. **Score Customers:**  
   - Recency: 1–4 (lower recency = higher score)  
   - Frequency & Monetary: 1–4 (higher = better)  

5. **Compute Combined Score:**  
   - `fm_score = ROUND((f_score + m_score) / 2)`  
   - `rfm_score = ROUND((r_score + f_score + m_score)/3.0,2)`

6. **Assign Customer Segments:**  
   Segments are assigned based on `r_score` and `fm_score` combinations:

   | Segment                 | R Score | FM Score |
   |-------------------------|---------|----------|
   | Champions               | 4       | 4        |
   | Recent Customers        | 4       | 2-3      |
   | Loyal Customers         | 3       | 4        |
   | Potential Loyalists     | 3       | 3        |
   | Promising               | 3-4     | 1-2      |
   | Can’t Lose Them         | 1-2     | 4        |
   | At Risk                 | 1-2     | 3        |
   | Customers Needing Attention | 2    | 1-2      |
   | Hibernating             | 1       | 2        |
   | Lost                    | 1       | 1        |
   | Others                  | -       | -        |

---

### SQL Code
```sql
WITH  
-- Calc frequency, monetary, last purchase
t1 AS (
  SELECT 
    CustomerID,
    Country,
    COUNT(DISTINCT InvoiceNo) AS frequency,
    MAX(DATE(InvoiceDate)) AS last_purchase_date,
    SUM(Quantity * UnitPrice) AS monetary
  FROM turing_data_analytics.rfm 
  WHERE
    CustomerID IS NOT NULL
    AND InvoiceDate >= '2010-12-01' AND InvoiceDate < '2011-12-01'
    AND UnitPrice IS NOT NULL AND UnitPrice > 0
    AND Quantity IS NOT NULL AND Quantity > 0
    AND Country != 'Unspecified'
  GROUP BY CustomerID, Country
),

-- Calc recency
t2 AS (
  SELECT *,

         DATE_DIFF(DATE '2011-12-01', last_purchase_date, DAY) AS recency
  FROM t1
),

-- Get R, F, M quartiles and flag outliers
t3 AS (
  SELECT 
    t2.*,

    -- Recency quartiles
    r.quartiles[OFFSET(1)] AS r1,
    r.quartiles[OFFSET(2)] AS r2,
    r.quartiles[OFFSET(3)] AS r3,

    -- Frequency quartiles
    f.quartiles[OFFSET(1)] AS f1,
    f.quartiles[OFFSET(2)] AS f2,
    f.quartiles[OFFSET(3)] AS f3,

    -- Monetary quartiles
    m.quartiles[OFFSET(1)] AS m1,
    m.quartiles[OFFSET(2)] AS m2,
    m.quartiles[OFFSET(3)] AS m3

  FROM 
    t2,
    (SELECT APPROX_QUANTILES(recency, 4) AS quartiles FROM t2) r,
    (SELECT APPROX_QUANTILES(frequency, 4) AS quartiles FROM t2) f,
    (SELECT APPROX_QUANTILES(monetary, 4) AS quartiles FROM t2) m
)
,

-- Score R, F, M
t4 AS (
  SELECT *,

    CASE 
      WHEN monetary <= m1 THEN 1
      WHEN monetary <= m2 THEN 2
      WHEN monetary <= m3 THEN 3
      ELSE 4
    END AS m_score,

    CASE 
      WHEN frequency <= f1 THEN 1
      WHEN frequency <= f2 THEN 2
      WHEN frequency <= f3 THEN 3
      ELSE 4
    END AS f_score,

    CASE 
      WHEN recency <= r1 THEN 4
      WHEN recency <= r2 THEN 3
      WHEN recency <= r3 THEN 2
      ELSE 1
    END AS r_score

  FROM t3
),

-- Compute combined scores
t5 AS (
  SELECT *,
    CAST(ROUND((f_score + m_score) / 2.0) AS INT64) AS fm_score
  FROM t4
),

-- Assign customer segments
t6 AS (
  SELECT 
    CustomerID, 
    recency,
    frequency, 
    monetary,
    r_score,
    f_score,
    m_score,
    fm_score,
    ROUND((f_score + m_score + r_score) / 3.0, 2) AS rfm_score,
    CASE
      WHEN r_score = 4 AND fm_score = 4 THEN 'Champions'
      WHEN r_score = 4 AND fm_score IN (2, 3) THEN 'Recent Customers'
      WHEN r_score = 3 AND fm_score = 4 THEN 'Loyal Customers'
      WHEN r_score = 3 AND fm_score = 3 THEN 'Potential Loyalists'
      WHEN r_score IN (3, 4) AND fm_score IN (1, 2) THEN 'Promising'
      WHEN r_score IN (1, 2) AND fm_score = 4 THEN 'Can’t Lose Them'
      WHEN r_score IN (1, 2) AND fm_score = 3 THEN 'At Risk'
      WHEN r_score = 2 AND fm_score IN (1, 2) THEN 'Customers Needing Attention'
      WHEN r_score = 1 AND fm_score IN (2) THEN 'Hibernating'
      WHEN r_score = 1 AND fm_score = 1 THEN 'Lost'
      ELSE 'Others'
    END AS rfm_segment,
    Country
  FROM t5
)

-- Final segment counts
SELECT  
  *
FROM t6
```
