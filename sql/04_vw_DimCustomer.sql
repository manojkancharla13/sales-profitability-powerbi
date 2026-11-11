/* =====================================================================
   04_vw_DimCustomer.sql
   View    : rpt.vw_DimCustomer
   Grain   : one row per customer (expected 18,484 rows)
   Purpose : who our online customers are, where they live, and when they
             first bought (used later for New vs Returning customers).
   Note    : value cleaning (M/F -> Male/Female, M/S -> Married/Single,
             1/0 -> Yes/No, age and income bands) is done in Power Query.
   ===================================================================== */
USE AdventureWorksDW2022;
GO

CREATE OR ALTER VIEW rpt.vw_DimCustomer
AS
SELECT
    cu.CustomerKey,
    cu.CustomerAlternateKey                                   AS CustomerCode,
    -- CONCAT_WS skips NULLs: 7,830 customers have no middle name, and
    -- FirstName + ' ' + MiddleName + ... would turn their whole name NULL.
    CONCAT_WS(' ', cu.FirstName, cu.MiddleName, cu.LastName) AS CustomerName,
    cu.Gender,
    cu.MaritalStatus,
    CAST(cu.BirthDate AS date)                                AS BirthDate,
    -- Age on the last order date in the data (Jan 2014), not today.
    -- DATEDIFF(year, ...) only counts year boundaries, so subtract 1
    -- when the birthday hasn't come yet in that year.
    DATEDIFF(year, cu.BirthDate, d.AsOfDate)
      - CASE WHEN DATEADD(year, DATEDIFF(year, cu.BirthDate, d.AsOfDate), cu.BirthDate) > d.AsOfDate
             THEN 1 ELSE 0 END                                AS Age,
    cu.YearlyIncome,
    cu.EnglishEducation                                       AS Education,
    cu.EnglishOccupation                                      AS Occupation,
    cu.HouseOwnerFlag                                         AS HomeOwner,
    cu.NumberCarsOwned                                        AS CarsOwned,
    cu.TotalChildren,
    cu.CommuteDistance,
    g.City,
    g.StateProvinceName                                       AS StateProvince,
    g.EnglishCountryRegionName                                AS Country,
    cu.DateFirstPurchase                                      AS FirstPurchaseDate
FROM dbo.DimCustomer AS cu
LEFT JOIN dbo.DimGeography AS g
       ON g.GeographyKey = cu.GeographyKey
-- One-row subquery: the "as of" date for Age, read from the data
-- instead of typed in, so it stays right if new sales are loaded.
CROSS JOIN (SELECT CAST(MAX(OrderDate) AS date) AS AsOfDate
            FROM dbo.FactInternetSales) AS d;
GO


/* ----------------------------- CHECKS -------------------------------- */

-- Check 1: expected 18484 and 18484 (CustomerKey is unique)
SELECT COUNT(*) AS RowsInView, COUNT(DISTINCT CustomerKey) AS UniqueKeys
FROM rpt.vw_DimCustomer;

-- Check 2: expected 0 (no blank names)
SELECT COUNT(*) AS BlankNames
FROM rpt.vw_DimCustomer
WHERE CustomerName IS NULL OR CustomerName = '';

-- Check 3: expected youngest 27, oldest 97
SELECT MIN(Age) AS YoungestAge, MAX(Age) AS OldestAge
FROM rpt.vw_DimCustomer;

-- Check 4: expected 0 (every customer in the sales table exists in the view)
SELECT COUNT(*) AS MissingCustomers
FROM dbo.FactInternetSales AS f
WHERE NOT EXISTS (SELECT 1 FROM rpt.vw_DimCustomer AS v WHERE v.CustomerKey = f.CustomerKey);
