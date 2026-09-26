
-- UK ECONOMIC MONITOR
-- 04: Combined monthly macroeconomic dataset
-- Sources: ONS inflation, labour market and real GVA

CREATE OR REPLACE VIEW v_monthly_macro AS

SELECT
    i.month,

    -- Inflation
    i.cpi_annual_pct,
    i.cpih_annual_pct,

    -- Labour market
    l.unemployment_rate,
    l.employment_rate,
    l.regular_pay_growth,

    -- Real economic activity
    g.gva_index,
    g.monthly_growth_pct,
    g.annual_growth_pct

FROM inflation AS i

INNER JOIN v_gva_growth AS g
    ON i.month = g.month

LEFT JOIN labour_market AS l
    ON i.month = l.month;


-- Check the latest observations

SELECT *
FROM v_monthly_macro
ORDER BY month DESC
LIMIT 6;


-- Validate the combined dataset

SELECT
    COUNT(*) AS total_months,
    COUNT(cpi_annual_pct) AS cpi_available,
    COUNT(unemployment_rate) AS unemployment_available,
    COUNT(regular_pay_growth) AS regular_pay_available,
    COUNT(gva_index) AS gva_available
FROM v_monthly_macro;
