# Ask flow

Read this for `/migrate ask`, and when a stage stops with `user: <question>` or a state with no owner.

## 1. Collect the open decisions

- Run `status` (all units, or the unit named). Each unit with a BLOCKED spec has an open blocking decision.
- Read the `PEND-` blocks in `spec.md` with an empty `resolution`, and the `ID-` blocks in `plan.md` with `status: proposed`.
- Add each `user: <question>` returned by a worker in this session.

## 2. Classify each open decision first

Every open decision is one of three kinds. Classify it before you do anything else. Legacy first (conduct rule 10): if the legacy code answers the decision, it is a fact, however it was phrased.

- **Fact.** What the code, the library or the runtime does. Its owner (section 3) answers it by reading or executing the source at the pin, and records the evidence (`path:line @sha7`, the captured output, or the URL). A fact is never a question to the user.
- **Conduct default.** A point that the migration conduct already decides: keep the source behavior (conduct rule 3), keep a source bug as `known-issue` (section 5 of the conduct), copy the observable error messages (section 1 of the conduct). Record it with the rule number, the evidence and the note "reversible: the user may change it". Never ask the user for it.
- **User choice.** Anything the conduct does not decide: a different input type or format, a different error class or category, fixing a source bug, dropping a behavior, adding a dependency. Only these are asked.

## 3. Answer facts and conduct defaults

The orchestrator does not read code. It hands each fact to its owner, and the owner answers it in this order, stopping at the first answer (conduct rule 6):

1. The implemented code: the source at the pinned commit (open the lines, cite `path:line @sha7`) and the target code already written.
2. The dependency source at the pinned version: lockfile, vendored code, or the package cache. Cite `path:line`.
3. The official documentation. Cite the URL.
4. MIGRATION.md and the artifacts already written.

Running the source to answer a fact is allowed only from a copy outside the snapshot, or with the interpreter flags that stop it writing caches into the snapshot (for example `PYTHONDONTWRITEBYTECODE=1`). Record the exact command and its output.

## 4. Ask the user only the user choices

- Ask only the user choices that change what gets built.
- Each question states `verified:` (the paths, lines, URLs and captured outputs you checked) and `why not in the sources:`. A question without `verified:` is not sent.
- Group up to 4 questions in one AskUserQuestion call. Put the recommended option first and mark it "(Recommended)".
- A user choice with no bearing on the result is not asked. Record its default as a PEND with `blocking: no` and list it in the report.
- A question about behavior that the legacy code implements is not asked. Send it back to behavior-extractor (`routing.md`), which answers with the `path:line @sha7` that shows it (conduct rule 10).

## 5. Record the answers

- Dispatch spec-writer (for PEND entries) or migration-planner (for ID entries) once, with every resolution quoted and tagged with its kind. Only while no task has started (freeze, `stages.md`); after the freeze, report the decisions to the user and stop:
  - `resolved by user, <date>` for a user choice;
  - `default by conduct rule <n>, reversible, <date>` for a conduct default;
  - `fact: <evidence>` for a fact.
- The orchestrator never writes an artifact and never decides a user choice itself. It hands the owner the resolutions it was given, and the owner cites them.
- A user answer to a question that behavior-extractor raised: dispatch behavior-extractor once with the answer quoted and tagged with its kind. It records the answer in `extraction.md` and sets the status again. Then run `status`.

## 6. Resume

Run `status <unit>`. Continue the stage loop from the first stage that is not OK.
