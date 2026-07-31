# Workshop environment setup

This workshop uses an internal WinDbg Slow Ring build plus SQL Server debugging extensions. The setup assets are not committed to Git.

## Required components

| Component | Required value | Default staging location |
|---|---|---|
| WinDbg app installer | `windbgSlowRing.appinstaller` | `C:\tools\SqlDebugWorkshop\WinDbg\` |
| WinDbg package | `Microsoft.WinDbg.Slow` | Installed AppX package |
| WinDbg version | `1.2606.22001.1` | Installed AppX package |
| MEX | `mex.dll` | `C:\tools\SqlDebugWorkshop\extensions\` |
| WinDbgCs package | `WinDbgCs.3.2.7.nupkg` | `C:\tools\` |
| SQL Server dscript files | One verified set per supported SQL Server version | `C:\tools\SqlDebugWorkshop\dscript\<version>\` |

The internal WinDbg installer source is:

`\\sesdfs\1Windows\TestContent\ES\dbg\dbgx\windbgSlowRing.appinstaller`

Access to this path requires the appropriate Microsoft corporate network and file-share permissions.

## Security and repository policy

Do not commit the following files:

- `.appinstaller`, `.msix`, or `.msixbundle` packages from internal shares.
- `mex.dll` or other debugger binaries.
- NuGet packages.
- SQL Server private symbols or source-derived binary assets.
- Dumps, TTD traces, credentials, or SAS tokens.

The repository contains only preparation automation and manifests. Each learner obtains the binaries through approved internal channels.

Verified package metadata and SHA-256 values are recorded in `setup/tool-assets-manifest.json`. Revalidate the hash before using a replacement binary with the same filename.

## Prepare the files

Run `setup/Prepare-WinDbgWorkshop.ps1` from PowerShell. The script:

1. Copies the WinDbg Slow Ring app installer from the internal share.
2. Reads the installer XML and checks that it references package `Microsoft.WinDbg.Slow` and version `1.2606.22001.1`.
3. Copies a user-supplied `mex.dll`.
4. Copies and inspects a user-supplied `WinDbgCs.3.2.7.nupkg`.
5. Downloads or copies each configured `dscript` asset from `setup/dscript-sources.json`.
6. Writes SHA-256 inventory information for reproducibility.

The committed dscript manifest intentionally contains no invented source URLs. Fill in only approved URLs or UNC paths, then run the preparation script.

## Install WinDbg Slow Ring

After the preparation script validates the installer, open:

`C:\tools\SqlDebugWorkshop\WinDbg\windbgSlowRing.appinstaller`

Complete the App Installer UI, then verify:

- Package name: `Microsoft.WinDbg.Slow`
- Version: `1.2606.22001.1`

Installing or updating the AppX package changes the machine and is deliberately not performed automatically by the preparation script.

## Install WinDbgCs

First ensure the package is staged as:

`C:\tools\WinDbgCs.3.2.7.nupkg`

The historical installation command supplied with the workshop notes is:

`Install-Package WinDbgCs.amd64 -Source C:\tools\WinDbgCs.3.2.7.nupkg`

The actual `WinDbgCs.3.2.7.nupkg` currently staged for this workshop contains package ID `WinDbgCs`, not `WinDbgCs.amd64`. Therefore, do not run the historical command blindly. With the verified package, use the containing directory as the NuGet source and pin both ID and version:

`Install-Package WinDbgCs -RequiredVersion 3.2.7 -Source C:\tools -ProviderName NuGet`

If a different approved package is provided later and its `.nuspec` reports `WinDbgCs.amd64`, use that package's verified ID. The embedded `.nuspec`, not the filename or historical command, is authoritative.

The documented command was preflighted with `Find-Package` against `C:\tools`; PackageManagement successfully discovered package `WinDbgCs` version `3.2.7` through the NuGet provider.

## Load MEX

After opening the dump in WinDbg, load the staged extension from:

`C:\tools\SqlDebugWorkshop\extensions\mex.dll`

Verify the extension loads successfully before relying on any MEX command output. Extension compatibility must be tested against the selected WinDbg architecture and dump architecture.

## Prepare dscript by SQL Server version

The workshop keeps dscript assets separated by SQL Server release because source-derived debugging helpers can be version-specific:

- `SQL2016`
- `SQL2017`
- `SQL2019`
- `SQL2022`
- `SQL2025`

At the time this setup was validated, `C:\tools\dscript` contained the `SQL2016` set. Sources for SQL Server 2017, 2019, 2022, and 2025 remain intentionally blank in the manifest until their approved copies finish arriving or their authoritative locations are provided.

For each entry in `setup/dscript-sources.json`, provide:

- An approved local or UNC source directory containing the complete version-specific script set.
- The expected SHA-256 when known.
- The SQL Server release destination directory.

The preparation script recursively copies each configured directory and produces a SHA-256 inventory for every file. A missing source causes preparation to fail rather than silently substituting another version.

## Final verification

Run the preparation script with `-VerifyOnly` after installation. Confirm:

- `Microsoft.WinDbg.Slow` version is exactly `1.2606.22001.1`.
- `mex.dll` exists and its SHA-256 is recorded.
- The WinDbgCs `.nuspec` package ID and version are expected.
- Every dscript release needed by the selected lab is present and hash-verified.
- WinDbg MCP can list and connect to the opened WinDbg session.
