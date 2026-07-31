# WinDbg workshop setup automation

Use `Prepare-WinDbgWorkshop.ps1` to stage and verify local debugger prerequisites without committing binaries to Git.

## Inputs

- Internal `windbgSlowRing.appinstaller` share path, configurable with `-WinDbgInstallerSource`.
- Approved local or UNC path to `mex.dll`, supplied with `-MexSource`.
- Approved local or UNC path to `WinDbgCs.3.2.7.nupkg`, supplied with `-WinDbgCsPackageSource`.
- Approved version-specific dscript source directories configured in `dscript-sources.json`.

## Behavior

The script copies files into `C:\tools\SqlDebugWorkshop`, recursively stages configured dscript directories, validates expected package metadata, calculates SHA-256 hashes, and writes `inventory.json`. It does not install AppX or NuGet packages automatically.

Use `-VerifyOnly` to inspect already staged files and the installed WinDbg package without copying or downloading assets.

Do not add binaries, private symbols, internal source assets, dumps, or the generated inventory to this repository.
