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

# Phase 1: Prepare the workshop environment

Prepare local assets, install debugger components, and verify symbol/source configuration in this order. Passing Phase 1 proves only that files and configuration are ready; it does not prove an extension is runtime-loaded in a WinDbg session.

Use the [directory layout](./setup/DIRECTORY-LAYOUT.md) as the canonical placement guide. Run PowerShell as Administrator for the package-installation step.

## Step 1 — Connect and validate source assets

Connect to the Microsoft corporate VPN, finish copying the approved assets into `C:\tools`, and run:

`workshop\setup\steps\01-Test-SourceAssets.ps1`

This verifies the internal WinDbg installer, `mex.dll`, WinDbgCs package, and available versioned dscript directories before making changes.

## Step 2 — Stage and hash workshop assets

Run:

`workshop\setup\steps\02-Stage-WorkshopAssets.ps1`

This invokes `Prepare-WinDbgWorkshop.ps1` using the standard source and destination directories.

## Step 3 — Install WinDbg Slow Ring

Open the validated app installer from:

`C:\tools\SqlDebugWorkshop\WinDbg\windbgSlowRing.appinstaller`

Complete the App Installer UI and verify package `Microsoft.WinDbg.Slow` version `1.2606.22001.1`.

## Step 4 — Install WinDbgCs

Run:

`workshop\setup\steps\03-Install-WinDbgCs.ps1`

The script first checks whether `WinDbgCs` version `3.2.7` is already installed. It avoids the confusing silent reinstall behavior and verifies the package after installation.

## Step 5 — Verify the complete environment

Run:

`workshop\setup\steps\04-Test-Installation.ps1`

Do not continue until every row passes.

## Step 6 — Configure symbols and source server

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

# Phase 2: Open the dump and connect WinDbg MCP

Phase 1 proves that local files, packages, and environment values are ready. Phase 2 proves that the target dump is open in WinDbg, MCP is connected to the exact session, and the extensions are runtime-loaded. Execute one debugger command per WinDbg MCP execution; never combine adjacent checkpoints.

Use the same teaching report for every checkpoint:

- `Observation`: what the current execution returned.
- `Evidence`: the relevant runtime output.
- `Interpretation`: what that evidence supports.
- `Confidence`: confidence in the current conclusion.
- `Does not prove`: conclusions not supported by this evidence.
- `Next checkpoint`: the next standalone check.

## Step 7 — Open the target dump and connect the exact session

Open the Lab 1 dump in WinDbg and wait until initial dump and symbol output settles. Then:

1. List WinDbg MCP sessions.
2. Select and connect to the session whose window title identifies the Lab 1 dump.
3. Read debugger output history and confirm the opened dump path matches the target artifact.
4. If no session matches, stop and ask the learner to open the dump manually; do not connect to an unrelated session.

Until the dump session is connected and `.chain` later verifies the extensions, report only that the DLL files are present—not that MEX or WinDbgCs is runtime-loaded. Process IDs and MCP pipe names are dynamic; never select a future session from a historical PID.

## Step 8 — Inspect the dump capture structure

After connecting to the exact session, execute separately:

```text
.dumpdebug
```

Teach the output as capture metadata rather than diagnosis:

- `MINIDUMP_HEADER`: signature, format version, stream count, directory, timestamp, and flags.
- `MINIDUMP_TYPE`/flags: capture options requested by the dump writer; they do not guarantee that every target address is readable.
- `ThreadListStream`: recorded thread IDs, contexts, and stack descriptors. A thread record does not guarantee complete unwindable stack memory.
- `ThreadInfoListStream`: additional thread metadata, not a call stack.
- `MemoryListStream`/`Memory64ListStream`: virtual-memory ranges whose bytes were captured.
- `MiniDumpWithFullMemoryInfo` describes memory-map metadata; it is not equivalent to `MiniDumpWithFullMemory`.
- `ModuleListStream` and `UnloadedModuleListStream`: module metadata; module presence is separate from successful symbol loading.
- `ExceptionStream`: the dump-triggering thread exception/context when present; it does not represent every thread.

Do not infer Log Writer state or a Lab 1 root cause from dump flags or stream names.

## Step 9 — Verify symbols

Run `.sympath` as one standalone WinDbg MCP command.

The validated symbol path is:

`srv*C:\symbol*https://symweb.azurefd.net;cache*C:\symbol;srv*https://symweb.azurefd.net`

If the current session must be corrected, execute separately:

```text
.sympath srv*C:\symbol*https://symweb.azurefd.net;cache*C:\symbol;srv*https://symweb.azurefd.net
```

When a forced reload is justified, execute it as another command:

```text
.reload /f
```

Never append another command after `.sympath`; semicolons are valid symbol-path syntax.

## Step 10 — Open a private WinDbg command log (recommended for teaching)

Use a local private directory, not the public repository. Execute each command separately:

```text
.logopen /t C:\temp\windbg-workshop.txt
```

```text
.logfile
```

At the end of the lesson:

```text
.logclose
```

`.logopen` is a native WinDbg command, not a similarly named WinDbgCs API. Do not silently overwrite an existing evidence file.

## Step 11 — Load MEX

Execute separately:

```text
.load C:\tools\SqlDebugWorkshop\extensions\mex.dll
```

The validated version reports MEX `3.1.0.243`. A silent or error-free `.load` is not sufficient proof; `.chain` must later show the exact path.

## Step 12 — Load WinDbgCs

Execute separately:

```text
.load C:\Program Files\PackageManagement\NuGet\Packages\WinDbgCs.3.2.7\WinDbgCsExt.dll
```

Load from the package directory because adjacent dependencies are required. The validated package reports WinDbgCs `3.2.7`.

## Step 13 — Verify the extension chain

Execute separately:

```text
.chain
```

Require both exact paths:

```text
C:\tools\SqlDebugWorkshop\extensions\mex.dll
C:\Program Files\PackageManagement\NuGet\Packages\WinDbgCs.3.2.7\WinDbgCsExt.dll
```

Do not rely on MEX or WinDbgCs command output until this gate passes.

## Step 14 — Discover MEX commands and establish the manual Log Writer stack baseline

After `.chain` succeeds, teach the learner to run each command separately:

1. Run `!mex.help` and use only syntax advertised by the loaded MEX version; do not guess commands from another release.
2. Run `!us logwriter`; do not start with unfiltered `!mex.us`.
3. Record the thread ID, selection link/command, and `SQLServerLogMgr::LogWriter` frame returned by this execution. A match identifies a candidate thread; it does not prove a root cause.
4. Record current debugger thread/context before switching.
5. Select only the runtime-returned thread link/ID; do not hard-code an example thread. If it is already current, record that fact rather than switching unnecessarily.
6. Run native `k` and preserve the WinDbg-unwound call chain.
7. Verify that debugger context still refers to the same runtime-returned thread.
8. Run `!mex.t -raw` and preserve the MEX stack-pointer-to-base scan.
9. Compare the outputs: `k` reconstructs a call chain using current thread/register context, unwind metadata, and symbols. `!mex.t -raw` scans for symbolizable potential code pointers between stack pointer and stack base; not every line is an unwind-validated frame.

A longer `!mex.t -raw` result does not mean MEX added dump memory, repaired the dump, or proved native symbols wrong. Setup teaches presentation differences only; send stack diagnosis to `agent_lab1`.

For the validated `SQLDump0016.mdmp`, the historical baseline had one matching thread and a native stack containing `sqlmin!SQLServerLogMgr::LogWriter`. Historical debugger thread `21` is comparison evidence only and must never be used for a future selection.

## Step 15 — Verify the SQL Server build and discover WinDbgCs scripts

First execute separately:

```text
lmv m sqlservr
```

Record the exact current SQL Server build and file version before selecting version-matched dscript. The validated dump historically reported SQL Server `13.0.5366.0`, file version `2015.131.5366.0`; current output is always authoritative.

Then execute the bare command separately:

```text
!execute
```

Preserve scripts, help, and DML links advertised by the active WinDbgCs runtime. Use only names and syntax returned by this execution. Do not guess script names or treat protected `.js` assets as ordinary JavaScript.

Only when bare `!execute` advertises the following initialization action and required scripts are absent may it be run separately:

```text
!execute ExternalScripts.Install ;
```

Skip installation when scripts are already loaded. Setup may teach catalog/help discovery; diagnostic dscript execution and interpretation belong to `agent_lab1`.

## Step 16 — Reproduce the baseline with Prompt + WinDbg MCP

After the manual sequence is understood:

1. Select **SQL Server WinDbg Instructor**.
2. In **Configure Tools**, check the complete `DbgX.Mcp.Proxy` group, including `list_sessions`, `connect_session`, `show_output`, and `get_output_history`. Row highlighting alone is not selection.
3. Run [WinDbg MCP Log Writer Demo](../.github/prompts/windbg-mcp-logwriter-demo.prompt.md) from Chat `/` completion or **Chat: Run Prompt...**.
4. Require the Prompt to revalidate current session state and execute separate commands in this fixed order: MEX `.load` → WinDbgCs `.load` → `.chain` → `!us logwriter` → runtime-returned thread selection → `k` → `!mex.t -raw`.
5. Compare each automated checkpoint with the manual baseline.

“Same result” means the same command order, runtime gates, evidence types, and report structure—not hard-coded dynamic values. The validated `SQLDump0016.mdmp` comparison baseline is MEX `3.1.0.243`, WinDbgCs `3.2.7`, and one matching thread containing `SQLServerLogMgr::LogWriter`; every new run must independently prove those observations or report the difference.

### Manual-to-Prompt evidence mapping

| Manual checkpoint | Prompt + MCP checkpoint | Required evidence |
|---|---|---|
| Identify the WinDbg window | List, connect, and verify session | Current dump path/title and active PID |
| Load MEX | First standalone `.load` | No load error; subsequently proven by `.chain` |
| Load WinDbgCs | Second standalone `.load` | No load error; subsequently proven by `.chain` |
| Verify extensions | Standalone `.chain` | Both exact DLL paths and versions |
| Find Log Writer | `!us logwriter` | Current returned thread and `SQLServerLogMgr::LogWriter` frame |
| Select thread | Current returned link/ID | Current debugger context is the matching thread |
| Native stack | Standalone `k` | WinDbg-unwound call chain |
| Raw stack scan | Standalone `!mex.t -raw` | Stack-pointer-to-base output for the same thread |

## Step 17 — Close the runtime gate and hand off

1. Execute `.chain` separately again and verify that both exact extension paths remain present.
2. If command logging was opened, run `.logfile` to verify state and then `.logclose`.
3. Summarize facts proven in this session, remaining unknowns, and differences from the validated baseline.
4. Report the Setup runtime gate as passed only when current evidence proves the dump/session, symbols, both extensions, filtered Log Writer thread, and both stack presentations.
5. Hand stack interpretation, source correlation, and root-cause investigation to `agent_lab1`.

# Reference appendices

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
