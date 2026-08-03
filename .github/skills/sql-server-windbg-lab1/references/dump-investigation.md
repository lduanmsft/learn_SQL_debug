# Lab 1 dump investigation

## Phase 1 — Understand

Read the Lab 1 scenario and artifact manifest. Restate the symptom without asserting the root cause. The historical screenshot establishes observed `LOGBUFFER` waits, not the internal causal chain.

## Phase 2 — Preflight

1. Verify artifact path, size, and SHA-256.
2. List/connect to the correct WinDbg session.
3. Read existing debugger history.
4. Record dump type, truncation/missing-page warnings, capture context, current exception context, timestamp, uptime, and process uptime where available.
5. Record the exact SQL Server module version and symbol state.
6. Run `.sympath` separately and record it.
7. Run `.chain` separately and record MEX/WinDbgCs state.

If symbol or source behavior is unexpected, inspect WinDbg logs before changing configuration.

## Phase 3 — Thread landscape

1. Enumerate all threads/stacks without assuming the causal thread.
2. Group repeated stack signatures.
3. Select representative waiting workers.
4. Identify candidate Log Writer, I/O completion, and related system threads.
5. Record debugger thread IDs and complete relevant stacks.
6. Compare at least two workers before generalizing.

Do not claim that a candidate thread owns or blocks a resource unless the dump provides supporting object/task evidence.

## Phase 4 — Focused inspection

For each selected thread:

- Record the context before switching.
- Identify Windows, SQLOS, storage/log, and wait/yield frames where symbols support that classification.
- Inspect parameters or objects only when symbols and captured memory permit it.
- Record unreadable memory and truncated-dump limitations.

## Phase 5 — Source correlation

1. Match the SQL Server build to SQL2016.
2. Use code search only to locate candidate functions/files.
3. Read the candidate file from the exact SQL2016 branch.
4. Record the verified condition/transition and its limits.
5. Never convert a possible source branch into a claimed historical event without debugger evidence.

## Phase 6 — Conclusion

Produce:

- Symptom and visible impact.
- Proven debugger observations.
- Most likely explanation with confidence.
- Alternatives not eliminated.
- Static-dump limitations.
- Missing evidence and next validation.
- Mitigation/recommendations appropriate to the lab.

Write findings into the evidence ledger when the learner requests file output or is using Escalation mode.
