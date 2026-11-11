/* =====================================================================
   07_vw_FactSales.sql
   View    : rpt.vw_FactSales
   Grain   : one row per order line (expected 60,398 rows)
   Purpose : the centre of the star schema - sales line items with keys
             to each dimension, money columns, and line-level profit.
   Notes   : * No joins here: dimensions connect through relationships in
               Power BI. That is what makes it a star schema.
             * Profit Margin % is NOT a column. Percentages can't be added
               up, so margin must be SUM(Profit) / SUM(Sales) in DAX.
             * Dropped on purpose: date keys (we relate on real dates),
               PromotionKey and discount columns (no discount was ever
               applied), CurrencyKey (all amounts are in USD),
               ExtendedAmount (= SalesAmount), ProductStandardCost
               (= TotalProductCost, quantity is always 1), tax and freight
               (not part of revenue or profit).
   ===================================================================== */
USE AdventureWorksDW2022;
GO

CREATE OR ALTER VIEW rpt.vw_FactSales
AS
SELECT
    f.SalesOrderNumber,
    f.SalesOrderLineNumber,
    CAST(f.OrderDate AS date)          AS OrderDate,   -- active relationship to vw_DimDate[Date]
    CAST(f.ShipDate  AS date)          AS ShipDate,    -- optional, for USERELATIONSHIP later
    CAST(f.DueDate   AS date)          AS DueDate,     -- optional
    f.ProductKey,
    f.CustomerKey,
    f.SalesTerritoryKey,
    f.OrderQuantity                    AS Quantity,    -- always 1 for internet sales
    f.UnitPrice,
    f.SalesAmount,                                     -- revenue, excluding tax and freight
    f.TotalProductCost,
    f.SalesAmount - f.TotalProductCost AS Profit       -- safe per row; margin % is a DAX measure
FROM dbo.FactInternetSales AS f;
GO


/* ----------------------------- CHECKS -------------------------------- */

-- Check 1: expected 60398 rows and 60398 unique order lines
SELECT COUNT(*) AS RowsInView,
       COUNT(DISTINCT CONCAT(SalesOrderNumber, '-', SalesOrderLineNumber)) AS UniqueOrderLines
FROM rpt.vw_FactSales;

-- Check 2: expected the same number twice (the view loses no sales)
SELECT (SELECT SUM(SalesAmount) FROM rpt.vw_FactSales)      AS ViewSales,
       (SELECT SUM(SalesAmount) FROM dbo.FactInternetSales) AS SourceSales;

-- Check 3: expected Difference = 0 (profit adds up)
SELECT SUM(Profit) - (SUM(SalesAmount) - SUM(TotalProductCost)) AS Difference
FROM rpt.vw_FactSales;

-- Check 4: expected 0 (no missing keys)
SELECT COUNT(*) AS RowsWithNullKeys
FROM rpt.vw_FactSales
WHERE ProductKey IS NULL OR CustomerKey IS NULL
   OR SalesTerritoryKey IS NULL OR OrderDate IS NULL;

-- Check 5 (run after ALL five views exist): joining the fact to every
-- dimension must give the same rows and sales as Check 1 and Check 2.
-- Fewer rows = a dimension is missing keys; more rows = a dimension has
-- duplicate keys (like a wrong join in vw_DimProduct).
SELECT COUNT(*) AS RowsAfterJoins, SUM(fs.SalesAmount) AS SalesAfterJoins
FROM rpt.vw_FactSales AS fs
JOIN rpt.vw_DimProduct   AS p ON p.ProductKey        = fs.ProductKey
JOIN rpt.vw_DimCustomer  AS c ON c.CustomerKey       = fs.CustomerKey
JOIN rpt.vw_DimTerritory AS t ON t.SalesTerritoryKey = fs.SalesTerritoryKey
JOIN rpt.vw_DimDate      AS d ON d.[Date]            = fs.OrderDate;
