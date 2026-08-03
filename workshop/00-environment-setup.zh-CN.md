# Workshop 环境配置

本 Workshop 使用 Microsoft 内部 WinDbg Slow Ring，以及用于 SQL Server 调试的 MEX、WinDbgCs 和版本匹配的 dscript。内部二进制与配置文件不会提交到公开 GitHub 仓库。

英文版参见 [Workshop environment setup](./00-environment-setup.md)。

## 1. 目标目录

详细目录说明参见 [目录结构](./setup/DIRECTORY-LAYOUT.md)。标准本地目录如下：

```text
C:\tools\
├── WinDbgCs.3.2.7.nupkg
├── mex\
│   └── mex.dll
├── dscript\
│   ├── SQL2016\
│   ├── SQL2017\
│   ├── SQL2019\
│   ├── SQL2022\
│   └── SQL2025\
└── SqlDebugWorkshop\
    ├── WinDbg\
    │   └── windbgSlowRing.appinstaller
    ├── extensions\
    │   └── mex.dll
    ├── source-server\
    │   └── srcsrv.default.ini
    ├── dscript\
    │   └── SQL2016\
    └── inventory.json
```

WinDbgCs 安装后的目录为：

```text
C:\Program Files\PackageManagement\NuGet\Packages\WinDbgCs.3.2.7\
```

Lab 1 dump 保存在 Git 仓库之外：

```text
C:\Users\lduan\debug_workshop\log_writer\wait_logbuffer\SQLDump0016.mdmp
```

## 2. 所需组件

| 组件 | 要求 | 默认位置 |
|---|---|---|
| WinDbg installer | `windbgSlowRing.appinstaller` | `C:\tools\SqlDebugWorkshop\WinDbg\` |
| WinDbg package | `Microsoft.WinDbg.Slow` | Windows AppX package |
| WinDbg version | `1.2606.22001.1` | Windows AppX package |
| MEX | `mex.dll`，已验证版本 `3.1.0.243` | `C:\tools\SqlDebugWorkshop\extensions\` |
| WinDbgCs | Package ID `WinDbgCs`，版本 `3.2.7` | `C:\tools\WinDbgCs.3.2.7.nupkg` |
| Source Server INI | `srcsrv.default.ini` | `C:\SRC\srcsrv.default.ini` |
| Symbol cache | SQL/Windows symbols | `C:\symbol` |
| dscript | 必须与 SQL Server 版本匹配 | `C:\tools\SqlDebugWorkshop\dscript\<version>\` |

WinDbg installer 的 Microsoft 内部来源为：

```text
\\sesdfs\1Windows\TestContent\ES\dbg\dbgx\windbgSlowRing.appinstaller
```

访问该路径前必须连接 Microsoft corporate VPN，并具有对应共享目录权限。

## 3. 安全要求

以下内容不得提交到公开 GitHub：

- `.appinstaller`、`.msix`、`.msixbundle`。
- `mex.dll` 和其他内部 debugger binary。
- `WinDbgCs.3.2.7.nupkg`。
- `srcsrv.default.ini`，因为其中包含 Microsoft 内部 source server 配置。
- SQL Server private symbols、dscript 和其他 source-derived assets。
- Dump、TTD trace、credential、token 或 SAS。

公开 GitHub 只保存安装脚本、验证逻辑、目录说明和不包含敏感内容的 manifest。

# 阶段一：准备 Workshop 环境

按以下顺序准备本地 assets、安装 debugger components，并验证 symbols/source 配置。阶段一完成只代表文件和配置已就绪，不代表 extension 已在某个 WinDbg session 中 runtime-loaded。

## Step 1：连接 VPN 并启动 SQL Server WinDbg Instructor Agent

1. 连接 Microsoft corporate VPN，并确认当前账户具有内部共享目录权限。
2. 在 VS Code Chat 的 Agent picker 中选择 **SQL Server WinDbg Instructor**。
3. 输入：`验证 Workshop 环境并按顺序指导我完成 Setup`。
4. 按 Chat 中显示的 checkpoint 逐步完成检查。需要安装软件、staging assets 或修改持久配置时，请先确认再继续。

环境检查会在仓库根目录运行以下 source-assets 脚本：

在仓库根目录运行：

```powershell
.\workshop\setup\steps\01-Test-SourceAssets.ps1
```

脚本检查：

- 内部 WinDbg installer 是否可访问。
- `C:\tools\mex\mex.dll` 是否存在。
- `C:\tools\WinDbgCs.3.2.7.nupkg` 是否存在。
- `C:\tools\dscript` 下有哪些 SQL Server 版本。
- Lab 1 所需的 SQL2016 dscript 是否存在。

任何必需文件缺失时，不要继续下一步。

## Step 2：准备并计算 Workshop 文件哈希

运行：

```powershell
.\workshop\setup\steps\02-Stage-WorkshopAssets.ps1
```

该步骤会：

1. 从内部共享复制 `windbgSlowRing.appinstaller` 到 `C:\tools\SqlDebugWorkshop\WinDbg\`。
2. 验证 package name 为 `Microsoft.WinDbg.Slow`。
3. 验证 package version 为 `1.2606.22001.1`。
4. 将 MEX 复制到 `C:\tools\SqlDebugWorkshop\extensions\mex.dll`。
5. 检查 WinDbgCs `.nupkg` 中的 `.nuspec`。
6. 将 `C:\SRC\srcsrv.default.ini` 复制到私有 staged 目录。
7. 复制 manifest 中配置的版本化 dscript 目录。
8. 生成 `C:\tools\SqlDebugWorkshop\inventory.json`。

## Step 3：安装 WinDbg Slow Ring

打开：

```text
C:\tools\SqlDebugWorkshop\WinDbg\windbgSlowRing.appinstaller
```

在 App Installer UI 中完成安装，然后确认：

```text
Package: Microsoft.WinDbg.Slow
Version: 1.2606.22001.1
```

可以使用 PowerShell 验证：

```powershell
Get-AppxPackage -Name Microsoft.WinDbg.Slow |
    Select-Object Name, Version, InstallLocation
```

## Step 4：安装 WinDbgCs

建议使用封装脚本：

```powershell
.\workshop\setup\steps\03-Install-WinDbgCs.ps1
```

实际 package ID 是 `WinDbgCs`，不是 `WinDbgCs.amd64`。等效安装命令为：

```powershell
Install-Package WinDbgCs `
    -RequiredVersion 3.2.7 `
    -Source C:\tools `
    -ProviderName NuGet
```

`Install-Package` 成功后可能不输出任何内容。使用以下命令确认：

```powershell
Get-Package -Name WinDbgCs `
    -RequiredVersion 3.2.7 `
    -ProviderName NuGet
```

确认以下文件存在：

```text
C:\Program Files\PackageManagement\NuGet\Packages\WinDbgCs.3.2.7\WinDbgCsExt.dll
```

如果原 PowerShell 一直没有返回提示符，但 `Get-Package` 已显示 Installed，可以按 `Ctrl+C` 终止仍在等待的调用；不要立即重复安装。

## Step 5：配置 Symbol 和 Source Server

运行：

```powershell
.\workshop\setup\steps\05-Configure-SymbolsAndSource.ps1
```

该脚本为当前 Windows 用户配置：

```text
_NT_SYMBOL_PATH=cache*C:\symbol;srv*https://symweb.azurefd.net
SRCSRV_INI_FILE=C:\SRC\srcsrv.default.ini
```

如果 `C:\SRC\srcsrv.default.ini` 不存在，但私有离线包中存在：

```text
C:\tools\SqlDebugWorkshop\source-server\srcsrv.default.ini
```

脚本会先创建 `C:\SRC`，再复制 INI 文件。

配置完成后必须关闭并重新启动 WinDbg，新启动的 WinDbg process 才会继承环境变量。

验证环境变量：

```powershell
[Environment]::GetEnvironmentVariable('_NT_SYMBOL_PATH', 'User')
[Environment]::GetEnvironmentVariable('SRCSRV_INI_FILE', 'User')
```

不要在未经批准时修改 Machine scope，以免影响机器上的其他用户。

## Step 6：验证完整环境

在 Chat 中输入：

```text
运行完整环境验证并逐项解释结果
```

检查过程中实际运行的验证脚本是：

```powershell
.\workshop\setup\steps\04-Test-Installation.ps1
```

如果 Chat 无法执行本地命令，请在仓库根目录手工运行同一脚本，再把完整输出粘贴到 Chat 中进行解释；验证标准不变。

必须确认所有检查项均为 `True`：

- WinDbg package 和版本。
- Staged app installer。
- MEX。
- WinDbgCs extension。
- SQL2016 dscript。
- Staged `srcsrv.default.ini`。
- 用户级 `SRCSRV_INI_FILE`。
- Asset inventory。

检查结果会按 `Observation`、`Evidence`、`Interpretation`、`Confidence`、`Does not prove` 和 `Next checkpoint` 展示。脚本通过只证明本地 prerequisites 已准备好，不证明 dump 已打开、MCP 已连接或 extensions 已 runtime-loaded；这些事实将在阶段二重新验证。

# 阶段二：打开 Dump 并连接 WinDbg MCP

阶段一只证明本地文件、package 和环境变量已经准备好；阶段二才证明目标 dump 已在 WinDbg 中打开、MCP 已连接到准确 session，并且 extension 已在该 runtime 中加载。每个 debugger command 必须单独执行，不能把相邻命令合并为一次 MCP execution。

阅读每个 checkpoint 时，请关注：

- `Observation`：本次实际观察到什么。
- `Evidence`：支持观察结果的 runtime 输出。
- `Interpretation`：该证据能够说明什么。
- `Confidence`：对当前结论的置信度。
- `Does not prove`：该证据不能证明什么。
- `Next checkpoint`：下一条要执行的检查。

## Step 7：打开目标 Dump 并连接准确 Session

在 WinDbg 中打开：

```text
C:\Users\lduan\debug_workshop\log_writer\wait_logbuffer\SQLDump0016.mdmp
```

等待 dump 和初始 symbols 加载完成。

接下来必须先通过 WinDbg MCP 完成 runtime gate：

1. 列出当前可用的 WinDbg sessions。
2. 根据 window title 选择打开了上述 Lab 1 dump 的 session。
3. 连接该 session。
4. 读取 debugger output history，确认历史中显示的 dump 路径与目标 dump 一致。

在 WinDbg MCP 成功连接并确认目标 dump 之前，只能把 MEX/WinDbgCs 记为“文件已存在”；不能报告扩展已经加载。

如果没有匹配 session，停止并要求学员在 WinDbg 中手工打开 dump；不得连接无关 session。PID 和 MCP pipe 每次启动都可能变化，不能使用历史 PID 选择 session。

## Step 8：检查 Dump Capture Structure

连接准确 session 后，单独执行：

```text
.dumpdebug
```

教学时说明：

- `MINIDUMP_HEADER`：signature、format version、stream count、directory、timestamp 和 capture flags。
- `MINIDUMP_TYPE`/flags：dump 创建时请求的 capture options；不能保证每个目标地址都可读。
- `ThreadListStream`：记录的 thread ID、context 和 stack descriptor；存在 thread record 不等于整个 stack 都能 unwind。
- `ThreadInfoListStream`：额外 thread metadata，不是 call stack。
- `MemoryListStream`/`Memory64ListStream`：实际保存字节的 virtual-memory ranges。
- `MiniDumpWithFullMemoryInfo` 描述 memory map metadata，不等同于 `MiniDumpWithFullMemory`。
- `ModuleListStream` 与 `UnloadedModuleListStream`：module metadata；module 存在不等于 symbols 已成功加载。
- `ExceptionStream`：存在时描述 dump-triggering thread 的 exception/context，不代表所有 threads。

这里只解释 dump capture structure，不分析 Log Writer 状态，也不推断 Lab 1 root cause。

## Step 9：检查 Symbols

连接完成后，使用 `.sympath` 作为一次独立的 WinDbg MCP 命令检查当前 session 的 symbol path。已经验证过的 WinDbg session path 为：

```text
srv*C:\symbol*https://symweb.azurefd.net;cache*C:\symbol;srv*https://symweb.azurefd.net
```

环境变量中保存的简化路径为：

```text
cache*C:\symbol;srv*https://symweb.azurefd.net
```

如需在当前 WinDbg session 中显式设置已验证路径，可运行：

```text
.sympath srv*C:\symbol*https://symweb.azurefd.net;cache*C:\symbol;srv*https://symweb.azurefd.net
```

需要强制 reload 时，再单独执行：

```text
.reload /f
```

不要把多个 debugger 命令拼接到 `.sympath` 参数后面，否则后续文本可能被错误地当作 symbol path。

## Step 10：打开私有 WinDbg Command Log（教学时建议）

使用本机私有目录，不要把 dump command output 写入公开仓库。分别执行：

```text
.logopen /t C:\temp\windbg-workshop.txt
```

```text
.logfile
```

课程结束时单独执行：

```text
.logclose
```

`.logopen` 是 WinDbg native command，不要与 WinDbgCs 中名称相似的 logging API 混淆。如果目标文件已存在，不要静默覆盖证据。

## Step 11：加载 MEX

在 WinDbg command window 中运行：

```text
.load C:\tools\SqlDebugWorkshop\extensions\mex.dll
```

已验证的成功输出包含：

```text
Mex 3.1.0.243 Loaded!
```

`.load` 没有报错仍不足以单独证明 extension 已加载；后续必须用 `.chain` 验证准确路径。

## Step 12：加载 WinDbgCs

运行：

```text
.load C:\Program Files\PackageManagement\NuGet\Packages\WinDbgCs.3.2.7\WinDbgCsExt.dll
```

已验证的成功输出包含：

```text
WinDbgCs: C# scripting for WinDbg
NuGet Version: 3.2.7
```

不要只复制 `WinDbgCsExt.dll`。它依赖同一 package 目录下的其他 DLL，因此应从 PackageManagement 安装目录加载。

## Step 13：确认 Extension Chain

运行：

```text
.chain
```

输出中必须同时包含：

```text
C:\tools\SqlDebugWorkshop\extensions\mex.dll
C:\Program Files\PackageManagement\NuGet\Packages\WinDbgCs.3.2.7\WinDbgCsExt.dll
```

在 `.chain` 验证通过之前，不要依赖 MEX 或 WinDbgCs 的命令输出。

## Step 14：发现 MEX 命令并建立 Log Writer Stack 基线

完成 `.chain` 验证后，学员先逐条手工执行以下步骤。每个命令必须单独运行：

1. 执行 `!mex.help`，确认当前 MEX 版本实际提供的语法；不要根据其他版本猜测 command name。
2. 执行 `!us logwriter`，不要使用输出量很大的无过滤 `!mex.us`。
3. 记录本次输出返回的 debugger thread ID、selection link/command 和 `SQLServerLogMgr::LogWriter` frame。匹配只表示 candidate thread，不证明 root cause。
4. 记录切换前的 current debugger thread/context。
5. 仅使用本次输出返回的 thread link/ID 切换 thread；不得把示例 thread ID 固化到课程。如果目标 thread 已经是 current thread，则记录该事实，不做无意义切换。
6. 执行 native `k`，保存 WinDbg unwind call chain。
7. 确认 current debugger context 仍是同一个 runtime-returned thread。
8. 执行 `!mex.t -raw`，保存 MEX 从 stack pointer 到 stack base 的 raw scan。
9. 对比两者：`k` 使用当前 thread/register context、unwind metadata 和 symbols 重建 call chain；`!mex.t -raw` 扫描 stack pointer 到 stack base 之间可符号化的潜在 code pointers，其中不一定都是经过 unwind 验证的 frame。

`!mex.t -raw` 输出更长，不表示 MEX 添加了 dump memory、修复了 dump、或证明 native symbols 错误。本阶段只比较 presentation difference，不分析 root cause。

对于已验证的 `SQLDump0016.mdmp`，历史比较基线是一个匹配 thread，且 native stack 包含 `sqlmin!SQLServerLogMgr::LogWriter`。历史 debugger thread ID `21` 只能用于课后比较，不能用于下一次 thread selection。

## Step 15：确认 SQL Server Build 并发现 WinDbgCs Scripts

先单独执行：

```text
lmv m sqlservr
```

记录当前 dump 中 `sqlservr.exe` 的精确 build 和 file version，再选择版本匹配的 dscript。已验证 dump 的历史 baseline 是 SQL Server `13.0.5366.0`、file version `2015.131.5366.0`；当前输出始终具有更高优先级。

然后单独执行 bare command：

```text
!execute
```

保存当前 WinDbgCs runtime 返回的 scripts、help 和 DML links。只能使用本次输出实际公布的名称与语法，不要猜 script name，也不要把受保护的 `.js` 文件当普通 JavaScript 直接执行。

只有当 bare `!execute` 明确公布下列初始化 action，并且所需 scripts 尚未加载时，才单独执行：

```text
!execute ExternalScripts.Install ;
```

如果 scripts 已加载，则跳过安装。本阶段只学习 catalog/help；需要执行诊断 dscript 或解释 SQL Server 状态时，再切换到 **agent_lab1**。

## Step 16：Prompt + WinDbg MCP 自动复现

手工基线讲解完成后，再演示 Prompt 自动化，不能用 Prompt 代替学员理解前面的命令：

1. 在 Agent picker 中选择 **SQL Server WinDbg Instructor**。
2. 在 **Configure Tools** 中勾选完整的 `DbgX.Mcp.Proxy` 工具组，至少包括 `list_sessions`、`connect_session`、`show_output` 和 `get_output_history`。蓝色高亮不等于已勾选。
3. 从 Chat `/` 菜单或 **Chat: Run Prompt...** 运行 [WinDbg MCP Log Writer Demo](../.github/prompts/windbg-mcp-logwriter-demo.prompt.md)。
4. Prompt 必须重新验证当前 session，不能复用上一次 Chat 的 PID、thread ID 或 extension 状态。
5. Prompt 通过 MCP 按固定顺序分别执行：MEX `.load` → WinDbgCs `.load` → `.chain` → `!us logwriter` → 本次返回的 thread selection → `k` → `!mex.t -raw`。
6. 对照 Prompt 输出和手工基线，确认 target session、两个 extension path、Log Writer thread，以及两种 stack view 的证据一致。

“得到一样的结果”指相同的命令顺序、runtime gate、证据类型和输出结构，不是硬编码相同的动态数值。对于已验证的 `SQLDump0016.mdmp`，预期比较点是 MEX `3.1.0.243`、WinDbgCs `3.2.7`，以及一个包含 `SQLServerLogMgr::LogWriter` 的匹配 thread；每次演示仍必须由当前 runtime 重新证明。如果结果不同，应保留并解释差异，不得强行输出历史值。

### 手工步骤与 Prompt + MCP 证据对照

| 手工 checkpoint | Prompt + MCP checkpoint | 必需证据 |
|---|---|---|
| 识别 WinDbg window | 列出、连接并验证 session | 当前 dump path/title 和 active PID |
| 加载 MEX | 第一条独立 `.load` | 无 load error；随后由 `.chain` 证明 |
| 加载 WinDbgCs | 第二条独立 `.load` | 无 load error；随后由 `.chain` 证明 |
| 验证 extensions | 独立 `.chain` | 两个准确 DLL path 和 version |
| 查找 Log Writer | `!us logwriter` | 本次返回的 thread 和 `SQLServerLogMgr::LogWriter` frame |
| 选择 thread | 本次返回的 link/ID | current context 是匹配 thread |
| Native stack | 独立 `k` | WinDbg-unwound call chain |
| Raw stack scan | 独立 `!mex.t -raw` | 同一 thread 的 stack-pointer-to-base output |

## Step 17：完成环境验证并进入 Lab 1

1. 再次单独执行 `.chain`，确认两个准确 extension paths 仍存在。
2. 如果打开了 command log，执行 `.logfile` 确认状态，然后执行 `.logclose`。
3. 汇总本次 session 已证明的事实、仍未知的内容，以及与 validated baseline 的差异。
4. 确认 dump/session、symbols、两个 extensions、filtered Log Writer thread 和两种 stack view 均有当前 runtime evidence。
5. 环境验证通过后，在 Agent picker 中切换到 **agent_lab1**，继续 stack interpretation、source correlation 和 root-cause investigation。

# 参考附录

## 5. dscript 版本管理

不同 SQL Server 版本的 dscript 必须分开存放：

```text
C:\tools\SqlDebugWorkshop\dscript\SQL2016\
C:\tools\SqlDebugWorkshop\dscript\SQL2017\
C:\tools\SqlDebugWorkshop\dscript\SQL2019\
C:\tools\SqlDebugWorkshop\dscript\SQL2022\
C:\tools\SqlDebugWorkshop\dscript\SQL2025\
```

执行 dscript 前必须：

1. 使用 debugger 确认 `sqlservr.exe` 的精确 build。
2. 选择匹配的 SQL Server release。
3. 确认对应 dscript set 已完整复制并记录在 inventory 中。
4. 不要因为某个脚本名称相同，就跨 SQL Server 版本替代使用。

Lab 1 使用 SQL Server 2016，因此必须使用 SQL2016 dscript。

## 6. 私有离线包

当前私有离线包为：

```text
C:\tools\SqlDebugWorkshop-offline-bundle.zip
```

包内包含：

- Staged WinDbg installer。
- MEX。
- WinDbgCs `.nupkg`。
- `source-server\srcsrv.default.ini`。
- 已准备的版本化 dscript。
- SHA-256 inventory。

当前 bundle SHA-256：

```text
E96A0DCC04921A45CFC48393F18FC171868A80330B9CC106E0BAFA71F59EC02F
```

该离线包包含 Microsoft 内部资产，只能放入经过批准且有访问控制的内部文件共享或制品仓库，不能上传到当前公开 GitHub 仓库。

## 7. 最终检查清单

- [ ] 已连接 VPN 并可访问内部 WinDbg installer。
- [ ] WinDbg package 是 `Microsoft.WinDbg.Slow`。
- [ ] WinDbg version 是 `1.2606.22001.1`。
- [ ] `_NT_SYMBOL_PATH` 指向 `C:\symbol` 和内部 symbol server。
- [ ] `SRCSRV_INI_FILE=C:\SRC\srcsrv.default.ini`。
- [ ] MEX 版本 `3.1.0.243` 已成功加载。
- [ ] WinDbgCs 版本 `3.2.7` 已成功加载。
- [ ] `.chain` 同时显示 MEX 和 WinDbgCs。
- [ ] 已手工执行 `!us logwriter`、thread selection、`k` 和 `!mex.t -raw`。
- [ ] 已运行 **WinDbg MCP Log Writer Demo**，并与手工 baseline 逐项核对。
- [ ] 使用与 dump 中 SQL Server build 匹配的 dscript。
- [ ] Dump、internal binary、INI 和 dscript 未提交到公开 GitHub。
