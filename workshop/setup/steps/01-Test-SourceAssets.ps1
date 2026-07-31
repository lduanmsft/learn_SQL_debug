[CmdletBinding()]
param(
    [string]$WinDbgInstaller = '\\sesdfs\1Windows\TestContent\ES\dbg\dbgx\windbgSlowRing.appinstaller',
    [string]$MexPath = 'C:\tools\mex\mex.dll',
    [string]$WinDbgCsPackage = 'C:\tools\WinDbgCs.3.2.7.nupkg',
    [string]$DscriptRoot = 'C:\tools\dscript'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$requiredFiles = @(
    [pscustomobject]@{ Component = 'WinDbg app installer'; Path = $WinDbgInstaller },
    [pscustomobject]@{ Component = 'MEX'; Path = $MexPath },
    [pscustomobject]@{ Component = 'WinDbgCs package'; Path = $WinDbgCsPackage }
)

$results = foreach ($required in $requiredFiles) {
    $exists = Test-Path -LiteralPath $required.Path -PathType Leaf
    [pscustomobject]@{
        Component = $required.Component
        Path = $required.Path
        Exists = $exists
        Sha256 = if ($exists) { (Get-FileHash -LiteralPath $required.Path -Algorithm SHA256).Hash } else { $null }
    }
}

$results | Format-Table -AutoSize
if ($results.Exists -contains $false) {
    throw 'One or more required source assets are unavailable. Connect VPN or finish copying the approved files.'
}

if (-not (Test-Path -LiteralPath $DscriptRoot -PathType Container)) {
    throw "Dscript root was not found: $DscriptRoot"
}

$dscriptSummary = foreach ($directory in Get-ChildItem -LiteralPath $DscriptRoot -Directory) {
    $files = @(Get-ChildItem -LiteralPath $directory.FullName -Recurse -File)
    [pscustomobject]@{
        Version = $directory.Name
        Files = $files.Count
        Bytes = ($files | Measure-Object Length -Sum).Sum
    }
}

$dscriptSummary | Format-Table -AutoSize
if (-not ($dscriptSummary.Version -contains 'SQL2016')) {
    throw 'SQL2016 dscript assets are required for Lab 1.'
}
