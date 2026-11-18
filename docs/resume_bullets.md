# Resume bullets: corrected and verified

**Sales & Profitability Analytics Dashboard | Power BI, DAX, Power Query, SQL Server**

- Built an end-to-end BI solution on AdventureWorksDW2022 (60K+ internet sales order lines across 27K+ orders, 18K+ customers, 158 products sold, 10 sales territories). T-SQL views shaped a star schema with a dedicated date table, and Power Query cleaned and standardised the data.
- Developed 30+ DAX measures (CALCULATE, SUMX, RANKX, DIVIDE, variables, time intelligence) for Total Sales, Profit Margin %, YoY growth, MTD/QTD/YTD, running totals, new vs returning customers and a dynamic Top N product ranking.
- Delivered a 4-page interactive Power BI report (KPI cards, drill-through, bookmarks, report-page tooltips, custom theme) with territory-level row-level security. Reconciled 22 measures and 3 RLS roles against SQL source queries using an automated DAX-vs-SQL script; all matched.
- Found that Bikes drive 96% of internet revenue at a 41% margin, while Accessories earn the highest margin (63%) on only 2% of sales. Since 26% of 2013 bike orders had no accessory, recommended bike and accessory bundles.

## What changed from the original bullets, and why

| Original claim | Status | Why |
|---|---|---|
| "60K+ internet sales **transactions**" | Reworded | 60,398 is the number of **order lines**; there are 27,659 orders. Say "order lines". |
| "600+ products" | Corrected | DimProduct has 606 rows, but they are 504 products (SCD history) and only **158 were sold online**. |
| "using T-SQL views to clean and shape" | Expanded | The views shape the data; **Power Query** does the value cleaning. |
| "20+ DAX measures" | Upgraded | There are 31 measures. "30+" is true. |
| "published to Power BI Service with scheduled refresh" | **Removed** | This needs a work or school account (personal email accounts cannot sign in) and a gateway for a local SQL Server. It wasn't done, so it isn't claimed. |
| "matched dashboard totals to SQL source queries" | Strengthened | `tools/reconcile.ps1`: 22/22 measures and 3/3 RLS roles pass. |
| "Bikes ~96%, Accessories ~62% vs ~41% Bikes" | Verified | 96.46%, 62.60%, 40.63% (`sql/08_validate_insights.sql`). |
| "recommended bundling" | Strengthened with evidence | 74.1% of 2013 bike orders already contain an accessory, so 2,515 (26%) are the bundle opportunity. |

If you later get access to a work or school Power BI account, you can publish the report and set up a gateway and scheduled refresh. Only then add back: "published to Power BI Service with scheduled refresh via an on-premises gateway".
