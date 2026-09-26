# UK-Economic-Monitor
PostgreSQL analysis of UK inflation, labour-market conditions and real economic growth using official ONS data.


UK Economic Monitor
A PostgreSQL portfolio project analysing UK inflation, labour-market conditions and real economic activity using official Office for National Statistics (ONS) data.
This project takes six ONS time series from raw CSV files through SQL staging, cleaning and validation to analysis-ready tables. It then uses joins, common table expressions (CTEs), views and window functions to investigate periods of coinciding economic pressures and changes in real economic activity.
Tools: PostgreSQL 18 · DBeaver · Excel (visualisations)
Data snapshot: September 2026 · Analysis period: January 2000–July 2026, subject to each series' availability
Results at a glance
1. Identifying periods of economic pressure
I used SQL to identify months when all three of the following conditions coincided:
- CPI annual inflation exceeded 2%.
- The reported unemployment rate increased compared with the preceding observation.
- Annual real gross value added (GVA) growth was negative.
 
The query identified 14 qualifying months. Ten occurred consecutively from August 2008 to May 2009; the remaining observations were January 2010, October 2011, May 2023 and December 2023.
Year	Qualifying months
2008	5
2009	5
2010	1
2011	1
2023	2
Total	14


Only years containing qualifying months are shown. This is a descriptive classification defined for this project, not an official recession indicator or evidence of causation.
[View the SQL](scripts/05_economic_pressure.sql) · [Download the query results](results/economic_pressure_results.csv)
2. Three-month rolling real GVA growth monitor
I calculated month-on-month and year-on-year changes from the ONS real GVA index using LAG(), then used a windowed AVG() to calculate the average of the latest three monthly growth rates.
 
In the September 2026 data snapshot, the latest observation (July 2026) showed 0.39% monthly GVA growth, 1.57% annual growth and a 0.23% three-month rolling average of monthly growth. The chart focuses on 2023–2026 to make recent variation visible.
The rolling indicator is an arithmetic mean of monthly growth rates calculated from rounded index values; it is not the ONS's official three-month-on-three-month growth measure.
[View the growth SQL](scripts/03_gva_growth.sql) · [View the rolling-monitor SQL](scripts/06_gva_rolling_monitor.sql) · [Download the results](results/gva_monitor_results.csv)
Data and database design
All six indicators come from the ONS. Original CSVs were loaded into text-based staging tables, where SQL filtered monthly observations from January 2000 onward, excluded metadata and annual rows, and converted dates and values into typed columns.
Indicator	ONS series	Final database column	Available observations
CPI annual inflation	D7G7	inflation.cpi_annual_pct	319
CPIH annual inflation	L55O	inflation.cpih_annual_pct	319
Unemployment rate, 16+, seasonally adjusted	MGSX	labour_market.unemployment_rate	317
Employment rate, 16–64, seasonally adjusted	LF24	labour_market.employment_rate	317
Whole-economy regular-pay annual growth, seasonally adjusted	KAI9	labour_market.regular_pay_growth	303
Monthly real GVA index, seasonally adjusted	ECY2	gdp.gva_index	319


The final database contains three monthly tables: inflation (319 months), labour_market (317 months) and gdp (319 months). The table named gdp stores the real GVA index, not GDP in pounds. Regular-pay growth has 14 unavailable observations at the beginning of the sample; these are retained as NULL.
The combined v_monthly_macro view joins inflation to GVA growth by month and uses a LEFT JOIN for the labour market. This preserves June and July 2026 even though the labour series ends in May 2026.
SQL skills demonstrated
- Data preparation: staging tables, CREATE TABLE, regular-expression filtering, TO_DATE(), numeric casting, INSERT INTO ... SELECT and UPDATE ... FROM.
- Data integrity: primary keys, completeness and date-continuity checks, and reconciliation of staged GVA observations against the final table.
- Analysis: INNER JOIN, LEFT JOIN, CTEs, CASE, reusable views, LAG() and windowed AVG()/COUNT().
- Communication: exported SQL results and two charts created in Excel.
Repository structure
uk-economic-monitor/
├── README.md
├── scripts/
│   ├── 01_schema_and_import.sql
│   ├── 02_data_quality.sql
│   ├── 03_gva_growth.sql
│   ├── 04_monthly_macro.sql
│   ├── 05_economic_pressure.sql
│   └── 06_gva_rolling_monitor.sql
├── results/
│   ├── economic_pressure_results.csv
│   └── gva_monitor_results.csv
└── figures/
    ├── economic_pressure.png
    └── gva_growth.png
How to explore the project
For a quick review, start with the two charts above and their linked result CSVs. The analytical scripts are arranged so you can follow the work from GVA growth calculations to the joined macroeconomic dataset and the two showcase analyses.
To attempt a rebuild:
1. Create an empty PostgreSQL database and use the schema sections of [`01_schema_and_import.sql`](scripts/01_schema_and_import.sql) to create the staging and final tables.
2. Download the six original series from the official ONS links above. The GVA series was extracted into a two-column CSV from the ONS monthly GDP time-series dataset. Import each CSV into its corresponding staging table using DBeaver, preserving both columns as text.
3. Run the cleaning and insertion sections of script 01, then [`02_data_quality.sql`](scripts/02_data_quality.sql).
4. Run scripts 03, 04, 05 and 06 in order to create the analytical views and reproduce the queries.
Reproducibility status: The existing database, validation queries and analytical views have been tested. Script 01 consolidates the original import steps but has not yet been tested end-to-end in a fresh database. Current ONS downloads may also differ from the September 2026 snapshot used for these results. Do not run script 01's inserts against an already populated database.
Interpretation and limitations
- This is descriptive analysis of co-occurring indicators; it does not establish causal relationships.
- ONS unemployment and employment estimates refer to overlapping three-month Labour Force Survey periods. Adjacent published observations should not be interpreted as independent single-month measurements.
- The latest inflation and GVA observations in this snapshot are for July 2026; labour-market observations end in May 2026. Missing later labour data has not been replaced with zeros.
- Published series may be revised. The source links above lead to official series pages, but downloading them later may not reproduce the exact September 2026 vintage.
- Bank of England Bank Rate and an interactive dashboard are possible future extensions; neither is part of this release.
