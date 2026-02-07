-- =====================================================================================
-- TEST SCRIPT FOR SP_GENERIC_DATA_LOADER
-- Description: Complete test setup with sample data
-- Instructions: 
--   1. Run sections step by step
--   3. Verify results after each step
-- =====================================================================================

-- =====================================================================================
-- STEP 1: Create Source Tables with Sample Data
-- =====================================================================================

-- Source table 1: Customers
CREATE OR REPLACE TABLE `project-951f8a47-5f31-42d4-b5b.mmr.source_customers` (
  customer_id STRING,
  first_name STRING,
  last_name STRING,
  email STRING,
  phone STRING,
  signup_date DATE,
  age INT64,
  is_active BOOL
);

-- Insert sample data into source_customers
INSERT INTO `project-951f8a47-5f31-42d4-b5b.mmr.source_customers`
(customer_id, first_name, last_name, email, phone, signup_date, age, is_active)
VALUES
  ('CUST001', 'John', 'Doe', 'john.doe@email.com', '555-0101', '2024-01-15', 35, TRUE),
  ('CUST002', 'Jane', 'Smith', 'jane.smith@email.com', '555-0102', '2024-02-20', 28, TRUE),
  ('CUST003', 'Bob', 'Johnson', 'bob.j@email.com', '555-0103', '2024-03-10', 42, TRUE),
  ('CUST004', 'Alice', 'Williams', 'alice.w@email.com', '555-0104', '2024-04-05', 31, FALSE),
  ('CUST005', 'Charlie', 'Brown', 'charlie.b@email.com', '555-0105', '2024-05-12', 25, TRUE);

-- Source table 2: Orders
CREATE OR REPLACE TABLE `project-951f8a47-5f31-42d4-b5b.mmr.source_orders` (
  order_id STRING,
  customer_id STRING,
  order_date DATE,
  order_amount FLOAT64,
  order_status STRING,
  item_count INT64
);

-- Insert sample data into source_orders
INSERT INTO `project-951f8a47-5f31-42d4-b5b.mmr.source_orders`
(order_id, customer_id, order_date, order_amount, order_status, item_count)
VALUES
  ('ORD001', 'CUST001', '2024-06-01', 150.50, 'COMPLETED', 3),
  ('ORD002', 'CUST002', '2024-06-02', 275.00, 'COMPLETED', 5),
  ('ORD003', 'CUST001', '2024-06-03', 89.99, 'PENDING', 2),
  ('ORD004', 'CUST003', '2024-06-04', 450.75, 'COMPLETED', 7),
  ('ORD005', 'CUST005', '2024-06-05', 125.00, 'CANCELLED', 1),
  ('ORD006', 'CUST002', '2024-06-06', 310.25, 'COMPLETED', 4);

-- Verify source data
SELECT 'source_customers' AS table_name, COUNT(*) AS row_count FROM `project-951f8a47-5f31-42d4-b5b.mmr.source_customers`
UNION ALL
SELECT 'source_orders', COUNT(*) FROM `project-951f8a47-5f31-42d4-b5b.mmr.source_orders`;

-- =====================================================================================
-- STEP 2: Create Target Tables (Empty)
-- =====================================================================================

-- Target table 1: Customers (slightly different schema)
CREATE OR REPLACE TABLE `project-951f8a47-5f31-42d4-b5b.mmr.target_customers` (
  customer_id STRING,
  first_name STRING,
  last_name STRING,
  email STRING,
  contact_phone STRING,        -- Different column name
  registration_date DATE,      -- Different column name
  customer_age STRING,         -- Different data type (INT64 -> STRING)
  active_flag BOOL
);

-- Target table 2: Orders (with data type conversions)
CREATE OR REPLACE TABLE `project-951f8a47-5f31-42d4-b5b.mmr.target_orders` (
  order_id STRING,
  customer_id STRING,
  order_date STRING,           -- Different data type (DATE -> STRING)
  order_amount NUMERIC,        -- Different data type (FLOAT64 -> NUMERIC)
  status STRING,               -- Different column name
  item_count STRING            -- Different data type (INT64 -> STRING)
);

-- Verify target tables are empty
SELECT 'target_customers' AS table_name, COUNT(*) AS row_count FROM `project-951f8a47-5f31-42d4-b5b.mmr.target_customers`
UNION ALL
SELECT 'target_orders', COUNT(*) FROM `project-951f8a47-5f31-42d4-b5b.mmr.target_orders`;

-- =====================================================================================
-- STEP 3: Create Metadata Table
-- =====================================================================================

CREATE OR REPLACE TABLE `project-951f8a47-5f31-42d4-b5b.mmr.table_metadata` (
  source_table STRING NOT NULL,
  source_attribute STRING NOT NULL,
  source_datatype STRING,
  target_table STRING NOT NULL,
  target_attribute STRING NOT NULL,
  target_datatype STRING,
  is_key_column BOOL DEFAULT FALSE,
  created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- =====================================================================================
-- STEP 4: Populate Metadata for Customers Table
-- =====================================================================================

INSERT INTO `project-951f8a47-5f31-42d4-b5b.mmr.table_metadata`
(source_table, source_attribute, source_datatype, target_table, target_attribute, target_datatype, is_key_column)
VALUES
  -- Customer mappings (same column names, same data types)
  ('project-951f8a47-5f31-42d4-b5b.mmr.source_customers', 'customer_id', 'STRING', 'project-951f8a47-5f31-42d4-b5b.mmr.target_customers', 'customer_id', 'STRING', TRUE),
  ('project-951f8a47-5f31-42d4-b5b.mmr.source_customers', 'first_name', 'STRING', 'project-951f8a47-5f31-42d4-b5b.mmr.target_customers', 'first_name', 'STRING', FALSE),
  ('project-951f8a47-5f31-42d4-b5b.mmr.source_customers', 'last_name', 'STRING', 'project-951f8a47-5f31-42d4-b5b.mmr.target_customers', 'last_name', 'STRING', FALSE),
  ('project-951f8a47-5f31-42d4-b5b.mmr.source_customers', 'email', 'STRING', 'project-951f8a47-5f31-42d4-b5b.mmr.target_customers', 'email', 'STRING', FALSE),
  
  -- Customer mappings (different column names)
  ('project-951f8a47-5f31-42d4-b5b.mmr.source_customers', 'phone', 'STRING', 'project-951f8a47-5f31-42d4-b5b.mmr.target_customers', 'contact_phone', 'STRING', FALSE),
  ('project-951f8a47-5f31-42d4-b5b.mmr.source_customers', 'signup_date', 'DATE', 'project-951f8a47-5f31-42d4-b5b.mmr.target_customers', 'registration_date', 'DATE', FALSE),
  ('project-951f8a47-5f31-42d4-b5b.mmr.source_customers', 'is_active', 'BOOL', 'project-951f8a47-5f31-42d4-b5b.mmr.target_customers', 'active_flag', 'BOOL', FALSE),
  
  -- Customer mappings (data type conversion: INT64 to STRING)
  ('project-951f8a47-5f31-42d4-b5b.mmr.source_customers', 'age', 'INT64', 'project-951f8a47-5f31-42d4-b5b.mmr.target_customers', 'customer_age', 'STRING', FALSE);

-- =====================================================================================
-- STEP 5: Populate Metadata for Orders Table
-- =====================================================================================

INSERT INTO `project-951f8a47-5f31-42d4-b5b.mmr.table_metadata`
(source_table, source_attribute, source_datatype, target_table, target_attribute, target_datatype, is_key_column)
VALUES
  -- Order mappings with various transformations
  ('project-951f8a47-5f31-42d4-b5b.mmr.source_orders', 'order_id', 'STRING', 'project-951f8a47-5f31-42d4-b5b.mmr.target_orders', 'order_id', 'STRING', TRUE),
  ('project-951f8a47-5f31-42d4-b5b.mmr.source_orders', 'customer_id', 'STRING', 'project-951f8a47-5f31-42d4-b5b.mmr.target_orders', 'customer_id', 'STRING', FALSE),
  
  -- Data type conversion: DATE to STRING
  ('project-951f8a47-5f31-42d4-b5b.mmr.source_orders', 'order_date', 'DATE', 'project-951f8a47-5f31-42d4-b5b.mmr.target_orders', 'order_date', 'STRING', FALSE),
  
  -- Data type conversion: FLOAT64 to NUMERIC
  ('project-951f8a47-5f31-42d4-b5b.mmr.source_orders', 'order_amount', 'FLOAT64', 'project-951f8a47-5f31-42d4-b5b.mmr.target_orders', 'order_amount', 'NUMERIC', FALSE),
  
  -- Different column name
  ('project-951f8a47-5f31-42d4-b5b.mmr.source_orders', 'order_status', 'STRING', 'project-951f8a47-5f31-42d4-b5b.mmr.target_orders', 'status', 'STRING', FALSE),
  
  -- Data type conversion: INT64 to STRING
  ('project-951f8a47-5f31-42d4-b5b.mmr.source_orders', 'item_count', 'INT64', 'project-951f8a47-5f31-42d4-b5b.mmr.target_orders', 'item_count', 'STRING', FALSE);

-- Verify metadata
SELECT 
  target_table,
  COUNT(*) AS column_count
FROM `project-951f8a47-5f31-42d4-b5b.mmr.table_metadata`
GROUP BY target_table
ORDER BY target_table;

-- View detailed metadata
SELECT 
  source_table,
  source_attribute,
  source_datatype,
  target_attribute,
  target_datatype,
  CASE WHEN source_datatype != target_datatype THEN '⚠️ CAST' ELSE '✓' END AS conversion_status,
  CASE WHEN source_attribute != target_attribute THEN '⚠️ RENAMED' ELSE '✓' END AS column_status
FROM `project-951f8a47-5f31-42d4-b5b.mmr.table_metadata`
WHERE target_table = 'project-951f8a47-5f31-42d4-b5b.mmr.target_customers'
ORDER BY source_attribute;

-- =====================================================================================
-- STEP 6: Run the Stored Procedure - Test 1 (Load Customers Only)
-- =====================================================================================

CALL `project-951f8a47-5f31-42d4-b5b.mmr.SP_GENERIC_DATA_LOADER`(
  'project-951f8a47-5f31-42d4-b5b.mmr.table_metadata',
  'project-951f8a47-5f31-42d4-b5b.mmr.target_customers'
);

-- =====================================================================================
-- STEP 7: Verify Results for Customers
-- =====================================================================================

-- Check row count
SELECT 'target_customers' AS table_name, COUNT(*) AS row_count 
FROM `project-951f8a47-5f31-42d4-b5b.mmr.target_customers`;

-- View data
SELECT * FROM `project-951f8a47-5f31-42d4-b5b.mmr.target_customers` ORDER BY customer_id;

-- Compare source vs target
SELECT 
  s.customer_id,
  s.first_name AS src_first_name,
  t.first_name AS tgt_first_name,
  s.age AS src_age,
  t.customer_age AS tgt_age_converted,
  s.phone AS src_phone,
  t.contact_phone AS tgt_phone_renamed,
  s.signup_date AS src_signup_date,
  t.registration_date AS tgt_reg_date_renamed,
  CASE WHEN s.customer_id = t.customer_id THEN '✓ Match' ELSE '❌ Mismatch' END AS status
FROM `project-951f8a47-5f31-42d4-b5b.mmr.source_customers` s
LEFT JOIN `project-951f8a47-5f31-42d4-b5b.mmr.target_customers` t
  ON s.customer_id = t.customer_id
ORDER BY s.customer_id;

-- =====================================================================================
-- STEP 8: Run the Stored Procedure - Test 2 (Load Orders Only)
-- =====================================================================================

CALL `project-951f8a47-5f31-42d4-b5b.mmr.SP_GENERIC_DATA_LOADER`(
  'project-951f8a47-5f31-42d4-b5b.mmr.table_metadata',
  'project-951f8a47-5f31-42d4-b5b.mmr.target_orders'
);

-- =====================================================================================
-- STEP 9: Verify Results for Orders
-- =====================================================================================

-- Check row count
SELECT 'target_orders' AS table_name, COUNT(*) AS row_count 
FROM `project-951f8a47-5f31-42d4-b5b.mmr.target_orders`;

-- View data
SELECT * FROM `project-951f8a47-5f31-42d4-b5b.mmr.target_orders` ORDER BY order_id;

-- Compare source vs target
SELECT 
  s.order_id,
  s.order_date AS src_order_date,
  t.order_date AS tgt_order_date_string,
  s.order_amount AS src_amount_float,
  t.order_amount AS tgt_amount_numeric,
  s.item_count AS src_item_count_int,
  t.item_count AS tgt_item_count_string,
  s.order_status AS src_status,
  t.status AS tgt_status_renamed
FROM `project-951f8a47-5f31-42d4-b5b.mmr.source_orders` s
LEFT JOIN `project-951f8a47-5f31-42d4-b5b.mmr.target_orders` t
  ON s.order_id = t.order_id
ORDER BY s.order_id;

-- =====================================================================================
-- STEP 10: Run the Stored Procedure - Test 3 (Load All Tables)
-- =====================================================================================

-- First, truncate target tables
TRUNCATE TABLE `project-951f8a47-5f31-42d4-b5b.mmr.target_customers`;
TRUNCATE TABLE `project-951f8a47-5f31-42d4-b5b.mmr.target_orders`;

-- Load all tables at once
CALL `project-951f8a47-5f31-42d4-b5b.mmr.SP_GENERIC_DATA_LOADER`(
  'project-951f8a47-5f31-42d4-b5b.mmr.table_metadata',
  NULL  -- NULL means load all tables
);

-- =====================================================================================
-- STEP 11: Final Verification - All Tables
-- =====================================================================================

-- Check all row counts
SELECT 'source_customers' AS table_name, COUNT(*) AS row_count 
FROM `project-951f8a47-5f31-42d4-b5b.mmr.source_customers`
UNION ALL
SELECT 'target_customers', COUNT(*) 
FROM `project-951f8a47-5f31-42d4-b5b.mmr.target_customers`
UNION ALL
SELECT 'source_orders', COUNT(*) 
FROM `project-951f8a47-5f31-42d4-b5b.mmr.source_orders`
UNION ALL
SELECT 'target_orders', COUNT(*) 
FROM `project-951f8a47-5f31-42d4-b5b.mmr.target_orders`
ORDER BY table_name;

-- Summary report
SELECT 
  'CUSTOMERS' AS test_case,
  (SELECT COUNT(*) FROM `project-951f8a47-5f31-42d4-b5b.mmr.source_customers`) AS source_count,
  (SELECT COUNT(*) FROM `project-951f8a47-5f31-42d4-b5b.mmr.target_customers`) AS target_count,
  CASE 
    WHEN (SELECT COUNT(*) FROM `project-951f8a47-5f31-42d4-b5b.mmr.source_customers`) = 
         (SELECT COUNT(*) FROM `project-951f8a47-5f31-42d4-b5b.mmr.target_customers`) 
    THEN '✓ PASS' 
    ELSE '❌ FAIL' 
  END AS result
UNION ALL
SELECT 
  'ORDERS',
  (SELECT COUNT(*) FROM `project-951f8a47-5f31-42d4-b5b.mmr.source_orders`),
  (SELECT COUNT(*) FROM `project-951f8a47-5f31-42d4-b5b.mmr.target_orders`),
  CASE 
    WHEN (SELECT COUNT(*) FROM `project-951f8a47-5f31-42d4-b5b.mmr.source_orders`) = 
         (SELECT COUNT(*) FROM `project-951f8a47-5f31-42d4-b5b.mmr.target_orders`) 
    THEN '✓ PASS' 
    ELSE '❌ FAIL' 
  END;

-- =====================================================================================
-- STEP 12: Cleanup (Optional - Run only if you want to remove test data)
-- =====================================================================================

/*
DROP TABLE IF EXISTS `project-951f8a47-5f31-42d4-b5b.mmr.source_customers`;
DROP TABLE IF EXISTS `project-951f8a47-5f31-42d4-b5b.mmr.source_orders`;
DROP TABLE IF EXISTS `project-951f8a47-5f31-42d4-b5b.mmr.target_customers`;
DROP TABLE IF EXISTS `project-951f8a47-5f31-42d4-b5b.mmr.target_orders`;
DROP TABLE IF EXISTS `project-951f8a47-5f31-42d4-b5b.mmr.table_metadata`;
*/

-- =====================================================================================
-- TEST SCENARIOS COVERED
-- =====================================================================================
-- ✓ Same column names, same data types
-- ✓ Different column names (phone -> contact_phone)
-- ✓ Data type conversions (INT64 -> STRING, FLOAT64 -> NUMERIC, DATE -> STRING)
-- ✓ Loading specific table
-- ✓ Loading all tables at once
-- ✓ Multiple source-target table combinations
-- =====================================================================================
