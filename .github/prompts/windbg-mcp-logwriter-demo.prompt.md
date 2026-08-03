---
name: 'WinDbg MCP Log Writer Demo'
description: 'Use a Prompt and WinDbg MCP to reproduce the manual MEX/WinDbgCs loading and verification, find a Log Writer thread, and compare native k with !mex.t -raw.'
argument-hint: 'Optional: provide the target SQL Server dump file name or full path'
agent: 'SQL Server WinDbg Instructor'
---

Use WinDbg MCP to conduct a Log Writer stack demonstration in the target SQL Server dump session, automatically reproducing the steps the learner just completed manually.

Even if the previous chat completed successfully, rerun the workflow and collect fresh evidence from the current session. Do not reuse a previous PID, thread ID, extension state, or stack output. Follow the exact order below; do not reorder or combine debugger commands.

1. List the WinDbg sessions. Use the window title and output history to connect to and verify the target SQL Server dump session; do not select an unrelated session.
2. Execute only one debugger command per WinDbg MCP execution.
3. Load each extension separately:
   - `C:\tools\SqlDebugWorkshop\extensions\mex.dll`
   - `C:\Program Files\PackageManagement\NuGet\Packages\WinDbgCs.3.2.7\WinDbgCsExt.dll`
4. Execute `.chain` separately. Report MEX and WinDbgCs as runtime-loaded only after the output shows both exact paths.
5. Execute `!us logwriter` separately and record the Log Writer debugger thread ID returned by the current runtime. Do not use unfiltered `!mex.us`.
6. Switch to the Log Writer thread using the thread ID or link actually returned by this `!us logwriter` execution. Do not use a fixed thread ID from an example.
7. On the same thread, execute native `k` and `!mex.t -raw` as separate commands.
8. Compare the two actual outputs:
   - `k` is the native call chain produced from the current debugger thread/register context and WinDbg unwind metadata.
   - `!mex.t -raw` displays symbolizable potential code pointers from the stack pointer to the stack base; do not treat every line as an unwind-validated frame.
   - Longer output does not mean that MEX added dump memory, repaired the dump, or proved that the native symbols are incorrect.
9. For every checkpoint, use: `Observation`, `Evidence`, `Interpretation`, `Confidence`, `Does not prove`, and `Next checkpoint`.
10. Teach only how Prompt + MCP obtains the same runtime evidence as the manual steps. Do not analyze the Log Writer state or provide a Lab 1 root cause. Redirect diagnostic requests to `agent_lab1`.

Finally, provide a "Manual Steps vs. Prompt + MCP Steps" comparison covering at least session verification, both `.load` commands, `.chain`, `!us logwriter`, thread selection, `k`, and `!mex.t -raw`.

For the validated `SQLDump0016.mdmp`, the historical baseline is MEX `3.1.0.243`, WinDbgCs `3.2.7`, and one thread returned by `!us logwriter` containing `SQLServerLogMgr::LogWriter`. Use these values only for comparison; the current runtime output must prove them again. If the current results differ, report the differences rather than forcing the historical values into the output.
