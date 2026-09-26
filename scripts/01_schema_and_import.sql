
-- ============================================================
-- UK ECONOMIC MONITOR
-- 01: DATABASE SCHEMA, DATA CLEANING AND IMPORT
-- ============================================================
--
-- Database: uk_economic_monitor
-- Software: PostgreSQL / DBeaver
-- Data source: Office for National Statistics (ONS)
-- Sample: January 2000 onwards
--
-- PURPOSE:
-- Create staging and final tables for six UK economic
-- indicators and transform the original ONS CSV data into
-- a structured, analysis-ready database.
--
-- This script documents the original import procedure.
-- Run the appropriate sections in order in a NEW database.
-- Do not rerun the imports against populated tables.
--
-- ============================================================


-- ============================================================
-- PART 1: CREATE RAW STAGING TABLES
-- ============================================================
--
-- Staging tables preserve the original downloaded data.
-- TEXT fields accommodate ONS metadata and missing values.
-- Data cleaning is performed in SQL after CSV import.


-- CPI annual inflation: ONS D7G7

CREATE TABLE stg_cpi_raw (
    period_raw TEXT,
    value_raw TEXT
);


-- CPIH annual inflation: ONS L55O

CREATE TABLE stg_cpih_raw (
    period_raw TEXT,
    value_raw TEXT
);


-- Unemployment rate: ONS MGSX

CREATE TABLE stg_unemployment_raw (
    period_raw TEXT,
    value_raw TEXT
);


-- Employment rate: ONS LF24

CREATE TABLE stg_employment_raw (
    period_raw TEXT,
    value_raw TEXT
);


-- Regular pay annual growth: ONS KAI9

CREATE TABLE stg_regular_pay_raw (
    period_raw TEXT,
    value_raw TEXT
);


-- Monthly real GVA index: ONS ECY2

CREATE TABLE stg_gdp_raw (
    period_raw TEXT,
    gva_index_raw TEXT
);


-- ============================================================
-- PART 2: CREATE FINAL ANALYTICAL TABLES
-- ============================================================


-- Inflation: CPI and CPIH annual percentage changes

CREATE TABLE inflation (
    month DATE PRIMARY KEY,
    cpi_annual_pct NUMERIC(5,2),
    cpih_annual_pct NUMERIC(5,2)
);


-- Labour market: unemployment, employment and earnings

CREATE TABLE labour_market (
    month DATE PRIMARY KEY,
    unemployment_rate NUMERIC(5,2),
    employment_rate NUMERIC(5,2),
    regular_pay_growth NUMERIC(5,2)
);


-- Economic output: real monthly GVA index
-- The table is named gdp for convenience.
-- ECY2 is an index, NOT GDP measured in pounds.

CREATE TABLE gdp (
    month DATE PRIMARY KEY,
    gva_index NUMERIC(8,2)
);


-- ============================================================
-- PART 3: IMPORT ORIGINAL CSV DATA
-- ============================================================
--
-- At this point, import all six CSV files into their
-- corresponding staging tables using DBeaver.
--
-- SOURCE FILE                  STAGING TABLE
--
-- cpi_raw.csv                  stg_cpi_raw
-- cpih_raw.csv                 stg_cpih_raw
-- unemployment_raw.csv         stg_unemployment_raw
-- employment_raw.csv           stg_employment_raw
-- regular_pay_raw.csv          stg_regular_pay_raw
-- gdp_gva_only.csv             stg_gdp_raw
--
-- Check the actual local filenames before importing.
--
-- DBeaver import settings:
--   Header position: none
--   First CSV column: period_raw
--   Second CSV column: value_raw
--   For GVA: second column is gva_index_raw
--   Disable automatic creation of additional columns.
--
-- The GVA source was originally a wide ONS CSV.
-- Its first two columns were extracted into
-- gdp_gva_only.csv using Python's csv module.
--
-- Preserve the original source files unchanged.
--
-- IMPORTANT:
-- Import and inspect all six staging tables before
-- proceeding to Part 4.


-- ============================================================
-- PART 4: CLEAN AND INSERT INFLATION DATA
-- ============================================================


-- 4.1 Insert CPI annual inflation
--
-- Restrict observations to monthly dates from 2000.
-- Exclude metadata, annual rows and nonnumeric values.

INSERT INTO inflation (
    month,
    cpi_annual_pct
)

SELECT
    TO_DATE(period_raw, 'YYYY MON'),
    TRIM(value_raw)::NUMERIC

FROM stg_cpi_raw

WHERE period_raw ~
    '^20[0-9]{2} (JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)$'

AND TRIM(value_raw) ~
    '^[+-]?[0-9]+(\.[0-9]+)?$';


-- 4.2 Match CPIH observations to existing CPI months
--
-- UPDATE rather than INSERT avoids duplicating months.

UPDATE inflation AS i

SET cpih_annual_pct = c.cpih_annual_pct

FROM (
    SELECT
        TO_DATE(period_raw, 'YYYY MON') AS month,
        TRIM(value_raw)::NUMERIC AS cpih_annual_pct

    FROM stg_cpih_raw

    WHERE period_raw ~
        '^20[0-9]{2} (JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)$'

    AND TRIM(value_raw) ~
        '^[+-]?[0-9]+(\.[0-9]+)?$'

) AS c

WHERE i.month = c.month;


-- ============================================================
-- PART 5: CLEAN AND INSERT LABOUR-MARKET DATA
-- ============================================================


-- 5.1 Insert unemployment rate
--
-- Unemployment: aged 16+, seasonally adjusted.

INSERT INTO labour_market (
    month,
    unemployment_rate
)

SELECT
    TO_DATE(period_raw, 'YYYY MON'),
    TRIM(value_raw)::NUMERIC

FROM stg_unemployment_raw

WHERE period_raw ~
    '^20[0-9]{2} (JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)$'

AND TRIM(value_raw) ~
    '^[+-]?[0-9]+(\.[0-9]+)?$';


-- 5.2 Match employment observations
--
-- Employment: aged 16-64, seasonally adjusted.

UPDATE labour_market AS l

SET employment_rate = e.employment_rate

FROM (
    SELECT
        TO_DATE(period_raw, 'YYYY MON') AS month,
        TRIM(value_raw)::NUMERIC AS employment_rate

    FROM stg_employment_raw

    WHERE period_raw ~
        '^20[0-9]{2} (JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)$'

    AND TRIM(value_raw) ~
        '^[+-]?[0-9]+(\.[0-9]+)?$'

) AS e

WHERE l.month = e.month;


-- 5.3 Match regular-pay annual growth
--
-- Whole-economy regular-pay growth, seasonally adjusted.
-- Unavailable earlier observations remain NULL.

UPDATE labour_market AS l

SET regular_pay_growth = p.regular_pay_growth

FROM (
    SELECT
        TO_DATE(period_raw, 'YYYY MON') AS month,
        TRIM(value_raw)::NUMERIC AS regular_pay_growth

    FROM stg_regular_pay_raw

    WHERE period_raw ~
        '^20[0-9]{2} (JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)$'

    AND TRIM(value_raw) ~
        '^[+-]?[0-9]+(\.[0-9]+)?$'

) AS p

WHERE l.month = p.month;


-- ============================================================
-- PART 6: CLEAN AND INSERT REAL GVA
-- ============================================================
--
-- Source: ONS ECY2
-- Seasonally adjusted, constant-price monthly GVA index.
--
-- Observations before January 2000 are excluded to
-- align the analysis period with the other indicators.


INSERT INTO gdp (
    month,
    gva_index
)

SELECT
    TO_DATE(period_raw, 'YYYY MON'),
    TRIM(gva_index_raw)::NUMERIC

FROM stg_gdp_raw

WHERE period_raw ~
    '^20[0-9]{2} (JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)$'

AND TRIM(gva_index_raw) ~
    '^[+-]?[0-9]+(\.[0-9]+)?$';


-- ============================================================
-- PART 7: VERIFY THE IMPORT
-- ============================================================
--
-- Inspect all three final tables before analysis.
-- These are the counts obtained from the September 2026
-- data files used in this project.


SELECT
    'inflation' AS dataset,
    COUNT(*) AS observations,
    MIN(month) AS first_month,
    MAX(month) AS latest_month

FROM inflation

UNION ALL

SELECT
    'labour_market',
    COUNT(*),
    MIN(month),
    MAX(month)

FROM labour_market

UNION ALL

SELECT
    'gdp',
    COUNT(*),
    MIN(month),
    MAX(month)

FROM gdp;


-- Expected results for the original data snapshot:
--
-- inflation:       319 rows
-- labour_market:   317 rows
-- gdp:             319 rows
--
-- Regular-pay growth contains 14 expected missing values.
--
-- Run 02_data_quality.sql for comprehensive validation,
-- including completeness, date continuity and comparison
-- of the GVA staging and final tables.
--
-- ============================================================
-- END OF SCRIPT
-- ============================================================
