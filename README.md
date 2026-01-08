# Customer Segmentation & RFM Analysis

![BigQuery](https://img.shields.io/badge/BigQuery-4285F4?style=for-the-badge&logo=google-bigquery&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-025E8C?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=for-the-badge&logo=microsoft-power-bi&logoColor=white)
![Analytics](https://img.shields.io/badge/Analytics-4682B4?style=for-the-badge)

An RFM-based customer segmentation project that identifies high-value, at-risk, and dormant customers, enabling targeted marketing and retention strategies.

---

## 🔗 Quick Links
* 📁 **[Dataset / BigQuery Table](#)**  
* 📊 **[Power BI Dashboard Preview](dashboard_exampple.png)**

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
-- Your full RFM SQL code goes here