Read this when you write TypeScript tests, choose a test runner, or set up the gate commands for a TypeScript unit.

# Testing and tooling (TypeScript 7.0)

The repository's own runner and scripts decide. The commands below were run on 2026-10-29 (Node v22.23.1, npm 11.17.0, tsc 7.0.2) or are cited from the official docs of the tool.

## Layout

- `test/<unit>.test.ts` for rule tests, one file per unit.
- `test/golden/<unit>/<case>.json` for recorded source outputs. Write each golden file from the source, never from the target.
- A test name carries the rule id when the migration has one, for example `BR-ROUND-002 rounds ties to even`.

## Runners

- `node --test` (node:test) needs no dependency. In Node 22 it finds `**/*.test.ts`, `**/*-test.ts`, `**/test/**/*.ts` and others by default, unless `--no-experimental-strip-types` is passed (https://nodejs.org/docs/latest-v22.x/api/test.html).
- An ES `import` in a `.ts` test did not fail on Node v22.23.1 without `"type": "module"` (verified 2026-10-29): with `package.json` set to `{}`, `node --test` printed `# pass 1` and `# fail 0`, exit 0, and `node test/a.test.ts` exited 0. The packages page documents syntax detection (enabled by default since v22.7.0) only for `.js` and extensionless files; `.ts` is not documented there (https://nodejs.org/docs/latest-v22.x/api/packages.html).
- Test structure with node:test, as documented (https://nodejs.org/docs/latest-v22.x/api/test.html):

```ts
import { describe, it } from "node:test";
import assert from "node:assert/strict";
// import { roundHalfEven } from "../src/round.ts"; // placeholder: the unit under test

describe("BR-ROUND-002", () => {
  it("rounds ties to even", () => {
    const actual = "2"; // placeholder: roundHalfEven("2.5") in the real test
    assert.equal(actual, "2");
  });
});
```

- Vitest: `npm install -D vitest`, then `vitest run` for one run without watch. Vitest needs Node 22.12.0 or later (https://vitest.dev/guide/). The guide does not describe the TypeScript setup: verify before use.
- Jest: TypeScript runs through Babel (`@babel/preset-typescript`) or ts-jest (`npm install --save-dev ts-jest`). `npm test` runs the `test` script, for example `"test": "jest"` (https://jestjs.io/docs/getting-started). The Babel preset page does not say whether it type-checks (verify before use), so keep `tsc` in the gate.

Choose the runner the repository has. Add one only when the plan names it. Node's runner needs no install; Vitest and Jest bring their own configuration and transforms.

## Doubles and fakes

- Depend on an `interface` and inject it through a constructor or a parameter. Do not patch globals in a test.
- A typed fake is an object literal typed as the interface. The compiler checks it: `interface Clock { now(): number }` with `const fake: Clock = {};` gives TS2741 "Property 'now' is missing" (verified). Add every member the code calls.
- Timers in node:test: `mock.timers.enable({ apis: ["setTimeout"] })` (https://nodejs.org/docs/latest-v22.x/api/test.html names the `MockTimers` class and this call). Enable only the APIs the test uses. Verify the method that advances the clock on that page before use.

## Golden comparison

- Read the golden file, parse it through a validator (references/runtime-validation.md), and compare with `assert.deepStrictEqual` from `node:assert/strict`.
- Compare exact values as strings or `bigint`. A `number` above 2^53 - 1 loses digits (verified).
- A missing golden file fails the test. Never create it from the target's output.

## Gate commands

| Gate | Command | Pass means | Run on 2026-10-29 |
|---|---|---|---|
| Compiler version | `npx tsc --version` | Prints the declared version | `Version 7.0.2` |
| Install | `npm ci` | Exit 0 with a lockfile in sync (https://docs.npmjs.com/cli/v11/commands/npm-ci) | not run on a unit |
| Type check | `npx tsc --noEmit -p tsconfig.json` | Exit 0, no output | clean file: exit 0; `const n: number = "x";`: exit 1, TS2322 |
| Tests (script) | `npm test` | Exit 0; the runner's summary shows no failures | not run on a unit |
| Tests (node:test) | `node --test` | Exit 0; summary `# fail 0` | `# pass 1`, `# fail 0`, exit 0 |
| Lint | `npx eslint .` (only with ESLint) | Exit 0 | not run |
| Coverage | the repository's tool, when the plan sets a minimum | The figure the plan requires | verify before use |

Report the command, the exit code and the line that decides the result. A gate that did not run is not a pass.

## Lint with typescript-eslint

- Install: `npm install --save-dev eslint @eslint/js typescript typescript-eslint`. The quickstart uses `defineConfig(...)` and `tseslint.configs.recommended` (https://typescript-eslint.io/getting-started).
- The quickstart does not set up type information. Rules that need types need a separate setup; the page points to a typed-rules guide.
- With TypeScript 7.0, the 7.0 announcement says `@typescript/typescript6` re-exports the 6.0 API for tools such as typescript-eslint. Verify before use which packages the lint setup needs.

## Tool choice

- Use what the repository already has. Add a tool only when the plan names it and a gate needs it.
- Pin versions in `devDependencies`. Check the version before you pin it.
- Formatters and coverage tools are the repository's choice. Verify their commands before use; this skill does not name one.
