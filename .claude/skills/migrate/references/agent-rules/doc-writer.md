# doc-writer: rules, UI units and architecture mode

Read by `doc-writer` before its first step (its prompt points here). Each section applies when its heading says so.

## UI units (platform web or mobile)

Read `unit_platform` and `unit_kind` from `docs/migration/MIGRATION.md`. For `backend`, ignore this block.

For `web` or `mobile`, the sections above replace Entry points, Inputs, Outputs, Errors, Rules, Flow and Side effects with these, in `doc_language`, in this order after Summary:
- Route and params: `| Route or screen | Param | Type | Required | Default | Evidence |`
- UI states: `| State | Trigger | What the user sees | Evidence |` (loading, empty, error, populated, permission denied, each one)
- Interactions and events: `| Event | Handler | Effect | Evidence |`
- Navigation in and out: `| Direction | Target | Params | Evidence |`
- Strings and i18n: `| Key or literal | Locale file or source | Evidence |`
- Accessibility: `| Element | Role or label | Focus or keyboard behavior | Evidence |`

Keep Known issues and deviations, Legacy decisions, Context, Gaps and Glossary as above. Backend units keep the backend sections unchanged. Cite each UI statement as usual; a visual value is cited as a token, not described from memory.

## Rules

- The implemented target code is the only source of behavior. Spec, extraction, plan and review are context and never add a behavior.
- Cite each statement as `path:line` relative to `target_root`, with forward slashes, or `path:start-end`. Target citations have no `@sha7`. A citation you did not reopen in this run is a defect.
- Quote expressions, constants, literals and messages exactly as the code writes them. Never restate them in your own words.
- Never invent a rule, default, limit, type, status or example. A rule the code does not show is a gap.
- Examples come only from a test or fixture you read in this run. Otherwise write the types, never a made-up value.
- Framework or library behavior is stated with its source at the version the lockfile pins, read in this run. A runtime fact may cite its official URL instead. Otherwise record a gap.
- Describe known issues and deviations as the code behaves. Never recommend a change and never call behavior wrong.
- Never write a secret value. Write `<redacted>` and cite where it is.
- Change no code and no file except the doc. Use Bash only for check.sh and read-only inspection.
- Hashes come from check.sh only. Never compute them by hand.
- Git: follow `migration-conduct` section 6a.
- A stale doc is regenerated in place (step 6). Ids stay stable. Removed statements are deleted, never renumbered.
- Never ask the user directly. Stop with `NEEDS: user: <question, quoted>, verified: <paths and lines you read>` only when the doc cannot be finished without a decision that the implemented code, the dependency source at the pinned version and the official documentation do not settle, checked in that order (migration-conduct section 0, rules 6 to 9). Otherwise record a gap. Never stop for format, structure or style.
- The doc is written 100% in `doc_language`. Identifiers, literals, paths, `path:line`, ids, frontmatter keys, markers and error messages stay as written. This file is English, and none of it reaches the doc.
- Legacy fidelity (conduct rule 10): document each ADR of the unit, with its hash in the Sources table. Never call a kept legacy decision a defect.
- Writing standard: follow the "Writing standard" section of the doc-writing skill. The test is a junior developer who never saw the code: each section starts with the answer, sentences stay short, each term is defined before its first use, and each rule gets one sentence on why it exists when the sources show the reason. Plain wording never removes a citation, a number, a status code or an id.
