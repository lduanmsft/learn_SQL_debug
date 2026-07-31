@echo off
setlocal

if "%~1"=="" goto :usage
if "%~2"=="" goto :usage

set "SQL_INSTANCE=%~1"
set "DATABASE_NAME=%~2"
set "OSTRESS_EXE=%~3"
if not defined OSTRESS_EXE set "OSTRESS_EXE=C:\tools\RMLUtils\ostress.exe"

if not exist "%OSTRESS_EXE%" (
    echo ERROR: ostress.exe was not found at "%OSTRESS_EXE%".
    exit /b 2
)

echo WARNING: This starts 400 unbounded update sessions against %SQL_INSTANCE% / %DATABASE_NAME%.
echo Run only on an isolated disposable lab instance.
choice /C YN /N /M "Continue? [Y/N] "
if errorlevel 2 exit /b 1

"%OSTRESS_EXE%" -S"%SQL_INSTANCE%" -E -d"%DATABASE_NAME%" -n400 -r1 -Q"SET NOCOUNT ON; EXEC dbo.test_insert;" -q -N -b -onNULL
exit /b %ERRORLEVEL%

:usage
echo Usage: %~nx0 ^<server\instance^> ^<database^> [full-path-to-ostress.exe]
echo Example: %~nx0 HADES-DLINGER\SQL2016 testurl C:\tools\RMLUtils\ostress.exe
exit /b 64
