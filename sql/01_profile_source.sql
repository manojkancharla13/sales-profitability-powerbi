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


-- 2) YOUR TURN: list every row of DimSalesTerritory.
--    How many rows are there, and which one is not a real territory?



-- 3) YOUR TURN: how many distinct products actually appear in FactInternetSales?
--    Compare it with the DimProduct row count. Why are they different?
--    Hint: COUNT(DISTINCT ...)


