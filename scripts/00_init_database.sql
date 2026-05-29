/*
===============================================================================
Create Database and Schemas
===============================================================================
Purpose:
    This script creates a new database named 'data_warehouse' from scratch.
    If the database exists, it is dropped and recreated. Additionally, the script sets up 
    three schemas within the database:
    	'bronze', 'silver', and 'gold'

WARNING:
   The script will drop the entire 'data_warehouse' database.
   All data in the database will be permanently deleted. Proceed with caution and
   ensure you have proper backups before running this script.
===============================================================================
*/

-- Connect to 'postgres' database before running this block of code
-- Run the code to create a new database 'data_warehouse' if it does not exist yet.
-- If it does, this code will drop the entire 'data_warehouse' database before creating a new one.
-- After running, reconnect to the created database.

DROP DATABASE IF EXISTS data_warehouse;
CREATE DATABASE data_warehouse;


-- Then, run this block of code to create three schemas

DROP SCHEMA IF EXISTS bronze CASCADE;
DROP SCHEMA IF EXISTS silver CASCADE;
DROP SCHEMA IF EXISTS gold CASCADE;

CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;