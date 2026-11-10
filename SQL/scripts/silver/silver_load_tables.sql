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
		FROM bronze.machine1_data
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
