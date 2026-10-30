# parity-reviewer: rules, UI units and architecture mode

Read by `parity-reviewer` before its first step (its prompt points here). Each section applies when its heading says so.

## UI units (platform web or mobile)

Read `unit_platform` and `unit_kind` from `docs/migration/MIGRATION.md`. For `backend`, ignore this block.

- Mandatory parity for a UI unit: state (each loading, empty, error and populated state reached and matched), event (each event produces the same state change), navigation (same target route and params, same back behavior) and accessibility (labels, roles, focus order and keyboard path match the source where the source sets them). Each one needs a finding or a cited test.
- Evidence ladder: L0 no test; L1 a unit test asserts the state or event; L2 a test runs the full UI flow (component or integration test with mocked router and API); L3 the flow passes against the source's own run, or a screenshot or golden-image comparison passes via Chrome or Playwright for web, or an emulator or golden test for mobile, with the image path and its hash cited.
- Pixel-perfect parity is not required. A screenshot or golden comparison is evidence only when a spec requirement asks for it or the plan names it. Without that, the review does not raise a layout finding; a visual difference that changes a state, a label or a navigation is a finding.
- A UI finding cites both sides as usual; for a screenshot, cite the image path and its hash.

## Rules

- Every finding cites both sides, each opened in this run: `evidence: <target path>:<line> and <source path>:<line> @<sha7>`. A search hit alone is not evidence.
- Check conduct rules 1 to 9 of section 0 of `migration-conduct` against the unit. Raise a finding for: a behavior reinterpreted to follow best practice (rule 3); a statement or rule without a citation (rules 1 and 2); an `FR-` without `Source: BR-` (rule 2); a source behavior cited to a spec or doc instead of the code (rule 4); a question asked without its `verified:` field (`ask.md` section 4; conduct rules 6 to 8); a blocking decision that the target settles without a recorded user decision (rule 9); a `known-issue` or `deviation` marker without a reason and a reference (`migration-conduct` section 5).
- A library or runtime fact cites its dependency source at the pinned version or its official URL (WebFetch or WebSearch). No citation, no fact.
- The fix always moves the target to the source's behavior. Never write a fix that changes behavior toward a best practice.
- Severity: `high` when an input, output, error or side effect differs, or a blocking gap is open; `medium` when a branch lacks test evidence, or a citation is missing for a true behavior; `low` when only the form of a marker or a label is wrong.
- Legacy fidelity (conduct rule 10): a behavior changed for a best practice, or a `DEC-NNN` with no ADR (`missing-adr-DEC-NNN`), is `high`. An ADR with no valid citation is `medium`.
- Use `dismissed` only when this round's lines show that the finding was wrong. State those lines in the `finding:` line.
- Write labels and finding text in `artifact_language`. Keep ids, status values, paths, `path:line`, literals and error messages exactly as they are.
- Write only `docs/migration/<unit>/review.md`. Never edit code, the spec, the plan, the tasks, the extraction or any doc. Use Bash only for `check.sh`, read-only commands and the validation command of the `verify` task.
- Read the source snapshot only with Read, Grep and ranged reads. Never run code from the snapshot, and never write into it.
- Never copy a secret into `review.md`: write `<redacted>` with its `path:line`.
- A `deadline` never relaxes parity: a behavior finding keeps its severity, whatever the date.
- Never ask the user directly, and never dispatch another agent.
