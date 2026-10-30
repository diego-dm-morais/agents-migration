# migration-planner: rules, UI units and architecture mode

Read by `migration-planner` before its first step (its prompt points here). Each section applies when its heading says so.

## Architecture mode

When the dispatch mode is `architecture`, write only `docs/migration/ARCHITECTURE.md` with its template in `.claude/skills/migrate/references/templates.md`. Read MIGRATION.md (Target conventions, Non-functional requirements, Backlog) and the `## Shared dependencies` and `## Data structures` sections of every extraction that exists. Every source fact cites `path:line @sha7`. Every target choice (service split, data strategy, cutover shape) is an `ID-ANNN` with `status: proposed`, never a fact; a choice that changes an input, an output or an error ends with `NEEDS: user: <question, quoted, with the ID>, verified: <paths and lines>`. Legacy behavior is never changed by the architecture (conduct rule 10). Set `upstream_migration` with `check.sh hash docs/migration/MIGRATION.md`. Skip the unit procedure below.

## UI units (platform web or mobile)

Read `unit_platform` and `unit_kind` from `docs/migration/MIGRATION.md`. For `backend`, ignore this block.

- Construct rows for a UI unit cover, in addition to the procedure's rows: component or widget (source `path:line @sha7` to the target component or widget); state store (source store, reducer or provider to the target state holder, with what persists); router entry (source route or navigator entry to the target route, with params); style or theme (source tokens or theme values to the target theme, cited); asset (source image, font or icon to the target asset path); platform API (source `Platform`, camera, geolocation or storage call to the target equivalent, with the dependency version that confirms it).
- Cutover Route: the entry in `## Cutover` is a feature flag or a navigation entry (the route that now points to the new screen, or the flag that selects it). It is never a DNS or server switch for a UI unit.
- The parity risk of a UI row names the state, event or navigation it could change.

## Rules

- The spec is the only source of required behavior. Do not plan a behavior the spec does not require, and do not drop one it requires.
- Read source only at the lines the extraction and the spec cite. A fact the extraction lacks goes out as `NEEDS: behavior-extractor: <fact, quoted>`. A requirement the spec lacks goes out as `NEEDS: spec-writer: <requirement, quoted>`. Never fill either gap here.
- A contract choice (input type, output format, error class) that the source does not fix is not yours to make. Do not decide it. End with `NEEDS: spec-writer: <contract choice, quoted>`.
- A target choice that changes an input, an output or an error is an `ID-NNN` with `status: proposed`. Set `accepted` only when a decision already exists, and cite it: a resolution the orchestrator hands you, tagged by kind (`resolved by user, <date>`, `default by conduct rule <n>, reversible, <date>` or `fact: <evidence>`, per `.claude/skills/migrate/references/ask.md` section 5); a dated user decision in MIGRATION.md or the spec; or the pinned source (conduct section 4, items 1 and 2). Otherwise keep `status: proposed`. If no decision settles it, set the plan `blocked` and end with `NEEDS: user: <question, quoted, with the ID>`.
- An idiomatic choice that keeps inputs, outputs and errors the same stays `proposed`, with its reason (conduct section 0, rule 3).
- Legacy fidelity (conduct rule 10): one ADR per `DEC-NNN` in `docs/migration/adr/`, from the templates.md template, next free number. Never plan a target behavior that changes a legacy decision.
- With a `deadline` in MIGRATION.md, add `## Deadline` (target date, critical path). It never changes legacy behavior.
- A library or pattern listed under `Forbidden libraries or patterns` in MIGRATION.md is never used. If the target needs it, set the plan `blocked` and end with `NEEDS: user: <library or pattern, quoted>`. A library that the target language skill names in its quality gate (its section 8) is an `ID-NNN` with `status: proposed`, with its version and the URL that confirms it. It does not block the plan and is never asked: it is a default. Any other library outside `Allowed libraries` is an `ID-NNN` with `status: proposed`; set the plan `blocked` and end with ONE `NEEDS: user` that lists every such library, quoted, with its ID. Never ask for one library per run.
- Never write steps, tests, tasks or code. Task breakdown belongs to task-decomposer, code to implementer.
- Write only `docs/migration/ARCHITECTURE.md` (architecture mode), or `docs/migration/<unit>/plan.md` and the ADR files of its DEC items under `docs/migration/adr/`. Never write inside the source snapshot.
- Never ask the user directly. Before any `NEEDS: user`, check the cited code, the dependency source and the official docs (conduct rule 6). Then write `NEEDS: user: <question, quoted>, verified: <paths, lines and URLs checked>` (conduct rule 8).
- Never copy a secret value. Write `<redacted>` and cite where it is.
- Keep identifiers, paths and literals untranslated.
- Productivity (conduct rule 12): plan only what the spec requires; open the target repository and the dependency sources only as far as a mapping row needs; a choice that changes no input, output or error is a default with its reason, not a question. Never trade parity or a validation command for time.
