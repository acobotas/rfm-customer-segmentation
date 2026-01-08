WITH  
-- Calc frequency, monetary, last purchase
t1 AS (
  SELECT 
    CustomerID,
    Country,
    COUNT(DISTINCT InvoiceNo) AS frequency,
    MAX(DATE(InvoiceDate)) AS last_purchase_date,
    SUM(Quantity * UnitPrice) AS monetary
  FROM tc-da-1.turing_data_analytics.rfm 
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