# Generic BigQuery Data Loader Stored Procedure

## Overview
A fully generic BigQuery stored procedure that loads data from source to target tables based on metadata-driven configuration. Supports both INSERT and MERGE operations with automatic data type conversion.

## Features
✅ **Metadata-driven**: Configure source-to-target mappings in a metadata table  
✅ **Multiple modes**: Supports INSERT (append) and MERGE (upsert) operations  
✅ **Data type conversion**: Automatically casts columns when source/target types differ  
✅ **Column mapping**: Handles different column names between source and target  
✅ **Flexible keys**: Supports single or composite key columns for MERGE operations  
✅ **Batch processing**: Process multiple tables or specific tables  
✅ **Error handling**: Comprehensive error messages and exception handling  
✅ **Logging**: Built-in logging for monitoring execution progress  

## Files Created

1. **SP_GENERIC_DATA_LOADER.sql** - Main stored procedure
2. **METADATA_TABLE_SETUP.sql** - Metadata table DDL and sample data
3. **SP_GENERIC_DATA_LOADER_USAGE.sql** - Usage examples and verification queries
4. **SP_GENERIC_DATA_LOADER_README.md** - This documentation

## Metadata Table Structure

```sql
CREATE TABLE TABLE_METADATA (
  source_table STRING,        -- Fully qualified source table name
  source_attribute STRING,    -- Source column name
  source_datatype STRING,     -- Source column data type
  target_table STRING,        -- Fully qualified target table name
  target_attribute STRING,    -- Target column name (can differ from source)
  target_datatype STRING,     -- Target data type (auto-cast if different)
  is_key_column BOOL,         -- Flag for key columns (optional)
  created_date TIMESTAMP      -- Audit timestamp
);
```

## Stored Procedure Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `p_metadata_table` | STRING | Yes | Fully qualified metadata table name (e.g., `project.dataset.TABLE_METADATA`) |
| `p_mode` | STRING | Yes | Load mode: `'INSERT'` or `'MERGE'` |
| `p_target_table` | STRING | No | Specific target table to process (NULL = all tables) |
| `p_merge_keys` | STRING | Yes (for MERGE) | Comma-separated key columns for MERGE operation |

## Usage Examples

### 1. INSERT Mode - Load All Tables
```sql
CALL `project.dataset.SP_GENERIC_DATA_LOADER`(
  'project.dataset.TABLE_METADATA',
  'INSERT',
  NULL,
  NULL
);
```

### 2. INSERT Mode - Load Specific Table
```sql
CALL `project.dataset.SP_GENERIC_DATA_LOADER`(
  'project.dataset.TABLE_METADATA',
  'INSERT',
  'project.dataset.target_customers',
  NULL
);
```

### 3. MERGE Mode - Single Key
```sql
CALL `project.dataset.SP_GENERIC_DATA_LOADER`(
  'project.dataset.TABLE_METADATA',
  'MERGE',
  'project.dataset.target_customers',
  'customer_id'
);
```

### 4. MERGE Mode - Composite Key
```sql
CALL `project.dataset.SP_GENERIC_DATA_LOADER`(
  'project.dataset.TABLE_METADATA',
  'MERGE',
  'project.dataset.target_orders',
  'order_id,customer_id'
);
```

## Setup Instructions

### Step 1: Create the Metadata Table
```sql
-- Run METADATA_TABLE_SETUP.sql
-- Replace <PROJECT_ID> and <DATASET> with your values
```

### Step 2: Populate Metadata
```sql
INSERT INTO `project.dataset.TABLE_METADATA`
(source_table, source_attribute, source_datatype, target_table, target_attribute, target_datatype)
VALUES
  ('proj.ds.src_table', 'src_col1', 'STRING', 'proj.ds.tgt_table', 'tgt_col1', 'STRING'),
  ('proj.ds.src_table', 'src_col2', 'INT64', 'proj.ds.tgt_table', 'tgt_col2', 'STRING');
```

### Step 3: Create the Stored Procedure
```sql
-- Run SP_GENERIC_DATA_LOADER.sql
-- Replace <PROJECT_ID> and <DATASET> with your values
```

### Step 4: Execute the Procedure
```sql
-- Use examples from SP_GENERIC_DATA_LOADER_USAGE.sql
```

## How It Works

### INSERT Mode
1. Reads metadata table for source-target mappings
2. Groups by source_table and target_table combinations
3. Builds dynamic SELECT with CAST for data type conversions
4. Executes INSERT statement for each source-target pair

### MERGE Mode
1. Reads metadata table for source-target mappings
2. Builds MERGE condition based on provided key columns
3. Creates UPDATE clause for non-key columns
4. Executes MERGE statement (updates existing, inserts new)

## Data Type Conversion

The procedure automatically handles data type conversion:

```sql
-- Example: INT64 to STRING conversion
CAST(src.order_id AS STRING) AS order_id

-- Example: FLOAT64 to NUMERIC conversion
CAST(src.amount AS NUMERIC) AS amount
```

## Column Name Mapping

Source and target columns can have different names:

```sql
-- Metadata example
source_attribute: 'prod_id'     → target_attribute: 'product_id'
source_attribute: 'prod_name'   → target_attribute: 'product_name'
source_attribute: 'price'       → target_attribute: 'unit_price'
```

## Error Handling

The procedure includes validation for:
- Invalid mode (must be INSERT or MERGE)
- Missing merge keys when mode is MERGE
- SQL execution errors with detailed error messages
- Displays failed SQL statement for debugging

## Best Practices

1. **Test with small datasets first**: Validate metadata mappings before running on production data
2. **Use specific target table parameter**: When processing individual tables for better control
3. **Maintain metadata table**: Keep source_datatype and target_datatype updated
4. **Use appropriate mode**:
   - INSERT: For append-only operations or initial loads
   - MERGE: For incremental loads with updates
5. **Index key columns**: Ensure MERGE key columns are indexed for performance
6. **Monitor execution**: Check logs for errors or warnings
7. **Backup target tables**: Before running MERGE operations on production data

## Performance Considerations

- The procedure processes tables sequentially (not in parallel)
- For large datasets, consider:
  - Partitioning target tables by date
  - Using clustering on key columns
  - Running during off-peak hours
  - Processing tables individually rather than all at once

## Troubleshooting

### Error: "Invalid mode"
- Ensure `p_mode` is exactly 'INSERT' or 'MERGE' (case-insensitive)

### Error: "MERGE mode requires p_merge_keys"
- Provide comma-separated key columns when using MERGE mode

### Error: "Table not found"
- Verify fully qualified table names in metadata (project.dataset.table)
- Check permissions on source and target tables

### Data type mismatch
- Update metadata table with correct source_datatype and target_datatype
- Verify data type compatibility for CAST operations

## Extending the Solution

### Add Audit Columns
Modify the SELECT clause to include audit columns:
```sql
CURRENT_TIMESTAMP() AS loaded_date,
SESSION_USER() AS loaded_by
```

### Add Filters
Modify the source query to include WHERE clauses:
```sql
WHERE src.status = 'ACTIVE'
  AND src.created_date >= CURRENT_DATE() - 7
```

### Add Truncate Option
Add a parameter to truncate target before INSERT:
```sql
IF p_truncate_before_insert THEN
  EXECUTE IMMEDIATE FORMAT('TRUNCATE TABLE `%s`', v_target_table);
END IF;
```

## Support

For issues or questions:
1. Check the error message and failed statement
2. Verify metadata table configuration
3. Test with a single table first
4. Review the usage examples

## Version History

- **v1.0** (Feb 2026): Initial release with INSERT and MERGE modes
