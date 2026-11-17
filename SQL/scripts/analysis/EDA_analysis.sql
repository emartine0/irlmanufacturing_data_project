--=========================================================================
----------------------- DIMENSION EXPLORATION -----------------------------
--=========================================================================

-- production_datetime
-- production_shift

-- MACHINE 1

SELECT 1 srtodr, 'Oldest Record' AS Quantity_Name, CAST(MIN(production_datetime) AS NVARCHAR) AS Quantity_Value FROM gold.machine1
UNION
SELECT 2 srtodr, 'Newest Record', CAST(MAX(production_datetime) AS NVARCHAR) FROM gold.machine1
UNION
SELECT 3 srtodr, 'Range of Records (months)', CAST(DATEDIFF(MONTH, MIN(production_datetime), MAX(production_datetime)) AS NVARCHAR) FROM gold.machine1
UNION
SELECT 4 srtodr, 'Production Shifts (number)', CAST(COUNT(DISTINCT production_shift) AS NVARCHAR) FROM gold.machine1
ORDER BY srtodr

-- MACHINE 2

SELECT 1 srtodr, 'Oldest Record' AS Quantity_Name, CAST(MIN(production_datetime) AS NVARCHAR) AS Quantity_Value FROM gold.machine2
UNION
SELECT 2 srtodr, 'Newest Record', CAST(MAX(production_datetime) AS NVARCHAR) FROM gold.machine2
UNION
SELECT 3 srtodr, 'Range of Records (months)', CAST(DATEDIFF(MONTH, MIN(production_datetime), MAX(production_datetime)) AS NVARCHAR) FROM gold.machine2
UNION
SELECT 4 srtodr, 'Production Shifts (number)', CAST(COUNT(DISTINCT production_shift) AS NVARCHAR) FROM gold.machine2
ORDER BY srtodr

--=========================================================================
------------------------ MEASURES EXPLORATION -----------------------------
--=========================================================================

-- production_good_pieces 
-- production_bad_pieces
-- production_target_pieces
-- machine_running_time
-- machine_planned_downtime
-- machine_idle_time
-- machine_breakdown_time
-- machine_availability_percent
-- production_perfromance_percent
-- production_quality_percent
-- overall_equipement_effectiveness_percent

-- MACHINE 1

SELECT 1 srtodr, 'Total Produced Pieces' AS Quantity_Name, CAST(SUM(production_good_pieces + production_bad_pieces) AS NVARCHAR) AS Quantity_Value FROM gold.machine1
UNION 
SELECT 2 srtodr, 'Total Produced Bad Pieces' AS Quantity_Name, CAST(SUM(production_bad_pieces) AS NVARCHAR) AS Quantity_Value FROM gold.machine1
UNION 
SELECT 3 srtodr, 'Average Production Quality', CONCAT(CAST(AVG(production_quality_percent) AS NVARCHAR), '%') FROM gold.machine1 WHERE (production_good_pieces + production_bad_pieces) != 0
UNION
SELECT 4 srtodr, 'Total No-Scheduled Downtime', CAST(CAST(SUM(machine_running_time + machine_idle_time + machine_breakdown_time) AS NUMERIC(12,2)) AS NVARCHAR(25)) FROM gold.machine1
UNION
SELECT 5 srtodr, 'Total Breakdown Time', CAST(CAST(SUM(machine_breakdown_time) AS NUMERIC(10,2)) AS NVARCHAR(25)) FROM gold.machine1
UNION
SELECT 6 srtodr, 'Average Machine Availability', CONCAT(CAST(AVG(machine_availability_percent) AS NVARCHAR), '%') FROM gold.machine1 WHERE (machine_running_time + machine_idle_time + machine_breakdown_time) != 0
ORDER BY srtodr

-- MACHINE 2

SELECT 1 srtodr, 'Total Produced Pieces' AS Quantity_Name, CAST(SUM(production_good_pieces + production_bad_pieces) AS NVARCHAR) AS Quantity_Value FROM gold.machine2
UNION 
SELECT 2 srtodr, 'Total Produced Bad Pieces' AS Quantity_Name, CAST(SUM(production_bad_pieces) AS NVARCHAR) AS Quantity_Value FROM gold.machine2
UNION 
SELECT 3 srtodr, 'Average Production Quality', CONCAT(CAST(AVG(production_quality_percent) AS NVARCHAR), '%') FROM gold.machine2 WHERE (production_good_pieces + production_bad_pieces) != 0
UNION
SELECT 4 srtodr, 'Total No-Scheduled Downtime', CAST(CAST(SUM(machine_running_time + machine_idle_time + machine_breakdown_time) AS NUMERIC(12,2)) AS NVARCHAR(25)) FROM gold.machine2
UNION
SELECT 5 srtodr, 'Total Breakdown Time', CAST(CAST(SUM(machine_breakdown_time) AS NUMERIC(10,2)) AS NVARCHAR(25)) FROM gold.machine2
UNION
SELECT 6 srtodr, 'Average Machine Availability', CONCAT(CAST(AVG(machine_availability_percent) AS NVARCHAR), '%') FROM gold.machine2 WHERE (machine_running_time + machine_idle_time + machine_breakdown_time) != 0
ORDER BY srtodr


--=========================================================================
--------------------------- MAGNITUD ANALYSIS -----------------------------
--=========================================================================

/* The next queries can also be done for gold.machine2 data */
	
-- Compute the average pieces produced by month by year (per hour)

SELECT
	YEAR(production_datetime) AS production_year,
	MONTH(production_datetime) AS production_month,
	AVG(production_good_pieces + production_bad_pieces) AS average_total_produced_pieces
FROM gold.machine1
WHERE (production_good_pieces + production_bad_pieces) != 0
GROUP BY YEAR(production_datetime), MONTH(production_datetime)
ORDER BY YEAR(production_datetime), MONTH(production_datetime)


-- Compute the average pieces produced shift (per hour)

SELECT
	production_shift,
	AVG(production_good_pieces + production_bad_pieces) AS average_total_produced_pieces
FROM gold.machine1
WHERE (production_good_pieces + production_bad_pieces) != 0
GROUP BY production_shift


-- Compute the average production quality by shift (per hour)

SELECT
	production_shift,
	ROUND(AVG(production_quality_percent),2) AS average_production_quality
FROM gold.machine1
WHERE (production_good_pieces + production_bad_pieces) != 0
GROUP BY production_shift

-- Compute the average breakdown time by month by year (per hour)

SELECT
	YEAR(production_datetime) AS year,
	MONTH(production_datetime) AS month,
	ROUND(AVG(machine_breakdown_time),2) AS avergae_breakdown_time
FROM gold.machine1
WHERE (machine_running_time + machine_idle_time + machine_breakdown_time) != 0 
GROUP BY YEAR(production_datetime), MONTH(production_datetime)
ORDER BY YEAR(production_datetime), MONTH(production_datetime)


-- Compute the average breakdown time by shift (per hour)

SELECT
	production_shift,
	ROUND(AVG(machine_breakdown_time),2) AS avergae_breakdown_time
FROM gold.machine1
WHERE (machine_running_time + machine_idle_time + machine_breakdown_time) != 0 
GROUP BY production_shift


-- Calculate the average machine availability by shift (per hour)

SELECT
	production_shift,
	ROUND(AVG(machine_availability_percent),2) AS average_machine_availability
FROM gold.machine1
WHERE (machine_running_time + machine_idle_time + machine_breakdown_time) != 0 
GROUP BY production_shift

--=========================================================================
-------------------- RANKING ANALYSIS TOP N -BOTTOM N ---------------------
--=========================================================================

-- Find the TOP 3 months where it was produced the most in 2024 and 2025

SELECT TOP 3
	MONTH(production_datetime) AS month,
	SUM(production_good_pieces + production_bad_pieces) AS total_produced_pieces
FROM gold.machine1
WHERE YEAR(production_datetime) = 2024
GROUP BY MONTH(production_datetime)
ORDER BY SUM(production_good_pieces + production_bad_pieces) DESC

SELECT TOP 3
	MONTH(production_datetime) AS month,
	SUM(production_good_pieces + production_bad_pieces) AS total_produced_pieces
FROM gold.machine1
WHERE YEAR(production_datetime) = 2025
GROUP BY MONTH(production_datetime)
ORDER BY SUM(production_good_pieces + production_bad_pieces) DESC

-- Find the TOP 3 months where it was produced the less in 2024 and 2025

SELECT TOP 3
	MONTH(production_datetime) AS month,
	SUM(production_good_pieces + production_bad_pieces) AS total_produced_pieces
FROM gold.machine1
WHERE YEAR(production_datetime) = 2024
GROUP BY MONTH(production_datetime)
ORDER BY SUM(production_good_pieces + production_bad_pieces) ASC

SELECT TOP 3
	MONTH(production_datetime) AS month,
	SUM(production_good_pieces + production_bad_pieces) AS total_produced_pieces
FROM gold.machine1
WHERE YEAR(production_datetime) = 2025
GROUP BY MONTH(production_datetime)
ORDER BY SUM(production_good_pieces + production_bad_pieces) ASC


-- Find the TOP 3 months where there was the most breakdowntime accumulated in 2024 and 2025

SELECT TOP 3
	MONTH(production_datetime) AS month,
	SUM(machine_breakdown_time) AS total_breakdown_time
FROM gold.machine1
WHERE YEAR(production_datetime) = 2024
GROUP BY MONTH(production_datetime)
ORDER BY SUM(machine_breakdown_time) DESC

SELECT TOP 3
	MONTH(production_datetime) AS month,
	SUM(machine_breakdown_time) AS total_breakdown_time
FROM gold.machine1
WHERE YEAR(production_datetime) = 2025
GROUP BY MONTH(production_datetime)
ORDER BY SUM(machine_breakdown_time) DESC

-- Find the TOP 3 months where there was the less breakdowntime accumulated in 2024 and 2025

SELECT TOP 3
	MONTH(production_datetime) AS month,
	SUM(machine_breakdown_time) AS total_breakdown_time
FROM gold.machine1
WHERE YEAR(production_datetime) = 2024
GROUP BY MONTH(production_datetime)
ORDER BY SUM(machine_breakdown_time) ASC

SELECT TOP 3
	MONTH(production_datetime) AS month,
	SUM(machine_breakdown_time) AS total_breakdown_time
FROM gold.machine1
WHERE YEAR(production_datetime) = 2025
GROUP BY MONTH(production_datetime)
ORDER BY SUM(machine_breakdown_time) ASC
