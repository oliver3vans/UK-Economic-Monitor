
-- UK ECONOMIC MONITOR
-- 03: Monthly and annual GVA growth
-- Source: ONS real monthly GVA index (ECY2)

-- Create a reusable view of economic growth

CREATE OR REPLACE VIEW v_gva_growth AS

WITH gva_lags AS (
    SELECT
        month,
        gva_index,

        LAG(gva_index, 1) OVER (
            ORDER BY month
        ) AS previous_month,

        LAG(gva_index, 12) OVER (
            ORDER BY month
        ) AS previous_year

    FROM gdp
)

SELECT
    month,
    gva_index,

    ROUND(
        100 * (
            gva_index /
            NULLIF(previous_month, 0) - 1
        ), 2
    ) AS monthly_growth_pct,

    ROUND(
        100 * (
            gva_index /
            NULLIF(previous_year, 0) - 1
        ), 2
    ) AS annual_growth_pct

FROM gva_lags;


-- Verify the view using the latest 12 months

SELECT *
FROM v_gva_growth
ORDER BY month DESC
LIMIT 12;
  
