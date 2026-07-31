[CmdletBinding()]
param(
    [string]$SymbolCache = 'C:\symbol',
    [string]$SymbolServer = 'https://symweb.azurefd.net',
    [string]$SourceServerIni = 'C:\SRC\srcsrv.default.ini'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $SourceServerIni -PathType Leaf)) {
    throw "Source server INI was not found: $SourceServerIni"
}

New-Item -ItemType Directory -Path $SymbolCache -Force | Out-Null

$symbolPath = "cache*$SymbolCache;srv*$SymbolServer"
[Environment]::SetEnvironmentVariable('_NT_SYMBOL_PATH', $symbolPath, 'User')
[Environment]::SetEnvironmentVariable('SRCSRV_INI_FILE', $SourceServerIni, 'User')

$env:_NT_SYMBOL_PATH = $symbolPath
$env:SRCSRV_INI_FILE = $SourceServerIni

[pscustomobject]@{
    Scope = 'Current user'
    NT_SYMBOL_PATH = [Environment]::GetEnvironmentVariable('_NT_SYMBOL_PATH', 'User')
    SRCSRV_INI_FILE = [Environment]::GetEnvironmentVariable('SRCSRV_INI_FILE', 'User')
} | Format-List

Write-Host 'Restart WinDbg after running this script so the debugger inherits the new environment variables.'