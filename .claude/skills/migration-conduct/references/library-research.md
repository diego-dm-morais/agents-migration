# Library research

Shared rule for every language skill and every migration agent that adds or recommends a library, package or dependency. Each language skill names its registry in its own `## Library registry` section and points here.

## Order of search

Take the first source that answers. Do not skip to a later one.

1. The repository itself: the manifest and lockfile already present, and the allowed and forbidden lists in `docs/migration/MIGRATION.md`. A library the repository already uses wins over a new one.
2. The language standard library and the runtime's built-ins. No dependency for what they do.
3. The registry of the ecosystem (see the skill's `## Library registry`). Search by function, then open the candidate's page.
4. Only if no candidate fits: write the code in the target repository.

## Evaluate each candidate

Record each check with its source (URL, or `path:line` for a manifest):

- Official or established: maintained by the language or platform project, or widely used with a clear owner.
- Maintenance: date of the latest release, open issues on the project's repository, whether the project responds to them.
- Maturity: stable version (not pre-release only), documented API, changelog.
- Compatibility: the version supports the language or platform version the target pins (`go` directive, `requires-python`, `engines`, `<TargetFramework>`, `rust-version`, SDK constraint, and so on). Read it from the registry page or the package metadata, not from memory.
- License: compatible with the project's license.
- Dependencies: transitive dependencies it pulls in, and whether any of them is forbidden in `MIGRATION.md`.
- Behavior: the library must reproduce the legacy behavior the unit depends on (inputs, outputs, errors). Check it with a test before adopting it. A library that changes rounding, parsing, time zones or error messages is a parity risk (section 1 of `migration-conduct`).

## Versions are facts only when confirmed in this run

- A name or version is a fact only after a registry page or the package metadata is read in this run. Cite the URL. A version from memory is not a fact (`migration-conduct` rule 1).
- Pin the exact version in the manifest and commit the lockfile.
- If the registry cannot be reached, record the library as an open item with the exact error. Do not recommend it as verified.

## Legacy fidelity

- The legacy code is the source of truth (`migration-conduct` rule 10). A library choice must not change legacy behavior to fit the target's common practice.
- A library that replaces a legacy behavior is recorded in the plan's `## Dependencies` table with its source of version and the behavior it reproduces.
- A legacy decision that a best-practice library would change is a `DEC` and an ADR (section 13 of `migration-conduct`), not a silent swap.

## Output

For each library the target adds, record in the plan (`## Dependencies`):

- name, exact version, registry URL that confirms it;
- why it was chosen, and which evaluation checks above it passed;
- alternatives rejected, with the reason;
- the forbidden-list check result from `MIGRATION.md`.

Any library not in the plan's `## Dependencies` table is not added. Ask the planner to update the plan first (`NEEDS: migration-planner`).
