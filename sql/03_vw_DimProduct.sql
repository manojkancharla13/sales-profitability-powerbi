USE AdventureWorksDW2022;
GO
CREATE OR ALTER VIEW rpt.vw_DimProduct
AS
SELECT  p.ProductKey,
		p.ProductAlternateKey,
		p.EnglishProductName,
		sc.EnglishProductSubcategoryName,
		c.EnglishProductCategoryName,
		p.ModelName,
		p.ProductLine,
		p.Color,
		p.ListPrice,
		p.StandardCost,
		p.Status
		FROM dbo.DimProduct p left join dbo.DimProductSubcategory sc 
		on p.ProductSubcategoryKey=sc.ProductSubcategoryKey
		left join dbo.DimProductCategory c 
		on sc.ProductCategoryKey= c.ProductCategoryKey;
GO
-- checks: put your test queries below the view