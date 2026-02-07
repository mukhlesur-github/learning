-- =====================================================================================
-- Stored Procedure: SP_GENERIC_DATA_LOADER
-- Description: Generic data loader that inserts data from source to target tables
--              based on metadata table configuration
-- Parameters:
--   - p_metadata_table: Fully qualified metadata table name (project.dataset.table)
--   - p_target_table: Optional filter for specific target table (NULL = all tables)
-- =====================================================================================

CREATE OR REPLACE PROCEDURE `project-951f8a47-5f31-42d4-b5b.mmr.SP_GENERIC_DATA_LOADER`(
  p_metadata_table STRING,
  p_target_table STRING
)
BEGIN
  DECLARE v_sql STRING;
  DECLARE v_insert_sql STRING;
  DECLARE v_loop_sql STRING;
  DECLARE v_source_table STRING;
  DECLARE v_target_table STRING;
  DECLARE v_select_clause STRING;
  DECLARE v_target_columns STRING;
  DECLARE v_row_count INT64;
  DECLARE v_records ARRAY<STRUCT<source_table STRING, target_table STRING>>;
  DECLARE v_idx INT64 DEFAULT 0;

  -- Log start
  SELECT FORMAT('Starting INSERT data load. Metadata Table: %s, Target: %s', 
                p_metadata_table, IFNULL(p_target_table, 'ALL'))
  AS log_message;

  -- Get count of tables to process
  SET v_sql = FORMAT("""
    SELECT COUNT(DISTINCT target_table) FROM `%s`
    WHERE 1=1 %s
  """, 
  p_metadata_table,
  CASE WHEN p_target_table IS NOT NULL 
       THEN FORMAT(" AND target_table = '%s'", p_target_table)
       ELSE '' 
  END);
  
  EXECUTE IMMEDIATE v_sql INTO v_row_count;
  
  SELECT FORMAT('Found %d table(s) to process', v_row_count) AS log_message;

  -- Get source-target combinations into an array
  SET v_loop_sql = FORMAT("""
    SELECT ARRAY_AGG(STRUCT(source_table, target_table))
    FROM (
      SELECT DISTINCT 
        source_table,
        target_table
      FROM `%s`
      WHERE 1=1 %s
      ORDER BY target_table
    )
  """, 
  p_metadata_table,
  CASE WHEN p_target_table IS NOT NULL 
       THEN FORMAT(" AND target_table = '%s'", p_target_table)
       ELSE '' 
  END);
  
  EXECUTE IMMEDIATE v_loop_sql INTO v_records;

  -- Loop through each record using WHILE
  WHILE v_idx < ARRAY_LENGTH(v_records) DO
    SET v_source_table = v_records[OFFSET(v_idx)].source_table;
    SET v_target_table = v_records[OFFSET(v_idx)].target_table;
    
    SELECT FORMAT('Processing: %s -> %s', v_source_table, v_target_table) AS log_message;

    -- Build SELECT clause with CAST for data type conversion
    SET v_sql = FORMAT("""
      SELECT 
        STRING_AGG(
          CASE 
            WHEN target_datatype IS NOT NULL AND target_datatype != source_datatype THEN
              CONCAT('CAST(src.', source_attribute, ' AS ', target_datatype, ') AS ', target_attribute)
            ELSE
              CONCAT('src.', source_attribute, ' AS ', target_attribute)
          END,
          ', '
        ) AS select_clause,
        STRING_AGG(target_attribute, ', ') AS target_columns
      FROM `%s`
      WHERE source_table = '%s'
        AND target_table = '%s'
    """, p_metadata_table, v_source_table, v_target_table);
    
    EXECUTE IMMEDIATE v_sql INTO v_select_clause, v_target_columns;

    -- Build INSERT statement
    SET v_insert_sql = FORMAT("""
      INSERT INTO `%s` (%s)
      SELECT 
        %s
      FROM `%s` AS src
    """, 
    v_target_table,
    v_target_columns,
    v_select_clause,
    v_source_table);
    
    SELECT FORMAT('Executing INSERT for %s', v_target_table) AS log_message;
    EXECUTE IMMEDIATE v_insert_sql;
    
    SELECT FORMAT('✓ Inserted rows into %s', v_target_table) AS log_message;

    -- Increment counter
    SET v_idx = v_idx + 1;
  END WHILE;

  -- Log completion
  SELECT FORMAT('✓ Data load completed successfully. Tables processed: %d', v_row_count) AS log_message;

EXCEPTION WHEN ERROR THEN
  SELECT 
    FORMAT('❌ Error occurred: %s', @@error.message) AS error_message,
    @@error.statement_text AS failed_statement;
  RAISE USING MESSAGE = @@error.message;
END;
