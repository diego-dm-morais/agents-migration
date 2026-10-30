# Source parity: characterization and golden workflow

Read this when a task captures output from the source, writes a golden test, or compares target output with source output.

## 1. Capture (kind `capture`)

1. Check the pin first. Run `sh .claude/skills/migrate/scripts/check.sh pin`. If the output is not `pin OK`, stop and report (migration-conduct section 11).
2. Run the source only from a copy outside the snapshot. Never write inside the snapshot. When the source runtime has a flag that disables its build or bytecode caches, set it, so no cache lands in the snapshot (migration-conduct section 6).
3. Inputs come from the spec and the extraction: one case per branch, boundary and error path that the spec names. Each case has an id. Never invent an input the spec does not name.
4. Record each output as one fixture per case, under the golden directory that the plan names (for example `golden/<area>/<case>.json`).
5. Record the output exactly as the source returns it: values, field names, presence of each field, nulls, status, and error kind, code and message when present. Do not normalize.
6. Write each fixture path, its provenance (section 2) and the command that recorded it into the capture task's `evidence:`. Then run the task's `validation:` command.

## 2. Provenance

- `observed`: recorded by running the source at `source_sha`. The evidence names the command.
- `derived`: written by hand from the source code. The evidence cites `path:line @sha7` for each line used.
- Only a capture task writes a fixture. Never write a fixture from the target's output.
- A derived fixture proves L1 only (migration-conduct section 3). Report it as L1, not L2.

## 3. Missing fixture

- If the source cannot be run for a case and the spec names no derived case, the fixture stays missing. The golden test stays red and the task is not `done`. Report the open item with the file path and the owner step.
- Do not add an update flag that rewrites fixtures from the target output. That turns the test into a snapshot of the implementation, which proves nothing about parity.
- If a fixture and the spec disagree, apply the conflict order of migration-conduct section 4: a dated user decision first, then the source at the pinned commit, otherwise mark the task `blocked` and cite both sides. Never pick one silently.

## 4. Comparison

- Compare parsed values, not raw text, unless the spec requires byte equality. Key order counts when the source emits keys in a fixed order (cite `path:line`). Otherwise compare parsed values and record the choice as an `ID-` decision in the plan. Whitespace does not count.
- Compare field presence and nulls. A missing field, a null and an empty value are three different outputs.
- Compare lists in order when the source orders them. The extraction records the ordering under its numeric and type semantics.
- Amounts compare as exact decimal values, never through binary floating point. When the source fixes the number of digits after the decimal point, compare that count too.
- Fields that the source makes non-deterministic (for example a generated identifier or a timestamp) are compared by the rule the spec states. Never mask them silently.
- Error outputs compare kind, code, message and status. Messages are literal: copy them as the source states them.
- Differential run (L3): run the source and the target on the same recorded inputs and compare with the rules above. Report L3 only when this run did it, with the command and its result.
