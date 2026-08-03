# Validated runtime baseline — SQLDump0016

This file records the evidence observed during the validated workshop run. It is a comparison baseline, not current debugger state. Every new Agent invocation must rerun the commands and preserve the current output. Never inject these values when the runtime differs.

## Target identity observed

- Dump name: `SQLDump0016.mdmp`
- WinDbg: `Microsoft.WinDbg.Slow` `1.2606.22001.1`
- Historical WinDbg process ID: `17620`
- Historical MCP pipe: `WinDbg-MCP-17620`
- Window title ended with `SQLDump0016\SQLDump0016.mdmp - WinDbg 1.2606.22001.1`

The process ID and pipe are dynamic and must never be used to select a future session. Match the current window title and output history instead.

## Fixed execution order

After current-session identification and connection, use one debugger command per MCP execution:

1. `.dumpdebug`
2. `.sympath`
3. `.load C:\tools\SqlDebugWorkshop\extensions\mex.dll`
4. `.load C:\Program Files\PackageManagement\NuGet\Packages\WinDbgCs.3.2.7\WinDbgCsExt.dll`
5. `.chain`
6. `!mex.help`
7. `!us logwriter`
8. Select the runtime-returned thread only when it is not already current.
9. `k`
10. `!mex.t -raw`
11. `lmv m sqlservr`
12. Bare `!execute`
13. `!execute ExternalScripts.Install ;` only if the current bare `!execute` output advertises it and the required scripts are absent.

When command logging is taught, run `.logopen`, `.logfile`, and `.logclose` separately. Do not combine them with another command.

## Runtime evidence observed

### Extensions

- MEX version: `3.1.0.243`
- MEX path in `.chain`: `C:\tools\SqlDebugWorkshop\extensions\mex.dll`
- WinDbgCs version: `3.2.7`
- WinDbgCs path in `.chain`: `C:\Program Files\PackageManagement\NuGet\Packages\WinDbgCs.3.2.7\WinDbgCsExt.dll`

A silent `.load` is not sufficient proof. The current `.chain` output must show both paths.

### SQL Server

- SQL Server build: `13.0.5366.0`
- File version: `2015.131.5366.0`
- Release family: SQL Server 2016

The current `lmv m sqlservr` output remains authoritative for version-matched dscript selection.

### Filtered Log Writer discovery

The validated `!us logwriter` execution reported:

- One matching thread out of 505.
- Historical debugger thread ID: `21`.
- A symbolized `sqlmin!SQLServerLogMgr::LogWriter+0x6ae` frame.

Thread `21` is historical. Future runs must use only the ID/link returned by their own `!us logwriter` output.

### Native `k` presentation

On the selected historical thread, native `k` produced a reconstructed call chain containing these key frames in the observed wait-to-worker path:

- `ntdll!ZwWaitForSingleObject`
- `KERNELBASE!WaitForSingleObjectEx`
- `sqldk!SOS_Scheduler::SwitchContext`
- `sqldk!SOS_Scheduler::SuspendNonPreemptive`
- `sqldk!EventInternal<SuspendQueueSLock>::Wait`
- `sqldk!ResQueueBase::Dequeue`
- `sqlmin!SQLServerLogMgr::LogWriter`
- SQL scheduler/worker entry frames
- `ntdll!RtlUserThreadStart`

These names are comparison evidence only and are not a Setup-level diagnosis.

### MEX `!mex.t -raw` presentation

The validated raw view identified historical debugger thread `21`, OS thread `0x10fc` (`4348`), and displayed a stack-pointer-to-base scan. It contained addresses corresponding to the native chain plus additional symbolizable stack values.

The extra values are not all unwind-validated frames. Their presence does not prove added dump memory, repaired capture state, incorrect native symbols, or a root cause.

## Prompt + MCP replay contract

The reusable Prompt replays the bounded automation sequence:

1. Verify current target session.
2. Load MEX separately.
3. Load WinDbgCs separately.
4. Verify both with `.chain`.
5. Run `!us logwriter`.
6. Select the current runtime-returned thread when required.
7. Run `k`.
8. Run `!mex.t -raw`.
9. Map each automated checkpoint to its manual equivalent.

A replay passes when current evidence satisfies the same gates and presentation semantics. If PID, thread ID, counts, frames, versions, or paths differ, preserve the current output and report the exact difference. Do not force the historical result.

## Required checkpoint report

For every checkpoint, output:

- `Observation`
- `Evidence`
- `Interpretation`
- `Confidence`
- `Does not prove`
- `Next checkpoint`

End with:

- What was proven in the current session.
- What remains unknown.
- Differences from this baseline.
- Whether setup is ready for handoff to `agent_lab1`.
