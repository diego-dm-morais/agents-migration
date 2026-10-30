# Stages

Read this when you need the criteria of a stage, or the order of the stages.

## Order and states

Order: extract → spec → plan → tasks (READY) → build → review → doc.

Every artifact has a frontmatter `status`: `draft`, `ok` or `blocked`. `check.sh` turns it into a state:

| State | Meaning |
|---|---|
| MISSING | the file does not exist |
| DRAFT | status draft, or work still pending |
| BLOCKED | status blocked, an open blocking decision, or a blocked task |
| INVALID | a structural check failed (ids, coverage, citations, missing keys) |
| STALE | an upstream or the code changed after this artifact was written |
| OK | status ok and every check passed |

Priority when several apply: INVALID, then STALE, then BLOCKED, then DRAFT, then OK.

READY means extract, spec, plan and tasks are OK. Build, review and doc come after READY.

## Stage criteria

| Stage | Owner | Input | Output | OK when |
|---|---|---|---|---|
| extract | behavior-extractor | snapshot, unit entry point | `<unit>/extraction.md` | every entry point traced; every rule `BR-` has a citation; the closure checklist is ticked; gaps are listed; `cites` has no bad citation; the legacy decisions section lists each `DEC-` with a citation, or `none found` |
| spec | spec-writer | extraction OK | `<unit>/spec.md` | every `BR-` is covered by an `FR-`; target requirements `TS-`; non-goals `NG-`; open decisions `PEND-` with `blocking`; no open blocking `PEND-` |
| plan | migration-planner | spec OK | `<unit>/plan.md` and `docs/migration/adr/ADR-NNN-<slug>.md` for each `DEC-` | target design; construct mapping; every dependency with a version and its source; decisions `ID-`; every `FR-` appears in the trace; conventions of MIGRATION.md respected; `check.sh adr <unit>` OK (an ADR for each `DEC-`) |
| tasks | task-decomposer | plan OK | `<unit>/tasks.md` | tasks `T-` in dependency order, each with kind, depends, files, spec refs and a validation command; every `FR-` covered by a task |
| build | implementer | tasks OK | code, tests, task status and evidence | every task `done` with `evidence:`; every listed file exists |
| review | parity-reviewer | build OK | `<unit>/review.md` | status ok only with no open or blocked `RV-`; `scope_hash` equals the current code scope |
| doc | doc-writer | review OK | `<doc_root>/<unit>.md` | the sources table matches the current artifacts and the scope hash |

## Rules that apply to every stage

- An artifact is rewritten in place. Ids stay stable.
- A stage writes only its own artifact. Code is written only by build.
- A stage that finds a problem owned by an upstream stage stops with a `NEEDS` line and does not work around it.
- Freeze: once any task is not `pending`, spec, plan and tasks do not run again. Changes after that point are reported to the user.
- Border gaps (`deferred-capture <id>` in the extraction Gaps, migration-conduct section 1a) do not block extract, spec, plan or tasks. The task that captures each one runs in build: the implementer records the source output with the command the plan names, in `docs/migration/<unit>/captures.md`, and parity-reviewer compares it. A capture that contradicts the assumed behavior is an addendum there; it does not reopen an earlier stage.
