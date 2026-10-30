---
name: migration-conduct
description: "Shared rules for every migration agent. Covers behavioral parity, evidence citations, the evidence ladder, gap and conflict handling, deviation and known-issue markers, stable ids, secrets, verification, and the final report contract. Preloaded by the migration agents; not invoked by users."
user-invocable: false
---

# Migration conduct

These rules apply to every migration agent. The agent's own prompt gives its role. This skill gives the rules that all roles share.

## 0. Mandatory rules

1. No hallucination. Every statement about source behavior cites `path:line @sha7`, opened in this run. A library or runtime fact cites its official URL or the dependency source at the pinned version. No citation, no fact.
2. No invented business rule. A rule is what the implemented code does. A `BR-` without a citation, or an `FR-` without `Source: BR-`, is a defect. `check.sh` rejects both.
3. Faithful documentation. Document the behavior as the code implements it, bugs included (`known-issue`). Do not change or reinterpret behavior to follow best practice. An idiomatic choice is allowed only when inputs, outputs and errors stay the same.
4. The primary source is the implemented code. The spec and any existing docs are labeled context, never the source of behavior.
5. Docs stay in sync with the implementation. A unit doc records the hashes of its sources and of the code scope. When code or a source artifact changes, the doc is STALE and must be regenerated before the unit is done.
6. Investigate before asking. In this order: (a) the implemented code, source and target; (b) the dependency source at the pinned version (lockfile, vendored code, local package cache); (c) the official documentation of the language, framework or library. Only then ask, and only when the answer changes what gets built.
7. No irrelevant questions. Never ask what the code answers, what the library answers, or what a default would settle without changing the result. Record the default with `blocking: no`.
8. Every question states what you checked (paths, lines, URLs) and why the answer is not there.
9. An unanswered blocking question stops the unit with `NEEDS: user: <question, quoted>`. Never pick the behavior yourself.
10. Legacy fidelity. Never ask the user a question that the legacy code can answer. Before any clarification, investigate the legacy code and identify its behavior, business rules and implemented decisions. The legacy code is the source of truth: preserve its behavior, business rules and decisions, even when they do not follow best practices or the recommended patterns of the target language. Do not change legacy behavior to fit best practices on your own initiative; functional fidelity to the original system comes first. Record in an ADR (Architecture Decision Record) every legacy decision that contradicts best practices and must be preserved: the decision, the reason to keep the original behavior, the best practices it contradicts, and the justification for keeping that implementation in the migration. Every agent applies this rule consistently in analysis, planning, implementation, testing and validation. Section 13 defines the records.

## 1. Goal: behavioral parity

For the same input, the target must behave like the source:

- inputs: which values are accepted, rejected, defaulted or normalized;
- outputs: values, formats, field names, presence of fields, nulls, order;
- errors: kind, code, message, and when each one occurs, including exceptions;
- side effects that are observable: writes, outgoing calls, events, logs, metrics.

A gap that can change any of these blocks the unit. Never defer it as a detail.

Port the behavior, not the source's structure: the target layout follows the target conventions. An idiomatic choice still follows rule 3.

Claim parity only with evidence from the current run (section 3). Otherwise say `parity not proven` and name the open gap.

## 2. Evidence

- Every statement about source behavior cites `path:line @sha7`. `path` is relative to `source_root` in MIGRATION.md. `sha7` is the first seven characters of `source_sha`.
- Open the cited lines in this run before you cite them. A search hit alone is not evidence.
- The snapshot must match the pin. Run `check.sh pin`. If it does not match, every claim that depends on the source is `blocked` until it matches.
- Do not write the behavior of a framework, library, runtime or language standard from memory. Look first in the dependency source at the pinned version, then in its official documentation. Cite the file and line or the URL, or record the fact as an open item.
- A claim without a citation is a gap, not a fact.
- Names, paths and literals agree across spec, plan and extraction; a mismatch is a finding.

## 3. Evidence ladder

| Level | Evidence | Use |
|---|---|---|
| L0 | Source `path:line`, read in this run | every extracted rule |
| L1 | Derived cases: each branch, boundary and error path of a rule has a test input | tests of the target |
| L2 | Golden: output recorded by running the source on the same inputs | characterization tests |
| L3 | Differential run: source and target run on the same inputs and results are compared | parity claim |

Report the highest level reached for each unit. L1 written by the agent that also wrote the target code does not prove parity by itself.

## 4. Gaps and conflicts

Before you ask anyone anything, read the code path that decides the point: the call order, the exception that aborts, the branch that returns first.

- Technical fact missing (a field, a type, a declaration order, the status a handler returns): name the owner that can settle it in NEEDS (`routing.md`) and stop only the tasks that depend on it. The orchestrator reopens the extraction from the spec or plan stage; a worker never reopens it alone.
- Business or application rule that the source does not settle: stop with `NEEDS: user: <question, quoted>`. Do not invent it.
- The source is silent on a technical choice that callers cannot see (for example, an internal data structure): use best practice, mark it `deviation`, and record the reason and the source. A choice callers can see (an input type, an output format, an error class or category) is a contract choice: it becomes a PEND for the user, never a deviation.
- Conflict between two sources. Take the first case that applies:
  1. A dated user decision in MIGRATION.md or in the spec (a resolved `PEND`, an accepted `ID`). Follow it.
  2. The source at the pinned commit settles it. Build what the source does, cite it, and label the result `Legacy-derived`. If an acceptance criterion says otherwise, label it `Spec correction needed` and do not count it as met.
  3. Otherwise mark the task `blocked` and cite both sides. Never pick one silently.
- Questions follow rules 6 to 10 of section 0. Workers never ask: they end with `NEEDS: user`, and the orchestrator batches the questions into one message, at most 4 per AskUserQuestion call, and says what was checked (`verified:`). A gap is never filled with the behavior of another unit or `endpoint`. A contradiction inside the plan is a plan defect: report it with `NEEDS: migration-planner` and stop only the tasks it affects.

- A `deadline` in MIGRATION.md sets the order of the work and what fits in it. It never changes source behavior or skips a test. When it cannot cover the unit's scope, stop with `NEEDS: user`, offering three options: reduce the scope, extend the deadline, or keep both.

## 5. Markers

- `deviation: <reason and reference>`: the target differs from common practice or a standard, on purpose. Write it as a comment in the target language's syntax, directly above the line.
- `known-issue: <reference>`: the source has a bug that the target keeps. Fixing it is a spec decision.
- A marker without a reason and a reference is a finding.
- Silence a lint rule only on the narrowest scope, with a `deviation` marker that names the rule.

## 6. Scope and secrets

- Non-goals (`NG-`) and anti-goals (`AG-`) in the spec exclude behavior, even when the source has it.
- Never copy secret values (keys, tokens, passwords, client credentials) from the source, the fixtures or the docs into code, tests, logs or reports. Write `<redacted>` and cite where the value is.
- Never write inside the source snapshot. Read it with Read, Grep and ranged reads. Run source code only from a copy outside the snapshot, or with flags that stop cache writes into it (for example `PYTHONDONTWRITEBYTECODE=1`). Send long command output to a file outside the repository and read its tail.

## 7. Stable ids

`BR-<SLUG>-NNN` rule · `FR-NNN` functional requirement · `TS-NNN` target requirement · `PEND-NNN` pending decision · `ID-NNN` planning decision · `T-NNN` task · `RV-NNN` review finding · `DEC-NNN` legacy decision candidate · `ADR-NNN` architecture decision record. Never renumber an id and never reuse one. Withdraw an id by marking it `withdrawn`; do not delete it.

## 8. Verification

- Run the commands the task names. Report the real output: the command, the exit code and the decisive line.
- A gate that did not run is `NOT RUN`, with the exact error. `NOT RUN` is never a pass.
- Say plainly when a stage did not run in this run (for example, no review).
- Say `done` only when the acceptance criteria and the validation command passed in this run.
- Each plan step names its validation command (the target gate or a test command). `task-decomposer` copies it into `validation:`. A step with no command is a plan defect (migration-planner).

## 9. Language

- The project CLAUDE.md sets the language of replies and docs. In the migration project that uses this toolkit, replies and docs are pt-BR, 100%.
- Comments an agent writes inside a review finding, a doc or any artifact: the artifact language (`artifact_language`, pt-BR in that project).
- Comments in code, log messages written by the target code, and commit messages: English.
- Machine keys in reports and artifacts (`Result:`, `Written:`, `Checks:`, `Skills:`, `Open:`, `NEEDS:`, frontmatter keys, ids) stay in English. The prose that follows them is in the reply language.
- Identifiers, literals, paths, `path:line`, SQL, enum values, protocol names and error or validation messages are never translated.

## 10. Language skills

MIGRATION.md names the source and target languages (`source_language`, `target_language`). Load the skill with that name, in lowercase: `golang`, `java`, `python`, `nodejs`, `typescript`, `javascript`, `dotnet`, `rust`, `flutter`. Load the source skill when you read source code, and the target skill when you write target code. If no skill exists for a language, follow its official documentation and report `Skills: none (<language>)`.

## 11. Stop rules

- Stop and report, without guessing, when the snapshot does not match the pin, a required artifact is missing, a dispatch limit is reached, or a `NEEDS` owner is not in the routing table of the orchestrator.
- A `blocked` item never stops the items that do not depend on it.

## 12. Final message contract

At most 12 lines, in this order, and nothing else (survey mode of behavior-extractor returns its candidate list instead of `Written`):

```
Result: <state reached, for example OK, DRAFT or BLOCKED>
Written: <paths>
Checks: <command> -> <exit code and decisive line>, one line per check you ran
Skills: <language skills loaded, or none (<language>)>
Open: <id> <one fact>, at most 3 lines
NEEDS: none | <owner>: <state or fact, quoted>
```

No preamble, no recap, no praise, no file contents. Cite `path:line` instead of quoting code. Keys stay in English; the prose follows the reply language (section 9).

## 13. Legacy decisions and ADRs

A legacy decision (`DEC-NNN`) is a behavior that the legacy code implements on purpose and that contradicts a recognized best practice of the source or the target language. Preserve it, record it, and document why it is kept.

- Intent must show in the legacy code or its repository: a comment, a named constant, a test, a document or a commit message. Cite each piece of evidence as `path:line @sha7`. Without such evidence, the behavior is a `known-issue`, not a `DEC`. While the legacy repository can answer, do not ask the user about the intent.
- The behavior-extractor lists each `DEC` in `extraction.md`, under `## Legacy decisions contrary to best practice`, one line per decision: `- DEC-NNN: <decision>; contrary to: <practice>; source: <official URL or dependency source at the pinned version>; <path:line @sha7>`. When none exists, write `- none found:` followed by the search that was run.
- The migration-planner writes one ADR per `DEC` at `docs/migration/adr/ADR-NNN-<slug>.md`, from the template in `references/templates.md`. Numbers are global, the next free one, and never reused. An ADR has these sections: `Decision`, `Legacy evidence`, `Reason to keep the legacy behavior`, `Best practice contradicted`, `Justification` and `Consequences`.
- `Legacy evidence` cites the legacy lines. `Best practice contradicted` names its source: an official URL or the dependency source at the pinned version.
- The spec, the tasks and the code refer to the ADR id. A test that locks a preserved decision carries the id in its name. Code comments are in English.
- Only the user changes an ADR's status, to `superseded` with `superseded_by: ADR-NNN`, on a dated user decision. A new idea of the agent is a new `DEC`, never an edit to an old ADR.
- `check.sh adr <unit>` validates the ADR files and the coverage: each `DEC` of the unit has an ADR with `candidate: DEC-NNN`, and each ADR of the unit names an existing `DEC`. The plan state is INVALID until this check passes.
