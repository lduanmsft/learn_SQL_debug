# Workshop directory layout

The repository contains documentation and automation. Large or internal assets remain under `C:\tools` or the external lab-artifact directory.

## Git repository

```text
C:\Users\lduan\learn_SQL_debug\
├── .github\                         # Copilot Skill (added in a later phase)
├── workshop\
│   ├── 00-environment-setup.md      # Ordered learner setup guide
│   ├── setup\
│   │   ├── steps\                   # Numbered setup and verification scripts
│   │   ├── Prepare-WinDbgWorkshop.ps1
│   │   ├── dscript-sources.json
│   │   └── tool-assets-manifest.json
│   └── lab-01-wait-logbuffer\       # Lab 1 content and SQL reproduction scripts
└── .gitignore
```

## Local tools

```text
C:\tools\
├── WinDbgCs.3.2.7.nupkg             # Original local NuGet source package
├── mex\
│   └── mex.dll                      # Approved MEX source copy
├── dscript\
│   ├── SQL2016\                     # Complete SQL Server 2016 script set
│   ├── SQL2017\                     # Add only when approved assets are available
│   ├── SQL2019\
│   ├── SQL2022\
│   └── SQL2025\
└── SqlDebugWorkshop\                # Staged, verified workshop files
    ├── WinDbg\
    │   └── windbgSlowRing.appinstaller
    ├── extensions\
    │   └── mex.dll
    ├── dscript\
    │   └── SQL2016\
    └── inventory.json
```

## PackageManagement installation

```text
C:\Program Files\PackageManagement\NuGet\Packages\
└── WinDbgCs.3.2.7\
    ├── WinDbgCsExt.dll
    ├── CsDebugScript.Engine.dll
    ├── DbgEngManaged.dll
    └── ...
```

Do not manually move individual WinDbgCs dependencies. Load `WinDbgCsExt.dll` from the package directory so its adjacent dependencies remain discoverable.

## External Lab 1 artifact

```text
C:\Users\lduan\debug_workshop\log_writer\
└── wait_logbuffer\
    └── SQLDump0016.mdmp
```

The dump is identified by the Lab 1 artifact manifest but is not committed to Git.
