--Data dictionary using system view
USE Examination_System;
GO
WITH
-- PK columns
PK_Cols AS (
  SELECT 
    tc.TABLE_SCHEMA,
    tc.TABLE_NAME,
    ku.COLUMN_NAME
  FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS tc
  JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS ku
    ON tc.CONSTRAINT_NAME = ku.CONSTRAINT_NAME
   AND tc.TABLE_SCHEMA   = ku.TABLE_SCHEMA
  WHERE tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
),
-- FK columns and their referenced table/column
FK_Cols AS (
  SELECT 
    fkcu.TABLE_SCHEMA,
    fkcu.TABLE_NAME,
    fkcu.COLUMN_NAME,
    rc.CONSTRAINT_NAME    AS FK_Constraint,
    pkcu.TABLE_NAME       AS Referenced_Table,
    pkcu.COLUMN_NAME      AS Referenced_Column
  FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS AS rc
  JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS fkcu
    ON rc.CONSTRAINT_NAME = fkcu.CONSTRAINT_NAME
  JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS pkcu
    ON rc.UNIQUE_CONSTRAINT_NAME = pkcu.CONSTRAINT_NAME
   AND fkcu.ORDINAL_POSITION     = pkcu.ORDINAL_POSITION
),
-- Column descriptions
Col_Descriptions AS (
  SELECT 
    s.name      AS TABLE_SCHEMA,
    o.name      AS TABLE_NAME,
    c.name      AS COLUMN_NAME,
    ep.value    AS Column_Description
  FROM sys.extended_properties AS ep
  JOIN sys.objects            AS o 
    ON ep.major_id = o.object_id
   AND ep.class    = 1 -- object or column
  JOIN sys.schemas            AS s 
    ON o.schema_id = s.schema_id
  JOIN sys.columns            AS c 
    ON ep.minor_id = c.column_id
   AND c.object_id = o.object_id
  WHERE ep.name = 'MS_Description'
)

SELECT
  t.TABLE_SCHEMA,
  t.TABLE_NAME,
  c.ORDINAL_POSITION,
  c.COLUMN_NAME,
  c.DATA_TYPE
    + COALESCE('(' +
        CASE 
          WHEN c.CHARACTER_MAXIMUM_LENGTH IN (-1) THEN 'MAX'
          ELSE CAST(c.CHARACTER_MAXIMUM_LENGTH AS VARCHAR(10))
        END 
      + ')','') AS Full_Data_Type,
  CASE c.IS_NULLABLE 
    WHEN 'YES' THEN 'NULL' 
    ELSE 'NOT NULL' 
  END AS Nullability,
  
  -- detect PK membership
  CASE WHEN pk.COLUMN_NAME IS NOT NULL THEN 'PK' ELSE '' END AS [Key],
  
  -- detect FK membership
  fk.FK_Constraint,
  fk.Referenced_Table,
  fk.Referenced_Column,
  c.COLUMN_DEFAULT   AS Default_Value,
  cd.Column_Description
FROM INFORMATION_SCHEMA.TABLES AS t
JOIN INFORMATION_SCHEMA.COLUMNS AS c
  ON t.TABLE_SCHEMA = c.TABLE_SCHEMA
 AND t.TABLE_NAME   = c.TABLE_NAME
LEFT JOIN PK_Cols AS pk
  ON pk.TABLE_SCHEMA = c.TABLE_SCHEMA
 AND pk.TABLE_NAME   = c.TABLE_NAME
 AND pk.COLUMN_NAME  = c.COLUMN_NAME
LEFT JOIN FK_Cols AS fk
  ON fk.TABLE_SCHEMA = c.TABLE_SCHEMA
 AND fk.TABLE_NAME   = c.TABLE_NAME
 AND fk.COLUMN_NAME  = c.COLUMN_NAME
LEFT JOIN Col_Descriptions AS cd
  ON cd.TABLE_SCHEMA = c.TABLE_SCHEMA
 AND cd.TABLE_NAME   = c.TABLE_NAME
 AND cd.COLUMN_NAME  = c.COLUMN_NAME
WHERE t.TABLE_TYPE = 'BASE TABLE'
ORDER BY
  t.TABLE_SCHEMA,
  t.TABLE_NAME,
  c.ORDINAL_POSITION;