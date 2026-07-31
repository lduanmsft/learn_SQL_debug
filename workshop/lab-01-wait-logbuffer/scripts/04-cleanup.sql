:setvar DatabaseName "testurl"
:setvar BlobContainerUrl "https://REPLACE_ACCOUNT.blob.core.windows.net/REPLACE_CONTAINER"

/*
Stop every ostress.exe workload process before running this script.
Run in SQLCMD mode only after retaining all required lab evidence.
*/

USE master;
GO

IF DB_ID(N'$(DatabaseName)') IS NOT NULL
BEGIN
    ALTER DATABASE [$(DatabaseName)] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [$(DatabaseName)];
END;
GO

IF EXISTS
(
    SELECT 1
    FROM sys.credentials
    WHERE name = N'$(BlobContainerUrl)'
)
BEGIN
    DROP CREDENTIAL [$(BlobContainerUrl)];
END;
GO

PRINT N'Local SQL Server database and scoped credential cleanup completed.';
PRINT N'Remove the remote log blob and rotate/revoke the SAS through the lab environment security process.';
