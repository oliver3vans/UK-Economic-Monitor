
-- UK ECONOMIC MONITOR
-- 06: Three-month rolling GVA growth monitor
-- Source: ONS monthly real GVA index (ECY2)

CREATE OR REPLACE VIEW v_gva_monitor AS

WITH rolling_growth AS (
    SELECT
        month,
        gva_index,
        monthly_growth_pct,
        annual_growth_pct,

        AVG(monthly_growth_pct) OVER (
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING
                     AND CURRENT ROW
        ) AS rolling_average,

        COUNT(monthly_growth_pct) OVER (
            ORDER BY month
            ROWS BETWEEN 2 PRECEDING
                     AND CURRENT ROW
        ) AS available_months

    FROM v_gva_growth
)

SELECT
    month,
    gva_index,
    monthly_growth_pct,
    annual_growth_pct,

    CASE
        WHEN available_months = 3
        THEN ROUND(rolling_average, 2)
        ELSE NULL
    END AS rolling_3m_growth_pct,

    CASE
        WHEN available_months < 3
            THEN 'Insufficient data'
        WHEN rolling_average < 0
            THEN 'Negative'
        WHEN rolling_average > 0
            THEN 'Positive'
        ELSE 'Zero'
    END AS growth_direction

FROM rolling_growth;


-- Inspect the latest 12 observations


SELECT *
FROM v_gva_monitor
ORDER BY month;