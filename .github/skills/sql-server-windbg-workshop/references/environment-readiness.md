# Environment readiness workflow

Use the learner's language. Prefer the Chinese setup guide when the learner writes Chinese.

## Procedure

Steps 1–8 are the automated prerequisite phase. Run idempotent checks automatically, skip work already proven complete, and pause only for required learner interaction or approval. Manual teaching mode begins at step 9: present one checkpoint, wait for the learner to complete it and return the result, then continue. Do not execute WinDbg MCP commands automatically unless the learner explicitly invokes the Prompt demo or asks for that debugger checkpoint to be run.

Execute local actions only through the checked-in PowerShell scripts named below. Execute debugger commands only by copying the corresponding exact entry from [06-WinDbg-Load-Commands.txt](../../../workshop/setup/steps/06-WinDbg-Load-Commands.txt). Do not synthesize command text from this prose. If a required static command is not cataloged, add it to the catalog before execution. Thread selection is the only dynamic exception and must be copied verbatim from current MEX DML output.

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
16. Teach native command logging with separate `.logopen`, `.logfile`, and `.logclose` commands when requested.
17. Use `!mex.help` separately for current-version command discovery; do not invent MEX commands.
18. Avoid unfiltered `!mex.us`; execute `!us logwriter` separately to find matching Log Writer threads.
19. Preserve the returned thread identifiers and follow only a thread-selection link/command returned by MEX.
20. Execute native `k` separately for the selected debugger thread, then execute `!mex.t -raw` separately for the MEX raw view. Compare only the runtime output: `k` uses WinDbg's current debugger context; `!mex.t -raw` is MEX-provided and may present/unwind the stack differently. Neither command adds memory to the dump. Do not diagnose the stack in Setup.
21. Verify `sqlservr.exe` with `lmv m sqlservr` before dscript initialization.
22. Execute bare `!execute` separately to enumerate the scripts/help already exposed by the current WinDbgCs runtime.
23. Preserve that output and use only runtime-advertised script links and syntax.
24. Execute `!execute ExternalScripts.Install ;` only if the action is explicitly advertised and the required scripts are not already loaded.
25. Redirect diagnostic dscript execution and interpretation to `agent_lab1`.
26. After the learner completes and understands the manual sequence, invoke `WinDbg MCP Log Writer Demo` from `.github/prompts/windbg-mcp-logwriter-demo.prompt.md`.
27. Confirm `DbgX.Mcp.Proxy` tools are selected for the custom Agent, especially `list_sessions`, `connect_session`, `show_output`, and `get_output_history`.
28. Compare the Prompt + MCP evidence with the manual baseline for session verification, both `.load` commands, `.chain`, `!us logwriter`, thread selection, `k`, and `!mex.t -raw`. A demo passes only when the runtime evidence agrees; do not diagnose the stack in Setup.

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
