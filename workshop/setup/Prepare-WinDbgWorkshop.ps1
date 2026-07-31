[CmdletBinding()]
param(
    [string]$DestinationRoot = 'C:\tools\SqlDebugWorkshop',
    [string]$WinDbgInstallerSource = '\\sesdfs\1Windows\TestContent\ES\dbg\dbgx\windbgSlowRing.appinstaller',
    [string]$MexSource,
    [string]$WinDbgCsPackageSource,
    [string]$DscriptManifest = (Join-Path $PSScriptRoot 'dscript-sources.json'),
    [switch]$VerifyOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$expectedWinDbgPackage = 'Microsoft.WinDbg.Slow'
$expectedWinDbgVersion = [version]'1.2606.22001.1'
$expectedWinDbgCsId = 'WinDbgCs'
$expectedWinDbgCsVersion = '3.2.7'
$inventory = [System.Collections.Generic.List[object]]::new()

function Add-InventoryItem {
    param(
        [Parameter(Mandatory)] [string]$Component,
        [Parameter(Mandatory)] [string]$Path,
        [string]$Version,
        [string]$Notes
    )

    $item = Get-Item -LiteralPath $Path -ErrorAction Stop
    $inventory.Add([pscustomobject]@{
        Component = $Component
        Path = $item.FullName
        SizeBytes = $item.Length
        Sha256 = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash
        Version = $Version
        Notes = $Notes
    })
}

function Copy-RequiredFile {
    param(
        [Parameter(Mandatory)] [string]$Source,
        [Parameter(Mandatory)] [string]$Destination,
        [Parameter(Mandatory)] [string]$Description
    )

    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
        throw "$Description was not found: $Source"
    }

    $parent = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    $sourcePath = [IO.Path]::GetFullPath($Source)
    $destinationPath = [IO.Path]::GetFullPath($Destination)
    if ($sourcePath -ne $destinationPath) {
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
    }
}

function Test-WinDbgInstaller {
    param([Parameter(Mandatory)] [string]$Path)

    [xml]$xml = Get-Content -LiteralPath $Path -Raw
    $nodes = @($xml.SelectNodes('//*[local-name()="MainPackage" or local-name()="MainBundle" or local-name()="Package"]'))
    $packageNode = $nodes | Where-Object { $_.GetAttribute('Name') -eq $expectedWinDbgPackage } | Select-Object -First 1

    if ($null -eq $packageNode) {
        $observedNames = ($nodes | ForEach-Object { $_.GetAttribute('Name') } | Where-Object { $_ } | Sort-Object -Unique) -join ', '
        throw "The app installer does not reference expected package $expectedWinDbgPackage. Observed: $observedNames"
    }

    $packageVersion = $packageNode.GetAttribute('Version')
    if ([version]$packageVersion -ne $expectedWinDbgVersion) {
        throw "Unexpected WinDbg package version $packageVersion; expected $expectedWinDbgVersion."
    }

    Add-InventoryItem -Component 'WinDbg app installer' -Path $Path -Version $packageVersion -Notes $packageNode.GetAttribute('Name')
}

function Get-NuGetMetadata {
    param([Parameter(Mandatory)] [string]$Path)

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($Path)
    try {
        $nuspecEntry = $archive.Entries | Where-Object FullName -Like '*.nuspec' | Select-Object -First 1
        if ($null -eq $nuspecEntry) {
            throw "No .nuspec was found in $Path."
        }

        $reader = [System.IO.StreamReader]::new($nuspecEntry.Open())
        try {
            [xml]$nuspec = $reader.ReadToEnd()
        }
        finally {
            $reader.Dispose()
        }

        $metadata = $nuspec.package.metadata
        [pscustomobject]@{
            Id = [string]$metadata.id
            Version = [string]$metadata.version
        }
    }
    finally {
        $archive.Dispose()
    }
}

function Stage-DscriptAssets {
    param([Parameter(Mandatory)] [string]$ManifestPath)

    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        throw "Dscript manifest was not found: $ManifestPath"
    }

    $manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
    foreach ($release in $manifest.releases) {
        if ([string]::IsNullOrWhiteSpace([string]$release.sourceDirectory)) {
            Write-Warning "No approved dscript source is configured for $($release.version); skipping."
            continue
        }

        $sourceDirectory = [string]$release.sourceDirectory
        if (-not (Test-Path -LiteralPath $sourceDirectory -PathType Container)) {
            throw "$($release.version) dscript directory was not found: $sourceDirectory"
        }

        $destinationDirectory = Join-Path $DestinationRoot "dscript\$($release.version)"
        New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
        Copy-Item -Path (Join-Path $sourceDirectory '*') -Destination $destinationDirectory -Recurse -Force

        $stagedFiles = @(Get-ChildItem -LiteralPath $destinationDirectory -Recurse -File)
        if ($stagedFiles.Count -eq 0) {
            throw "No files were staged for $($release.version) from $sourceDirectory."
        }

        foreach ($file in $stagedFiles) {
            Add-InventoryItem -Component "dscript $($release.version)" -Path $file.FullName -Notes 'Version-specific workshop asset'
        }
    }
}

$installerDestination = Join-Path $DestinationRoot 'WinDbg\windbgSlowRing.appinstaller'
$mexDestination = Join-Path $DestinationRoot 'extensions\mex.dll'
$winDbgCsDestination = 'C:\tools\WinDbgCs.3.2.7.nupkg'

if (-not $VerifyOnly) {
    Copy-RequiredFile -Source $WinDbgInstallerSource -Destination $installerDestination -Description 'WinDbg Slow Ring app installer'

    if ([string]::IsNullOrWhiteSpace($MexSource)) {
        Write-Warning 'MexSource was not supplied; mex.dll was not staged.'
    }
    else {
        Copy-RequiredFile -Source $MexSource -Destination $mexDestination -Description 'mex.dll'
    }

    if ([string]::IsNullOrWhiteSpace($WinDbgCsPackageSource)) {
        Write-Warning 'WinDbgCsPackageSource was not supplied; WinDbgCs was not staged.'
    }
    else {
        Copy-RequiredFile -Source $WinDbgCsPackageSource -Destination $winDbgCsDestination -Description 'WinDbgCs package'
    }

    Stage-DscriptAssets -ManifestPath $DscriptManifest
}

if (Test-Path -LiteralPath $installerDestination -PathType Leaf) {
    Test-WinDbgInstaller -Path $installerDestination
}
else {
    Write-Warning "Staged WinDbg app installer is missing: $installerDestination"
}

if (Test-Path -LiteralPath $mexDestination -PathType Leaf) {
    Add-InventoryItem -Component 'MEX extension' -Path $mexDestination
}
else {
    Write-Warning "Staged mex.dll is missing: $mexDestination"
}

if (Test-Path -LiteralPath $winDbgCsDestination -PathType Leaf) {
    $metadata = Get-NuGetMetadata -Path $winDbgCsDestination
    if ($metadata.Id -ne $expectedWinDbgCsId) {
        throw "Unexpected WinDbgCs package ID $($metadata.Id); expected $expectedWinDbgCsId."
    }
    if ($metadata.Version -ne $expectedWinDbgCsVersion) {
        throw "Unexpected WinDbgCs package version $($metadata.Version); expected $expectedWinDbgCsVersion."
    }
    Add-InventoryItem -Component 'WinDbgCs NuGet package' -Path $winDbgCsDestination -Version $metadata.Version -Notes "Package ID: $($metadata.Id)"
}
else {
    Write-Warning "Staged WinDbgCs package is missing: $winDbgCsDestination"
}

$installedWinDbg = Get-AppxPackage -Name $expectedWinDbgPackage -ErrorAction SilentlyContinue |
    Sort-Object Version -Descending |
    Select-Object -First 1

if ($null -eq $installedWinDbg) {
    Write-Warning "$expectedWinDbgPackage is not installed. Open the validated app installer manually."
}
elseif ([version]$installedWinDbg.Version -ne $expectedWinDbgVersion) {
    throw "Installed $expectedWinDbgPackage version is $($installedWinDbg.Version); expected $expectedWinDbgVersion."
}
else {
    Write-Host "Verified installed $expectedWinDbgPackage $($installedWinDbg.Version)."
}

New-Item -ItemType Directory -Path $DestinationRoot -Force | Out-Null
$inventoryPath = Join-Path $DestinationRoot 'inventory.json'
$inventory | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $inventoryPath -Encoding utf8
$inventory | Format-Table -AutoSize
Write-Host "Inventory written to $inventoryPath"
