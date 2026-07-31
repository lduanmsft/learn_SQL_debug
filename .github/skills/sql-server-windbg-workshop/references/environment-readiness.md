# Environment readiness workflow

Use the learner's language. Prefer the Chinese setup guide when the learner writes Chinese.

## Procedure

1. Read the applicable setup guide under `workshop`.
2. Check source assets with `workshop/setup/steps/01-Test-SourceAssets.ps1`.
3. Stage assets with `02-Stage-WorkshopAssets.ps1` only when requested.
4. Verify WinDbg package name and exact version.
5. Verify WinDbgCs package metadata and installation state; successful `Install-Package` can be silent.
6. Configure symbols/source with `05-Configure-SymbolsAndSource.ps1` when requested.
7. Verify the environment with `04-Test-Installation.ps1`.
8. Tell the learner to restart WinDbg after environment-variable changes.
9. Ask the learner to open the target dump manually in the restarted WinDbg and wait for initial loading.
10. Use WinDbg MCP to list sessions, then connect to the session whose title/history identifies the target dump. Do not check runtime extension state before this gate passes.
11. Read debugger history to verify the expected dump was opened and preserve the existing context.
12. Run `.sympath` as a standalone WinDbg MCP command.
13. Execute `.load C:\tools\SqlDebugWorkshop\extensions\mex.dll` as one standalone WinDbg MCP command.
14. Execute `.load C:\Program Files\PackageManagement\NuGet\Packages\WinDbgCs.3.2.7\WinDbgCsExt.dll` as a separate standalone WinDbg MCP command.
15. Execute `.chain` as a third standalone command and verify both exact extension paths are present.

## Expected values

- `_NT_SYMBOL_PATH=cache*C:\symbol;srv*https://symweb.azurefd.net`
- `SRCSRV_INI_FILE=C:\SRC\srcsrv.default.ini`
- MEX successful load includes `Mex 3.1.0.243 Loaded!`
- WinDbgCs successful load includes `NuGet Version: 3.2.7`

## Failure handling

- Internal installer unavailable: confirm VPN/share access; do not invent another source.
- Symbol or source failure: inspect WinDbg logs first, then compare `.sympath`, environment inheritance, cache access, and source-server INI existence.
- Extension load failure: inspect exact error, architecture, full path, and adjacent WinDbgCs dependencies.
- A file existing on disk does not prove WinDbg loaded it; `.chain` is required.
