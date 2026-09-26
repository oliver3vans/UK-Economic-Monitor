
-- UK ECONOMIC MONITOR
-- 05: Identifying periods of economic pressure

WITH monthly_changes AS (
    SELECT
        month,
        cpi_annual_pct,
        unemployment_rate,
        annual_growth_pct,

        LAG(unemployment_rate, 1) OVER (
            ORDER BY month
        ) AS previous_unemployment

    FROM v_monthly_macro

    -- Exclude months without labour-market data
    WHERE unemployment_rate IS NOT NULL
)

SELECT
    month,
    cpi_annual_pct,
    unemployment_rate,
    previous_unemployment,
    annual_growth_pct

FROM monthly_changes

WHERE
    cpi_annual_pct > 2
    AND unemployment_rate > previous_unemployment
    AND annual_growth_pct < 0

ORDER BY month;