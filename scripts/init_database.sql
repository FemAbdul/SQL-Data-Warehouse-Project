/*
---------------------------------------
CREATE DATABASE AND SCHEMAS
---------------------------------------
The script creates the 'DataWarehouse' database and schemas 'Bronze','Silver','Gold'
*/

CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

CREATE SCHEMA Bronze;
GO
CREATE SCHEMA Silver;
GO
CREATE SCHEMA Gold;