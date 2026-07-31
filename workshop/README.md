# SQL Server debugging workshops

This directory contains hands-on SQL Server debugging workshops driven through WinDbg MCP.

## Setup

- [Prepare WinDbg Slow Ring, MEX, WinDbgCs, and versioned dscript assets](./00-environment-setup.md)
- [中文：配置 WinDbg、Symbol、Source Server、MEX 和 WinDbgCs](./00-environment-setup.zh-CN.md)

## Labs

- [Lab 01 — Investigating `LOGBUFFER` waits with a SQL Server dump](./lab-01-wait-logbuffer/README.md)

Large dump and TTD artifacts are stored outside Git and identified by per-lab manifests. Credentials, SAS tokens, customer data, and debugger outputs containing sensitive data must not be committed.
