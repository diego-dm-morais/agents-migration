# Testing and tooling (JavaScript)

Read this when you write tests for JavaScript code, choose a runner or a double, or set up the gate. Commands and results were run on Node.js 22.23.1 on 2026-10-29.

## Runner

- Runner: `node:test`. Assertions: `node:assert/strict`. Runtime details are in the nodejs skill.
- `node --test` runs each matching test file. A file that exits with code 0 passes; any other exit code fails (Node.js 22 test docs, https://nodejs.org/docs/latest-v22.x/api/test.html).
- Sample run (`sample.test.mjs`, three `it` blocks). Output lines that decide the result:

```
# tests 3
# suites 1
# pass 3
# fail 0
```

Exit code 0.

Sample test shape:

```js
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

describe('BR-EXAMPLE-001', () => {
  it('Math.round rounds -2.5 toward +infinity to -2', () => {
    assert.equal(Math.round(-2.5), -2);
  });

  it('loose equality coerces an empty array to false', () => {
    assert.equal([] == false, true);
  });

  it('NaN is not equal to itself', () => {
    assert.equal(Number.isNaN(NaN), true);
    assert.equal(NaN === NaN, false);
  });
});
```

## Layout

- One test file per unit: `test/<unit>.test.js` (or `.mjs`). Keep test helpers in `test/` and out of `src/`.
- Golden files: `test/golden/<unit>/<case>.json`. Each file holds the input and the output recorded from the source. Write it from the source, never from the target.
- A test name carries the rule id when there is one: `BR-ROUND-002 rounds ties toward +infinity`.

## Comparing values

- Use `Object.is` when the source distinguishes NaN or -0 (references/semantics-and-coercion.md):

```js
assert.equal(Object.is(Math.round(-0.4), -0), true);
assert.equal(Object.is(0, -0), false);
```

- Compare parsed values, not raw text, unless the source output is text.
- Money and other exact values are compared as strings or integers, never as floats.
- Use `assert.deepStrictEqual` for objects and arrays. Compare key order only when the source output has a defined order (references/as-source.md, Serialization).

## Golden comparison

```js
import { readFile } from 'node:fs/promises';

const expected = JSON.parse(
  await readFile(new URL('./golden/round/case-01.json', import.meta.url), 'utf8'),
);
assert.deepStrictEqual(actual, expected.output);
```

- A missing golden file fails the test. Never create it from the target's output.

## Doubles and isolation

- Pass a fake function as a parameter (a clock, a random source, a fetch function). The unit under test takes it through its constructor or its arguments.
- Do not patch a global (`Math.random`, `Date`, `fetch`) in a test. Another test in the same process may read it.
- For mock helpers and fake timers, use the test runner's own helpers and read the nodejs skill for the Node.js version in use.

## Gate commands

| Gate | Command | Pass means | Probe result (2026-10-29) |
|---|---|---|---|
| Runtime | `node --version` | v22.x or later, or the version in `engines` | `v22.23.1`, exit 0 |
| Tests | `node --test` | exit code 0 and `# fail 0` | `# pass 3`, `# fail 0`, exit 0 |
| Format | `npx prettier --check .` (only with Prettier) | exit 0 (exit 1 lists unformatted files) | not run: no Prettier config in the repository |
| Lint | `npx eslint .` (only with ESLint) | exit 0 | not run: no ESLint config in the repository |

- Prettier `--check`: exit code 0 when all files are formatted, 1 when some are not, 2 when Prettier itself fails (https://prettier.io/docs/cli).
- ESLint: `npx eslint .` lints the current directory (https://eslint.org/docs/latest/use/command-line-interface).

## Tool choice

- Use what the repository already has. Add a tool only when the plan names it and the gate needs it.
- Lint and format versions belong in `devDependencies`. Check the version on the registry before you pin it.
- Do not add a test framework other than `node:test` unless the repository already uses it.
