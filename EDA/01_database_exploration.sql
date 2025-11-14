/* =====================================================================
 🏗️ DATABASE EXPLORATION
===================================================================== */

-- Explore all tables in the database (excluding system schemas)
SELECT
    *
FROM information_schema.tables
WHERE table_schema NOT IN ('pg_catalog', 'information_schema');

-- Explore all columns of a specific table
SELECT
    *
FROM information_schema.columns
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
  AND table_name = 'dim_customers';

-- Explore all columns in the 'gold' schema
SELECT
    *
FROM information_schema.columns
WHERE table_schema = 'gold';
