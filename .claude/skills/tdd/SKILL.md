---
name: tdd
description: "Test-first method for the implementer: red-green-refactor, test names that carry the spec id, characterization and golden tests against the source, isolation of external dependencies in unit tests, and the coverage gate."
user-invocable: false
---

# tdd

Test-first method for one migration task. The implementer runs it for `test` and `impl` tasks. A `capture` task follows `references/source-parity.md`. A `verify` task runs the whole gate (section 8). The method is red, green, refactor. Mechanics for the target language (how to run tests, write doubles, load fixtures) come from the target language skill.

## 1. Precedence

1. The unit's `spec.md` and `tasks.md`: test ids and validation commands.
2. `docs/migration/MIGRATION.md`: target conventions and `artifact_language`.
3. The target language skill: tooling and mechanics.
4. This skill and its references.

A test that pins behavior which an idiom of the target would change keeps the source behavior. Mark it `deviation:` or `known-issue:` (migration-conduct section 5) and list it in the report. A business rule the source does not settle is not a test decision: stop with `NEEDS: user` (migration-conduct section 4).

## 2. The three laws

1. Write production code only to make a failing test pass.
2. Stop writing a test as soon as it fails. A compile or load error counts as a failure.
3. Write only the code the failing test needs.

## 3. The loop

Build a test list before the first test. One line per behavior, taken from the spec ids (`TS-`, `FR-`) and from the derived cases of the evidence ladder: each branch, boundary and error path of a rule (migration-conduct section 3, L1). Do not take the list from the code you are about to write. Pick the smallest item.

1. **RED.** Write one test. Predict how it will fail. Run only that test with the task's validation command, narrowed to the test name. The failure must match the prediction and the reason in the spec. If it fails in an unexpected way, check your assumption before going on. Keep the RED output.
2. **GREEN.** Make it pass with the least code. Hard-coded values and branches are fine here. Then add the next test that forces the general case (triangulation). Do not add behavior that no test asks for.
3. **REFACTOR.** Only when the whole suite is green. Remove duplication, improve names, keep behavior. Run the suite after each change.
4. **Stuck.** Red for more than a few minutes: return to the last green state and take smaller steps. Check which changes are yours, and revert only those.
5. Repeat until the task's validation passes.

## 4. Test names and shape

- Name each test for one behavior and carry its spec id in the naming style of the target language. Write the id as the spec does (`TS-003`) where the identifier rules allow a hyphen, otherwise drop the hyphen (`TS003`). Example: `quote_TS003_rejects_negative_weight`.
- One behavior per test. Arrange, act, assert. Two acts with an assert between them mean two tests.
- Assert on outputs and observable effects, not on internal calls. A test breaks when behavior changes, not when structure changes.
- A long arrange block is a design signal. Fix the design before writing the test.
- Each case name is a sentence that describes the behavior. The test output must read as the spec.

## 5. Style

- **Detroit (default):** real objects, doubles only where needed. Use for pure rules: validators, calculators, state transitions.
- **London:** test a use case or a handler with its ports replaced by doubles. Use when the collaborators are external and costly.
- Prefer a fake (a small working implementation) when the real behavior matters and a double would hide it.
- Double only interfaces that the target code owns, declared by the consumer. Never double another package's internals.

Dependency rules and the table: `references/isolation.md`.

## 6. Source parity and bugs

- Before you change code derived from the source, pin its behavior with characterization tests. The source is the truth, even where it is buggy.
- Golden tests compare against fixtures captured from the source. Workflow and comparison rules: `references/source-parity.md`.
- Fix a bug test-first: write a test that reproduces it, see it fail, then fix. The test stays.
- A source bug that the spec keeps is kept and marked `known-issue: <reference>`. Fixing it is a spec decision: report it, do not decide it in code.
- Evidence level: a test written by the agent that also wrote the target code does not prove parity by itself. Golden output recorded from the source is L2. A differential run in this run is L3. Report the highest level reached for the unit.

## 7. External dependencies

Unit tests never reach a real database, network host, queue, cloud service, clock, random source, environment variable or container runtime. Every external dependency sits behind an interface owned by its consumer and is injected. Use a fixed clock, a fixed random source and a configuration built in the test. The full table: `references/isolation.md`.

Integration tests are a separate tier, allowed only when the plan's `## Data migration` or `## Cutover` names them: they run against a disposable container (database, queue) started by the test command, never a shared or production host, sit in their own directory or build tag, and do not count toward unit coverage. Data checks (backfill, reconciliation, dual-write) live in this tier.

- A line that only a real resource can reach means the seam is wrong. Move the logic behind an interface or into a pure function, and test that. Never add a real resource to pass the gate. If the seam cannot be fixed inside the task, the task is `blocked`.
- Tests that need a real resource are outside the unit gate. Do not write them unless the task names them. A requirement that only a real resource can check is an open item in the report.

## 8. Coverage gate

- Threshold: the minimum recorded in an accepted `ID-` decision of the plan. When the plan records none, the default is 90 percent line coverage (the toolkit default). The report names where the number comes from. A plan may set another number. The threshold applies to the unit tests of the code the task creates or changes.
- Count only unit tests, in which every external dependency is a double or a fake. Generated code and generated doubles are excluded only as the target conventions in MIGRATION.md say.
- Before the gate, search the package for the forbidden calls listed in `references/isolation.md` section 2. A hit blocks the task until it is removed; the coverage number does not count while one remains.
- The number is a floor. High coverage with weak asserts proves little. The test list and the red flags are the quality check.
- Compare the coverage ratio with the threshold exactly, not with the rounded value the tool prints.
- A unit or package missing from the coverage profile counts as 0%.
- No test exists only to run lines: each test asserts a behavior.
- A numeric tolerance appears only in an assertion whose name says so.
- Report per package: the command, its exit code, the coverage ratio from the profile, the interfaces doubled, and the tests that used a double. Say which source behavior and which query or protocol text the unit tests did not execute.
- A gate that did not run is `NOT RUN`, with the exact error (migration-conduct section 8).

## 9. Red flags

Stop and fix the process when:
- Code was written before its test.
- A new test passes at its first run. Make it fail first, or drop it.
- The test repeats the implementation: same branches, expected values computed the same way.
- The test doubles a type the target code does not own.
- A test has several acts and asserts.
- The setup needs many collaborators.
- A test reads the real clock, random source, environment, network or database.
- A golden fixture is missing, and the test was skipped, made green, or the fixture was built from the target's output.
- An expected value was edited to match the output.
- A coverage number is reported without its command output.

## 10. Done gate

- A task is `done` only when its `validation:` command passed in this run. Write the command and its decisive result into the task's `evidence:`.
- Report the RED output of each test you wrote, the deviations, the known issues and the open items.
- Never claim a pass that was not run in this run.

## 11. Language

Code, comments and test names are in English. Markers keep their keys: `deviation:`, `known-issue:`. Reports and artifacts follow `artifact_language`. Identifiers, literals, paths and error messages are never translated.

## References

- `references/source-parity.md`: characterization and golden workflow, fixtures, provenance, comparison rules.
- `references/isolation.md`: dependency table, forbidden calls in unit tests, adapter tests.
