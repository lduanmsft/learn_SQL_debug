[CmdletBinding()]
param(
    [string]$StagingRoot = 'C:\tools\SqlDebugWorkshop'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$expectedWinDbgVersion = [version]'1.2606.22001.1'
$winDbg = Get-AppxPackage -Name 'Microsoft.WinDbg.Slow' -ErrorAction SilentlyContinue |
    Sort-Object Version -Descending |
    Select-Object -First 1

$checks = [System.Collections.Generic.List[object]]::new()
$checks.Add([pscustomobject]@{
    Component = 'Microsoft.WinDbg.Slow'
    Passed = $null -ne $winDbg -and [version]$winDbg.Version -eq $expectedWinDbgVersion
    Detail = if ($null -eq $winDbg) { 'Not installed' } else { "$($winDbg.Version) at $($winDbg.InstallLocation)" }
})

$paths = @(
    [pscustomobject]@{ Component = 'Staged app installer'; Path = Join-Path $StagingRoot 'WinDbg\windbgSlowRing.appinstaller' },
    [pscustomobject]@{ Component = 'MEX file present (not runtime-loaded)'; Path = Join-Path $StagingRoot 'extensions\mex.dll' },
    [pscustomobject]@{ Component = 'WinDbgCs DLL present (not runtime-loaded)'; Path = 'C:\Program Files\PackageManagement\NuGet\Packages\WinDbgCs.3.2.7\WinDbgCsExt.dll' },
    [pscustomobject]@{ Component = 'SQL2016 dscript'; Path = Join-Path $StagingRoot 'dscript\SQL2016' },
    [pscustomobject]@{ Component = 'Staged source server INI'; Path = Join-Path $StagingRoot 'source-server\srcsrv.default.ini' },
    [pscustomobject]@{ Component = 'Asset inventory'; Path = Join-Path $StagingRoot 'inventory.json' }
)

foreach ($entry in $paths) {
    $checks.Add([pscustomobject]@{
        Component = $entry.Component
        Passed = Test-Path -LiteralPath $entry.Path
        Detail = $entry.Path
    })
}

$sourceServerIni = [Environment]::GetEnvironmentVariable('SRCSRV_INI_FILE', 'User')
$checks.Add([pscustomobject]@{
    Component = 'Source server INI'
    Passed = $sourceServerIni -eq 'C:\SRC\srcsrv.default.ini' -and (Test-Path -LiteralPath $sourceServerIni -PathType Leaf)
    Detail = if ([string]::IsNullOrWhiteSpace($sourceServerIni)) { 'SRCSRV_INI_FILE is not set for the current user' } else { $sourceServerIni }
})

$checks | Format-Table -AutoSize
if ($checks.Passed -contains $false) {
    throw 'Workshop installation verification failed. Resolve every failed row before opening the lab dump.'
}

$dscriptFiles = @(Get-ChildItem -LiteralPath (Join-Path $StagingRoot 'dscript\SQL2016') -Recurse -File)
Write-Host "SQL2016 dscript files: $($dscriptFiles.Count)"
Write-Host 'Environment verification passed.'
