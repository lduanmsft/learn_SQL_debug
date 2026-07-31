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

## 4. 按顺序安装

### Step 1：连接 VPN 并检查源文件

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

### Step 2：准备并计算 Workshop 文件哈希

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

### Step 3：安装 WinDbg Slow Ring

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

### Step 4：安装 WinDbgCs

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

### Step 5：配置 Symbol 和 Source Server

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

### Step 6：验证完整环境

运行：

```powershell
.\workshop\setup\steps\04-Test-Installation.ps1
```

必须确认所有检查项均为 `True`：

- WinDbg package 和版本。
- Staged app installer。
- MEX。
- WinDbgCs extension。
- SQL2016 dscript。
- Staged `srcsrv.default.ini`。
- 用户级 `SRCSRV_INI_FILE`。
- Asset inventory。

### Step 7：打开 Dump

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
.reload /f
```

不要把多个 debugger 命令拼接到 `.sympath` 参数后面，否则后续文本可能被错误地当作 symbol path。

### Step 8：加载 MEX

在 WinDbg command window 中运行：

```text
.load C:\tools\SqlDebugWorkshop\extensions\mex.dll
```

已验证的成功输出包含：

```text
Mex 3.1.0.243 Loaded!
```

### Step 9：加载 WinDbgCs

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

### Step 10：确认扩展链

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
- [ ] 使用与 dump 中 SQL Server build 匹配的 dscript。
- [ ] Dump、internal binary、INI 和 dscript 未提交到公开 GitHub。
