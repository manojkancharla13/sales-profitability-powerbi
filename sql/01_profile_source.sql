/* =====================================================================
   01_profile_source.sql
   Purpose : Profile the AdventureWorksDW2022 source before building
             anything - how big is each table we will use?
   Run in  : SSMS, connected to localhost
   ===================================================================== */
USE AdventureWorksDW2022;
GO

-- 1) Exact row counts for the tables in our star schema.
--    COUNT(*) reads every row, so the result is exact. These are the
--    numbers we use to verify the resume.
--    [RowCount] is in brackets because ROWCOUNT is a reserved word in T-SQL.
SELECT 'FactInternetSales'     AS TableName, COUNT(*) AS [RowCount] FROM dbo.FactInternetSales
UNION ALL
SELECT 'DimCustomer',                        COUNT(*)              FROM dbo.DimCustomer
UNION ALL
SELECT 'DimProduct',                         COUNT(*)              FROM dbo.DimProduct
UNION ALL
SELECT 'DimProductSubcategory',              COUNT(*)              FROM dbo.DimProductSubcategory
UNION ALL
SELECT 'DimProductCategory',                 COUNT(*)              FROM dbo.DimProductCategory
UNION ALL
SELECT 'DimSalesTerritory',                  COUNT(*)              FROM dbo.DimSalesTerritory
UNION ALL
SELECT 'DimDate',                            COUNT(*)              FROM dbo.DimDate
ORDER BY [RowCount] DESC;


-- Bonus: the same counts read from metadata instead of scanning the tables.
-- Instant even on billions of rows, but Microsoft documents
-- sys.partitions.rows as approximate - use COUNT(*) for validation.
SELECT t.name      AS TableName,
       SUM(p.rows) AS [RowCount]
FROM sys.tables AS t
JOIN sys.partitions AS p
  ON p.object_id = t.object_id
 AND p.index_id IN (0, 1)   -- 0 = heap, 1 = clustered index: the table's own rows
WHERE t.name IN (N'FactInternetSales', N'DimCustomer', N'DimProduct',
                 N'DimProductSubcategory', N'DimProductCategory',
                 N'DimSalesTerritory', N'DimDate')
GROUP BY t.name
ORDER BY [RowCount] DESC;


-- 2) List every row of DimSalesTerritory.
SELECT SalesTerritoryKey,
       SalesTerritoryAlternateKey,
       SalesTerritoryRegion,
       SalesTerritoryCountry,
       SalesTerritoryGroup
FROM dbo.DimSalesTerritory
ORDER BY SalesTerritoryKey;
-- Finding: 11 rows = 10 real territories + 1 placeholder.
--   SalesTerritoryKey 11 (alternate key 0) has 'NA' in every column: an
--   "unknown / not applicable" member added by the warehouse. No sales point
--   to it; only employees without a sales territory do.
--   => "10 sales territories" on the resume is correct.


-- 3) How many distinct products actually appear in FactInternetSales?
SELECT COUNT(DISTINCT ProductKey) AS ProductsSoldOnline
FROM dbo.FactInternetSales;
-- Finding: 158 products sold online, but DimProduct has 606 rows.

-- 3b) Why the difference? DimProduct rows vs products sold online, by category.
SELECT ISNULL(c.EnglishProductCategoryName, '(no subcategory)') AS Category,
       COUNT(*)            AS DimProductRows,
       COUNT(s.ProductKey) AS SoldOnline
FROM dbo.DimProduct AS p
LEFT JOIN dbo.DimProductSubcategory AS sc ON sc.ProductSubcategoryKey = p.ProductSubcategoryKey
LEFT JOIN dbo.DimProductCategory    AS c  ON c.ProductCategoryKey     = sc.ProductCategoryKey
LEFT JOIN (SELECT DISTINCT ProductKey FROM dbo.FactInternetSales) AS s
       ON s.ProductKey = p.ProductKey
GROUP BY c.EnglishProductCategoryName
ORDER BY DimProductRows DESC;
-- Findings:
--   * 209 rows have no subcategory: raw parts used in manufacturing, never sold.
--   * 189 Components are sold only through resellers (bike shops), never online.
--   * Bikes 116 + Clothing 20 + Accessories 22 = 158 sold online.

-- 3c) DimProduct keeps price/cost history (slowly changing dimension type 2),
--     so one product can have several rows.
SELECT COUNT(*)                            AS DimProductRows,
       COUNT(DISTINCT ProductAlternateKey) AS UniqueProducts
FROM dbo.DimProduct;
-- Finding: 606 rows but only 504 unique products.
