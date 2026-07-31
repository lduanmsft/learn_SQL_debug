:setvar DatabaseName "testurl"

USE [$(DatabaseName)];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID(N'dbo.Table100', N'U') IS NOT NULL
    THROW 51010, 'dbo.Table100 already exists. Clean up the previous workload first.', 1;
GO

CREATE TABLE dbo.Table100
(
    id float NOT NULL,
    cc1 char(2000) NOT NULL,
    cc2 char(2000) NOT NULL
) ON [PRIMARY];
GO

DECLARE @i int = 1;

BEGIN TRANSACTION;
WHILE @i <= 100
BEGIN
    INSERT dbo.Table100 (id, cc1, cc2)
    SELECT RAND(), 'aa', 'cc';

    SET @i += 1;
END;
COMMIT TRANSACTION;
GO

DECLARE
    @number int = 51,
    @table_name sysname,
    @stmt nvarchar(4000);

WHILE @number <= 549
BEGIN
    SET @table_name = N'Table' + CONVERT(nvarchar(5), @number);

    IF OBJECT_ID(N'dbo.' + QUOTENAME(@table_name), N'U') IS NULL
    BEGIN
        SET @stmt = N'SELECT * INTO dbo.' + QUOTENAME(@table_name)
                  + N' FROM dbo.Table100;';
        EXEC sys.sp_executesql @stmt;
    END;

    SET @number += 1;
END;
GO

IF OBJECT_ID(N'dbo.test_insert', N'P') IS NOT NULL
    DROP PROCEDURE dbo.test_insert;
GO

CREATE PROCEDURE dbo.test_insert
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @i int = 1,
        @table_name sysname = N'Table' + CONVERT(nvarchar(20), @@SPID),
        @stmt_b nvarchar(4000),
        @stmt_c nvarchar(4000);

    IF OBJECT_ID(N'dbo.' + QUOTENAME(@table_name), N'U') IS NULL
        THROW 51011, 'No workload table exists for this SPID.', 1;

    SET @stmt_b = N'UPDATE dbo.' + QUOTENAME(@table_name)
                + N' SET cc1 = REPLICATE(''b'', 1800);';
    SET @stmt_c = N'UPDATE dbo.' + QUOTENAME(@table_name)
                + N' SET cc1 = REPLICATE(''c'', 1800);';

    WHILE 1 = 1
    BEGIN
        BEGIN TRANSACTION;

        IF @i % 2 = 0
            EXEC sys.sp_executesql @stmt_b;
        ELSE
            EXEC sys.sp_executesql @stmt_c;

        COMMIT TRANSACTION;
        WAITFOR DELAY '00:00:00.010';
        SET @i += 1;
    END;
END;
GO

SELECT
    COUNT_BIG(*) AS generated_table_count,
    MIN(t.name) AS first_table_name,
    MAX(t.name) AS last_table_name
FROM sys.tables AS t
WHERE t.name = N'Table100'
   OR t.name LIKE N'Table[0-9]%';
GO
