# Routing

Read this when a stage returns a state or a `NEEDS` line and you must choose the next owner.

## Owner by state

| State from `check.sh` | Dispatch | Notes |
|---|---|---|
| extract MISSING, DRAFT, INVALID | behavior-extractor | INVALID usually means a citation or a duplicate id |
| extract STALE | behavior-extractor | `source_sha` in MIGRATION.md changed after the extraction; re-extract before any later stage |
| extract BLOCKED | none | the ask flow |
| spec MISSING, DRAFT, INVALID | spec-writer | |
| spec STALE | spec-writer | the extraction changed after the spec |
| spec BLOCKED | none | an open blocking decision: run the ask flow |
| plan MISSING, DRAFT, INVALID, STALE | migration-planner | |
| plan BLOCKED | none | the ask flow; a `NEEDS` to another owner follows step 6 of the stage loop |
| tasks MISSING, DRAFT, INVALID, STALE | task-decomposer | |
| tasks BLOCKED | none | the ask flow |
| build MISSING, DRAFT | implementer | only after the user asked for the build (`<unit> build`, or `<unit>` with a build request) |
| build INVALID | implementer | a done task has no evidence, or a listed file is missing |
| build BLOCKED | none | report each blocked task id, its reason, and the owner who can unblock it |
| review MISSING | parity-reviewer | round 1 |
| review DRAFT | implementer | fix round for the RV ids with `status: open` in `review.md` |
| review STALE | parity-reviewer | new round; code changed since the last review |
| review INVALID | parity-reviewer | a finding is open while the status says ok |
| review BLOCKED | none | report; the user decides |
| doc MISSING, DRAFT, INVALID, STALE | doc-writer | |

## Allowed `NEEDS` owners by worker

| Worker | May request |
|---|---|
| behavior-extractor | user |
| spec-writer | behavior-extractor (missing technical fact), user |
| migration-planner | spec-writer, behavior-extractor, user |
| task-decomposer | migration-planner, spec-writer (requirement gap), behavior-extractor (missing technical fact), user |
| implementer | task-decomposer (only while no task has started), migration-planner (only while no task has started), spec-writer (only while no task has started), user |
| parity-reviewer | implementer (fix round) |
| doc-writer | user |

Any other owner is reported and the unit stops.

A `NEEDS: user` about legacy behavior whose `verified:` field lists no legacy path and line is not sent to the user. The orchestrator returns it to behavior-extractor, which investigates the legacy code first (conduct rule 10). A library or version question lists its dependency source or URL in `verified:` instead.

## Deadline

`check.sh status` prints the project deadline on its own line (`deadline none` or `deadline <date> days=<n>`). A deadline with `OVERDUE` is a warning in the report and never blocks a unit. When a deadline cannot cover the unit's scope, the worker that finds it ends with `NEEDS: user: <question, quoted>`, and the question offers three options: reduce the scope, extend the deadline, or keep both. The orchestrator stops the unit and runs the ask flow. No worker chooses among the three.

## Dispatch limits

- The same owner runs at most `limit_dispatch` times per stage, counting its first run and each run after a `NEEDS`.
- parity-reviewer runs at most `limit_review_rounds` rounds per unit.
- implementer runs at most `limit_fix_rounds` fix dispatches per unit.
- When a limit is reached, stop and report the state and the open items. Do not raise the limit yourself.
