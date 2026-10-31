/* =====================================================================
   00_restore.sql
   Purpose : Restore the AdventureWorksDW2022 sample data warehouse
             from Microsoft's official backup file.
   Source  : https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorksDW2022.bak
   Run in  : SSMS, connected to localhost (needs sysadmin or dbcreator)
   Change the two paths below if your .bak or data folder is elsewhere.
   ===================================================================== */
USE master;
GO

-- Tip: to see the logical file names inside any .bak before restoring:
-- RESTORE FILELISTONLY FROM DISK = N'D:\db\AdventureWorksDW2022.bak';

-- If the database already exists, disconnect everyone so RESTORE can
-- get exclusive access. ROLLBACK IMMEDIATE cancels open transactions.
IF DB_ID(N'AdventureWorksDW2022') IS NOT NULL
    ALTER DATABASE AdventureWorksDW2022 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

RESTORE DATABASE AdventureWorksDW2022
FROM DISK = N'D:\db\AdventureWorksDW2022.bak'
WITH
    FILE = 1,   -- a .bak can hold several backup sets; use the first one
    -- MOVE '<logical name>' TO '<physical path>': where each file is created
    MOVE N'AdventureWorksDW2022'     TO N'D:\SQLData\AdventureWorksDW2022.mdf',
    MOVE N'AdventureWorksDW2022_log' TO N'D:\SQLData\AdventureWorksDW2022_log.ldf',
    REPLACE,    -- overwrite an existing database with this name (harmless on a fresh server)
    STATS = 10; -- print progress every 10 percent
GO

-- The restored database comes back in MULTI_USER mode (as it was when backed up).
-- Quick check: where do the files live now?
SELECT name AS logical_name, type_desc, physical_name, size * 8 / 1024 AS size_mb
FROM sys.master_files
WHERE database_id = DB_ID(N'AdventureWorksDW2022');
GO
