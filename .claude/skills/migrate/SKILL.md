---
name: migrate
description: "Orchestrates a code migration between two languages, one unit at a time. Sets up the project (init), reports the state of every unit (status), answers pending decisions (ask), and runs a unit through extraction, spec, plan, tasks, build, review and documentation. Runs only when the user types /migrate."
disable-model-invocation: true
argument-hint: "[init | status | ask [unit] | <unit> [extract|spec|plan|tasks|build|review|doc]]"
allowed-tools: "Bash(sh ${CLAUDE_SKILL_DIR}/scripts/check.sh *), Bash(git clone --no-checkout *), Bash(git -C * checkout --detach *), Bash(git -C * rev-parse HEAD)"
---

# migrate

You are the orchestrator. You run the stages in order, dispatch one worker at a time, and read every result through `check.sh`. The artifacts are the state: there is no state file and no log. To resume after `/clear`, run `/migrate` again.

You do not write migration code, specs, plans, reviews or docs yourself. You run `check.sh`, run intake and the ask flow, and dispatch workers.

## Arguments

`$ARGUMENTS` decides the form:

- empty, or `status`: report the state of every unit.
- `init`: set up the project (`${CLAUDE_SKILL_DIR}/references/intake.md`).
- `ask` or `ask <unit>`: answer pending decisions (`${CLAUDE_SKILL_DIR}/references/ask.md`).
- `<unit>`: run the unit through the stages until it is READY, or until a stop.
- `<unit> <stage>`: run only that stage, after its upstream stages are OK.

A unit id must match `^[a-z0-9]+(-[a-z0-9]+)*$`. Any other value: print the usage and stop.

## Commands

Run the checker from the project root, through the Bash tool, quoted:

```
sh "${CLAUDE_SKILL_DIR}/scripts/check.sh" status <unit>
```

Run it before every decision and after every worker returns. Its output is the only source of states. The stage rules, owners and states are in `${CLAUDE_SKILL_DIR}/references/stages.md` and `${CLAUDE_SKILL_DIR}/references/routing.md`. Read them before the first dispatch.

## Stage loop

1. Run `status <unit>`. Read the state of each stage.
2. Choose the stage:
   - for `<unit>`: the first stage in order (extract, spec, plan, tasks) that is not OK. When every stage through tasks is OK, the unit is READY; continue to build only if the user asked for it.
   - for `<unit> <stage>`: that stage. Every upstream stage must be OK first; if one is not, report it and stop.
3. Freeze check: if any task in `tasks.md` has a status other than `pending`, the build has started. Do not dispatch spec-writer, migration-planner or task-decomposer. Report and stop.
4. Look up the owner of the state in `routing.md`. Dispatch it with the Agent tool, `subagent_type` set to the owner's name. The prompt gives: the unit id, the stage, the artifact path, the path of `docs/migration/MIGRATION.md`, the state line that caused the dispatch, and this line: "Your final message follows the migration-conduct contract."
5. Dispatch one worker and wait for its result before any other step. The result arrives as a notification. Do not check the artifacts or dispatch again before it.
6. When it returns, run `status <unit>` again. Read the `NEEDS:` line of its final message:
   - `none`: continue with step 2.
   - `<owner>: <fact>`, and the owner is allowed by `routing.md` for that worker: dispatch that owner once with the fact quoted. Stop after `limit_dispatch` dispatches of the same owner in this stage.
   - `user: <question>`: stop the unit and run the ask flow.
   - anything else: stop and report.
7. Stop, and report, when the state is BLOCKED with no owner, INVALID after the limit, or STALE after the limit.
8. Documentation sync: once the unit reaches build, review or doc, check the doc state. A doc STALE means the code or a source artifact changed after the doc was written. Dispatch doc-writer (within `limit_dispatch`) once the review is OK, before you report the unit done. The doc follows the code, never the other way around.

## Review loop (`<unit> review`, or the review step of READY)

- The parity-reviewer writes `review.md` with a `round` number. Its `NEEDS` line is `none` when the review is OK, or `implementer: <open RV ids>` when fixes are needed.
- On `implementer`, dispatch implementer in fix mode with the review path and the open RV ids. Then run `status`: the review is STALE, because the code changed.
- Dispatch parity-reviewer again for a new round. Stop after `limit_review_rounds` rounds, or after `limit_fix_rounds` fix dispatches, and report the open RV ids.
- The doc stage runs only when the review is OK.

## Build

`<unit> build` dispatches implementer, which runs the tasks in dependency order and writes each task's status and evidence. If it returns with pending tasks and no `NEEDS`, dispatch it once more within `limit_dispatch`. A `blocked` task does not stop the rest.

## Progress

Print one line per stage in the chat: the stage, the state before, the state after. There is no progress file.

## Rules

- Parameters come from `docs/migration/MIGRATION.md`: `limit_dispatch`, `limit_review_rounds`, `limit_fix_rounds`. Before each dispatch, count the runs of that owner in this stage, including the run after a NEEDS. At the limit, stop and report: a NEEDS fix does not lift the limit.
- Never run a later stage when an earlier one is not OK.
- Never edit an artifact yourself, except MIGRATION.md during `init` (`references/intake.md`). A decision reaches an artifact only through its owner.
- Decisions: classify each open point as a fact, a conduct default or a user choice (`references/ask.md`, section 2). Facts and conduct defaults go to the owner with their kind and evidence. Only user choices are asked, and you never decide one yourself.
- Questions follow migration-conduct rules 6 to 10: the legacy code, the dependency source and the docs are checked first; no irrelevant question; every question lists what was checked (`references/ask.md`). A `NEEDS: user` about legacy behavior with no legacy path in `verified:` goes back to behavior-extractor (`references/routing.md`).
- Legacy decisions (`DEC-`) become ADR files in the plan stage (`docs/migration/adr/`). The plan is INVALID until `check.sh adr <unit>` is OK (`references/stages.md`).
- A unit is never reported done while its doc is STALE.
- Background runs: for a scripted run, set `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` so that each worker finishes before the next step starts.
- The report to the user is in the reply language of the project CLAUDE.md (pt-BR in the migration project). It names the unit, the stages run, the final states, the open items and each `NEEDS` line.
- Every `status` run prints the deadline (`deadline` in MIGRATION.md). An `OVERDUE` deadline goes into the report as a warning. A deadline sets priority and scope, never fidelity (`references/routing.md`, Deadline).
- Commits, pushes and pull requests are outside this skill. Make them only when the user asks in those words, and never on `main` or `master`.
