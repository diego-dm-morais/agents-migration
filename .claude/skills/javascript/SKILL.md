---
name: javascript
description: "JavaScript (ECMAScript 2026, 17th edition, as run by current browsers and Node.js 26 LTS): loose equality, NaN and -0, IEEE-754 numbers, toFixed and Math.round tie rules, UTF-16 strings, zero-based Date months, default sort, promise and async ordering. Use for .js and .mjs code, and for migrations to or from JavaScript."
metadata:
  baseline: "ECMAScript 2026 (17th edition, June 2026), as run by current browsers and Node.js 26 LTS; language only"
  verified: "2026-10-29"
---

# javascript (ECMAScript 2026 (17th edition, June 2026), as run by current browsers and Node.js 26 LTS; language only)

Practice for JavaScript as a language: values, coercion, numbers, strings, dates, sorting, and promise and async ordering. The baseline is ECMAScript 2026 (17th edition, June 2026), as run by current browsers and Node.js 26 LTS. Facts were checked on 2026-10-29 against the ECMAScript specification, MDN, and runtime probes on Node.js 22.23.1. Runtime APIs (files, network, timers, process) belong to the nodejs skill. Sources are listed at the end.

## 1. Scope and versions

- Target the runtime the repository declares: `engines.node` in `package.json`, `.nvmrc`, or the browser list. If none is declared, use Node.js 26 LTS (current LTS; Node.js 22 is in Maintenance LTS until 2027-04-30) and say so in the report.
- The latest published edition is ECMAScript 2026, the 17th edition (ecma-international.org, June 2026). The living draft at tc39.es is ECMAScript 2027 (verify before use: its "living draft" label was not read). Use the draft only to read clause text, and say which text you used.
- Check each feature before use. MDN gives the baseline year. A runtime probe is the final check: `node -p "typeof Promise.try"` printed `undefined` on Node.js 22.23.1, although MDN marks `Promise.try` Baseline 2025.
- On Node.js 22.23.1 (probe, 2026-10-29), these are functions: `Object.groupBy`, `Promise.withResolvers`, `Array.prototype.toSorted`, `Set.prototype.union`, `Array.fromAsync`.
- A probe settles only the Node.js version it ran on. Re-run the probe before a parity claim on another runtime.

## 2. Layout and build

- Use one module per file with named exports. Name the module system the package uses: `"type": "module"` or `.mjs`. Do not mix module systems in one package without a reason.
- Separate pure logic (no I/O, no clock, no randomness) from adapters. Tests import the pure modules.
- Keep module-level variables out of pure modules. A variable that lives across calls is state: migrate it as state, with its own tests.
- Keep generated and vendored code out of the pure modules, and exclude it from the coverage target in the plan.
- Commit the lockfile of the package manager the repository already uses. Do not add a second manager.
- Plain ES modules need no build step on Node.js 22. Name the reason in the plan if a bundler is added.

## 3. Idioms

- Compare with `===` and `!==`. Use `Object.is` only when NaN or -0 must be told apart: `Object.is(NaN, NaN)` is `true`, `Object.is(0, -0)` is `false` (probe).
- Test NaN with `Number.isNaN(x)`. The global `isNaN` converts first: `isNaN("hello world")` is `true`, `Number.isNaN("hello world")` is `false` (MDN NaN).
- Sort a copy with `toSorted()` (MDN baseline July 2023). `Array.prototype.sort()` sorts in place and returns the same array (MDN Array/sort). Probe: after `[3, 1, 2].toSorted()` the original is still `[3, 1, 2]`.
- Group with `Object.groupBy` (MDN baseline March 2024). The result has a null prototype (probe: `true`).
- Wrap errors with the `cause` option: `new Error("message", { cause })` (MDN Error/cause, baseline since September 2021). Probe: `withCause.cause.message` returned the inner message.
- Use `Set.prototype.union` for set union (MDN: Baseline 2024, newly available June 2024). Check older browsers before use.
- Use `Map` for keys that are not strings. Key equality is SameValueZero (see references/semantics-and-coercion.md).
- Convert to text with `String(value)`. For -0 it gives `"0"`, the same as the template literal `${-0}` (probe).

## 4. Errors, resources and exit

- Throw `Error` instances. The language accepts any value: probe `throw "plain string"` ran, and the catch received a string. A migrated unit keeps the source's error kinds, not the language default.
- Give each error a stable `code` string when a caller must branch on it. This is a design convention, not a language rule. Record it as a choice.
- Set `cause` when wrapping an error, so the original stays reachable. `cause` is not enumerable (MDN Error/cause: Enumerable no), so spreading the error does not copy it.
- An `async` function that throws returns a rejected promise, and `await` rethrows the same error at the call site (probe).
- Keep the source's error text when the source returns it to a caller: the message is part of the output, punctuation included.
- Keep one test per error kind the source raises, each asserting its `code`, and its message text when the source has a stable one.
- Release resources in `finally` in the caller's code.
- A rejected promise that is never awaited, returned or caught is a defect of the migrated code. See references/async-and-ordering.md.

## 5. Concurrency

- JavaScript runs one job at a time on one thread. Concurrency here means the order of promise jobs (references/async-and-ordering.md).
- Fan-out: `Promise.all` rejects with the first rejection (MDN Promise/all, fail-fast). It resolves with values in input order (probe). Use `Promise.allSettled` when each outcome is needed; it also keeps input order (probe: statuses `rejected`, `fulfilled`).
- Collect results in input order when the source does (`Promise.all`). Record completion order only when the source logs or emits it.
- Limit parallel work with a small loop over a queue in the code. Add a library only if the repository already has one.
- Test the parallel limit as a parameter: one call at a time, then several, and compare the results.
- A read, an `await`, then a write on shared state can interleave with another job. Keep that section free of `await`, or guard it.

## 6. Data and numbers (parity traps)

- Numbers are IEEE-754 binary64 doubles (ECMAScript 4.4.23, verify before use). `Number.MAX_SAFE_INTEGER` is `9007199254740991`. `2 ** 53 + 1 === 2 ** 53` is `true` (probe). `Number("9007199254740993")` and `JSON.parse("9007199254740993")` both give `9007199254740992` (probe). `BigInt("9007199254740993")` keeps every digit (probe).
- `0.1 + 0.2` is `0.30000000000000004` (probe). For money, use integers in minor units, `BigInt`, or decimal strings with a fixed scale. Never floats.
- Text to number: `Number("")` is `0`, `Number(" 12 ")` is `12`, `Number("12px")` is `NaN`, and `Number("0x1A")` is `26`; `parseInt("12px", 10)` is `12` and `parseInt("0x1A", 10)` is `0` (probe). Record which one the source calls, and test each input class.
- `toFixed(d)` (ECMAScript 21.1.3.3, verify before use): it removes the sign, picks the integer closest to the exact binary value, and on a tie picks the larger integer. `(2.5).toFixed(0)` is `"3"`, `(-2.5).toFixed(0)` is `"-3"`, `(0.5).toFixed(0)` is `"1"`, `(1.005).toFixed(2)` is `"1.00"` (probe). A `d` outside 0 to 100 throws RangeError (MDN).
- `Math.round(x)` (ECMAScript 21.3.2.29, verify before use): on a tie it returns the value closer to +infinity. `Math.round(-2.5)` is `-2`, `Math.round(-3.5)` is `-3`, `Math.round(0.49999999999999994)` is `0` (probe). It is not `Math.floor(x + 0.5)` (spec Note 2).
- The two functions agree on positive ties and disagree on negative ones: `Math.round(-2.5)` is `-2`, while `(-2.5).toFixed(0)` is `"-3"` (probe). Test negative ties on each path.
- Half-even rounding is not built in. `Uint8ClampedArray` rounds half to even (ECMAScript 7.1.12 ToUint8Clamp, 17th edition): `[0.5, 1.5, 2.5, 3.5]` becomes `0,2,2,4` (probe). Implement half-even on integers or decimal strings, and test both tie directions.
- Strings are sequences of UTF-16 code units. `"\u{1F600}".length` is `2` and `[..."\u{1F600}"].length` is `1` (probe; MDN String/length).
- Dates: months are zero-based, so January is `0` (MDN Date shows December as `11`; verify before use). Out-of-range parts carry over: `Date.UTC(2026, 1, 31)` is `2026-03-03T00:00:00.000Z` (probe). Store instants as UTC ISO 8601. Format with `Intl.DateTimeFormat` and an explicit `timeZone` (MDN, baseline since September 2017; probe with `timeZone: "UTC"` gave `1/31/2026`).
- Default sort compares strings by UTF-16 code units: `[10, 9, 1, 80].sort()` is `[1, 10, 80, 9]` (MDN Array/sort; probe). For numbers pass a comparator such as `(a, b) => a - b`. `undefined` elements sort to the end.
- Keep the source's comparator. The default comparator sorts code units, so a source that sorts by another key needs that key in the comparator, tested on ties.
- `Map` and `Set` compare keys with SameValueZero: `NaN` equals `NaN`, and `-0` equals `0` (probe).
- `JSON.stringify` drops `undefined` object fields, turns `NaN` and `Infinity` into `null`, and throws a TypeError on `BigInt` (probe). `Date` defines `toJSON`, so a date serializes as an ISO string (probe).

## 7. Testing

- Use the runner the runtime provides: `node:test` on Node.js (see the nodejs skill), with `node:assert/strict`. One behavior per test, named with its rule id.
- Test each tie, boundary and `-0` or NaN input the source can produce, in both directions.
- Test the empty input, the single-element input and the largest input of each collection rule.
- Assert the sign of zero with `Object.is` when the source can show it: `assert.equal(Object.is(Math.round(-0.4), -0), true)` passes on Node.js 22.23.1.
- Inject clocks, randomness and I/O as parameters. Never patch a global in a test.
- Keep each test independent of the others: no test reads a value that another test wrote.
- With process-level isolation enabled, `node --test` runs each test file in its own child process (Node.js 22 test docs). A file cannot change another file's result through shared state.
- Golden tests load recorded source output from a file and compare parsed values with `assert.deepStrictEqual`. Never regenerate the golden from the new code.
- Name each golden file after its case (`case-01.json`), so a failing case names its own recorded input and output.
- Details: references/testing-and-tooling.md.

## 8. Quality gate

Run each command, read its result, and report the real output. A gate that did not run is not a pass.

1. `node --version`: v22.x or later, or the version in `engines`. Probe: `v22.23.1`, exit 0.
2. `node --test`: exit code 0 and `# fail 0`. Node.js runs each matching file, and a file that exits non-zero fails (Node.js 22 test docs). Probe: `# pass 3`, `# fail 0`, exit 0.
3. `npx prettier --check .`: exit 0 when all files are formatted, exit 1 when some are not (prettier.io/docs/cli). Run only when the repository uses Prettier.
4. `npx eslint .`: lints the current directory (eslint.org CLI docs). Run only when the repository uses ESLint.
5. When the repository has no Prettier or ESLint config, steps 3 and 4 are not run and are reported as not run.

Record each command with its exit code and its decisive line in the report. A command that was not run is reported as not run. A JSON number above 2^53 loses digits when parsed (probe), so store such source values as strings in the golden file.

Keep the gate commands in the repository's `package.json` `scripts`, so that a run of the repository executes the commands listed here.

## 9. Migrating TO JavaScript

- Parity beats idiom. Choose an idiom only when inputs, outputs and errors stay the same. Otherwise keep the source behavior and mark the difference `deviation`, with its reason and source.
- Map each source construct with references/as-target.md. The constructs a migrated unit usually needs are rounding (section 6), text (UTF-16 length, normalization, default sort order), dates (zero-based months, time zones), errors (`code`, `cause`, rejections), I/O (`fetch`, files, environment, through the nodejs skill), and collections (arrays, `Map`, `Set`, plain objects with their key order).
- Keep the source's numeric, string, date and sort semantics (section 6). Write a test for each tie, boundary and error path before the code.
- Write the golden tests from the source's recorded outputs first, then the code that must match them.
- Migrate one rule at a time. A rule is done when its tests pass against the source's recorded outputs, not when the code looks equivalent.
- Keep the error model: one `code` per source exception, and the same message text when the source has a stable message.
- Keep the source's public names only when an external caller depends on them.
- Name each target function after the source function it replaces, unless the target language rules forbid the name.

## 10. Migrating FROM JavaScript

- Read references/as-source.md first. Behavior hides in these places:
  - runtime defaults: the default sort comparator, and date formatting with no `timeZone` (verify before use);
  - implicit conversions: `[] == false` is `true`, and `null == 0` is `false` while `null >= 0` is `true` (probe);
  - ordering: promise jobs run first in, first out, so a `.then` chain can interleave with another chain (references/async-and-ordering.md);
  - encodings: `.length` counts UTF-16 code units, and `normalize()` is not applied unless the code calls it (probe);
  - time zones: local-time `Date` methods use the environment's time zone (MDN Date).
- Read references/semantics-and-coercion.md for comparisons and numbers, and references/async-and-ordering.md for promise order.
- Read references/testing-and-tooling.md before writing the target's tests: it defines the golden layout and the gate commands.
- The source's test fixtures and golden files show the inputs its authors chose. They do not show the whole behavior, so cover the boundaries and ties of each rule as well.
- List each host call the source makes (network, files, clock, randomness). Each one is an input of the migrated unit, and its tests give it an injected stand-in.
- Mark each host-dependent behavior (timers, process queues, I/O) for the nodejs skill.

## 11. Anti-patterns

- `==` where the source compares strictly. `[] == false` is `true` and `"" == 0` is `true` (probe).
- `x === NaN` as a test for NaN.
- `Object.is` as a general equality operator. `Object.is(0, -0)` is `false` while `0 === -0` is `true` (probe).
- `Math.round` used as half-even, or as half-away-from-zero for negative ties.
- `toFixed` as the money rounding rule, with no note on its tie direction.
- `sort()` on numbers without a comparator.
- `new Date(y, m, d)` with 1-based months, or month overflow left unchecked.
- `.length` used to count the characters a user sees.
- `parseInt` where the source calls `Number`, or the reverse: `Number("12px")` is `NaN` and `parseInt("12px", 10)` is `12` (probe).
- `JSON.parse` of an integer field that the source keeps exact, with no string form: `JSON.parse("9007199254740993")` is `9007199254740992` (probe).
- A promise that is neither awaited, returned nor caught.
- Code that depends on the order of two independent promise chains.
- `JSON.stringify` of values with `undefined` fields, `NaN`, `Infinity` or `BigInt`, with no replacer and no test.

## Sources

- ECMAScript 2026 (17th edition), publication page: https://ecma-international.org/publications-and-standards/standards/ecma-262/
- ECMAScript 17th edition HTML: https://262.ecma-international.org/17.0/index.html (did not index in this run)
- ECMAScript living draft (clauses 4.4.23, 7.1.14, 21.1.3.3, 21.3.2.29, 23.1.3.30, 27.5.1.8, 27.5.2.1): https://tc39.es/ecma262/. Clause numbers come from this draft; verify them against the 17th edition before a parity claim.
- MDN JavaScript reference: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/ (pages: Number/toFixed, Math/round, Array/sort, Array/toSorted, Object/groupBy, Promise/all, Promise/withResolvers, Promise/try, Set/union, Date, String/length, NaN, Operators/Equality, Error/cause, Intl/DateTimeFormat, Statements/throw)
- Node.js 22 test runner: https://nodejs.org/docs/latest-v22.x/api/test.html
- Node.js release schedule (Node.js 26 LTS from 2026-10-28; Node.js 24 LTS from 2025-10-28; Node.js 22 Maintenance LTS from 2025-10-21, end-of-life 2027-04-30): https://github.com/nodejs/release#release-schedule
- Prettier CLI: https://prettier.io/docs/cli. ESLint CLI: https://eslint.org/docs/latest/use/command-line-interface
