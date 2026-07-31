:setvar DatabaseName "testurl"
:setvar BlobContainerUrl "https://REPLACE_ACCOUNT.blob.core.windows.net/REPLACE_CONTAINER"
:setvar SasToken "REPLACE_WITH_SAS_WITHOUT_LEADING_QUESTION_MARK"
:setvar DataDirectory "C:\Program Files\Microsoft SQL Server\MSSQL13.SQL2016\MSSQL\DATA"

/*
Run in SQLCMD mode on a disposable SQL Server 2016 lab instance.
This script makes no changes. It intentionally fails if required SQLCMD
variables still contain placeholders.
*/

SET NOCOUNT ON;

SELECT
    @@SERVERNAME AS server_name,
    CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(128)) AS product_version,
    CAST(SERVERPROPERTY('ProductLevel') AS nvarchar(128)) AS product_level,
    CAST(SERVERPROPERTY('Edition') AS nvarchar(128)) AS edition;

IF N'$(BlobContainerUrl)' LIKE N'%REPLACE_%'
    THROW 51000, 'Set BlobContainerUrl in SQLCMD mode before continuing.', 1;

IF N'$(SasToken)' LIKE N'REPLACE_%' OR LEN(N'$(SasToken)') = 0
    THROW 51001, 'Set SasToken locally before continuing. Do not commit it.', 1;

IF LEFT(N'$(SasToken)', 1) = N'?'
    THROW 51002, 'SasToken must not include the leading question mark.', 1;

IF N'$(DataDirectory)' NOT LIKE N'%MSSQL13.%'
    PRINT N'WARNING: DataDirectory does not look like a SQL Server 2016 instance path. Review it manually.';

IF DB_ID(N'$(DatabaseName)') IS NOT NULL
    THROW 51003, 'The target database already exists. Choose another name or clean up the previous lab.', 1;

SELECT
    N'$(DatabaseName)' AS database_name,
    N'$(BlobContainerUrl)' AS blob_container_url,
    N'$(DataDirectory)' AS data_directory,
    LEN(N'$(SasToken)') AS sas_token_length;

PRINT N'Prerequisite variable validation passed. Confirm endpoint reachability and permissions outside this script.';
