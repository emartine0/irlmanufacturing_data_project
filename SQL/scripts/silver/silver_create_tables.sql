/*
===============================================================================
DDL Script: Create Silver Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'silver' schema, dropping existing tables 
    if they already exist.
	  Run this script to re-define the DDL structure of 'bronze' tables.
===============================================================================
*/

IF OBJECT_ID('silver.machine1_data', 'U') IS NOT NULL
    DROP TABLE silver.machine1_data;
GO

CREATE TABLE silver.machine1_data (
  period_dt         DATETIME,
  good_pcs	        INT,
  bad_pcs	          INT,
  target_pcs        INT,
  running_sec	      INT,
  scheduled_sec	    INT,
  idle_sec	        INT,
  breakdown_sec	    INT,
  availability_pct	FLOAT,
  performance_pct	  FLOAT,
  quality_pct	      FLOAT,
  oee_pct           FLOAT
);
GO

IF OBJECT_ID('silver.machine2_data', 'U') IS NOT NULL
    DROP TABLE silver.machine2_data;
GO

CREATE TABLE silver.machine2_data (
  period_dt         DATETIME,
  good_pcs	        INT,
  bad_pcs	          INT,
  target_pcs	      INT,
  running_sec	      INT,
  scheduled_sec     INT,
  idle_sec	        INT,
  breakdown_sec	    INT,
  availability_pct	FLOAT,
  performance_pct	  FLOAT,
  quality_pct	      FLOAT,
  oee_pct           FLOAT
);
GO
