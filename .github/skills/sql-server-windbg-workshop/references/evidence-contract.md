# Evidence contract

Every material conclusion must be traceable.

## Evidence classes

- **Debugger observation** — exact captured state shown by a reproducible WinDbg command.
- **Environment observation** — verified local file, package, hash, environment variable, or version.
- **Source evidence** — code read from the exact product branch/build family.
- **Interpretation** — reasoning that connects observations; never present it as raw evidence.
- **Unknown** — a fact not recoverable from the current dump or available sources.

## Confidence labels

- `Proven`: directly shown by the cited evidence.
- `Likely`: best explanation supported by multiple observations, with a stated gap.
- `Possible`: consistent with evidence but weakly distinguished from alternatives.
- `Unknown`: insufficient evidence.

## Required row fields

For each important finding record:

- ID.
- Observation.
- Command/thread/frame/object or local verification method.
- Source branch/file when applicable.
- Interpretation.
- Confidence.
- What the evidence does not prove.
- Next validation.

## Prohibited reasoning

- Wait name alone equals root cause.
- Function name alone proves the executed branch.
- Source code proves that a historical event occurred.
- Static dump reconstructs events not retained in memory.
- One worker stack represents every worker without comparison.
- Search-index output is accepted as branch-exact source without reading the branch file.
