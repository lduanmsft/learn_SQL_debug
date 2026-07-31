# Lab 01 — Investigating `LOGBUFFER` waits with a SQL Server dump

## Scenario

A SQL Server 2016 workload uses local data files and a transaction log hosted in Azure Blob Storage. After storage connectivity is degraded, many sessions become suspended with `LOGBUFFER` waits. A dump captured during the incident is available for offline WinDbg analysis.

This lab separates two activities:

1. **Local reproduction** — generate log-intensive concurrent transactions and observe the live SQL Server state.
2. **Dump investigation** — use WinDbg MCP to examine the supplied dump and build an evidence-backed explanation.

> Safety: run the reproduction only in an isolated lab instance. It creates hundreds of tables, starts 400 unbounded update loops, and intentionally disrupts storage connectivity. Never use a production or shared SQL Server.

## Audience and modes

- **Guided:** SQL Server knowledge, little or no WinDbg experience.
- **Challenge:** prior WinDbg experience; complete the checkpoints with minimal hints.
- **Escalation:** produce a support-style evidence ledger and distinguish proven facts from hypotheses.

## Learning objectives

After completing the lab, the learner should be able to:

- Explain at a high level why transaction log buffers must be made available to concurrent transactions.
- Recognize a system-wide accumulation of `LOGBUFFER` waits.
- Capture the SQL Server version, dump context, symbol state, relevant threads, and stacks before forming a conclusion.
- Identify candidate Log Writer and waiting worker call paths in a dump.
- Separate debugger observations, source-code evidence, inference, and unknowns.
- State what a static dump can and cannot prove about an earlier I/O slowdown.

## Repository layout

| Path | Purpose |
|---|---|
| `scripts/00-prerequisites.sql` | Validate instance and SQLCMD inputs before creating anything. |
| `scripts/01-create-database.sql` | Create the scoped credential and URL-log database. |
| `scripts/02-create-workload.sql` | Create seed tables and the unbounded update procedure. |
| `scripts/03-observe.sql` | Observe waiting sessions without using deprecated `sys.sysprocesses`. |
| `scripts/run-ostress.cmd` | Start concurrent `ostress` sessions. |
| `scripts/04-cleanup.sql` | Optional cleanup after all workload processes are stopped. |
| `artifact-manifest.json` | Identifies the supplied dump without checking it into Git. |
| `evidence-ledger.md` | Worksheet for the dump investigation. |

## Prerequisites

- Complete the shared [workshop debugger environment setup](../00-environment-setup.md).
- Windows lab machine with SQL Server 2016 instance `SQL2016` or an explicitly substituted instance.
- A disposable Azure Blob container supported by the SQL Server version and configuration used in the lab.
- A freshly generated container SAS with only the permissions required by the lab.
- RML Utilities with `ostress.exe` available.
- WinDbg with the WinDbg MCP proxy enabled.
- Access to matching SQL Server symbols; source access is optional but required for source-level validation.

## Secret handling

Do not store the SAS in this repository. Supply it only in a local, unsaved SQLCMD session or through another approved secret-delivery mechanism. The `SasToken` value must omit the leading `?`.

The SAS included in the original historical reproduction notes is deliberately not retained here. It should be treated as exposed and rotated if it is still valid.

## Part A — Local reproduction

### A1. Review and set SQLCMD variables

Open the scripts in SQLCMD mode. Review all defaults before execution, especially:

- `BlobContainerUrl`
- `SasToken`
- `DataDirectory`
- `DatabaseName`
- SQL Server instance supplied to `run-ostress.cmd`

### A2. Validate prerequisites

Run `scripts/00-prerequisites.sql`. Continue only when the version, paths, and SQLCMD substitutions are correct.

### A3. Create the database

Run `scripts/01-create-database.sql` from `master`. It creates eight local data files and one URL-based transaction log file.

**Checkpoint A:** Record the SQL Server build, database state, recovery model, and physical location of every file.

<details>
<summary>Hint</summary>

Query `SERVERPROPERTY`, `sys.databases`, and `sys.master_files`. Verify that the transaction log is remote and the data files are local; do not assume the script completed exactly as intended.

</details>

### A4. Create the workload

Run `scripts/02-create-workload.sql`. It creates `Table100`, copies it into `Table51` through `Table549`, and creates `dbo.test_insert`.

The procedure chooses a table from the executing session's SPID. The supplied 400-session workload therefore assumes the assigned SPIDs remain in the generated table range. The observation script exposes mapping failures if that assumption is violated.

### A5. Start concurrency

From a dedicated command prompt, run:

`run-ostress.cmd <server\instance> <database> [path-to-ostress.exe]`

The default third argument is `C:\tools\RMLUtils\ostress.exe`. The workload loops indefinitely; stop the `ostress` process manually after collecting the lab evidence.

### A6. Observe the healthy baseline

Run `scripts/03-observe.sql` before introducing the fault. Record:

- Number of active workload sessions.
- Current waits and cumulative wait duration.
- Database file configuration.
- Any workload errors.

### A7. Introduce the fault

After the workload has run for several minutes, reproduce the historical network interruption by disconnecting the VPN or otherwise isolating the Blob endpoint **only on the disposable lab host**.

The exact effect depends on DNS, route, TCP retry, storage, SQL Server build, and authentication state. Therefore, network disconnection is a fault injection, not proof that a specific wait or root cause must occur.

### A8. Observe the degraded state

Run `scripts/03-observe.sql` again and capture the results. The historical reproduction showed many suspended sessions with `LOGBUFFER`; the screenshot is context, not a substitute for current evidence.

**Checkpoint B:** Explain the difference between:

- The injected connectivity fault.
- The observed SQL Server waits.
- The still-unproven internal causal chain.

<details>
<summary>Expected reasoning</summary>

The network action is known because the learner performed it. The waits are known only if the live diagnostic query records them. Connecting the two through Log Writer internals still requires debugger, source, and/or additional I/O evidence. A wait name alone does not prove the exact blocked function or failed operation.

</details>

## Part B — Dump investigation with WinDbg MCP

Artifact: `C:\Users\lduan\debug_workshop\log_writer\wait_logbuffer\SQLDump0016.mdmp`

### B1. Open and connect

1. Open the dump in WinDbg manually.
2. Wait for initial dump loading to complete.
3. Ask the workshop skill to list WinDbg sessions and connect to this dump session.
4. Preserve the initial debugger context; do not start by changing thread or frame globally without recording it.

### B2. Preflight

Collect and record:

- Dump type and capture reason, if available.
- Exception/current context.
- Exact `sqlservr.exe` version.
- Loaded `sqlservr` module information.
- Symbol status.
- Process uptime or dump timestamp when available.

If symbols or source do not load, inspect the WinDbg application logs first. Do not infer that a PDB is absent merely from an unresolved stack.

**Checkpoint C:** Is the available dump sufficient for all intended object inspection? List any limitations caused by dump type, missing pages, symbols, or source.

### B3. Establish the thread landscape

Without assuming which thread is causal:

1. Enumerate threads and stacks.
2. Group stacks by common signatures.
3. Identify candidate waiting workers.
4. Identify candidate Log Writer, I/O completion, and other relevant system threads.
5. Record thread IDs and complete stack evidence in the ledger.

<details>
<summary>Guided hint</summary>

Start broad. Thread grouping is safer than searching for one expected function because symbol quality and implementation details vary by build. A familiar function name is a lead, not a conclusion.

</details>

### B4. Analyze waiting workers

For representative waiting workers:

- Record the debugger thread and stack.
- Resolve SQL Server task/session metadata only where the dump contains sufficient data.
- Identify the frame where execution yields or waits.
- Compare multiple workers to avoid overgeneralizing from one stack.

**Checkpoint D:** What is directly proven about the suspended workers? What remains inferred from the live screenshot or reproduction notes?

### B5. Analyze the Log Writer path

For each candidate Log Writer thread:

- Capture the complete stack.
- Identify the lowest reliable SQL Server frames.
- Check relevant parameters or objects only when symbols and memory are available.
- Correlate the frames with the exact SQL Server branch/source version.
- Document whether the thread is executing, waiting, or in completion processing at the instant of capture.

**Checkpoint E:** Does the dump prove slow Blob I/O, a pending completion, a retry path, or only a state consistent with one of these? Use precise confidence language.

### B6. Source validation

For every source-backed claim:

1. Match the dump build to the correct SQL Server source branch.
2. Search to locate candidate code.
3. Read the file from the correct branch to verify it; do not trust a shared-index search result alone.
4. Record function, file, branch, and the relevant condition or transition.
5. Explain how the source connects to the observed stack without claiming that an unobserved branch executed.

### B7. Conclusion

Complete `evidence-ledger.md`, then provide:

- Symptom.
- Scope and impact visible in the supplied evidence.
- Proven observations.
- Most likely causal explanation and confidence.
- Alternative hypotheses not eliminated.
- Missing evidence.
- Immediate mitigation used by the lab.
- Safer long-term design or operational recommendations.

## Success criteria

The lab is complete only when:

- The conclusion cites at least one waiting-worker stack and one relevant system-thread stack.
- SQL Server version and symbol quality are documented.
- Every material claim is labelled `Proven`, `Likely`, `Possible`, or `Unknown`.
- Static dump limitations are explicitly stated.
- No secret is committed to Git.

## Cleanup

1. Stop all `ostress.exe` processes.
2. Restore network connectivity and verify the Blob endpoint is reachable.
3. Allow SQL Server recovery/cleanup to settle and retain any desired evidence.
4. Run `scripts/04-cleanup.sql` only when the database is no longer needed.
5. Remove or rotate the lab SAS according to the lab environment's security process.
