# Copilot Agent 与 Skill

本目录把 Workshop 教学内容和自动化行为分开：

```text
.github\
├── agents\
│   └── sql-server-windbg-instructor.agent.md
└── skills\
    └── sql-server-windbg-workshop\
        ├── SKILL.md
        └── references\
            ├── environment-readiness.md
            ├── dump-investigation.md
            ├── evidence-contract.md
            └── teaching-modes.md
```

## Skill 的职责

`sql-server-windbg-workshop` 是可复用的操作流程，负责：

- 根据请求选择 Setup、Lab 1、Evidence Review 或 Teaching Mode。
- 读取 Workshop 中的中英文 setup 和 Lab 文档。
- 驱动 WinDbg MCP session discovery、history/log 检查和只读分析。
- 约束 symbol/source、MEX、WinDbgCs、dscript 和 source correlation 的验证步骤。
- 防止把静态 dump、函数名或源码可能路径错误地写成已证明根因。
- 规定 evidence ledger 和置信度标签。

可以在 Chat 中通过 `/sql-server-windbg-workshop` 显式调用，也可以由 Copilot 根据 description 自动加载。

## Agent 的职责

`SQL Server WinDbg Instructor` 是面向学员的角色，负责：

- Guided：逐步解释命令、输出和 checkpoint。
- Challenge：只给目标，让学员提出命令和假设。
- Escalation：维护 hypothesis/evidence ledger，输出 support-style 结论。
- 调用 WinDbg MCP 获取 debugger 事实。
- 在确认 SQL Server build 后使用 SQL2016 code source 做精确源码验证。

在 VS Code Chat 的 Agent picker 中选择 **SQL Server WinDbg Instructor**，然后输入例如：

- `用 Guided 模式开始 Lab 1 preflight`
- `检查我的 WinDbg workshop 环境`
- `帮我确认 symbol、source server、MEX 和 WinDbgCs 是否正确`
- `用 Escalation 模式分析 LOGBUFFER dump`
- `检查 evidence ledger 是否存在过度推断`

## 为什么 Agent 和 Skill 分开

- Workshop 文档说明“学什么”。
- Skill 定义“必须怎样调查和验证”。
- Agent 定义“怎样与学员交互和教学”。

以后增加 TTD、recovery、AG redo 或 latch Lab 时，应优先增加新的 Skill reference/Lab 文档，避免把所有专题堆进 Agent 文件。

## 重新加载

新建或修改 `.agent.md` / `SKILL.md` 后，如果 Agent picker 或 slash command 没有立即出现：

1. 确认文件已保存。
2. 执行 VS Code **Developer: Reload Window**。
3. 重新打开该 workspace。
4. 检查 Problems 面板是否有 frontmatter 诊断。
