:setvar DatabaseName "testurl"
:setvar BlobContainerUrl "https://REPLACE_ACCOUNT.blob.core.windows.net/REPLACE_CONTAINER"
:setvar SasToken "REPLACE_WITH_SAS_WITHOUT_LEADING_QUESTION_MARK"
:setvar DataDirectory "C:\Program Files\Microsoft SQL Server\MSSQL13.SQL2016\MSSQL\DATA"

/*
Run in SQLCMD mode on an isolated SQL Server 2016 lab instance.
Never save or commit a real SasToken in this file.
*/

USE master;
GO

IF N'$(BlobContainerUrl)' LIKE N'%REPLACE_%'
    THROW 51000, 'Set BlobContainerUrl before running this script.', 1;

IF N'$(SasToken)' LIKE N'REPLACE_%' OR LEN(N'$(SasToken)') = 0
    THROW 51001, 'Set SasToken locally before running this script.', 1;

IF DB_ID(N'$(DatabaseName)') IS NOT NULL
    THROW 51002, 'The target database already exists.', 1;
GO

CREATE CREDENTIAL [$(BlobContainerUrl)]
WITH
    IDENTITY = 'SHARED ACCESS SIGNATURE',
    SECRET = '$(SasToken)';
GO

CREATE DATABASE [$(DatabaseName)]
ON PRIMARY
(
    NAME = N'testurl_data1',
    FILENAME = N'$(DataDirectory)\testurl_data.mdf'
),
(
    NAME = N'testurl_data2',
    FILENAME = N'$(DataDirectory)\testurl_data2.mdf'
),
(
    NAME = N'testurl_data3',
    FILENAME = N'$(DataDirectory)\testurl_data3.mdf'
),
(
    NAME = N'testurl_data4',
    FILENAME = N'$(DataDirectory)\testurl_data4.mdf'
),
(
    NAME = N'testurl_data5',
    FILENAME = N'$(DataDirectory)\testurl_data5.mdf'
),
(
    NAME = N'testurl_data6',
    FILENAME = N'$(DataDirectory)\testurl_data6.mdf'
),
(
    NAME = N'testurl_data7',
    FILENAME = N'$(DataDirectory)\testurl_data7.mdf'
),
(
    NAME = N'testurl_data8',
    FILENAME = N'$(DataDirectory)\testurl_data8.mdf'
)
LOG ON
(
    NAME = N'testnew_log',
    FILENAME = N'$(BlobContainerUrl)/$(DatabaseName)_log.ldf'
);
GO

SELECT
    d.name,
    d.state_desc,
    d.recovery_model_desc
FROM sys.databases AS d
WHERE d.name = N'$(DatabaseName)';

SELECT
    mf.name,
    mf.type_desc,
    mf.physical_name,
    mf.state_desc
FROM sys.master_files AS mf
WHERE mf.database_id = DB_ID(N'$(DatabaseName)')
ORDER BY mf.file_id;
GO
