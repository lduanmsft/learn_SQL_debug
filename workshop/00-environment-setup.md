# Workshop environment setup

This workshop uses an internal WinDbg Slow Ring build plus SQL Server debugging extensions. The setup assets are not committed to Git.

Chinese version: [Workshop 环境配置](./00-environment-setup.zh-CN.md)

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

## Ordered setup

Use the [directory layout](./setup/DIRECTORY-LAYOUT.md) as the canonical placement guide. Run PowerShell as Administrator for the package-installation step.

### Step 1 — Connect and validate source assets

Connect to the Microsoft corporate VPN, finish copying the approved assets into `C:\tools`, and run:

`workshop\setup\steps\01-Test-SourceAssets.ps1`

This verifies the internal WinDbg installer, `mex.dll`, WinDbgCs package, and available versioned dscript directories before making changes.

### Step 2 — Stage and hash workshop assets

Run:

`workshop\setup\steps\02-Stage-WorkshopAssets.ps1`

This invokes `Prepare-WinDbgWorkshop.ps1` using the standard source and destination directories.

### Step 3 — Install WinDbg Slow Ring

Open the validated app installer from:

`C:\tools\SqlDebugWorkshop\WinDbg\windbgSlowRing.appinstaller`

Complete the App Installer UI and verify package `Microsoft.WinDbg.Slow` version `1.2606.22001.1`.

### Step 4 — Install WinDbgCs

Run:

`workshop\setup\steps\03-Install-WinDbgCs.ps1`

The script first checks whether `WinDbgCs` version `3.2.7` is already installed. It avoids the confusing silent reinstall behavior and verifies the package after installation.

### Step 5 — Verify the complete environment

Run:

`workshop\setup\steps\04-Test-Installation.ps1`

Do not continue until every row passes.

### Step 6 — Configure symbols and source server

The validated environment uses:

- Symbol cache: `C:\symbol`
- Symbol server: `https://symweb.azurefd.net`
- Source server INI: `C:\SRC\srcsrv.default.ini`

Run the idempotent configuration script:

`workshop\setup\steps\05-Configure-SymbolsAndSource.ps1`

Persist the source-server INI for the current Windows user, then restart WinDbg so the newly launched process inherits it:

`[Environment]::SetEnvironmentVariable('SRCSRV_INI_FILE', 'C:\SRC\srcsrv.default.ini', 'User')`

Set it for the current PowerShell process as well when immediate verification is required:

`$env:SRCSRV_INI_FILE = 'C:\SRC\srcsrv.default.ini'`

Verify it with:

`[Environment]::GetEnvironmentVariable('SRCSRV_INI_FILE', 'User')`

Do not set the machine scope unless all users on the machine should share the same source-server configuration and the change has been approved.

### Step 7 — Open the dump, connect WinDbg MCP, and load extensions

Open the Lab 1 dump in WinDbg and wait for initial loading. Then:

1. List WinDbg MCP sessions.
2. Select and connect to the session whose window title identifies the Lab 1 dump.
3. Read debugger output history and confirm the opened dump path matches the target artifact.
4. Run `.sympath` as one standalone WinDbg MCP command.
5. Run each `.load` from `workshop\setup\steps\06-WinDbg-Load-Commands.txt` as a separate WinDbg MCP execution.
6. Run `.chain` as another separate execution and verify both exact extension paths.

Until the dump session is connected and `.chain` verifies the extensions, report only that the DLL files are present—not that MEX or WinDbgCs is runtime-loaded.

The validated symbol path is:

`srv*C:\symbol*https://symweb.azurefd.net;cache*C:\symbol;srv*https://symweb.azurefd.net`

## Preparation script details

Run `setup/Prepare-WinDbgWorkshop.ps1` from PowerShell. The script:

1. Copies the WinDbg Slow Ring app installer from `\\sesdfs\1Windows\TestContent\ES\dbg\dbgx\windbgSlowRing.appinstaller` to `C:\tools\SqlDebugWorkshop\WinDbg\windbgSlowRing.appinstaller`.
2. Reads the installer XML and checks that it references package `Microsoft.WinDbg.Slow` and version `1.2606.22001.1`.
3. Copies a user-supplied `mex.dll`.
4. Copies and inspects a user-supplied `WinDbgCs.3.2.7.nupkg`.
5. Copies `C:\SRC\srcsrv.default.ini` to `C:\tools\SqlDebugWorkshop\source-server\srcsrv.default.ini` for the private offline bundle.
6. Copies each configured version-specific `dscript` directory from `setup/dscript-sources.json`.
7. Writes SHA-256 inventory information for reproducibility.

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

`Install-Package` may complete successfully without printing a success message. Verify installation explicitly:

`Get-Package -Name WinDbgCs -RequiredVersion 3.2.7 -ProviderName NuGet`

For the machine used to validate this workshop, the package was installed at:

`C:\Program Files\PackageManagement\NuGet\Packages\WinDbgCs.3.2.7`

Confirm that `WinDbgCsExt.dll` and its dependencies exist in that directory before loading the extension in WinDbg. If the original PowerShell window still does not return to a prompt after `Get-Package` reports the package as installed, interrupt that waiting invocation with `Ctrl+C`; do not run a second installation until the installed-package check is complete.

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
