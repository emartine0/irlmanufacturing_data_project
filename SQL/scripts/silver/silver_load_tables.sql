/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC silver.load_silver;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME; 
    BEGIN TRY
        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';

		-- Loading silver.machine1_data

		PRINT '------------------------------------------------';
		PRINT 'Loading Machine 1 Table';
		PRINT '------------------------------------------------';

        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.machine1_data';
		TRUNCATE TABLE silver.machine1_data;
		PRINT '>> Inserting Data Into: silver.machine1_data';
		INSERT INTO silver.machine1_data (
			period_dt,
			good_pcs,
			bad_pcs,
			target_pcs,
			running_sec,
			scheduled_sec,
			idle_sec,
			breakdown_sec,
			availability_pct,
			performance_pct,
			quality_pct,
			oee_pct			
		)
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
					WHEN calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1 
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
					WHEN calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1 
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
						WHEN calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1 
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
							WHEN calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1 
							THEN scheduled_sec - assign_running
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
								WHEN calc_performance NOT BETWEEN performance_pct - 1 AND performance_pct + 1 
								THEN CASE
											WHEN (good_pcs + bad_pcs) * 6.2 > 3600 
											THEN 3600
											ELSE (good_pcs + bad_pcs) * 6.2
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
								(CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 6.20) AS target_pcs,
								running_sec,
								scheduled_sec,
								idle_sec,
								breakdown_sec,
								availability_pct,
								CASE WHEN target_pcs != 0 THEN ROUND((CAST(good_pcs + bad_pcs AS FLOAT) / (CAST(running_sec + idle_sec + breakdown_sec AS FLOAT) / 6.20)) * 100,2)
								ELSE 0 
								END AS calc_performance,
								performance_pct,
								quality_pct,
								oee_pct
							FROM (
								SELECT
									period_dt,
									good_pcs,
									bad_pcs,
									target_pcs,
									running_sec,
									scheduled_sec,
									idle_sec,
									breakdown_sec,
									availability_pct,
									performance_pct,
									quality_pct,
									oee_pct			
								FROM (
									SELECT
										CONVERT(DATETIME, period + ':00', 103) AS period_dt,
										good_pieces AS good_pcs,
										bad_pieces AS bad_pcs,
										target AS target_pcs,
										running AS running_sec,
										scheduled AS scheduled_sec,
										idle AS idle_sec,
										breakdown AS breakdown_sec,
										availability AS availability_pct,
										performance AS performance_pct,
										quality AS quality_pct,
										oee	AS oee_pct
									FROM bronze.machine1_data
									)t
								)t
							)t
						)t
					)t
				)t
			)t
		)t
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';
		
		-- Loading silver.machine2_data

		PRINT '------------------------------------------------';
		PRINT 'Loading Machine 2 Table';
		PRINT '------------------------------------------------';

        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.machine2_data';
		TRUNCATE TABLE silver.machine2_data;
		PRINT '>> Inserting Data Into: silver.machine2_data';
		INSERT INTO silver.machine2_data (
			period_dt,
			good_pcs,
			bad_pcs,
			target_pcs,
			running_sec,
			scheduled_sec,
			idle_sec,
			breakdown_sec,
			availability_pct,
			performance_pct,
			quality_pct,
			oee_pct			
		)
		SELECT
			CONVERT(DATETIME, period + ':00', 103) AS period,
			good_pieces,
			bad_pieces,
			target,
			running,
			scheduled,
			idle,
			breakdown,
			availability,
			performance,
			quality,
			oee	
		FROM bronze.machine2_data
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';		
	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message: ' + ERROR_MESSAGE();
		PRINT 'Error Message: ' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message: ' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END
