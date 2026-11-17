/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and separetes data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create View: gold.machine1
-- =============================================================================

IF OBJECT_ID('gold.machine1', 'V') IS NOT NULL
    DROP VIEW gold.machine1;
GO

CREATE VIEW gold.machine1 AS
SELECT
	period_dt AS production_datetime,
	CASE
		WHEN DATEPART(HOUR,period_dt) BETWEEN 6 AND 14 THEN 'Day'
		WHEN DATEPART(HOUR,period_dt) BETWEEN 14 AND 23 THEN 'Swing'
		ELSE 'Night'
	END AS production_shift,
	good_pcs AS production_good_pieces,
	bad_pcs AS production_bad_pieces,
	target_pcs AS production_target_pieces,
	running_sec AS machine_running_time,
	scheduled_sec AS machine_planned_downtime,
	idle_sec AS machine_idle_time,
	breakdown_sec AS machine_breakdown_time,
	availability_pct AS machine_availability_percent,
	performance_pct AS production_performance_percent,
	quality_pct AS production_quality_percent,
	oee_pct AS overall_equipement_effectiveness_percent
FROM silver.machine1_data;
GO

-- =============================================================================
-- Create View: gold.machine2
-- =============================================================================

IF OBJECT_ID('gold.machine2', 'V') IS NOT NULL
    DROP VIEW gold.machine2;
GO

CREATE VIEW gold.machine2 AS
SELECT
	period_dt AS production_datetime,
	CASE
		WHEN DATEPART(HOUR,period_dt) BETWEEN 6 AND 14 THEN 'Day'
		WHEN DATEPART(HOUR,period_dt) BETWEEN 14 AND 23 THEN 'Swing'
		ELSE 'Night'
	END AS production_shift,
	good_pcs AS production_good_pieces,
	bad_pcs AS production_bad_pieces,
	target_pcs AS production_target_pieces,
	running_sec AS machine_running_time,
	scheduled_sec AS machine_planned_downtime,
	idle_sec AS machine_idle_time,
	breakdown_sec AS machine_breakdown_time,
	availability_pct AS machine_availability_percent,
	performance_pct AS production_performance_percent,
	quality_pct AS production_quality_percent,
	oee_pct AS overall_equipement_effectiveness_percent
FROM silver.machine2_data;
GO
