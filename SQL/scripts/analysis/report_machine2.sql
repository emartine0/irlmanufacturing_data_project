/*
=================================================================================
Production Report Machine 2 2024-2026
=================================================================================
Script Purpose:
    This report (VIEW) consolidates key production metrics, details and evaluations
    related to machines.

Highlights:
    1. Gathers essential fields such as shift, production and machine-time details.
    2. Aggregates production at shift-level and date-level metrics.
        -- total produced pieces
        -- total production of bad pieces
        -- total no-scheduled downtime
        -- total breakdown time
    3. Calculates valuable production KPI's
        -- Production quality percentage
        -- Machine availability percentage
    4. Segments months in which:
     (a) the production of bad pieces is above the average and
     (b) also in which the breakdown time is above the average.
=================================================================================
*/

IF OBJECT_ID('gold.report_machine2', 'V') IS NOT NULL
    DROP VIEW gold.report_machine2;
GO

CREATE VIEW gold.report_machine2 AS
WITH base_query AS (
---------------------------------------------------------------------------------
/*              BASE QUERY: RETRIEVES CORE COLUMNS FROM TABLES                 */
---------------------------------------------------------------------------------
SELECT
     [production_datetime]
    ,[production_shift]
    ,[production_good_pieces]
    ,[production_bad_pieces]
    ,[machine_running_time]
    ,[machine_idle_time]
    ,[machine_breakdown_time]
    ,[machine_availability_percent]
    ,[production_quality_percent]
FROM gold.machine2
WHERE (production_good_pieces + production_bad_pieces) != 0 AND
      (machine_running_time + machine_idle_time + machine_breakdown_time) != 0)
, production_aggregation AS (
---------------------------------------------------------------------------------
/*         PRODUCTION AGGREGATIONS: KEY METRIC AT PRODUCTION LEVEL             */
---------------------------------------------------------------------------------
SELECT
    YEAR(production_datetime) AS year,
    MONTH(production_datetime) AS month,
    production_shift,
    SUM(production_good_pieces + production_bad_pieces) AS total_pieces,
    SUM(production_bad_pieces) AS total_bad_pieces,
    SUM(machine_running_time + machine_idle_time + machine_breakdown_time) AS total_no_scheduled_time,
    SUM(machine_breakdown_time) AS total_breakdown_time,
    ROUND(AVG(machine_availability_percent),2) AS average_machine_availability,
    ROUND(AVG(production_quality_percent),2) AS average_production_quality
FROM base_query
GROUP BY YEAR(production_datetime), MONTH(production_datetime), production_shift)
---------------------------------------------------------------------------------
/*     CATEGORIZATION OF MONTHS AND SHIFTS: PRODUCTION AND BREAKDOWN TIME      */
---------------------------------------------------------------------------------
SELECT
    year,
    month,
    production_shift,
    total_pieces,
    total_bad_pieces,
    AVG(total_bad_pieces) OVER(PARTITION BY year) AS bp_year_average,
    AVG(total_bad_pieces) OVER(PARTITION BY month) AS bp_month_average,
    CASE WHEN (AVG(total_bad_pieces) OVER(PARTITION BY year)) - (AVG(total_bad_pieces) OVER(PARTITION BY month)) < 0
         THEN 'ABOVE the year average'
         ELSE 'BELOW or EQUAL the year average'
    END AS month_bad_production_test,
    average_production_quality,
    total_no_scheduled_time,
    total_breakdown_time,
    AVG(total_breakdown_time) OVER(PARTITION BY year) AS bd_year_average,
    AVG(total_breakdown_time) OVER(PARTITION BY month) AS bd_month_average,
    CASE WHEN (AVG(total_breakdown_time) OVER(PARTITION BY year)) - (AVG(total_breakdown_time) OVER(PARTITION BY month)) < 0
         THEN 'ABOVE the year average'
         ELSE 'BELOW or EQUAL the year average'
    END AS month_breakdown_machine_test,
    average_machine_availability
FROM production_aggregation
