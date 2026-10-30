# Code migration toolkit

This file takes precedence over `C:\Users\Administrator\.claude\CLAUDE.md` (global) on any conflict. Ignore examples in the global instructions that name agents, paths or projects this toolkit does not have.

## Session start

At the first reply of each session in this project, before any other work:

1. Read the status printed by the SessionStart hook in this context (configured in `.claude/settings.local.json`). If it is not in this context, run `sh .claude/skills/migrate/scripts/check.sh status` from the project root.
2. A migration is in progress when the `project` line is not `MISSING` and at least one unit has a `doc` line other than `OK`. Then do not run `gh-check`; report each unit's state in a short list and wait for the user's instruction. Do not dispatch any stage on your own.
3. Otherwise (`project MISSING`, `units NONE`, or every unit's `doc` is `OK`), this is a first session with no migration in progress. Run the `gh-check` skill first; if `gh` is missing or not authenticated, alert the user in pt-BR with the fix it gives. Then read `.claude/skills/migrate/references/help.md` and show its content verbatim first (same output as `/migrate help`; the skill is user-invoked only, so print the file yourself instead of invoking it). Then ask the user in one message for:
   - the source repository (local path or URL);
   - the tag to migrate (or branch or commit);
   - the unit(s) to migrate and their platform (`backend`, `web` or `mobile`), in one of these forms: a backend HTTP operation (method + path, for example `POST /v1/users`, which becomes the unit id `post-v1-users`); a screen or feature of a web or mobile frontend (route or screen file, for example `src/app/checkout/payment/page.tsx` or `lib/screens/checkout_payment.dart`, which becomes the unit id `checkout-payment`); or a collection (Postman, OpenAPI or Apidog export for backend, Figma or storyboard for frontend), used only to list operations or screens and names, with secrets redacted.
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

## Run configuration

- Every agent runs on model `claude-haiku-5-5` at effort `medium`: a balance of accuracy, productivity and speed, aimed at meeting the `deadline`. Each agent sets both in its frontmatter, the `/migrate` skill sets them for the orchestrator, and `.claude/tests/gate_format.py` fails on any other value.
- Changing the model or the effort is a user decision. Record it in `.claude/docs/convencoes.md` and update `PINNED_MODEL` or `PINNED_EFFORT` in the gate.
- The mandatory rules below guide every stage: analysis, planning, implementation, tests, validation and documentation.

## Mandatory rules (full text: migration-conduct skill, section 0)

1. **No hallucination.** Every statement about source behavior cites `path:line @sha7`, opened in this run. A library or runtime fact cites its official URL or the dependency source at the pinned version. No citation, no fact.
2. **No invented business rule.** A rule is what the implemented code does. A `BR-` without a citation, or an `FR-` without `Source: BR-`, is a defect. `check.sh` rejects both.
3. **Faithful documentation.** Document behavior as the code implements it, bugs included (`known-issue`). Do not change or reinterpret behavior to follow best practice. An idiomatic choice is allowed only when inputs, outputs and errors stay the same.
4. **The primary source is the implemented code.** The spec and any existing docs are labeled context, never the source of behavior.
5. **Docs stay in sync with the implementation.** A unit doc records the hashes of its sources and of the code scope. When code or a source artifact changes, the doc is STALE and must be regenerated before the unit is done.
6. **Investigate before asking.** In this order: (a) the implemented code, source and target, with its tests and configuration; (b) the dependency source at the pinned version (lockfile, vendored code, local package cache); (c) the official documentation of the language, framework or library. The legacy repository's documentation is context only. Only then ask, and only when the answer changes what gets built.
7. **No irrelevant questions.** Never ask what the code or the library answers, or what a default would settle without changing the result. Record the default with `blocking: no`. Never hand the user an investigation that you can run yourself.
8. **Every question states what was checked** (paths, lines, URLs) and why the answer is not there.
9. **An unanswered blocking question** stops the unit with `NEEDS: user: <question, quoted>`. Never pick the behavior yourself.
10. **Legacy fidelity (absolute priority).** The goal is to preserve the behavior of the legacy system and reproduce it in the new project. Functional equivalence comes first, before best practices, style or speed. Never ask the user a question that the legacy code can answer. The legacy code is the source of truth: preserve its behavior, business rules, validations and decisions, even when they do not follow best practices or the recommended patterns of the target language. Do not change legacy behavior to fit best practices on your own initiative. Record in an ADR (Architecture Decision Record) every legacy decision that contradicts best practices and must be preserved. Every agent applies this rule in analysis, planning, implementation, testing, validation and documentation (`migration-conduct` section 0 and section 13).

11. **No creativity in the target.** Agents invent no behavior, rule, field, state, route, event, string or layout. Every UI state, event and text comes from the legacy code at the pin, with `path:line @sha7`. A gap becomes `Gaps` or a `blocking: yes` PEND, never an assumption.

12. **Productivity within the deadline.** Be critical of your own decisions and deliverables. Do not repeat an analysis, ask an unnecessary question or build what no requirement needs. Choose the objective and safe solution that keeps the legacy behavior, and order the work for progress toward the `deadline`. Never trade functional fidelity or technical quality for speed.

13. **Build to 100%, then review.** Build the target code and its unit tests to 100% before review: every task `done` with evidence; every `FR-` and every core `BR-` covered by a passing unit test that reproduces its cited legacy behavior; every border `deferred-capture` run, or recorded `NOT RUN` with its reason. A `blocked` item keeps the unit short of 100%: report it with its reason, and never send partial code to review. At 100% convergence with the legacy code at the pin, the unit goes to the `review` stage (parity-reviewer); the current flow then continues: review rounds, then `doc`.

Also: source bugs stay as `known-issue`; a conflict between a standard and the behavior is recorded as `deviation` with its reason. Report the real output of every command; a gate that did not run is not a pass.

Core and border (decided 2026-10-30, migration-conduct section 1a): a core gap blocks the unit; a border gap (behavior the framework decides and the spec does not state) is `deferred-capture <id>` in Gaps, and the build settles it with a golden capture. Parity for a border gap is `not proven` until that capture passes.

## Project memory

- This project's Claude memory is stored in `.claude/memory/` (inside the local repo), with `MEMORY.md` as the index and one file per memory (frontmatter `name`, `description`, `metadata.type`).
- When saving or updating a memory, always write to `.claude/memory/`, never to another path.
- `.claude/memory/` is in the repository `.gitignore`, so this memory is not committed. The rest of `.claude/` is versionable.
