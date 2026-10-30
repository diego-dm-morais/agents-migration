# Code migration toolkit

This file takes precedence over `C:\Users\Administrator\.claude\CLAUDE.md` (global) on any conflict. Ignore examples in the global instructions that name agents, paths or projects this toolkit does not have.

## Session start

At the first reply of each session in this project, before any other work:

1. Read the status printed by the SessionStart hook in this context (configured in `.claude/settings.local.json`). If it is not in this context, run `sh .claude/skills/migrate/scripts/check.sh status` from the project root.
2. A migration is in progress when the `project` line is not `MISSING` and at least one unit has a `doc` line other than `OK`. Then do not run `gh-check`; report each unit's state in a short list and wait for the user's instruction. Do not dispatch any stage on your own.
3. Otherwise (`project MISSING`, `units NONE`, or every unit's `doc` is `OK`), this is a first session with no migration in progress. Run the `gh-check` skill first; if `gh` is missing or not authenticated, alert the user in pt-BR with the fix it gives. Then read `.claude/skills/migrate/references/help.md` and show its content verbatim first (same output as `/migrate help`; the skill is user-invoked only, so print the file yourself instead of invoking it). Then ask the user in one message for:
   - the source repository (local path or URL);
   - the tag to migrate (or branch or commit);
   - the endpoint(s) to migrate.
   Ask only for what `docs/migration/MIGRATION.md` does not already give.
4. Do not run the intake yourself. Tell the user the answers and ask them to type `/migrate init` with them: the skill is user-invoked only, and its `allowed-tools` and rules apply only when it runs. The intake then asks for whatever is still missing.

## Language

- Replies to the user: pt-BR, 100%.
- Docs generated in the project (`doc_language` in `docs/migration/MIGRATION.md`): pt-BR, 100%.
- Comments: in code, English (approved plan and global rule). Comments an agent writes inside a review finding, a doc or any artifact: pt-BR.
- Commit messages: English.
- Prompts of agents and skills, and this file: English.
- Migration artifacts: the language in `artifact_language` (pt-BR in this project).
- Never translate identifiers, literals, paths, `path:line`, SQL, enum values or error messages. Machine keys in reports and artifacts (`Result:`, `Written:`, `NEEDS:`, frontmatter keys, ids) stay in English; the prose that follows them is in the language of the section.

## Toolkit

- Commands: `/migrate init`, `/migrate <unit>`, `/migrate status`, `/migrate ask [unit]`.
- Agents (alias): behavior-extractor (Eduardo), spec-writer (Sofia), migration-planner (Paula), task-decomposer (Tiago), implementer (Isabela), parity-reviewer (Rafael), doc-writer (Daniela). Dispatch them through `/migrate`; call one directly only when the user asks for it, by name or alias.
- Language skills: golang, java, python, nodejs, typescript, javascript, dotnet, rust, flutter. Load the skill for the source language or the target language.
- Human docs (pt-BR, not loaded by agents): `.claude/docs/README.md`.

## Mandatory rules (full text: migration-conduct skill, section 0)

1. **No hallucination.** Every statement about source behavior cites `path:line @sha7`, opened in this run. A library or runtime fact cites its official URL or the dependency source at the pinned version. No citation, no fact.
2. **No invented business rule.** A rule is what the implemented code does. A `BR-` without a citation, or an `FR-` without `Source: BR-`, is a defect. `check.sh` rejects both.
3. **Faithful documentation.** Document behavior as the code implements it, bugs included (`known-issue`). Do not change or reinterpret behavior to follow best practice. An idiomatic choice is allowed only when inputs, outputs and errors stay the same.
4. **The primary source is the implemented code.** The spec and any existing docs are labeled context, never the source of behavior.
5. **Docs stay in sync with the implementation.** A unit doc records the hashes of its sources and of the code scope. When code or a source artifact changes, the doc is STALE and must be regenerated before the unit is done.
6. **Investigate before asking.** In this order: (a) the implemented code, source and target; (b) the dependency source at the pinned version (lockfile, vendored code, local package cache); (c) the official documentation of the language, framework or library. Only then ask, and only when the answer changes what gets built.
7. **No irrelevant questions.** Never ask what the code or the library answers, or what a default would settle without changing the result. Record the default with `blocking: no`.
8. **Every question states what was checked** (paths, lines, URLs) and why the answer is not there.
9. **An unanswered blocking question** stops the unit with `NEEDS: user: <question, quoted>`. Never pick the behavior yourself.
10. **Legacy fidelity.** Never ask the user a question that the legacy code can answer. Before any clarification, investigate the legacy code and identify its behavior, business rules and implemented decisions. The legacy code is the source of truth: preserve its behavior, business rules and decisions, even when they do not follow best practices or the recommended patterns of the target language. Do not change legacy behavior to fit best practices on your own initiative; functional fidelity to the original system comes first. Record in an ADR (Architecture Decision Record) every legacy decision that contradicts best practices and must be preserved: the decision, the reason to keep the original behavior, the best practices it contradicts, and the justification for keeping that implementation in the migration. Every agent applies this rule consistently in analysis, planning, implementation, testing and validation (`migration-conduct` section 0 and section 13).

Also: source bugs stay as `known-issue`; a conflict between a standard and the behavior is recorded as `deviation` with its reason. Report the real output of every command; a gate that did not run is not a pass.

## Project memory

- This project's Claude memory is stored in `.claude/memory/` (inside the local repo), with `MEMORY.md` as the index and one file per memory (frontmatter `name`, `description`, `metadata.type`).
- When saving or updating a memory, always write to `.claude/memory/`, never to another path.
- `.claude/memory/` is in the repository `.gitignore`, so this memory is not committed. The rest of `.claude/` is versionable.
