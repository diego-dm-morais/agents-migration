# Intake and init

Read this for `/migrate init`, and when a new source or unit must be registered.

## What `init` needs

`init` asks only for what MIGRATION.md does not already have. First create the snapshot (below), then read the source language and version from its files (`go.mod`, `.python-version`, `pyproject.toml`, `.nvmrc`, `Dockerfile`). Ask only for what those files do not settle. Ask all the remaining questions in one round, in groups of up to 4 per AskUserQuestion call, so the user answers once:

1. Source: language, version, repository (local path or URL), ref (tag, branch or commit), source root inside the repository (default `.`). Detected values are shown, not asked.
2. Target: language, version, target root (default `.`), and the directory for the generated docs (default `docs`). The target framework, driver and gate tools come from the language skill's defaults, each written as `proposed`; ask only when the user wants another choice.
3. Unit platform and kind. Platform: `backend`, `web` or `mobile`. One platform per migration; a migration may list units of other platforms only as separate migrations. Kind by platform:
   - `backend`: function, class, module, HTTP operation, CLI command or job (`unit_kind` value: `endpoint` for HTTP operation, `feature` for the others).
   - `web` or `mobile`: screen or feature (`unit_kind: screen` or `feature`).
   Write `unit_platform` and `unit_kind` in MIGRATION.md.
4. Languages of the artifacts and of the docs (default: the language the user writes in).
5. Deadline, optional: ask once, with the options "No deadline (Recommended)" and "Enter a date". Write `deadline: none` for no deadline, or `deadline: YYYY-MM-DD` for a date. The default never blocks a unit. A deadline sets the order of the work and what fits in it. It never changes legacy behavior or skips a test (`migration-conduct` section 4).

6. Target architecture: same structure as the source, or a new architecture (services, data stores, events). For a new one, ask for the non-functional requirements the user already has (latency, observability, security, deployment) and write them as `NFR-NNN` with the date. Never invent one.

Then ask for the limits only if the user wants to change them: `limit_dispatch` 2, `limit_review_rounds` 3, `limit_fix_rounds` 2.

## Create the snapshot

The snapshot is a checkout of the source at the ref. It lives outside the target repository, so that nothing in the target is affected. Default: `../<target-directory-name>-source`.

```
git clone --no-checkout <source_repo> <snapshot>
git -C <snapshot> checkout --detach <source_ref>
git -C <snapshot> rev-parse HEAD
```

Write the full sha from the last command into `source_sha`, and the snapshot path into `source_snapshot` (relative to the target root). Then run `sh "${CLAUDE_SKILL_DIR}/scripts/check.sh" pin`. It must print `pin OK`.

Never run a mutating git command in the source repository, and never write inside the snapshot.

## Preflight

Run `sh "${CLAUDE_SKILL_DIR}/scripts/check.sh" preflight`. It prints one line per item: the source runtime, the docker daemon, each image of the source Dockerfile and of its compose files, and the target runtime. Write its output under `## Environment` in MIGRATION.md, one line per item. For each `MISSING` or `UNKNOWN` item, ask the user once, with two options: install it or waive it. A waiver is written as `- waived: <item> by user <date>` in the same section. A waived item is `NOT RUN` in every task that needs it, with the waiver as the reason. No stage checks the item again.

## Backlog

Dispatch behavior-extractor in mode `survey` with the source root, `unit_platform` and `unit_kind`. It returns candidate units with their entry points and dependencies. For `web` or `mobile`, the survey finds routes, navigators, screen or page components and feature folders. When the user already named the unit and the survey finds exactly that unit, write it under `## Backlog` without asking. Otherwise show the candidates with AskUserQuestion, and write the confirmed units under `## Backlog` in MIGRATION.md, each with its `depends:` from the survey. For a new architecture, then run `/migrate architecture` before the first unit. Unit ids come from the operation, screen or symbol name, in lowercase kebab-case. Screen ids use `<area>-<screen>` (for example `checkout-payment`).

## Secrets in input

curl commands, collections (Postman, OpenAPI, Apidog exports) and configuration files can hold tokens and credentials. Replace each value with `<redacted>` in every file you write, and keep no copy of it. A collection is used only to list operations and their names. Its examples are never the source of behavior: the source code at the pin is.

## Units

A unit is the smallest piece that behaves on its own. Migrate units in dependency order from the backlog. The unit id must match `^[a-z0-9]+(-[a-z0-9]+)*$`.
