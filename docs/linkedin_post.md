💡 I found a 26% revenue opportunity hiding in a $29M sales dataset. Here's how 👇

I built an end-to-end Sales & Profitability Analytics Dashboard in Power BI on Microsoft's AdventureWorks data warehouse, from raw SQL tables all the way to a business recommendation.

📊 What the data revealed
• Bikes drive 96% of revenue, but at only a 41% margin
• Accessories earn the highest margin (63%) yet make up just 2% of sales
• 26% of 2013 bike orders (2,515 orders) had no accessory in the basket
➡️ Recommendation: bike + accessory bundles to lift margin without needing new customers

🛠️ What I built
✅ SQL Server: 5 T-SQL views shaping a star schema (60K+ order lines, 18K+ customers, dedicated date table)
✅ Power Query: data cleaning and standardisation
✅ DAX: 31 measures, including CALCULATE, SUMX, RANKX, time intelligence (YoY, MTD/QTD/YTD, running total), new vs returning customers, and a dynamic Top N
✅ 4-page interactive report: KPI cards, drill-through, bookmarks, tooltips, custom theme
✅ Row-level security by sales territory
✅ Automated validation: a script that runs every measure in DAX and in SQL and compares them. 22/22 matched ✔️

🧠 A lesson every analyst should know: the data showed +16,195% YoY growth in 2011, but 2010 had only 3 days of sales. Partial periods can make numbers lie, so always check the denominator.

🔗 Full project (SQL, DAX, screenshots, documentation): https://github.com/manojkancharla13/sales-profitability-powerbi

🚀 I'm actively looking for Data Analyst / Power BI Developer opportunities in Hyderabad or remote. If your team needs someone who can turn data into decisions, I'd love to connect. Feel free to DM me!

#DataAnalyst #PowerBI #SQL #DAX #DataAnalytics #BusinessIntelligence #DataVisualization #OpenToWork #HyderabadJobs #Hiring
