/*
=====================================
Create datawarehouse schema 
=====================================

Purpose:
Create Bronze,Silver,Gold schemas

*/
--Create Bronze Layer
CREATE SCHEMA IF NOT EXISTS bronze;

--Create Silver Layer
CREATE SCHEMA IF NOT EXISTS silver;

--Create Gold Layer
CREATE SCHEMA IF NOT EXISTS gold;
