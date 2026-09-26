
-- Check 3: Compare GVA staging and final tables

WITH source_data AS (
    SELECT
        TO_DATE(period_raw, 'YYYY MON') AS month,
        gva_index_raw::NUMERIC AS gva_index
    FROM stg_gdp_raw
    WHERE period_raw ~
        '^20[0-9]{2} (JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)$'
      AND TRIM(gva_index_raw) ~
        '^[+-]?[0-9]+(\.[0-9]+)?$'
),

comparison AS (
    SELECT
        s.month AS source_month,
        g.month AS final_month,
        s.gva_index AS source_value,
        g.gva_index AS final_value
    FROM source_data AS s
    FULL JOIN gdp AS g
        ON s.month = g.month
)

SELECT
    COUNT(source_month) AS source_rows,
    COUNT(final_month) AS final_rows,

    COUNT(*) FILTER (
        WHERE source_month IS NULL
           OR final_month IS NULL
    ) AS unmatched_months,

    COUNT(*) FILTER (
        WHERE source_month IS NOT NULL
          AND final_month IS NOT NULL
          AND source_value IS DISTINCT FROM final_value
    ) AS incorrect_values

FROM comparison;