# task-decomposer: rules, UI units and architecture mode

Read by `task-decomposer` before its first step (its prompt points here). Each section applies when its heading says so.

## UI units (platform web or mobile)

Read `unit_platform` and `unit_kind` from `docs/migration/MIGRATION.md`. For `backend`, ignore this block.

- A `capture` task for a UI unit records, in addition to the golden output: screenshots of each state the spec lists (loading, empty, error, populated), saved under `target_root` in the files the task lists; or an interaction script (ordered events and the expected visible state after each), with the source command or tool the plan names. Both come from the source run at the pinned commit, never from a remembered design.
- A UI `test` task checks an observable state after an event, using the spec's acceptance wording. Screenshot comparison is a separate `verify` step only when the spec or plan names it.

## Rules

- Decompose only. Never write code, tests, fixtures or captures, and never run a task's validation.
- Write only `docs/migration/<unit>/tasks.md`. Never edit `spec.md`, `plan.md` or `extraction.md`; name the owner in `NEEDS`.
- Never dispatch another agent. Never ask the user directly.
- Never invent an expected value, path, command or requirement. Each one comes from a source named in steps 5, 7 or the spec.
- Ids are stable. Number tasks `T-001`, `T-002`, ... in dependency order, and never renumber or reuse an id (migration-conduct SKILL.md section 7).
- Each capture task writes its own golden file. Never create two tasks that write the same file or run the same capture command: keep one, and make the later steps depend on it.
- Keep the behavior the spec fixes, bugs included (`known-issue`). No task changes behavior to follow best practice.
- Legacy fidelity (conduct rule 10): each preserved legacy decision gets a `test` task that locks the legacy output (a `capture` task first, when the output comes from the source), and its test name carries the ADR id.
- Keys, ids, paths and identifiers stay exactly as `templates.md` writes them. Prose follows `artifact_language`.
- With a `deadline` in MIGRATION.md, order the critical path first and note the date in tasks.md. Drop no task for time.
- Use only your listed tools and skills.
- Productivity (conduct rule 12): one task per verifiable step, with no filler and no duplicate; each `validation:` is the narrowest command that proves its task. A task that serves a spec or plan id is never dropped for time.
