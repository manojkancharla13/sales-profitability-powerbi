/* =====================================================================
   05_vw_DimTerritory.sql
   View    : rpt.vw_DimTerritory
   Grain   : one row per real sales territory (expected 10 rows)
   Purpose : regions for slicing, maps, and row-level security
             (RLS will filter on TerritoryGroup).
   ===================================================================== */
USE AdventureWorksDW2022;
GO

CREATE OR ALTER VIEW rpt.vw_DimTerritory
AS
SELECT
    t.SalesTerritoryKey,
    t.SalesTerritoryRegion  AS Region,
    t.SalesTerritoryCountry AS Country,
    t.SalesTerritoryGroup   AS TerritoryGroup   -- North America / Europe / Pacific
FROM dbo.DimSalesTerritory AS t
-- Alternate key 0 is the 'NA' placeholder row: not a real territory and no
-- sales point to it. Filter on its meaning (0) rather than the surrogate key 11.
WHERE t.SalesTerritoryAlternateKey <> 0;
GO


/* ----------------------------- CHECKS -------------------------------- */

-- Check 1: expected 10 rows
SELECT COUNT(*) AS RowsInView
FROM rpt.vw_DimTerritory;

-- Check 2: expected 3 groups (Europe, North America, Pacific)
SELECT TerritoryGroup, COUNT(*) AS Territories
FROM rpt.vw_DimTerritory
GROUP BY TerritoryGroup;

-- Check 3: expected 0 (removing the NA row lost no sales)
SELECT COUNT(*) AS MissingTerritories
FROM dbo.FactInternetSales AS f
WHERE NOT EXISTS (SELECT 1 FROM rpt.vw_DimTerritory AS v WHERE v.SalesTerritoryKey = f.SalesTerritoryKey);
