/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from xlsx files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME; 
	BEGIN TRY
		PRINT '================================================';
		PRINT 'Loading Bronze Layer';
		PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading Machine 1 Table';
		PRINT '------------------------------------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.machine1_data';
		TRUNCATE TABLE bronze.machine1_data;
		PRINT '>> Inserting Data Into: bronze.machine1_data';
		BULK INSERT bronze.machine1_data
		FROM 'C:\Users\emartine\Documents\DSProjects\Manufacturing_irl\machine1_data.csv'
		WITH (
			FIRSTROW = 3,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';

		PRINT '------------------------------------------------';
		PRINT 'Loading Machine 2 Table';
		PRINT '------------------------------------------------';

    	SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.machine2_data';
		TRUNCATE TABLE bronze.machine2_data;
		PRINT '>> Inserting Data Into: bronze.machine2_data';
		BULK INSERT bronze.machine2_data
		FROM 'C:\Users\emartine\Documents\DSProjects\Manufacturing_irl\machine2_data.csv' 
		WITH (
			FIRSTROW = 3,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';
	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END
