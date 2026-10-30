---
name: nodejs
description: "Node.js 22 and later (LTS) for code that runs on Node: ESM and CommonJS, built-in node:test, fetch and AbortSignal, errors and exit codes, numeric parity (IEEE-754, toFixed and Math.round tie rules, no native decimal), and the quality gate. Use for Node.js code, package.json, node --test suites, or migrations to or from Node.js."
metadata:
  baseline: "Node.js 22 LTS (v22.23.x docs)"
  verified: "2026-10-29"
---

# nodejs (Node.js 22+)

Practice for code that runs on Node.js. The baseline is Node.js 22 LTS. Facts here were checked against the Node.js 22 API docs and the ECMAScript specification on 2026-10-29. Sources are listed at the end.

## 1. Scope and versions

- Target the version the repository declares: `engines.node` in `package.json`, or `.nvmrc`. If it declares none, use `>=22` and say so in the report.
- Node.js 22 is LTS. The Node.js releases page listed v22, v24 and v26 as LTS on 2026-10-29. Production code uses an LTS line.
- New code is ESM: `"type": "module"` in `package.json`, or `.mjs` files. Keep CommonJS only where the repository is CommonJS. Do not mix both in one package without a reason.
- Flags have stability levels. Before you use a flag, check its stability in the docs of the version you target (section 9).

## 2. Layout and build

- `package.json` has `name`, `type`, `engines`, `exports` for packages, and `scripts` for `test`, `lint`, `format:check` and `check`.
- Commit the lockfile of the repository's package manager. Do not add a second manager.
- Plain ESM needs no build step. If the target needs a bundler, name the reason in the plan.
- Split by responsibility: pure modules (no I/O) for logic, thin adapters for files, network and environment. Tests import the pure modules directly.

## 3. Idioms

- Built-in modules use the `node:` prefix: `node:fs/promises`, `node:path`, `node:test`, `node:assert/strict`.
- HTTP: the global `fetch`, with `AbortSignal.timeout(ms)` for a deadline. `AbortSignal.any([...])` combines signals (since v20.3).
- Paths in ESM: `import.meta.dirname` and `import.meta.filename` (since v21.2 and v20.11; no longer experimental since v22.16). Do not use `__dirname` in ESM.
- Copies: `structuredClone(value)`. It throws on functions and turns class instances into plain objects (the prototype is lost). Check the input shape first.
- Command-line flags: `util.parseArgs` (stable since v20). No argument-parsing dependency for a simple CLI.
- Environment: read `process.env` in one config module, with defaults and validation at start. `--env-file=<file>` loads a file (no longer experimental since v22.21). Never log a secret value.
- JSON: `import data from './x.json' with { type: 'json' }`. The attribute is mandatory (JSON modules are not experimental since v22.12).

## 4. Errors, exit and resources

- Throw `Error` instances, never strings. Attach the cause: `throw new Error('message', { cause })`.
- Give each error a stable `code` string when a caller must branch on it. The code is part of the contract: map every source exception to one code.
- Library code sets `process.exitCode`; it does not call `process.exit()`, so pending writes can flush.
- Unhandled promise rejections throw by default (since v15). Every promise is awaited, returned, or has a `.catch`.
- Close handles in `finally`: file handles, streams, servers, timers.

## 5. Concurrency

- One event loop. CPU-bound work blocks every request; move it to `worker_threads` or to another process.
- Fan-out: `Promise.all` keeps input order in its result and rejects on the first failure. `Promise.allSettled` returns each outcome. `Promise.any` returns the first success.
- Limit parallel work with a small loop over a queue; add a dependency only if the repository already has one.
- Timers: `setTimeout` from `node:timers/promises` inside `async` code. Clear every interval you create.
- A read, an `await`, then a write on shared state is a race. Keep such a section synchronous, or guard it.

## 6. Data and numbers (parity traps)

- Numbers are IEEE-754 doubles. Integers are exact only up to `Number.MAX_SAFE_INTEGER` (2^53 - 1). For money, use integers in minor units (`BigInt` or safe integers with a range check), or decimal strings with a fixed scale. Never floats.
- `Number.prototype.toFixed(d)`: the ECMAScript specification (21.1.3.3) picks the closest integer, and on a tie the larger one, working on the absolute value after the sign is removed. So ties round away from zero: `(2.5).toFixed(0)` is `"3"` and `(-2.5).toFixed(0)` is `"-3"`. It uses the exact binary value, so `(1.005).toFixed(2)` is `"1.00"`.
- `Math.round(x)` rounds ties toward +infinity: `Math.round(-2.5)` is `-2`.
- Half-even (banker's) rounding is not built in. Implement it on integers or on decimal strings, and test both tie directions.
- `JSON.parse` turns numbers above 2^53 into inexact doubles. When the source keeps exact integers, carry them as strings or `BigInt`.
- Strings are UTF-16. `.length` counts code units, not user-perceived characters. `Buffer` holds bytes; `TextEncoder` and `TextDecoder` convert.
- Dates: store instants as ISO 8601 in UTC. Format with `Intl.DateTimeFormat` and an explicit `timeZone`. Never depend on the process time zone.

## 7. Testing

- Runner: `node:test`. Use `describe`/`it` or `test`. Assertions: `node:assert/strict`.
- Run: `node --test` (default discovery: `**/*.test.js`, `**/test/**/*.js` and similar), or pass glob patterns in double quotes: `node --test "test/**/*.test.js"`.
- Time: `context.mock.timers.enable({ apis: ['setTimeout'] })` inside a test; call `tick`.
- Doubles: `mock.fn()` and `mock.method(object, 'name')`. For `fetch`, inject the function through the constructor or a parameter; do not patch the global.
- Golden tests: load the recorded output from a file, compare parsed values with `deepStrictEqual`. Never regenerate the golden from the new code.
- Test names state the rule id or behavior; one behavior per test.

## 8. Quality gate

Run each command, read its result, and report the real output. A gate that did not run is not a pass.

1. `node --version`: v22.x or later, matching `engines`.
2. Install from the lockfile: `npm ci` (or the repository's frozen-install command).
3. Format: `npx prettier --check .` only if the repository uses Prettier.
4. Lint: `npx eslint .` only if the repository uses ESLint.
5. Tests: `node --test`. The exit code must be 0.
6. Coverage, when the plan sets a minimum: `node --test --experimental-test-coverage`, then read the summary line. The threshold flags `--test-coverage-lines` and related ones are experimental in 22 (stability 1, since v22.8); state that in the report when you use them.

## 9. Migrating TO Node.js

- Parity beats idiom. Choose an idiom only when inputs, outputs and errors stay the same. Otherwise keep the source behavior, and mark the difference `deviation` with its reason and its source.
- Map each source construct to a Node idiom with `references/as-target.md`.
- Keep the source's numeric, string and date semantics (section 6). Write a test for each tie, each boundary and each error path before you write the code.
- Keep the error model: one `code` per source exception, and the same message text when the source has a stable message.
- Keep the source's public names only when an external caller depends on them. Otherwise use idiomatic names and record the mapping.

## 10. Migrating FROM Node.js

- Read `references/as-source.md` for the places where Node behavior hides: time zones, floats, unhandled rejections, event ordering, and encoding.

## 11. Anti-patterns

- `require` or `__dirname` inside an ESM file.
- `process.exit()` inside a library module.
- Floats for money, or `toFixed` used as a rounding rule without a note on its tie direction.
- A `Promise` that is neither awaited nor caught.
- `readFileSync` or `execSync` in a request path.
- `JSON.parse` of an untrusted body with no size limit.
- A global `fetch` patch in a test instead of an injected function.
- A `setInterval` without a matching clear.

## Library registry

- Registry: https://www.npmjs.com/ (package pages show versions, `engines`, license, maintainers and last publish date).
- Before adding a package, check the built-in modules first (`node:test`, `fetch`, `node:util`, and so on). Then search npm, open the package page, and confirm: latest version, `engines.node` compatible with the target Node.js line, license, last publish, and open issues.
- Read the exact versions with `npm view <package> version engines` and pin them. Commit the lockfile.
- Full procedure and evaluation checks: `.claude/skills/migration-conduct/references/library-research.md`.

## Sources

- npm registry: https://www.npmjs.com/
- Node.js 22 documentation, `test`, `cli`, `modules`, `esm`, `globals`, `util` pages: https://nodejs.org/docs/latest-v22.x/api/
- Node.js releases page (LTS status): https://nodejs.org/en/about/previous-releases
- ECMAScript 2027, Number.prototype.toFixed (21.1.3.3) and ToUint8Clamp (7.1.14): https://tc39.es/ecma262/
