/* =====================================================================
   08_validate_insights.sql
   Purpose : Phase 3 - prove every number the dashboard and the resume
             claim, straight from the rpt views. These are the "answer
             key" values that Power BI must match in Phase 8.
   ===================================================================== */
USE AdventureWorksDW2022;
GO

-- Q1: headline KPIs
SELECT COUNT(*)                                   AS OrderLines,
       COUNT(DISTINCT SalesOrderNumber)           AS Orders,
       COUNT(DISTINCT CustomerKey)                AS Customers,
       COUNT(DISTINCT ProductKey)                 AS ProductsSold,
       SUM(SalesAmount)                           AS TotalSales,
       SUM(TotalProductCost)                      AS TotalCost,
       SUM(Profit)                                AS GrossProfit,
       CAST(SUM(Profit) / SUM(SalesAmount) AS decimal(9,4)) AS ProfitMargin,
       CAST(SUM(SalesAmount) / COUNT(DISTINCT SalesOrderNumber) AS decimal(12,2)) AS AvgOrderValue
FROM rpt.vw_FactSales;

-- Q2: category share of revenue and margin (resume bullet 4)
SELECT p.EnglishProductCategoryName                              AS Category,
       SUM(f.SalesAmount)                                        AS Sales,
       CAST(100.0 * SUM(f.SalesAmount) / SUM(SUM(f.SalesAmount)) OVER () AS decimal(5,2)) AS SalesSharePct,
       SUM(f.Profit)                                             AS Profit,
       CAST(100.0 * SUM(f.Profit) / SUM(f.SalesAmount) AS decimal(5,2)) AS MarginPct,
       COUNT(DISTINCT f.SalesOrderNumber)                        AS Orders
FROM rpt.vw_FactSales AS f
JOIN rpt.vw_DimProduct AS p ON p.ProductKey = f.ProductKey
GROUP BY p.EnglishProductCategoryName
ORDER BY Sales DESC;

-- Q3: why did 2013 grow ~180%? Sales by year and category
-- (Accessories and Clothing only start selling online on 2012-12-28)
SELECT YEAR(f.OrderDate) AS [Year], p.EnglishProductCategoryName AS Category,
       SUM(f.SalesAmount) AS Sales, COUNT(DISTINCT f.SalesOrderNumber) AS Orders
FROM rpt.vw_FactSales AS f
JOIN rpt.vw_DimProduct AS p ON p.ProductKey = f.ProductKey
GROUP BY YEAR(f.OrderDate), p.EnglishProductCategoryName
ORDER BY [Year], Sales DESC;

-- Q4: territory performance (RLS groups)
SELECT t.TerritoryGroup, t.Region, SUM(f.SalesAmount) AS Sales,
       CAST(100.0 * SUM(f.Profit) / SUM(f.SalesAmount) AS decimal(5,2)) AS MarginPct
FROM rpt.vw_FactSales AS f
JOIN rpt.vw_DimTerritory AS t ON t.SalesTerritoryKey = f.SalesTerritoryKey
GROUP BY t.TerritoryGroup, t.Region
ORDER BY t.TerritoryGroup, Sales DESC;

-- Q5: top 10 products by sales
SELECT TOP (10) p.EnglishProductName AS Product, p.EnglishProductSubcategoryName AS Subcategory,
       SUM(f.SalesAmount) AS Sales,
       CAST(100.0 * SUM(f.Profit) / SUM(f.SalesAmount) AS decimal(5,2)) AS MarginPct
FROM rpt.vw_FactSales AS f
JOIN rpt.vw_DimProduct AS p ON p.ProductKey = f.ProductKey
GROUP BY p.EnglishProductName, p.EnglishProductSubcategoryName
ORDER BY Sales DESC;

-- Q6: bundling evidence - orders that contain a bike, and how many of
-- them also contain an accessory
WITH o AS (
    SELECT f.SalesOrderNumber,
           MAX(CASE WHEN p.EnglishProductCategoryName = 'Bikes'       THEN 1 ELSE 0 END) AS HasBike,
           MAX(CASE WHEN p.EnglishProductCategoryName = 'Accessories' THEN 1 ELSE 0 END) AS HasAccessory
    FROM rpt.vw_FactSales AS f
    JOIN rpt.vw_DimProduct AS p ON p.ProductKey = f.ProductKey
    WHERE f.OrderDate >= '2013-01-01'          -- accessories first sold online on 2012-12-28
    GROUP BY f.SalesOrderNumber
)
SELECT SUM(HasBike)                                   AS OrdersWithBike,
       SUM(HasBike * HasAccessory)                    AS BikeOrdersWithAccessory,
       CAST(100.0 * SUM(HasBike * HasAccessory) / NULLIF(SUM(HasBike), 0) AS decimal(5,2)) AS AttachRatePct
FROM o;

-- Q7: new vs returning customers by year (customer is "new" in the year
-- of their first order)
WITH firsts AS (SELECT CustomerKey, MIN(OrderDate) AS FirstOrder FROM rpt.vw_FactSales GROUP BY CustomerKey)
SELECT YEAR(f.OrderDate) AS [Year],
       COUNT(DISTINCT CASE WHEN YEAR(fi.FirstOrder) = YEAR(f.OrderDate) THEN f.CustomerKey END) AS NewCustomers,
       COUNT(DISTINCT CASE WHEN YEAR(fi.FirstOrder) < YEAR(f.OrderDate) THEN f.CustomerKey END) AS ReturningCustomers
FROM rpt.vw_FactSales AS f
JOIN firsts AS fi ON fi.CustomerKey = f.CustomerKey
GROUP BY YEAR(f.OrderDate)
ORDER BY [Year];
