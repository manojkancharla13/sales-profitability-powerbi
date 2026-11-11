/* =====================================================================
   06_vw_DimDate.sql
   View    : rpt.vw_DimDate
   Grain   : one row per calendar day, full years only
             (expected 1,826 rows: 2010-01-01 to 2014-12-31)
   Purpose : the calendar for all time analysis (YoY, MTD, QTD, YTD).
             Power BI time intelligence needs one row per day, no gaps,
             full calendar years, and a real date column.
   ===================================================================== */
USE AdventureWorksDW2022;
GO

CREATE OR ALTER VIEW rpt.vw_DimDate
AS
SELECT
    CAST(d.FullDateAlternateKey AS date)                       AS [Date],   -- relationship column: must be date, not datetime
    d.DateKey,                                                              -- e.g. 20130115
    d.CalendarYear                                             AS [Year],
    d.CalendarQuarter                                          AS QuarterNumber,
    CONCAT('Q', d.CalendarQuarter)                             AS [Quarter],       -- Q1
    CONCAT(d.CalendarYear, ' Q', d.CalendarQuarter)            AS YearQuarter,     -- 2013 Q1
    d.MonthNumberOfYear                                        AS MonthNumber,     -- sort key for MonthName
    d.EnglishMonthName                                         AS [MonthName],
    LEFT(d.EnglishMonthName, 3)                                AS MonthShort,      -- Jan
    CONCAT(d.CalendarYear, '-', RIGHT(CONCAT('0', d.MonthNumberOfYear), 2))
                                                               AS YearMonth,       -- 2013-01
    d.CalendarYear * 100 + d.MonthNumberOfYear                 AS YearMonthNumber, -- 201301, sort key
    d.DayNumberOfMonth                                         AS DayOfMonth,
    d.DayNumberOfWeek                                          AS DayOfWeekNumber, -- 1 = Sunday ... 7 = Saturday
    d.EnglishDayNameOfWeek                                     AS DayName,
    d.WeekNumberOfYear                                         AS WeekOfYear,
    CASE WHEN d.DayNumberOfWeek IN (1, 7) THEN 'Weekend' ELSE 'Weekday' END
                                                               AS DayType
FROM dbo.DimDate AS d
-- Full years from the first order to the last due date, read from the
-- sales table instead of typed in, so new data extends the calendar.
WHERE d.CalendarYear BETWEEN (SELECT YEAR(MIN(OrderDate)) FROM dbo.FactInternetSales)
                         AND (SELECT YEAR(MAX(DueDate))   FROM dbo.FactInternetSales);
GO


/* ----------------------------- CHECKS -------------------------------- */

-- Check 1: expected 1826 rows, 1826 unique dates, 2010-01-01 to 2014-12-31,
--          and DaysInRange = RowsInView (proves there are no gaps)
SELECT COUNT(*)                                 AS RowsInView,
       COUNT(DISTINCT [Date])                   AS UniqueDates,
       MIN([Date])                              AS FirstDate,
       MAX([Date])                              AS LastDate,
       DATEDIFF(day, MIN([Date]), MAX([Date])) + 1 AS DaysInRange
FROM rpt.vw_DimDate;

-- Check 2: expected 0, 0, 0 (every order, ship and due date is in the calendar)
SELECT
    SUM(CASE WHEN o.[Date] IS NULL THEN 1 ELSE 0 END) AS MissingOrderDates,
    SUM(CASE WHEN s.[Date] IS NULL THEN 1 ELSE 0 END) AS MissingShipDates,
    SUM(CASE WHEN u.[Date] IS NULL THEN 1 ELSE 0 END) AS MissingDueDates
FROM dbo.FactInternetSales AS f
LEFT JOIN rpt.vw_DimDate AS o ON o.[Date] = CAST(f.OrderDate AS date)
LEFT JOIN rpt.vw_DimDate AS s ON s.[Date] = CAST(f.ShipDate  AS date)
LEFT JOIN rpt.vw_DimDate AS u ON u.[Date] = CAST(f.DueDate   AS date);

-- Check 3: spot-check one day (expected 2013-01-15, 2013 Q1, January, Tuesday, Weekday)
SELECT [Date], YearQuarter, [MonthName], YearMonth, DayName, DayType
FROM rpt.vw_DimDate
WHERE [Date] = '2013-01-15';
