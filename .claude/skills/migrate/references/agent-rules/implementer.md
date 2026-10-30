# implementer: rules, UI units and architecture mode

Read by `implementer` before its first step (its prompt points here). Each section applies when its heading says so.

## UI units (platform web or mobile)

Read `unit_platform` and `unit_kind` from `docs/migration/MIGRATION.md`. For `backend`, ignore this block.

- Component or widget tests render the unit in isolation. The router is mocked: a navigation is asserted as a call with its target and params, never performed.
- Time is faked (fake timers, a fixed clock) for every debounce, animation, timeout and polling. A test never waits on real time.
- Locale is fixed in each test (the locale the source test or the spec names). Strings are asserted by key or by the literal the source has.
- The viewport is fixed in each test that depends on layout or breakpoints (width and height the plan names). Platform APIs (camera, location, storage, `Platform`) are replaced by fakes.
- A UI test never reaches a real backend, a real browser storage shared between tests, or a real device.

## Rules

- Write code and tests only in `target_root`, in the files that a task lists in `files:`. In `tasks.md`, change only the `status:` and `evidence:` lines. Never edit `spec.md`, `plan.md`, `extraction.md`, `review.md` or any doc.
- Behavior comes from the spec (`FR-`, `TS-`) and from the source at `path:line @sha7`. Never change it to follow a best practice. An idiomatic choice is allowed only when inputs, outputs and errors stay the same. Mark it `deviation:`; mark a kept source bug `known-issue:`. Each marker has a reason and a reference.
- Legacy fidelity (conduct rule 10): keep legacy behavior even when it is not idiomatic; name each test of an ADR-backed behavior with its ADR id; never fix a legacy quirk without its decision. In fix mode, revert changes toward best practice.
- Unit tests never reach a real database, network host, queue, cloud service, clock, random source or environment variable (`tdd` section 7). Never add a real resource to pass the gate.
- A line that only a real resource reaches means the seam is wrong. Move the logic behind an interface or into a pure function. If that cannot be done inside the task, the task is `blocked`.
- Git: follow `migration-conduct` section 6a.
- A technical fact that the extraction lacks: block the task and report it in `Open:`. The extractor is not an allowed NEEDS owner for this worker.
- A business rule or a contract choice (input type, output format, error class, error category) that the source does not fix: read the code path first (migration-conduct section 4), then stop with `NEEDS: user`. Never choose the behavior yourself.
- A conflict between two sources: apply migration-conduct section 4 in order. When it does not settle the conflict, mark the task `blocked` and cite both sides.
- A change needed in the spec, the plan or the tasks after the first task has started is reported with `NEEDS: user`, because the freeze stops the unit (stages.md).
- Never copy a secret value. Write `<redacted>` and cite where it is. Never write into the source snapshot; read it with Read, Grep and ranged reads.
- Never ask what the source or the plan settles; a default that changes no result is taken, not asked.
- Never ask the user directly, and never dispatch another agent.
- Report the real output of each command. `NOT RUN` is never a pass.
- Comments in code are in English. Text in `evidence:` and the reasons is in `artifact_language`. Identifiers, literals, paths and error messages are never translated.
- A `deadline` sets the order of the work. It never skips a test, a gate or a characterization test.
- Use only your listed tools and skills. Finished code has no TODO and no dead code: delete code that no behavior needs.
- Read the spec and extraction sections a task cites before changing its files. A failed final gate resets the owning task to `in_progress`.
- Productivity (conduct rule 12): write the smallest code that makes the failing test pass, and nothing the spec or the tests do not need. Run the narrowest check that proves each step, and leave the whole gate to the `verify` task. Review your diff against the cited `FR-` and `TS-` before `done`. Never skip a test or a gate for time.
