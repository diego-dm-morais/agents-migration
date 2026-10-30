# Templates

Read this when you create an artifact. Keep the keys, ids and frontmatter exactly. Write the labels in `artifact_language`, and keep identifiers, paths, ids and literals as they are. Each template starts with `status: draft`. Set `ok` only when the stage's criteria hold (`stages.md`).

Hashes: `upstream_*` values come from `sh "${CLAUDE_SKILL_DIR}/scripts/check.sh" hash <file>`. `scope_hash` comes from `sh "${CLAUDE_SKILL_DIR}/scripts/check.sh" scope <unit>`. Never compute them by hand.

## docs/migration/MIGRATION.md

```markdown
---
source_language:
source_version:
source_repo:
source_ref:
source_sha:
source_snapshot:
source_root: .
target_language:
target_version:
target_root: .
doc_root: docs
unit_kind:
artifact_language:
doc_language:
limit_dispatch: 2
limit_review_rounds: 3
limit_fix_rounds: 2
deadline: none
---

# Migration: <source> to <target>

## Target conventions
- Layout:
- Allowed libraries (name, version, URL that confirms the version):
- Forbidden libraries or patterns:
- Naming:

## Backlog
1. <unit-id> | <kind> | <entry point> | depends: none
```

## <unit>/extraction.md

```markdown
---
unit: <unit-id>
stage: extract
status: draft
---

# <unit-id>

## Entry points
- `<path>:<line> @<sha7>` <symbol>

## Flow
1. <step> — `<path>:<line> @<sha7>`

### BR-<SLUG>-001 <short title>
- Statement:
- Trigger or condition:
- Effect:
- Error or status:
- Evidence: `<path>:<line> @<sha7>`

## Numeric and type semantics
- <fact> — `<path>:<line> @<sha7>`
(rounding, precision, overflow, encoding, time zone, ordering, null handling)

## Legacy decisions contrary to best practice
- DEC-001: <decision>; contrary to: <practice>; source: <official URL or dependency source at the pinned version>; `<path>:<line> @<sha7>`
- none found: <the search that was run, with the paths read>

## Data structures
- <type>: fields, types, defaults, nullability, `<path>:<line> @<sha7>`

## Shared dependencies
- <dependency>: how the unit uses it, `<path>:<line> @<sha7>`

## Gaps
- <symbol or question>: <reason>

## Closure checklist
- [ ] every entry point traced
- [ ] every unresolved symbol resolved or listed under Gaps
- [ ] `check.sh symbols` reviewed: every listed symbol fixed or explained
- [ ] every response path mapped (success, each error, each exception)
- [ ] every cited line reopened in this run
- [ ] every rule has evidence
- [ ] every legacy decision listed under `## Legacy decisions contrary to best practice`, with its evidence, or `none found` with the search that was run
```

## <unit>/spec.md

```markdown
---
unit: <unit-id>
stage: spec
status: draft
upstream_extraction: <check.sh hash of extraction.md>
---

# <unit-id> specification

## Scope
- NG-001: <non-goal>
- AG-001: <anti-goal>

## Functional requirements

### FR-001 <title>
- Source: BR-<SLUG>-001
- Acceptance: <observable check>

## Target requirements

### TS-001 <title>
- Source: FR-001, or `path:line @sha7`, or the MIGRATION.md convention it follows
- Acceptance: <observable check>

## Pending decisions

### PEND-001 <question>
- blocking: yes | no
- options: <a>; <b>
- recommendation: <option>
- default: <what you would use, and its kind>
- resolution:
```

## <unit>/plan.md

```markdown
---
unit: <unit-id>
stage: plan
status: draft
upstream_spec: <check.sh hash of spec.md>
---

# <unit-id> plan

## Target design

## Construct mapping
| Source construct | Target construct | Parity risk |
|---|---|---|

## Dependencies
| Name | Version | Source of the version (URL) |
|---|---|---|

## Decisions

### ID-001 <title>
- status: proposed | accepted | withdrawn
- reason:

## Legacy decisions (ADR)
- ADR-001: `docs/migration/adr/ADR-001-<slug>.md` (candidate DEC-001)

## Validation
- <step>: <validation command from the target gate>

## Trace
- FR-001 -> <construct rows, TS- ids or ID- ids>
```

## <unit>/tasks.md

```markdown
---
unit: <unit-id>
stage: tasks
status: draft
upstream_spec: <check.sh hash of spec.md>
upstream_plan: <check.sh hash of plan.md>
---

# <unit-id> tasks

### T-001 <title>
status: pending
kind: capture | setup | test | impl | verify
depends: none
files: <paths relative to target_root, comma separated>
spec: FR-001
validation: <command>
evidence:
```

Task status: `pending`, `in_progress`, `done` or `blocked`. Kinds: `capture` records golden output from the source; `setup` prepares the target; `test` writes a failing test; `impl` makes tests pass; `verify` runs the whole gate. `evidence:` is empty until the task is done; then it holds the command and its decisive result.

## <unit>/review.md

```markdown
---
unit: <unit-id>
stage: review
status: draft
round: 1
scope_hash: <check.sh scope <unit>>
---

# <unit-id> review

### RV-001 <title>
status: open | fixed | dismissed | blocked
severity: high | medium | low
evidence: `<target path>:<line>` and `<source path>:<line> @<sha7>`
finding: <what differs>
fix: <what the code must do>
```

## docs/migration/adr/ADR-NNN-<slug>.md

One file per legacy decision (`DEC-NNN`) that contradicts best practice and must be kept. The id is global and never reused. `check.sh adr <unit>` validates the sections, the citations and the coverage.

```markdown
---
id: ADR-001
status: accepted
unit: <unit-id>
candidate: DEC-001
source_sha: <full source_sha from MIGRATION.md>
---

# ADR-001 <decision title>

## Decision
<the legacy behavior, as the code implements it>. Evidence: `<path>:<line> @<sha7>`.

## Legacy evidence
- `<path>:<line> @<sha7>` <what the line does>
- <intent: comment, constant, test, document or commit, each with its citation>

## Reason to keep the legacy behavior
<why the migration keeps it: a caller, stored data or a business rule depends on it>

## Best practice contradicted
<the practice, and its source: official URL, or the dependency source at the pinned version>

## Justification
<why keeping it is right for this migration now, and what would change this decision>

## Consequences
- <what the target code does, and the test that locks it (its name carries ADR-001)>
- <what a future change must do to supersede this ADR>
```

## <doc_root>/<unit>.md

```markdown
---
unit: <unit-id>
stage: doc
status: draft
scope_hash: <check.sh scope <unit>>
---

# <unit-id>

## Sources
One row per ADR of the unit; the first cell is the ADR id.
| Source | cksum |
|---|---|
| extraction | <check.sh hash of extraction.md> |
| spec | <check.sh hash of spec.md> |
| plan | <check.sh hash of plan.md> |
| tasks | <check.sh hash of tasks.md> |
| ADR-001 | <check.sh hash of docs/migration/adr/ADR-001-<slug>.md> |
```
