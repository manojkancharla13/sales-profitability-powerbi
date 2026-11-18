# LinkedIn post (draft)

I just finished an end-to-end Sales & Profitability dashboard in Power BI on Microsoft's AdventureWorks data warehouse. I built it to make sure I can explain every step, from raw SQL tables to a business recommendation.

What I built:
🔹 SQL Server: 5 T-SQL views shaping a star schema (1 fact table with 60K order lines, 4 dimensions, a dedicated date table)
🔹 Power Query: cleaning codes into labels, handling unknowns, age and income bands
🔹 DAX: 31 measures, including CALCULATE, SUMX, RANKX, time intelligence (YoY, MTD/QTD/YTD, running total), new vs returning customers, and a dynamic Top N
🔹 Report: 4 pages with KPI cards, drill-through, bookmarks, report-page tooltips and a custom theme
🔹 Security: territory-level row-level security (3 roles)
🔹 Validation: a script that runs every measure as DAX against the model and as SQL against the source. 22/22 matched.

What the data said:
📊 Bikes are 96% of revenue at a 41% margin
📊 Accessories earn the best margin (63%) but only 2% of sales
📊 26% of 2013 bike orders had no accessory, which makes bike + accessory bundles the opportunity

One lesson: always check your YoY numbers. 2011 showed +16,195% growth only because 2010 had just 3 days of data. Partial years can mislead.

Code and screenshots: <your GitHub repo link>

#PowerBI #DAX #SQL #DataAnalytics #BusinessIntelligence #DataVisualization
