-- ====================================================================
-- Checking descriptions 'bronze.machine2_data'
-- ====================================================================

/*
	ACTION: (1) Eliminate SQL reserved words from the column names,
			(2) Include the units for the quanities in the column names.
*/

-- ====================================================================
-- Checking relations 'silver.machine2_data'
-- ====================================================================

/*
	Total time (3600 sec) (+)
		|
		├── Running time
		│
		├── Scheduled time
		│
		├── Idle time
		│
		└── Breakdown time
		
	Total pieces (+)
		|
		├── Good_pieces
		│
		└── Bad_pieces

	Overall Equipement Effectiveness (x)
		|
		├── Availability
		│
		├── Performance
		│
		└── Quality

	TEST: (1) Create aggregated column "Total pieces"

		  (2) Test complex columns (target_pcs, availability_pcs, performance_pcs, quality_pcs, oee_pct)

			target_pcs = (running_sec + idle_sec + breakdown_sec) / cycle time

			availability_pct = (running_sec + idle_sec) / (runnig_sec + idle_sec + breakdown_sec)
			performance_pct = (good_pcs + bad_pcs) / target_pcs
			quality_pct = good_pcs / (good_pcs + bad_pcs)
*/

-- cycle time

SELECT
	YEAR(period_dt),
	AVG(CAST((running_sec + idle_sec + breakdown_sec) AS FLOAT) / target_pcs) AS cycle_time
FROM silver.machine2_data
WHERE target_pcs != 0
GROUP BY YEAR(period_dt)


-- target test (There exist a significant difference between these two columns? ONLY IN 2024)

SELECT
	period_dt,
	target_pcs,
	AVG(target_pcs) OVER(PARTITION BY YEAR(period_dt)),
	CASE
		 WHEN YEAR(period_dt) = 2024
		 THEN (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 7.49)
		 ELSE (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 8.28)
	END AS calc_target,
	AVG(CASE
		 WHEN YEAR(period_dt) = 2024
		 THEN (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 7.49)
		 ELSE (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 8.28)
	END) OVER(PARTITION BY YEAR(period_dt))
FROM silver.machine2_data

-- Checking cycle time (monthly) for year 2024

SELECT
	MONTH(period_dt),
	AVG(CAST((running_sec + idle_sec + breakdown_sec) AS FLOAT) / target_pcs) AS cycle_time
FROM silver.machine2_data
WHERE target_pcs != 0 AND YEAR(period_dt) = 2024
GROUP BY MONTH(period_dt)
ORDER BY MONTH(period_dt) ASC

/* There was a change in the second half of 2024 to 8.28 sec/pc 
in cycle time, and the cycle time for the first half of 2024 was 5.98 */

-- Checking the average target pieces for the firs half of 2024

SELECT
	period_dt,
	AVG(CAST((running_sec + idle_sec + breakdown_sec) AS FLOAT) / target_pcs) OVER()
FROM silver.machine2_data
WHERE target_pcs != 0 AND YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6

/* The cycle time is 5.98 sec/pc */

-- Checking differences between computed average and actual target pieces
-- first half of 2024
SELECT
	period_dt,
	target_pcs,
	AVG(target_pcs) OVER(),
	(CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 5.98) AS calc_target,
	AVG(CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 5.98) OVER()
FROM silver.machine2_data
WHERE YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6

-- second half of 2024
SELECT
	period_dt,
	target_pcs,
	AVG(target_pcs) OVER(),
	(CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 8.28) AS calc_target,
	AVG(CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 8.28) OVER()
FROM silver.machine2_data
WHERE YEAR(period_dt) = 2024 AND MONTH(period_dt) NOT BETWEEN 1 AND 6

/* Theres no significative difference */


-- availability test (There exist a significant difference between these two columns?)

SELECT
	period_dt,
	CASE 
	WHEN (running_sec + idle_sec + breakdown_sec) = 0 THEN 0
	WHEN (running_sec + idle_sec + breakdown_sec) != 0 THEN ROUND((CAST(running_sec + idle_sec AS FLOAT) / (running_sec + idle_sec + breakdown_sec)) * 100,2)
	END AS calc_availability,
	AVG(CASE 
	WHEN (running_sec + idle_sec + breakdown_sec) = 0 THEN 0
	WHEN (running_sec + idle_sec + breakdown_sec) != 0 THEN ROUND((CAST(running_sec + idle_sec AS FLOAT) / (running_sec + idle_sec + breakdown_sec)) * 100,2)
	END) OVER(),
	availability_pct,
	AVG(availability_pct) OVER()
FROM silver.machine2_data

/* Theres no significative difference */

-- performance test (There exist a significant difference between these two columns?)
-- Take into account that the cycle time for the first half of 2024 is 5.98 sec/pc
-- This implies that the performance analysis needs to be done first for jan-jun 2024
-- and then for the rest of the records

-- 2024-1
SELECT
	period_dt,
	CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 5.98 AS calc_target,
	CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 5.98)) * 100,2)
	ELSE 0 
	END AS calc_performance,
	AVG(CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 5.98)) * 100,2)
	ELSE 0 
	END) OVER(),
	performance_pct,
	AVG(performance_pct) OVER()
FROM silver.machine2_data
WHERE YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6

/* Theres is a significative difference calc_perf avg = 64.9564 and perf_pct avg = 1363.4538 */

-- 2024-2
SELECT
	period_dt,
	CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 8.28 AS calc_target,
	CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 8.28)) * 100,2)
	ELSE 0 
	END AS calc_performance,
	AVG(CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 8.28)) * 100,2)
	ELSE 0 
	END) OVER(),
	performance_pct,
	AVG(performance_pct) OVER()
FROM silver.machine2_data
WHERE YEAR(period_dt) = 2024 AND MONTH(period_dt) NOT BETWEEN 1 AND 6

/* Theres is a significative difference */

-- 2025-26
SELECT
	period_dt,
	CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 8.28 AS calc_target,
	CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 8.28)) * 100,2)
	ELSE 0 
	END AS calc_performance,
	AVG(CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 8.28)) * 100,2)
	ELSE 0 
	END) OVER(),
	performance_pct,
	AVG(performance_pct) OVER()
FROM silver.machine2_data
WHERE YEAR(period_dt) IN (2025,2026)

/* Theres is a significative difference */

-- Quality test (There exist a significant difference between these two columns? NO)

SELECT
	good_pcs,
	bad_pcs,
	good_pcs + bad_pcs AS real_produced_units,
	CASE WHEN good_pcs + bad_pcs != 0 THEN (CAST(good_pcs AS FLOAT) / (good_pcs + bad_pcs)) * 100
	ELSE 0
	END AS calc_quality,
	AVG(CASE WHEN good_pcs + bad_pcs != 0 THEN (CAST(good_pcs AS FLOAT) / (good_pcs + bad_pcs)) * 100
	ELSE 0
	END) OVER(),
	quality_pct,
	AVG(quality_pct) OVER()
FROM silver.machine2_data

/* 
	ISSUE: There's a significant difference between the mean values of the performance_pct column
	and a computed version of it.
	ACTION: Understand the source of the issue taking into account that the cycle time for the first half of
	2024 is 5.98 and for the rest 8.28 sec/pc
*/

-- 2024-1
SELECT
	period_dt,
	CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 5.98)) * 100,2)
	ELSE 0 
	END AS calc_performance,
	performance_pct
FROM silver.machine2_data
WHERE (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND (CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 5.98)) * 100,2)
	ELSE 0 
	END) NOT BETWEEN performance_pct - 1 AND performance_pct + 1

-- 2024-2
SELECT
	period_dt,
	CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 8.28)) * 100,2)
	ELSE 0 
	END AS calc_performance,
	performance_pct
FROM silver.machine2_data
WHERE (YEAR(period_dt) = 2024 AND MONTH(period_dt) NOT BETWEEN 1 AND 6) AND (CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 8.28)) * 100,2)
	ELSE 0 
	END) NOT BETWEEN performance_pct - 1 AND performance_pct + 1

-- 2025-26
SELECT
	period_dt,
	CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 8.28)) * 100,2)
	ELSE 0 
	END AS calc_performance,
	performance_pct
FROM silver.machine2_data
WHERE (YEAR(period_dt) IN (2025,2026)) AND (CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 8.28)) * 100,2)
	ELSE 0 
	END) NOT BETWEEN performance_pct - 1 AND performance_pct + 1

/*
	ISSUE: There are 402, 152 and 108 rows, respectively for their time periods, 
	in which the difference between the calculation an the actual row value seems artificial.
	ACTION: Check the source table in order to find more information about this issue.
*/

-- 2024-1
SELECT
	period_dt,
	good_pcs,
	bad_pcs,
	(CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 5.98) AS calc_target,
	running_sec,
	scheduled_sec,
	idle_sec,
	breakdown_sec,
	CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 5.98)) * 100,2)
	ELSE 0 
	END AS calc_performance,
	performance_pct
FROM silver.machine2_data
WHERE (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND (CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 5.98)) * 100,2)
	ELSE 0 
	END) NOT BETWEEN performance_pct - 1 AND performance_pct + 1

-- 2024-2
SELECT
	period_dt,
	good_pcs,
	bad_pcs,
	(CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 8.28) AS calc_target,
	running_sec,
	scheduled_sec,
	idle_sec,
	breakdown_sec,
	CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 8.28)) * 100,2)
	ELSE 0 
	END AS calc_performance,
	performance_pct
FROM silver.machine2_data
WHERE (YEAR(period_dt) = 2024 AND MONTH(period_dt) NOT BETWEEN 1 AND 6) AND (CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 8.28)) * 100,2)
	ELSE 0 
	END) NOT BETWEEN performance_pct - 1 AND performance_pct + 1

-- 2025-26
SELECT
	period_dt,
	good_pcs,
	bad_pcs,
	(CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 8.28) AS calc_target,
	running_sec,
	scheduled_sec,
	idle_sec,
	breakdown_sec,
	CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 8.28)) * 100,2)
	ELSE 0 
	END AS calc_performance,
	performance_pct
FROM silver.machine2_data
WHERE (YEAR(period_dt) IN (2025,2026)) AND (CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 8.28)) * 100,2)
	ELSE 0 
	END) NOT BETWEEN performance_pct - 1 AND performance_pct + 1

/*
	ISSUE: The fundamental problem with these differences is that there are inconsistencies in data. 
	Particularly, (1) there are produced pieces witout running-machine time and (2) there are nonsense performance
	values like 34200%.
	ACTION: (1) Assign running time in accordance to the period cycle time.
	(2) assign scheduled time. (3) assign target pieces. (4) assign performance. (5) assign oee.
	Each one of these steps for the three time periods 2014-1, 2024-2, 2025-26.
	
*/

-- (1) 2024-1

SELECT
	period_dt,
	good_pcs,
	bad_pcs,
	target_pcs,
	CASE 
		WHEN (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1)
		THEN CASE
				 WHEN (good_pcs + bad_pcs) * 5.98 > 3600 
				 THEN 3600
				 ELSE (good_pcs + bad_pcs) * 5.98
			 END
		ELSE running_sec
	END AS assign_running,
	running_sec,
	scheduled_sec,
	idle_sec,
	breakdown_sec,
	availability_pct,
	calc_performance,
	performance_pct,
	quality_pct,
	oee_pct
FROM (
	SELECT
		period_dt,
		good_pcs,
		bad_pcs,
		(CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 5.98) AS target_pcs,
		running_sec,
		scheduled_sec,
		idle_sec,
		breakdown_sec,
		availability_pct,
		CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 5.98)) * 100,2)
		ELSE 0 
		END AS calc_performance,
		performance_pct,
		quality_pct,
		oee_pct
	FROM silver.machine2_data
	)t
/*WHERE (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND 
	(CASE
		WHEN calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1 
		THEN CASE
				 WHEN (good_pcs + bad_pcs) * 5.98 > 3600 
			     THEN 3600
				 ELSE (good_pcs + bad_pcs) * 5.98
			 END
		ELSE running_sec
	END) != running_sec*/

/*WHERE (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1*/


-- (2) 2024-1

SELECT
	period_dt,
		good_pcs,
		bad_pcs,
		target_pcs,
		assign_running,
		running_sec,
		CASE 
			WHEN (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1)
			THEN 3600 - assign_running - idle_sec - breakdown_sec
			ELSE scheduled_sec
		END AS assign_scheduled,
		scheduled_sec,
		idle_sec,
		breakdown_sec,
		availability_pct,
		calc_performance,
		performance_pct,
		quality_pct,
		oee_pct
FROM (
	SELECT
		period_dt,
		good_pcs,
		bad_pcs,
		target_pcs,
		CASE 
			WHEN (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1)
			THEN CASE
					 WHEN (good_pcs + bad_pcs) * 5.98 > 3600 
					 THEN 3600
					 ELSE (good_pcs + bad_pcs) * 5.98
				 END
			ELSE running_sec
		END AS assign_running,
		running_sec,
		scheduled_sec,
		idle_sec,
		breakdown_sec,
		availability_pct,
		calc_performance,
		performance_pct,
		quality_pct,
		oee_pct
	FROM (
		SELECT
			period_dt,
			good_pcs,
			bad_pcs,
			(CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 5.98) AS target_pcs,
			running_sec,
			scheduled_sec,
			idle_sec,
			breakdown_sec,
			availability_pct,
			CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 5.98)) * 100,2)
			ELSE 0 
			END AS calc_performance,
			performance_pct,
			quality_pct,
			oee_pct
		FROM silver.machine2_data
		)t
	)t
/*WHERE (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND (CASE 
			WHEN calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1 
			THEN 3600 - assign_running - idle_sec - breakdown_sec
			ELSE scheduled_sec
		END) != scheduled_sec*/
		

-- (3) 2024-1
SELECT
	period_dt,
	good_pcs,
	bad_pcs,
	CASE 
		WHEN (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
		THEN good_pcs + bad_pcs
		ELSE target_pcs
	END AS assign_target,
	target_pcs,
	assign_running,
	running_sec,
	assign_scheduled,
	scheduled_sec,
	idle_sec,
	breakdown_sec,
	availability_pct,
	calc_performance,
	performance_pct,
	quality_pct,
	oee_pct
FROM (
	SELECT
		period_dt,
		good_pcs,
		bad_pcs,
		target_pcs,
		assign_running,
		running_sec,
		CASE 
			WHEN (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
			THEN 3600 - assign_running - idle_sec - breakdown_sec
			ELSE scheduled_sec
		END AS assign_scheduled,
		scheduled_sec,
		idle_sec,
		breakdown_sec,
		availability_pct,
		calc_performance,
		performance_pct,
		quality_pct,
		oee_pct
	FROM (
		SELECT
			period_dt,
			good_pcs,
			bad_pcs,
			target_pcs,
			CASE 
				WHEN (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
				THEN CASE
						 WHEN (good_pcs + bad_pcs) * 5.98 > 3600 
						 THEN 3600
						 ELSE (good_pcs + bad_pcs) * 5.98
					 END
				ELSE running_sec
			END AS assign_running,
			running_sec,
			scheduled_sec,
			idle_sec,
			breakdown_sec,
			availability_pct,
			calc_performance,
			performance_pct,
			quality_pct,
			oee_pct
		FROM (
			SELECT
				period_dt,
				good_pcs,
				bad_pcs,
				(CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 5.98) AS target_pcs,
				running_sec,
				scheduled_sec,
				idle_sec,
				breakdown_sec,
				availability_pct,
				CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 5.98)) * 100,2)
				ELSE 0 
				END AS calc_performance,
				performance_pct,
				quality_pct,
				oee_pct
			FROM silver.machine2_data
			)t
		)t
	)t
/*WHERE (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND (CASE 
		WHEN calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1 
		THEN good_pcs + bad_pcs
		ELSE target_pcs
	END) != target_pcs*/

-- (4) 2024-1

SELECT
	period_dt,
	good_pcs,
	bad_pcs,
	assign_target,
	target_pcs,
	assign_running,
	running_sec,
	assign_scheduled,
	scheduled_sec,
	idle_sec,
	breakdown_sec,
	availability_pct,
	CASE
		WHEN (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
		THEN (CAST((good_pcs + bad_pcs) AS FLOAT) / assign_target) * 100
		ELSE calc_performance
	END AS assign_performance,
	calc_performance,
	performance_pct,
	quality_pct,
	oee_pct
FROM (
	SELECT
		period_dt,
		good_pcs,
		bad_pcs,
		CASE 
			WHEN (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
			THEN good_pcs + bad_pcs
			ELSE target_pcs
		END AS assign_target,
		target_pcs,
		assign_running,
		running_sec,
		assign_scheduled,
		scheduled_sec,
		idle_sec,
		breakdown_sec,
		availability_pct,
		calc_performance,
		performance_pct,
		quality_pct,
		oee_pct
	FROM (
		SELECT
			period_dt,
			good_pcs,
			bad_pcs,
			target_pcs,
			assign_running,
			running_sec,
			CASE 
				WHEN (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1)
				THEN 3600 - assign_running - idle_sec - breakdown_sec
				ELSE scheduled_sec
			END AS assign_scheduled,
			scheduled_sec,
			idle_sec,
			breakdown_sec,
			availability_pct,
			calc_performance,
			performance_pct,
			quality_pct,
			oee_pct
		FROM (
			SELECT
				period_dt,
				good_pcs,
				bad_pcs,
				target_pcs,
				CASE 
					WHEN (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
					THEN CASE
							 WHEN (good_pcs + bad_pcs) * 5.98 > 3600 
							 THEN 3600
							 ELSE (good_pcs + bad_pcs) * 5.98
						 END
					ELSE running_sec
				END AS assign_running,
				running_sec,
				scheduled_sec,
				idle_sec,
				breakdown_sec,
				availability_pct,
				calc_performance,
				performance_pct,
				quality_pct,
				oee_pct
			FROM (
				SELECT
					period_dt,
					good_pcs,
					bad_pcs,
					(CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 5.98) AS target_pcs,
					running_sec,
					scheduled_sec,
					idle_sec,
					breakdown_sec,
					availability_pct,
					CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 5.98)) * 100,2)
					ELSE 0 
					END AS calc_performance,
					performance_pct,
					quality_pct,
					oee_pct
				FROM silver.machine2_data
				)t
			)t
		)t
	)t
/*WHERE (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND 
		(CASE
		WHEN calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1 
		THEN CAST((good_pcs + bad_pcs) AS FLOAT) / assign_target
		ELSE calc_performance
	END) != calc_performance*/

-- (5) 2024-1

SELECT
	period_dt,
	good_pcs,
	bad_pcs,
	assign_target,
	target_pcs,
	assign_running,
	running_sec,
	assign_scheduled,
	scheduled_sec,
	idle_sec,
	breakdown_sec,
	availability_pct,
	assign_performance,
	calc_performance,
	performance_pct,
	quality_pct,
	CASE
		WHEN (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
		THEN (availability_pct * assign_performance * quality_pct) / 10000
		ELSE oee_pct
	END AS assign_oee,
	oee_pct
FROM (
SELECT
	period_dt,
	good_pcs,
	bad_pcs,
	assign_target,
	target_pcs,
	assign_running,
	running_sec,
	assign_scheduled,
	scheduled_sec,
	idle_sec,
	breakdown_sec,
	availability_pct,
	CASE
		WHEN (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1)
		THEN (CAST((good_pcs + bad_pcs) AS FLOAT) / assign_target) * 100
		ELSE calc_performance
	END AS assign_performance,
	calc_performance,
	performance_pct,
	quality_pct,
	oee_pct
FROM (
	SELECT
		period_dt,
		good_pcs,
		bad_pcs,
		CASE 
			WHEN (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1)
			THEN good_pcs + bad_pcs
			ELSE target_pcs
		END AS assign_target,
		target_pcs,
		assign_running,
		running_sec,
		assign_scheduled,
		scheduled_sec,
		idle_sec,
		breakdown_sec,
		availability_pct,
		calc_performance,
		performance_pct,
		quality_pct,
		oee_pct
	FROM (
		SELECT
			period_dt,
			good_pcs,
			bad_pcs,
			target_pcs,
			assign_running,
			running_sec,
			CASE 
				WHEN (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1)
				THEN 3600 - assign_running - idle_sec - breakdown_sec
				ELSE scheduled_sec
			END AS assign_scheduled,
			scheduled_sec,
			idle_sec,
			breakdown_sec,
			availability_pct,
			calc_performance,
			performance_pct,
			quality_pct,
			oee_pct
		FROM (
			SELECT
				period_dt,
				good_pcs,
				bad_pcs,
				target_pcs,
				CASE 
					WHEN (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
					THEN CASE
								WHEN (good_pcs + bad_pcs) * 5.98 > 3600 
								THEN 3600
								ELSE (good_pcs + bad_pcs) * 5.98
							END
					ELSE running_sec
				END AS assign_running,
				running_sec,
				scheduled_sec,
				idle_sec,
				breakdown_sec,
				availability_pct,
				calc_performance,
				performance_pct,
				quality_pct,
				oee_pct
			FROM (
				SELECT
					period_dt,
					good_pcs,
					bad_pcs,
					(CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 5.98) AS target_pcs,
					running_sec,
					scheduled_sec,
					idle_sec,
					breakdown_sec,
					availability_pct,
					CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 5.98)) * 100,2)
					ELSE 0 
					END AS calc_performance,
					performance_pct,
					quality_pct,
					oee_pct
				FROM silver.machine2_data
				)t
			)t
		)t
	)t
)t
/*WHERE (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND
		(CASE
			WHEN calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1 
			THEN availability_pct * assign_performance * quality_pct
			ELSE oee_pct
		END) != oee_pct*/

-- (6) 2024-1

SELECT
	period_dt,
	good_pcs,
	bad_pcs,
	assign_target,
	assign_running,
	assign_scheduled,
	idle_sec,
	breakdown_sec,
	availability_pct,
	assign_performance,
	quality_pct,
	assign_oee
FROM (
	SELECT
		period_dt,
		good_pcs,
		bad_pcs,
		assign_target,
		target_pcs,
		assign_running,
		running_sec,
		assign_scheduled,
		scheduled_sec,
		idle_sec,
		breakdown_sec,
		availability_pct,
		assign_performance,
		calc_performance,
		performance_pct,
		quality_pct,
		CASE
			WHEN (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
			THEN (availability_pct * assign_performance * quality_pct) / 10000
			ELSE oee_pct
		END AS assign_oee,
		oee_pct
	FROM (
	SELECT
		period_dt,
		good_pcs,
		bad_pcs,
		assign_target,
		target_pcs,
		assign_running,
		running_sec,
		assign_scheduled,
		scheduled_sec,
		idle_sec,
		breakdown_sec,
		availability_pct,
		CASE
			WHEN (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
			THEN (CAST((good_pcs + bad_pcs) AS FLOAT) / assign_target) * 100
			ELSE calc_performance
		END AS assign_performance,
		calc_performance,
		performance_pct,
		quality_pct,
		oee_pct
	FROM (
		SELECT
			period_dt,
			good_pcs,
			bad_pcs,
			CASE 
				WHEN (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
				THEN good_pcs + bad_pcs
				ELSE target_pcs
			END AS assign_target,
			target_pcs,
			assign_running,
			running_sec,
			assign_scheduled,
			scheduled_sec,
			idle_sec,
			breakdown_sec,
			availability_pct,
			calc_performance,
			performance_pct,
			quality_pct,
			oee_pct
		FROM (
			SELECT
				period_dt,
				good_pcs,
				bad_pcs,
				target_pcs,
				assign_running,
				running_sec,
				CASE 
					WHEN (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
					THEN 3600 - assign_running - idle_sec - breakdown_sec
					ELSE scheduled_sec
				END AS assign_scheduled,
				scheduled_sec,
				idle_sec,
				breakdown_sec,
				availability_pct,
				calc_performance,
				performance_pct,
				quality_pct,
				oee_pct
			FROM (
				SELECT
					period_dt,
					good_pcs,
					bad_pcs,
					target_pcs,
					CASE 
						WHEN (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6) AND (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
						THEN CASE
									WHEN (good_pcs + bad_pcs) * 5.98 > 3600 
									THEN 3600
									ELSE (good_pcs + bad_pcs) * 5.98
								END
						ELSE running_sec
					END AS assign_running,
					running_sec,
					scheduled_sec,
					idle_sec,
					breakdown_sec,
					availability_pct,
					calc_performance,
					performance_pct,
					quality_pct,
					oee_pct
				FROM (
					SELECT
						period_dt,
						good_pcs,
						bad_pcs,
						(CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 5.98) AS target_pcs,
						running_sec,
						scheduled_sec,
						idle_sec,
						breakdown_sec,
						availability_pct,
						CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 5.98)) * 100,2)
						ELSE 0 
						END AS calc_performance,
						performance_pct,
						quality_pct,
						oee_pct
					FROM silver.machine2_data
					)t
				)t
			)t
		)t
	)t
)t

------------------------------------------------------------
------------------- FINAL CODE 2024-1 ----------------------
------------------------------------------------------------

SELECT
	period_dt,
	good_pcs,
	bad_pcs,
	assign_target,
	assign_running,
	assign_scheduled,
	idle_sec,
	breakdown_sec,
	availability_pct,
	assign_performance,
	quality_pct,
	assign_oee
FROM (
	SELECT
		period_dt,
		good_pcs,
		bad_pcs,
		assign_target,
		target_pcs,
		assign_running,
		running_sec,
		assign_scheduled,
		scheduled_sec,
		idle_sec,
		breakdown_sec,
		availability_pct,
		assign_performance,
		calc_performance,
		performance_pct,
		quality_pct,
		CASE
			WHEN (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
			THEN (availability_pct * assign_performance * quality_pct) / 10000
			ELSE oee_pct
		END AS assign_oee,
		oee_pct
	FROM (
	SELECT
		period_dt,
		good_pcs,
		bad_pcs,
		assign_target,
		target_pcs,
		assign_running,
		running_sec,
		assign_scheduled,
		scheduled_sec,
		idle_sec,
		breakdown_sec,
		availability_pct,
		CASE
			WHEN (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
			THEN (CAST((good_pcs + bad_pcs) AS FLOAT) / assign_target) * 100
			ELSE calc_performance
		END AS assign_performance,
		calc_performance,
		performance_pct,
		quality_pct,
		oee_pct
	FROM (
		SELECT
			period_dt,
			good_pcs,
			bad_pcs,
			CASE 
				WHEN (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
				THEN good_pcs + bad_pcs
				ELSE target_pcs
			END AS assign_target,
			target_pcs,
			assign_running,
			running_sec,
			assign_scheduled,
			scheduled_sec,
			idle_sec,
			breakdown_sec,
			availability_pct,
			calc_performance,
			performance_pct,
			quality_pct,
			oee_pct
		FROM (
			SELECT
				period_dt,
				good_pcs,
				bad_pcs,
				target_pcs,
				assign_running,
				running_sec,
				CASE 
					WHEN (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
					THEN 3600 - assign_running - idle_sec - breakdown_sec
					ELSE scheduled_sec
				END AS assign_scheduled,
				scheduled_sec,
				idle_sec,
				breakdown_sec,
				availability_pct,
				calc_performance,
				performance_pct,
				quality_pct,
				oee_pct
			FROM (
				SELECT
					period_dt,
					good_pcs,
					bad_pcs,
					target_pcs,
					CASE 
						WHEN (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
						THEN CASE
									WHEN (good_pcs + bad_pcs) * 5.98 > 3600 
									THEN 3600
									ELSE (good_pcs + bad_pcs) * 5.98
								END
						ELSE running_sec
					END AS assign_running,
					running_sec,
					scheduled_sec,
					idle_sec,
					breakdown_sec,
					availability_pct,
					calc_performance,
					performance_pct,
					quality_pct,
					oee_pct
				FROM (
					SELECT
						period_dt,
						good_pcs,
						bad_pcs,
						(CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 5.98) AS target_pcs,
						running_sec,
						scheduled_sec,
						idle_sec,
						breakdown_sec,
						availability_pct,
						CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 5.98)) * 100,2)
						ELSE 0 
						END AS calc_performance,
						performance_pct,
						quality_pct,
						oee_pct
					FROM silver.machine2_data
					WHERE (YEAR(period_dt) = 2024 AND MONTH(period_dt) BETWEEN 1 AND 6)
					)t
				)t
			)t
		)t
	)t
)t

------------------------------------------------------------
------------------- FINAL CODE 2024-2 ----------------------
------------------------------------------------------------

SELECT
	period_dt,
	good_pcs,
	bad_pcs,
	assign_target,
	assign_running,
	assign_scheduled,
	idle_sec,
	breakdown_sec,
	availability_pct,
	assign_performance,
	quality_pct,
	assign_oee
FROM (
	SELECT
		period_dt,
		good_pcs,
		bad_pcs,
		assign_target,
		target_pcs,
		assign_running,
		running_sec,
		assign_scheduled,
		scheduled_sec,
		idle_sec,
		breakdown_sec,
		availability_pct,
		assign_performance,
		calc_performance,
		performance_pct,
		quality_pct,
		CASE
			WHEN (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
			THEN (availability_pct * assign_performance * quality_pct) / 10000
			ELSE oee_pct
		END AS assign_oee,
		oee_pct
	FROM (
	SELECT
		period_dt,
		good_pcs,
		bad_pcs,
		assign_target,
		target_pcs,
		assign_running,
		running_sec,
		assign_scheduled,
		scheduled_sec,
		idle_sec,
		breakdown_sec,
		availability_pct,
		CASE
			WHEN (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
			THEN (CAST((good_pcs + bad_pcs) AS FLOAT) / assign_target) * 100
			ELSE calc_performance
		END AS assign_performance,
		calc_performance,
		performance_pct,
		quality_pct,
		oee_pct
	FROM (
		SELECT
			period_dt,
			good_pcs,
			bad_pcs,
			CASE 
				WHEN (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
				THEN good_pcs + bad_pcs
				ELSE target_pcs
			END AS assign_target,
			target_pcs,
			assign_running,
			running_sec,
			assign_scheduled,
			scheduled_sec,
			idle_sec,
			breakdown_sec,
			availability_pct,
			calc_performance,
			performance_pct,
			quality_pct,
			oee_pct
		FROM (
			SELECT
				period_dt,
				good_pcs,
				bad_pcs,
				target_pcs,
				assign_running,
				running_sec,
				CASE 
					WHEN (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
					THEN 3600 - assign_running - idle_sec - breakdown_sec
					ELSE scheduled_sec
				END AS assign_scheduled,
				scheduled_sec,
				idle_sec,
				breakdown_sec,
				availability_pct,
				calc_performance,
				performance_pct,
				quality_pct,
				oee_pct
			FROM (
				SELECT
					period_dt,
					good_pcs,
					bad_pcs,
					target_pcs,
					CASE 
						WHEN (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
						THEN CASE
									WHEN (good_pcs + bad_pcs) * 8.28 > 3600 
									THEN 3600
									ELSE (good_pcs + bad_pcs) * 8.28
								END
						ELSE running_sec
					END AS assign_running,
					running_sec,
					scheduled_sec,
					idle_sec,
					breakdown_sec,
					availability_pct,
					calc_performance,
					performance_pct,
					quality_pct,
					oee_pct
				FROM (
					SELECT
						period_dt,
						good_pcs,
						bad_pcs,
						(CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 8.28) AS target_pcs,
						running_sec,
						scheduled_sec,
						idle_sec,
						breakdown_sec,
						availability_pct,
						CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 8.28)) * 100,2)
						ELSE 0 
						END AS calc_performance,
						performance_pct,
						quality_pct,
						oee_pct
					FROM silver.machine2_data
					WHERE (YEAR(period_dt) = 2024 AND MONTH(period_dt) NOT BETWEEN 1 AND 6)
					)t
				)t
			)t
		)t
	)t
)t


------------------------------------------------------------
------------------- FINAL CODE 2025-26 ----------------------
------------------------------------------------------------

SELECT
	period_dt,
	good_pcs,
	bad_pcs,
	assign_target,
	assign_running,
	assign_scheduled,
	idle_sec,
	breakdown_sec,
	availability_pct,
	assign_performance,
	quality_pct,
	assign_oee
FROM (
	SELECT
		period_dt,
		good_pcs,
		bad_pcs,
		assign_target,
		target_pcs,
		assign_running,
		running_sec,
		assign_scheduled,
		scheduled_sec,
		idle_sec,
		breakdown_sec,
		availability_pct,
		assign_performance,
		calc_performance,
		performance_pct,
		quality_pct,
		CASE
			WHEN (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
			THEN (availability_pct * assign_performance * quality_pct) / 10000
			ELSE oee_pct
		END AS assign_oee,
		oee_pct
	FROM (
	SELECT
		period_dt,
		good_pcs,
		bad_pcs,
		assign_target,
		target_pcs,
		assign_running,
		running_sec,
		assign_scheduled,
		scheduled_sec,
		idle_sec,
		breakdown_sec,
		availability_pct,
		CASE
			WHEN (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
			THEN (CAST((good_pcs + bad_pcs) AS FLOAT) / assign_target) * 100
			ELSE calc_performance
		END AS assign_performance,
		calc_performance,
		performance_pct,
		quality_pct,
		oee_pct
	FROM (
		SELECT
			period_dt,
			good_pcs,
			bad_pcs,
			CASE 
				WHEN (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
				THEN good_pcs + bad_pcs
				ELSE target_pcs
			END AS assign_target,
			target_pcs,
			assign_running,
			running_sec,
			assign_scheduled,
			scheduled_sec,
			idle_sec,
			breakdown_sec,
			availability_pct,
			calc_performance,
			performance_pct,
			quality_pct,
			oee_pct
		FROM (
			SELECT
				period_dt,
				good_pcs,
				bad_pcs,
				target_pcs,
				assign_running,
				running_sec,
				CASE 
					WHEN (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
					THEN 3600 - assign_running - idle_sec - breakdown_sec
					ELSE scheduled_sec
				END AS assign_scheduled,
				scheduled_sec,
				idle_sec,
				breakdown_sec,
				availability_pct,
				calc_performance,
				performance_pct,
				quality_pct,
				oee_pct
			FROM (
				SELECT
					period_dt,
					good_pcs,
					bad_pcs,
					target_pcs,
					CASE 
						WHEN (calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1) 
						THEN CASE
									WHEN (good_pcs + bad_pcs) * 8.28 > 3600 
									THEN 3600
									ELSE (good_pcs + bad_pcs) * 8.28
								END
						ELSE running_sec
					END AS assign_running,
					running_sec,
					scheduled_sec,
					idle_sec,
					breakdown_sec,
					availability_pct,
					calc_performance,
					performance_pct,
					quality_pct,
					oee_pct
				FROM (
					SELECT
						period_dt,
						good_pcs,
						bad_pcs,
						(CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 8.28) AS target_pcs,
						running_sec,
						scheduled_sec,
						idle_sec,
						breakdown_sec,
						availability_pct,
						CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 8.28)) * 100,2)
						ELSE 0 
						END AS calc_performance,
						performance_pct,
						quality_pct,
						oee_pct
					FROM silver.machine2_data
					WHERE (YEAR(period_dt) IN (2025,2026))
					)t
				)t
			)t
		)t
	)t
)t
