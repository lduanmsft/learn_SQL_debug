---
name: 'WinDbg MCP Log Writer Demo'
description: '使用 Prompt + WinDbg MCP 自动复现手工加载并验证 MEX/WinDbgCs、查找 Log Writer thread，以及比较 native k 与 !mex.t -raw 的教学演示。'
argument-hint: '可选：提供目标 SQL Server dump 文件名或完整路径'
agent: 'SQL Server WinDbg Instructor'
---

使用 WinDbg MCP 在目标 SQL Server dump session 中完成一次 Log Writer stack 教学演示，自动复现学员刚刚手工完成的步骤。

即使前一轮 Chat 已经成功，也必须在当前 session 中重新执行并收集证据。不得复用之前的 PID、thread ID、extension state 或 stack 输出。严格保持以下顺序，不得重排或合并 debugger commands。

1. 列出 WinDbg sessions，根据 window title 和 output history 连接并验证目标 SQL Server dump session；不要选择无关 session。
2. 每次 WinDbg MCP execution 只执行一条 debugger command。
3. 分别加载：
   - `C:\tools\SqlDebugWorkshop\extensions\mex.dll`
   - `C:\Program Files\PackageManagement\NuGet\Packages\WinDbgCs.3.2.7\WinDbgCsExt.dll`
4. 单独执行 `.chain`，只有在输出显示两个精确路径后，才报告 MEX 和 WinDbgCs 已 runtime-loaded。
5. 单独执行 `!us logwriter`，记录当前 runtime 返回的 Log Writer debugger thread ID。不要使用无过滤条件的 `!mex.us`。
6. 使用该次 `!us logwriter` 实际返回的 thread ID/link 切换到 Log Writer thread，不要使用示例中的固定 thread ID。
7. 在同一 thread 上分别单独执行 native `k` 和 `!mex.t -raw`。
8. 对比两份实际输出：
   - `k` 是基于当前 debugger thread/register context 和 WinDbg unwind metadata 得到的 native call chain。
   - `!mex.t -raw` 从 stack pointer 到 stack base 展示可符号化的潜在 code pointers；不得把每一行都当作经过 unwind 验证的 frame。
   - 输出更长不表示 MEX 添加了 dump memory、修复了 dump，或证明 native symbols 错误。
9. 对每个 checkpoint 使用：`Observation`、`Evidence`、`Interpretation`、`Confidence`、`Does not prove`、`Next checkpoint`。
10. 只教学 Prompt + MCP 如何得到与手工步骤相同的 runtime evidence；不要分析 Log Writer 状态或给出 Lab 1 root cause。诊断请求转交 `agent_lab1`。

最后提供“手工步骤与 Prompt + MCP 步骤对照”，至少覆盖 session verification、两个 `.load`、`.chain`、`!us logwriter`、thread selection、`k` 和 `!mex.t -raw`。

对于已验证的 `SQLDump0016.mdmp`，历史基线是 MEX `3.1.0.243`、WinDbgCs `3.2.7`，并且 `!us logwriter` 返回一个包含 `SQLServerLogMgr::LogWriter` 的 thread。它们仅用于比较；必须由本次 runtime 输出重新证明。若本次结果不同，报告差异，不要强行输出历史值。
