/*
===============================================================================
DDL Script: Create Bronze Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'bronze' schema, dropping existing tables 
    if they already exist.
	  Run this script to re-define the DDL structure of 'bronze' tables.
===============================================================================
*/

IF OBJECT_ID('bronze.machine1_data', 'U') IS NOT NULL
    DROP TABLE bronze.machine1_data;
GO

CREATE TABLE bronze.machine1_data (
  period        DATETIME,
  good_pieces	  INT,
  bad_pieces	  INT,
  target	      INT,
  running	      INT,
  scheduled	    INT,
  idle	        INT,
  breakdown	    INT,
  availability	FLOAT,
  performance	  FLOAT,
  quality	      FLOAT,
  oee           FLOAT
);
GO

IF OBJECT_ID('bronze.machine2_data', 'U') IS NOT NULL
    DROP TABLE bronze.machine2_data;
GO

CREATE TABLE bronze.machine2_data (
  period        DATETIME,
  good_pieces	  INT,
  bad_pieces	  INT,
  target	      INT,
  running	      INT,
  scheduled	    INT,
  idle	        INT,
  breakdown	    INT,
  availability	FLOAT,
  performance	  FLOAT,
  quality	      FLOAT,
  oee           FLOAT
);
GO
