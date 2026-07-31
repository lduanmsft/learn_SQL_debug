:setvar DatabaseName "testurl"

USE [$(DatabaseName)];
GO
SET NOCOUNT ON;

SELECT
    SYSDATETIMEOFFSET() AS captured_at,
    @@SERVERNAME AS server_name,
    CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(128)) AS product_version;

SELECT
    d.name,
    d.state_desc,
    d.recovery_model_desc,
    d.log_reuse_wait_desc
FROM sys.databases AS d
WHERE d.database_id = DB_ID();

SELECT
    df.file_id,
    df.name,
    df.type_desc,
    df.physical_name,
    df.state_desc,
    CONVERT(decimal(19,2), df.size * 8.0 / 1024) AS size_mb
FROM sys.database_files AS df
ORDER BY df.file_id;

SELECT
    r.session_id,
    s.status AS session_status,
    r.status AS request_status,
    r.command,
    r.wait_type,
    r.wait_time,
    r.last_wait_type,
    r.wait_resource,
    r.blocking_session_id,
    r.open_transaction_count,
    r.cpu_time,
    r.reads,
    r.writes,
    r.logical_reads,
    s.host_name,
    s.program_name,
    s.login_name,
    txt.text AS current_sql_text
FROM sys.dm_exec_requests AS r
JOIN sys.dm_exec_sessions AS s
    ON s.session_id = r.session_id
OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) AS txt
WHERE r.database_id = DB_ID()
  AND r.session_id > 50
ORDER BY
    CASE WHEN r.wait_type = N'LOGBUFFER' THEN 0 ELSE 1 END,
    r.wait_type,
    r.wait_time DESC,
    r.session_id;

SELECT
    r.wait_type,
    COUNT_BIG(*) AS waiting_request_count,
    SUM(CONVERT(bigint, r.wait_time)) AS total_current_wait_ms,
    MAX(r.wait_time) AS max_current_wait_ms
FROM sys.dm_exec_requests AS r
WHERE r.database_id = DB_ID()
  AND r.session_id > 50
  AND r.wait_type IS NOT NULL
GROUP BY r.wait_type
ORDER BY waiting_request_count DESC, total_current_wait_ms DESC;

SELECT
    s.session_id,
    s.status,
    s.host_name,
    s.program_name,
    s.login_name,
    CASE
        WHEN OBJECT_ID(N'dbo.' + QUOTENAME(N'Table' + CONVERT(nvarchar(20), s.session_id)), N'U') IS NULL
        THEN N'MISSING'
        ELSE N'OK'
    END AS spid_table_mapping
FROM sys.dm_exec_sessions AS s
WHERE s.is_user_process = 1
  AND s.database_id = DB_ID()
ORDER BY s.session_id;
GO
