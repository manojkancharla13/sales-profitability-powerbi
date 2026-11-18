<#
  reconcile.ps1  -  Phase 8: prove the Power BI model matches SQL Server.

  Runs the same question twice:
    * DAX against the open Power BI Desktop model (local Analysis Services)
    * T-SQL against the rpt views in AdventureWorksDW2022
  and prints PASS/FAIL per check.

  Requirements: Power BI Desktop has SalesProfitability.pbip open.
  Usage:  powershell -ExecutionPolicy Bypass -File tools\reconcile.ps1
#>
param([string]$SqlServer = 'localhost', [double]$Tolerance = 0.01)

# --- connect to the local Power BI model ---------------------------------
$pbiProc = Get-Process PBIDesktop -ErrorAction Stop | Select-Object -First 1
$bin     = Split-Path $pbiProc.Path
Add-Type -Path (Join-Path $bin 'Microsoft.PowerBI.AdomdClient.dll')
$msmd = Get-Process msmdsrv -ErrorAction Stop | Select-Object -First 1
$port = (netstat -ano | Select-String "127\.0\.0\.1:(\d+)\s+\S+\s+LISTENING\s+$($msmd.Id)$").Matches[0].Groups[1].Value
$dax  = New-Object Microsoft.AnalysisServices.AdomdClient.AdomdConnection "Data Source=localhost:$port"
$dax.Open()
$sql  = New-Object System.Data.SqlClient.SqlConnection "Server=$SqlServer;Database=AdventureWorksDW2022;Integrated Security=True"
$sql.Open()

function Get-Dax([string]$q) {
  $c = $dax.CreateCommand(); $c.CommandText = $q
  $r = $c.ExecuteReader(); [void]$r.Read(); $v = [double]$r.GetValue(0); $r.Close(); $v
}
function Get-Sql([string]$q) { $c = $sql.CreateCommand(); $c.CommandText = $q; [double]$c.ExecuteScalar() }

$f = 'FROM rpt.vw_FactSales f JOIN rpt.vw_DimProduct p ON p.ProductKey = f.ProductKey JOIN rpt.vw_DimTerritory t ON t.SalesTerritoryKey = f.SalesTerritoryKey'
$checks = @(
  @('Total Sales',              'EVALUATE ROW("v",[Total Sales])',        "SELECT SUM(SalesAmount) FROM rpt.vw_FactSales"),
  @('Total Cost',               'EVALUATE ROW("v",[Total Cost])',         "SELECT SUM(TotalProductCost) FROM rpt.vw_FactSales"),
  @('Gross Profit',             'EVALUATE ROW("v",[Gross Profit])',       "SELECT SUM(Profit) FROM rpt.vw_FactSales"),
  @('Profit Margin %',          'EVALUATE ROW("v",[Profit Margin %])',    "SELECT SUM(Profit)/SUM(SalesAmount) FROM rpt.vw_FactSales"),
  @('Order Count',              'EVALUATE ROW("v",[Order Count])',        "SELECT COUNT(DISTINCT SalesOrderNumber) FROM rpt.vw_FactSales"),
  @('Customer Count',           'EVALUATE ROW("v",[Customer Count])',     "SELECT COUNT(DISTINCT CustomerKey) FROM rpt.vw_FactSales"),
  @('Units Sold',               'EVALUATE ROW("v",[Units Sold])',         "SELECT SUM(Quantity) FROM rpt.vw_FactSales"),
  @('Avg Order Value',          'EVALUATE ROW("v",[Avg Order Value])',    "SELECT SUM(SalesAmount)/COUNT(DISTINCT SalesOrderNumber) FROM rpt.vw_FactSales"),
  @('Bikes Share %',            'EVALUATE ROW("v",[Bikes Share %])',      "SELECT SUM(CASE WHEN p.EnglishProductCategoryName='Bikes' THEN SalesAmount END)/SUM(SalesAmount) $f"),
  @('Accessories Margin %',     'EVALUATE ROW("v",CALCULATE([Profit Margin %],Product[Category]="Accessories"))', "SELECT SUM(Profit)/SUM(SalesAmount) $f WHERE p.EnglishProductCategoryName='Accessories'"),
  @('Bikes Margin %',           'EVALUATE ROW("v",CALCULATE([Profit Margin %],Product[Category]="Bikes"))',       "SELECT SUM(Profit)/SUM(SalesAmount) $f WHERE p.EnglishProductCategoryName='Bikes'"),
  @('Sales 2013',               'EVALUATE ROW("v",CALCULATE([Total Sales],''Date''[Year]=2013))',  "SELECT SUM(SalesAmount) FROM rpt.vw_FactSales WHERE YEAR(OrderDate)=2013"),
  @('Sales LY (2013)',          'EVALUATE ROW("v",CALCULATE([Sales LY],''Date''[Year]=2013))',     "SELECT SUM(SalesAmount) FROM rpt.vw_FactSales WHERE YEAR(OrderDate)=2012"),
  @('YoY Growth % (2013)',      'EVALUATE ROW("v",CALCULATE([YoY Growth %],''Date''[Year]=2013))', "SELECT (SUM(CASE WHEN YEAR(OrderDate)=2013 THEN SalesAmount END)-SUM(CASE WHEN YEAR(OrderDate)=2012 THEN SalesAmount END))/SUM(CASE WHEN YEAR(OrderDate)=2012 THEN SalesAmount END) FROM rpt.vw_FactSales"),
  @('Sales YTD (Jun-2013)',     'EVALUATE ROW("v",CALCULATE([Sales YTD],''Date''[Year]=2013,''Date''[MonthNumber]=6))', "SELECT SUM(SalesAmount) FROM rpt.vw_FactSales WHERE OrderDate BETWEEN '2013-01-01' AND '2013-06-30'"),
  @('Sales QTD (Jun-2013)',     'EVALUATE ROW("v",CALCULATE([Sales QTD],''Date''[Year]=2013,''Date''[MonthNumber]=6))', "SELECT SUM(SalesAmount) FROM rpt.vw_FactSales WHERE OrderDate BETWEEN '2013-04-01' AND '2013-06-30'"),
  @('Sales MTD (Jun-2013)',     'EVALUATE ROW("v",CALCULATE([Sales MTD],''Date''[Year]=2013,''Date''[MonthNumber]=6))', "SELECT SUM(SalesAmount) FROM rpt.vw_FactSales WHERE OrderDate BETWEEN '2013-06-01' AND '2013-06-30'"),
  @('Running Total (end 2012)', 'EVALUATE ROW("v",CALCULATE([Running Total],''Date''[Year]=2012))',"SELECT SUM(SalesAmount) FROM rpt.vw_FactSales WHERE OrderDate <= '2012-12-31'"),
  @('Europe Sales',             'EVALUATE ROW("v",CALCULATE([Total Sales],Territory[TerritoryGroup]="Europe"))', "SELECT SUM(SalesAmount) $f WHERE t.TerritoryGroup='Europe'"),
  @('New Customers (2013)',     'EVALUATE ROW("v",CALCULATE([New Customers],''Date''[Year]=2013))', "SELECT COUNT(*) FROM (SELECT CustomerKey FROM rpt.vw_FactSales GROUP BY CustomerKey HAVING YEAR(MIN(OrderDate))=2013) x"),
  @('Returning Customers (2013)','EVALUATE ROW("v",CALCULATE([Returning Customers],''Date''[Year]=2013))', "SELECT COUNT(DISTINCT f.CustomerKey) FROM rpt.vw_FactSales f JOIN (SELECT CustomerKey, MIN(OrderDate) fo FROM rpt.vw_FactSales GROUP BY CustomerKey) m ON m.CustomerKey=f.CustomerKey WHERE YEAR(f.OrderDate)=2013 AND YEAR(m.fo)<2013"),
  @('Bike Accessory Attach % (2013)', 'EVALUATE ROW("v",CALCULATE([Bike Accessory Attach %],''Date''[Year]=2013))', "WITH o AS (SELECT f.SalesOrderNumber, MAX(CASE WHEN p.EnglishProductCategoryName='Bikes' THEN 1 ELSE 0 END) b, MAX(CASE WHEN p.EnglishProductCategoryName='Accessories' THEN 1 ELSE 0 END) a $f WHERE YEAR(f.OrderDate)=2013 GROUP BY f.SalesOrderNumber) SELECT 1.0*SUM(b*a)/SUM(b) FROM o")
)

$fail = 0
$rows = foreach ($c in $checks) {
  $d = Get-Dax $c[1]; $s = Get-Sql $c[2]
  $ok = [math]::Abs($d - $s) -le $Tolerance
  if (-not $ok) { $fail++ }
  $inv = [Globalization.CultureInfo]::InvariantCulture
  [pscustomobject]@{ Check = $c[0]; PowerBI = $d.ToString('N4', $inv); SQL = $s.ToString('N4', $inv); Result = $(if ($ok) {'PASS'} else {'FAIL'}) }
}
$rows | Format-Table -AutoSize
"{0} of {1} checks passed" -f ($checks.Count - $fail), $checks.Count

# --- RLS: connect AS each role and confirm it only sees its own territories
"`nRow-level security (connect with Roles=<role>):"
$rls = foreach ($g in 'North America', 'Europe', 'Pacific') {
  $rc = New-Object Microsoft.AnalysisServices.AdomdClient.AdomdConnection "Data Source=localhost:$port;Roles=$g"
  $rc.Open(); $cmd = $rc.CreateCommand()
  $cmd.CommandText = 'EVALUATE ROW("sales",[Total Sales],"groups",COUNTROWS(VALUES(Territory[TerritoryGroup])))'
  $r = $cmd.ExecuteReader(); [void]$r.Read(); $d = [double]$r.GetValue(0); $groups = $r.GetValue(1); $r.Close(); $rc.Close()
  $s = Get-Sql "SELECT SUM(SalesAmount) $f WHERE t.TerritoryGroup='$g'"
  $ok = ([math]::Abs($d - $s) -le $Tolerance) -and ($groups -eq 1)
  [pscustomobject]@{ Role = $g; VisibleGroups = $groups; PowerBI = $d.ToString('N2', [Globalization.CultureInfo]::InvariantCulture); SQL = $s.ToString('N2', [Globalization.CultureInfo]::InvariantCulture); Result = $(if ($ok) {'PASS'} else {'FAIL'}) }
}
$rls | Format-Table -AutoSize
$dax.Close(); $sql.Close()
