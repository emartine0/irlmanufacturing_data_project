
-- ====================================================================
-- Checking descriptions 'bronze.machine1_data'
-- ====================================================================

/*
	ACTION: (1) Eliminate SQL reserved words from the column names,
			(2) Include the units for the quanities in the column names.
*/

-- ====================================================================
-- Checking relations 'silver.machine1_data'
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

			target_pcs = (runnig_sec + idle_sec + breakdown_sec) / cycle time

			availability_pct = (running_sec + idle_sec) / (runnig_sec + idle_sec + breakdown_sec)
			performance_pct = (good_pcs + bad_pcs) / target_pcs
			quality_pct = good_pcs / (good_pcs + bad_pcs)
*/

-- tartget test

SELECT
	target_pcs,
	(CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 6.20) AS calc_target
FROM silver.machine1_data

-- availability test
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
FROM silver.machine1_data

-- performance test
SELECT
	period_dt,
	CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 6.20 AS calc_target,
	CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 6.20)) * 100,2)
	ELSE 0 
	END AS calc_performance,
	AVG(CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 6.20)) * 100,2)
	ELSE 0 
	END) OVER(),
	performance_pct,
	AVG(performance_pct) OVER()
FROM silver.machine1_data


-- quality test
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
FROM silver.machine1_data

SELECT *
FROM silver.machine1_data

/* 
	ISSUE 1: Based on the formula for compute the target_pcs column (see docs folder),
	the actual column is a rounded integer version of the calculation.
	ACTION: Use the original calculation because the complex columns make use of it.


	ISSUE 2: There's a significant difference between the mean values of the performance_pct column
	and a computed version of it.
	ACTION: Understand the source of the issue.
	 
*/

SELECT
	period_dt,
	CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 6.20)) * 100,2)
	ELSE 0 
	END AS calc_performance,
	performance_pct
FROM silver.machine1_data
WHERE (CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 6.20)) * 100,2)
	ELSE 0 
	END) NOT BETWEEN performance_pct - 1 AND performance_pct + 1

/*
	ISSUE 2.1: There are 350 rows in which the difference between the calculation an the actual row value seems artificial.
	ACTION: Check the source table in order to find more information about this issue.
*/

SELECT
	period_dt,
	good_pcs,
	bad_pcs,
	(CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 6.20) AS calc_target,
	running_sec,
	scheduled_sec,
	idle_sec,
	breakdown_sec,
	CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 6.20)) * 100,2)
	ELSE 0 
	END AS calc_performance,
	performance_pct
FROM silver.machine1_data
WHERE (CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 6.20)) * 100,2)
	ELSE 0 
	END) NOT BETWEEN performance_pct - 1 AND performance_pct + 1

/*
	ISSUE 2.2: The fundamental problem with these differences is that there are inconsistencies in data. 
	Particularly, (1) there are produced pieces witout running-machine time and (2) there are nonsense performance
	values like 295120%.
	ACTION: 
	
*/
