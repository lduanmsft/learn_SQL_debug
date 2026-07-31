[CmdletBinding(SupportsShouldProcess)]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$packageName = 'WinDbgCs'
$packageVersion = '3.2.7'
$packageSource = 'C:\tools'

$installed = Get-Package -Name $packageName -AllVersions -ProviderName NuGet -ErrorAction SilentlyContinue |
    Where-Object Version -eq $packageVersion |
    Select-Object -First 1

if ($null -ne $installed) {
    Write-Host "$packageName $packageVersion is already installed at $($installed.Source)."
    return
}

$available = Find-Package -Name $packageName -RequiredVersion $packageVersion -Source $packageSource -ProviderName NuGet
Write-Host "Found $($available.Name) $($available.Version) in $packageSource."

if ($PSCmdlet.ShouldProcess("$packageName $packageVersion", 'Install local NuGet package')) {
    Install-Package -Name $packageName -RequiredVersion $packageVersion -Source $packageSource -ProviderName NuGet -Force | Out-Null
}

$installed = Get-Package -Name $packageName -AllVersions -ProviderName NuGet -ErrorAction Stop |
    Where-Object Version -eq $packageVersion |
    Select-Object -First 1

if ($null -eq $installed) {
    throw "$packageName $packageVersion was not found after installation."
}

Write-Host "Verified installed $packageName $packageVersion."
Write-Host "Package: $($installed.Source)"
