# Interview questions and answers for this project

**1. Walk me through the project.**
I took Microsoft's AdventureWorks data warehouse in SQL Server, which has 60K internet sales order lines, and built a sales and profitability dashboard. In SQL I created five views in a `rpt` schema: one fact and four dimensions, giving a clean star schema. In Power Query I cleaned the values: codes became labels, NULLs became "Unknown", and I added age and income bands. In Power BI I built the relationships, marked the date table, and wrote 31 DAX measures. The report has four pages, drill-through, bookmarks, tooltips and territory RLS. Finally, I wrote a script that runs every measure as DAX and as SQL and compares the results. All 22 checks matched.

**2. Why a star schema, and why not import the raw tables?**
The raw warehouse is a snowflake: Product links to Subcategory, which links to Category. It also has columns we don't need and a placeholder territory row. A star schema means one fact table and one hop to each dimension. Filters propagate simply, DAX stays simple, and the model is smaller and faster. I flattened Category and Subcategory into Product in the SQL view.

**3. What is the grain of your fact table, and why does it matter?**
One row per order line (SalesOrderNumber + SalesOrderLineNumber), so 60,398 rows. The grain decides what you can count. That's why Order Count uses DISTINCTCOUNT(SalesOrderNumber), which gives 27,659 orders, and not COUNTROWS, which counts lines.

**4. Why is Profit Margin % a measure and not a column?**
Percentages don't add up. If you sum or average per-row margins, you get a wrong total. Margin must be SUM(profit) ÷ SUM(sales) in whatever filter context you're in, and only a measure does that. I used DIVIDE so a zero denominator returns blank instead of an error.

**5. Explain CALCULATE and filter context with one of your measures.**
`Sales LY = CALCULATE([Total Sales], SAMEPERIODLASTYEAR('Date'[Date]))`. In a cell for 2013, the filter context contains the 2013 dates. CALCULATE replaces that date filter with the same dates one year earlier, then evaluates Total Sales. So the 2013 row shows 2012's sales. Time intelligence only works because Date is a continuous, marked date table related to OrderDate.

**6. How does your Running Total differ from YTD?**
YTD (TOTALYTD) restarts every 1 January. The Running Total uses `FILTER(ALL('Date'[Date]), 'Date'[Date] <= MAX('Date'[Date]))`. ALL removes the current date filter, and FILTER keeps every date up to the last date in the current cell. So it accumulates from the very first order and never resets.

**7. How did you build the dynamic Top N?**
A what-if table `Top N` (GENERATESERIES 1–20) feeds a slicer, and `Top N Value = SELECTEDVALUE('Top N'[Top N], 10)`. `Product Rank` uses RANKX over ALLSELECTED product names, inside ISINSCOPE so it only ranks at product level. `Top N Sales` returns sales only when the rank is ≤ N, so the chart shows exactly N products.

**8. How does your RLS work, and how did you test it?**
Three roles filter `Territory[TerritoryGroup]` to North America, Europe or Pacific. The relationship is single-direction from Territory to Sales, so the role filter flows to the fact table. I tested with *View as role* in Desktop. My reconcile script also connects with `Roles=Europe` and so on, and checks that each role sees exactly one territory group and the same total as SQL. In production I'd use dynamic RLS: a user-to-territory mapping table filtered by USERPRINCIPALNAME().

**9. How did you make sure the numbers were right?**
Three layers. First, every SQL view ends with checks: row counts, unique keys, no lost sales after joins. Second, I wrote a SQL "answer key" for the insights. Third, `reconcile.ps1` connects to Power BI Desktop's local Analysis Services port, runs 22 DAX queries, runs the same logic in T-SQL, and compares them. All 22 pass, plus 3 RLS checks. It even caught that my hand-rounded answer key said −17.42% where the true value is −17.4268%, which rounds to −17.43%.

**10. What was the most interesting insight, and what would you recommend?**
Bikes are 96% of revenue at about 41% margin, while Accessories have the best margin (63%) but only 2% of sales. I checked basket data: in 2013, 74% of bike orders already included an accessory, so 2,515 bike orders had none. My recommendation is a bike + accessory bundle aimed at those buyers, which lifts margin without needing new customers. I also flagged that 2011's +16,195% YoY is fake, because 2010 has only 3 days of data. Partial years must not be compared with full years.

## Bonus questions

- **Why PBIP instead of PBIX?** PBIP saves the model as TMDL text and the report as JSON. I can version it in Git, review DAX changes as diffs, and edit it in bulk.
- **Why didn't you publish to the Service?** Publishing needs a work or school account, and refreshing an on-premises SQL Server needs a gateway. I had a personal account, so I share the PBIP and screenshots, and I don't claim a publish that didn't happen.
- **What would you add next?** Dynamic RLS with a security table, incremental refresh, and a margin target with variance measures.
