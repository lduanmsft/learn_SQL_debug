[CmdletBinding()]
param(
    [string]$MexSource = 'C:\tools\mex\mex.dll',
    [string]$WinDbgCsPackageSource = 'C:\tools\WinDbgCs.3.2.7.nupkg'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$preparationScript = Join-Path (Split-Path -Parent $PSScriptRoot) 'Prepare-WinDbgWorkshop.ps1'
& $preparationScript -MexSource $MexSource -WinDbgCsPackageSource $WinDbgCsPackageSource

if ($LASTEXITCODE) {
    exit $LASTEXITCODE
}
