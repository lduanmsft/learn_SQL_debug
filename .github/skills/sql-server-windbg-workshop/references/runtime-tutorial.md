# WinDbg runtime setup tutorial

Use this tutorial after local prerequisites pass. Teach one checkpoint at a time and run one debugger command per WinDbg MCP execution.

## 1. Open the target dump in WinDbg

1. Start the validated WinDbg Slow Ring application.
2. Select **File > Open dump file** (or press `Ctrl+D`).
3. Select the target `.mdmp` file from the artifact manifest or learner-provided path.
4. Wait until initial dump and symbol loading stops producing output and the command prompt is available.

Opening a file in the editor or proving that it exists on disk does not prove WinDbg opened it.

## 2. Connect WinDbg MCP to the exact session

1. List all WinDbg MCP sessions.
2. Compare each session title with the target dump name/path.
3. Connect to the matching session only.
4. Read debugger output history and verify that the target dump path appears there.
5. If no matching session exists, ask the learner to open the dump manually; do not select an unrelated session.

MCP connection and dump loading are separate facts: MCP may be available while no target dump is open.

## 3. Inspect dump capture structure

After connecting to the exact dump session, execute one standalone command:

```text
.dumpdebug
```

Explain the output as dump metadata, not as a diagnosis:

- `MINIDUMP_HEADER`: signature, format version, stream count, directory location, timestamp, and capture flags.
- `MINIDUMP_TYPE`/flags: options requested when the dump was created. A flag does not guarantee that every requested address is readable.
- `ThreadListStream`: recorded thread IDs, contexts, and stack descriptors. A recorded thread does not by itself prove that its entire stack can be unwound.
- `ThreadInfoListStream`: additional thread metadata; it is not a call stack.
- `MemoryListStream` or `Memory64ListStream`: virtual-memory ranges whose bytes were saved. `MiniDumpWithFullMemoryInfo` describes the memory map; it is not equivalent to `MiniDumpWithFullMemory`.
- `ModuleListStream` and `UnloadedModuleListStream`: loaded and unloaded module metadata. Module presence is separate from successful symbol loading.
- `ExceptionStream`: exception record and context for the dump-triggering thread when present; it does not represent every thread.

Use the actual output to state what is present and what remains unknown. Do not conclude that a Log Writer thread is absent merely because a filter returns no result, and do not infer a Lab 1 root cause from dump flags or stream names.

## 4. Configure and verify symbols

For persistent user-level setup, use the approved configuration script only when requested:

```powershell
.\workshop\setup\steps\05-Configure-SymbolsAndSource.ps1
```

It configures:

```text
_NT_SYMBOL_PATH=cache*C:\symbol;srv*https://symweb.azurefd.net
SRCSRV_INI_FILE=C:\SRC\srcsrv.default.ini
```

Restart WinDbg after changing environment variables. In the connected dump session, execute `.sympath` by itself and explain each path component. Do not append another command after `.sympath`.

If the current session must be corrected, execute this as its own command:

```text
.sympath srv*C:\symbol*https://symweb.azurefd.net;cache*C:\symbol;srv*https://symweb.azurefd.net
```

Then execute `.reload /f` separately. This can be expensive; explain why it is needed before running it. If symbol loading is unexpected, inspect WinDbg logs before changing configuration again.

## 5. Open and close a WinDbg command log

The native WinDbg command is `.logopen`, not `log.open`.

Open a new log as one debugger command:

```text
.logopen /t C:\temp\windbg-workshop.txt
```

- `/t` adds process/date/time information to the generated log name.
- Use a local private path. Never write dump output into the public repository.
- If the selected file already exists, choose a different file or explicitly decide whether replacement/appending is appropriate; do not overwrite evidence silently.

Check the active log as a separate command:

```text
.logfile
```

Close it as a separate command:

```text
.logclose
```

Do not confuse native `.logopen` with a C# or dscript logging API such as `logopen(String)` found inside WinDbgCs.

## 6. Load and verify MEX

Execute exactly one command:

```text
.load C:\tools\SqlDebugWorkshop\extensions\mex.dll
```

Expected successful output includes:

```text
Mex 3.1.0.243 Loaded!
```

Then execute `.chain` separately and verify the exact MEX path. File presence or a remembered result from another session is insufficient.

For basic MEX discovery, execute the extension-qualified help command separately:

```text
!mex.help
```

Teach commands only from the help output returned by the currently loaded MEX version. Do not invent MEX command names or assume another version has identical syntax.

### Filter Log Writer threads and compare `k` with `!mex.t -raw`

Do not begin with unfiltered `!mex.us`: it can return a very large result. Use the filter as one standalone command:

```text
!us logwriter
```

Teaching sequence:

1. Explain that `!us` groups/searches stacks and `logwriter` is the filter text; the command finds threads whose captured stack matches that text.
2. Preserve every thread identifier and selection link/command returned by the current MEX output. A match is a candidate thread, not proof of a root cause.
3. Record the current debugger thread/context before switching.
4. Select one matching thread only by following the DML thread link or exact selection command returned by MEX. Do not invent a thread number or selector.
5. Execute native WinDbg `k` separately for the selected debugger thread:

```text
k
```

6. Execute the MEX raw view as another standalone command:

```text
!mex.t -raw
```

7. Compare only the output actually returned by this runtime:

   - `k` is a built-in WinDbg command. It walks the stack from the currently selected debugger thread and register context using WinDbg's native unwinder and symbols.
   - `!mex.t -raw` is a MEX extension command. The `-raw` option asks this loaded MEX version for its raw stack view of the MEX selected/current thread context.
   - The two displays may differ in frame count, inline-frame presentation, thread/context handling, and formatting. A longer MEX result does not mean `!mex.t -raw` added memory to the dump, repaired the dump, or proved that native `k` symbols are wrong.
   - Before comparing them, verify both commands refer to the same returned thread. If they differ, report the observed difference and preserve both outputs; do not invent an internal explanation.

8. Teach how to read the stack columns and frame order at a basic level, but do not interpret the Log Writer state, blocking chain, or cause. Redirect that analysis to `agent_lab1`.

`!us logwriter` is preferred over unfiltered `!mex.us` for this workshop checkpoint because it keeps output bounded and teaches targeted thread discovery. Setup may demonstrate command mechanics and compare `k` with `!mex.t -raw`; stack diagnosis belongs to `agent_lab1`.

## 7. Load and verify WinDbgCs

Execute exactly one command:

```text
.load C:\Program Files\PackageManagement\NuGet\Packages\WinDbgCs.3.2.7\WinDbgCsExt.dll
```

Expected successful output includes:

```text
WinDbgCs: C# scripting for WinDbg
NuGet Version: 3.2.7
```

Load from the package directory because adjacent dependencies are required. Then execute `.chain` separately and verify the exact WinDbgCs path.

## 8. Discover `!execute` scripts and initialize dscript only when needed

After `.chain` proves WinDbgCs is loaded, first execute the bare command as one standalone debugger execution:

```text
!execute
```

This is the WinDbgCs script/help discovery entry point. Preserve its exact output. It can show:

- Scripts currently loaded, grouped alphabetically.
- Script links or names exposed by the active runtime.
- Runtime-provided help/source links.

Before using diagnostic scripts:

1. Execute `lmv m sqlservr` separately and record the exact SQL Server build.
2. Confirm that the matching version-specific dscript set exists. Lab 1 requires SQL2016.
3. Compare the bare `!execute` output with the required script family.
4. Use only DML links, names, and syntax actually advertised by the current runtime output.
5. Never paste a staged `.js` file path into `!execute` as ordinary JavaScript source; these assets are protected and version-specific.

Only when the current WinDbgCs output explicitly advertises an installation action and the required scripts are not already loaded may the learner execute this separately:

```text
!execute ExternalScripts.Install ;
```

Do not run that initialization command by default. If bare `!execute` already reports the required script sets as loaded, continue with runtime help/discovery instead.

This Setup Agent may explain the catalog and follow a harmless runtime-provided Help link. Running diagnostic dscript and interpreting SQL state belongs to `agent_lab1` after the setup gate passes.

## 9. Final runtime proof

Execute `.chain` alone. Setup passes only when it shows both exact paths:

```text
C:\tools\SqlDebugWorkshop\extensions\mex.dll
C:\Program Files\PackageManagement\NuGet\Packages\WinDbgCs.3.2.7\WinDbgCsExt.dll
```

Record what is proven, what remains unknown, whether command logging is active/closed, and whether the learner can switch to `agent_lab1`.

## 10. Prompt + WinDbg MCP demo

Run this only after the learner understands the preceding manual commands. The objective is to demonstrate that one reusable Prompt can instruct the Agent to call WinDbg MCP and collect the same runtime evidence without bypassing any gate.

### Prepare the custom Agent tools

1. Select **SQL Server WinDbg Instructor** in the Agent picker.
2. Open **Configure Tools** for that Agent.
3. Select the complete `DbgX.Mcp.Proxy` group. At minimum, verify `list_sessions`, `connect_session`, `show_output`, and `get_output_history` are selected.
4. Apply the tool selection before running the Prompt. Highlighting the row is not sufficient; its checkbox must be checked.

### Invoke the reusable Prompt

Run **WinDbg MCP Log Writer Demo** by typing `/` in the Chat input and selecting it from the Prompt list, or by running **Chat: Run Prompt...** from the Command Palette and selecting it there. Do not use the Markdown source file as an execution action. To review its contents, use Quick Open (`Ctrl+P`) and enter `.github/prompts/windbg-mcp-logwriter-demo.prompt.md`. The Prompt instructs the Agent to:

1. List and verify the target dump session.
2. Execute the MEX and WinDbgCs `.load` commands separately.
3. Verify both exact extension paths with a separate `.chain`.
4. Run `!us logwriter` and preserve the runtime-returned thread ID.
5. Switch using that returned thread ID/link rather than a hard-coded example.
6. Execute native `k` and `!mex.t -raw` separately on the same thread.
7. Compare the actual outputs without diagnosing the Log Writer state.

### Manual-to-Prompt evidence mapping

| Manual checkpoint | Prompt + MCP checkpoint | Required evidence |
|---|---|---|
| Identify the WinDbg window | `list_sessions` and connect/verify | Target dump path/title and active PID |
| Load MEX | First standalone `.load` | No load error; later confirmed by `.chain` |
| Load WinDbgCs | Second standalone `.load` | No load error; later confirmed by `.chain` |
| Verify extensions | Standalone `.chain` | Both exact DLL paths and versions |
| Find Log Writer | `!us logwriter` | Runtime-returned matching thread and `SQLServerLogMgr::LogWriter` frame |
| Select thread | Runtime-returned link/ID | Current debugger context is the matching thread |
| Native stack | Standalone `k` | WinDbg-unwound call chain |
| Raw stack scan | Standalone `!mex.t -raw` | MEX stack-pointer-to-base output for the same thread |

The automated demo is successful only when its evidence matches the manual baseline. The Prompt does not replace understanding of the commands, does not make raw stack candidates into valid unwind frames, and does not extend Setup into Lab 1 diagnosis.

### Repeatability contract for the next session

Every new invocation of **SQL Server WinDbg Instructor** must reconstruct current runtime state rather than trusting this tutorial or a prior chat as evidence:

1. List sessions and identify the target from the current title/history.
2. Connect only when the target is not already the active proxy session.
3. Run the two `.load` commands separately in MEX-then-WinDbgCs order.
4. Run `.chain` and verify both exact paths before using extension output.
5. Run `!us logwriter`; use the returned thread ID from this execution.
6. Switch only if the returned thread is not already current.
7. Run `k`, then `!mex.t -raw`, as two separate executions.
8. Produce the same checkpoint report structure and manual-to-Prompt mapping.

For the validated `SQLDump0016.mdmp`, use [validated runtime baseline](./validated-runtime-baseline.md) for the complete comparison checklist. Its MEX `3.1.0.243`, WinDbgCs `3.2.7`, one Log Writer match, and native `k` evidence are expected observations, not constants to inject into output. A different current result must be preserved and reported as a difference.