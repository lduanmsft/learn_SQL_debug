# Copilot Agents 与 Skills

本目录把环境准备和 Lab 1 dump 调查分成两个独立 Agent/Skill，避免 Setup Agent 自动携带 stack/source/root-cause 调查上下文。

```text
.github\
├── agents\
│   ├── sql-server-windbg-instructor.agent.md
│   └── agent_lab1.agent.md
├── prompts\
│   └── windbg-mcp-logwriter-demo.prompt.md
└── skills\
    ├── sql-server-windbg-workshop\
    │   ├── SKILL.md
    │   └── references\
    │       ├── environment-readiness.md
    │       ├── runtime-tutorial.md
    │       └── validated-runtime-baseline.md
    └── sql-server-windbg-lab1\
        ├── SKILL.md
        └── references\
            ├── dump-investigation.md
            ├── evidence-contract.md
            └── teaching-modes.md
```

## SQL Server WinDbg Instructor

这是 Setup-only Agent，负责：

- 检查 WinDbg、symbols、source server、MEX、WinDbgCs 和 dscript 准备状态。
- 要求学员先在 WinDbg 打开目标 dump。
- 列出并连接包含该 dump 的准确 WinDbg MCP session。
- 教学配置/验证 symbols，并分别执行 `.sympath` 和必要的 `.reload /f`。
- 教学使用 `.logopen`、`.logfile` 和 `.logclose` 记录私有 WinDbg command log。
- 分别执行 MEX `.load`、WinDbgCs `.load` 和 `.chain`。
- 通过 `!mex.help` 教学当前版本的 MEX command discovery。
- 先教学手工执行 `!us logwriter`、thread selection、`k` 和 `!mex.t -raw`，再使用 Prompt + WinDbg MCP 自动复现相同 runtime evidence。
- 教学 WinDbgCs `!execute` 以及经过 SQL Server build gate 的 dscript 初始化。
- 只在 `.chain` 显示两个准确路径后报告扩展已 runtime-loaded。

它不分析 Lab 1 stack、不关联 SQL Server source，也不输出 root cause。

对应 Skill：`/sql-server-windbg-workshop`。

## `agent_lab1`

这是 Lab 1-only Agent，负责：

- Guided、Challenge、Escalation 和 evidence review。
- 验证 dump hash、dump 限制、SQL Server exact build 和 symbol state。
- 调查 `LOGBUFFER` waiting workers 与 Log Writer/system-thread stacks。
- 在 build 和 stack 确认后关联准确的 SQL Server 2016 source branch。
- 维护 evidence ledger，并区分 `Proven`、`Likely`、`Possible`、`Unknown`。

它首先检查 `.sympath` 和 `.chain`。如果 Setup 未完成，它会停止 Lab 1 分析并引导学员切换到 **SQL Server WinDbg Instructor**，而不是自行安装或加载 DLL。

对应 Skill：`/sql-server-windbg-lab1`。

## 推荐使用顺序

1. 在 Agent picker 中选择 **SQL Server WinDbg Instructor**。
2. 输入：`验证环境并加载 MEX 和 WinDbgCs`。
3. 完成手工 stack 步骤后，从 Chat `/` 菜单运行 **WinDbg MCP Log Writer Demo**，观察 Prompt 如何通过 MCP 自动复现同一组检查点。
4. 对照手工输出与 Prompt + MCP 输出，确认 session、extension chain、thread 和两种 stack view 一致。
5. Setup 完成后，切换到 **agent_lab1**。
6. 输入：`用 Guided 模式开始 Lab 1 preflight`。

## 设计原则

- Workshop 文档说明“学什么”。
- Skill 定义“必须怎样执行和验证”。
- Agent 定义“怎样与学员交互和教学”。
- Setup 和 Lab 1 分开，避免工具权限与上下文混用。

## 重新加载

新建或修改 `.agent.md` / `SKILL.md` 后，如果 Agent picker 或 slash command 没有立即出现：

1. 确认文件已保存。
2. 执行 VS Code **Developer: Reload Window**。
3. 重新打开 workspace。
4. 检查 Problems 面板是否有 frontmatter 诊断。
