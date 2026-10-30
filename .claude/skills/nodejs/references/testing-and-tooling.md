# Testing and tooling (Node.js 22)

Read this when you write tests, set up the gate, or choose a tool. Commands here were checked against the Node.js 22 test runner documentation on 2026-10-29.

## Test file layout

- `test/<unit>.test.js` for behavior tests, one file per unit.
- `test/golden/<unit>/<case>.json` for recorded outputs. The file records the input and the source output. It is written from the source, never from the target.
- A test name carries the rule id when there is one: `BR-ROUND-002 rounds ties to even`.

## Runner

```js
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { roundHalfEven } from '../src/round.js';

describe('BR-ROUND-002', () => {
  it('rounds 2.5 to 2', () => {
    assert.equal(roundHalfEven('2.5', 0), '2');
  });
});
```

- `node --test` finds `**/*.test.js`, `**/test/**/*.js` and other default patterns. To limit the search, pass glob patterns in double quotes: `node --test "test/**/*.test.js"`.
- `--test-concurrency=<n>` limits parallel test files; the default is available parallelism minus one.

## Doubles and time

- `mock.fn(impl)` records calls. `mock.method(object, 'name', impl)` replaces a method for the test and restores it.
- Time: `context.mock.timers.enable({ apis: ['setTimeout'] })`, then `context.mock.timers.tick(ms)`. Enable only the APIs the test uses.
- Inject `fetch`, clocks and randomness as parameters. Do not patch globals in a test that another test reads.

## Golden comparison

```js
import { readFile } from 'node:fs/promises';
const expected = JSON.parse(await readFile(new URL('./golden/round/case-01.json', import.meta.url), 'utf8'));
assert.deepStrictEqual(actual, expected.output);
```

- Compare parsed values, never raw text, unless the source output is text.
- Money and other exact values are compared as strings or integers.
- A missing golden file fails the test. Do not create it from the target's output.

## Gate commands

| Gate | Command | Pass means |
|---|---|---|
| Runtime | `node --version` | v22.x or later |
| Install | `npm ci` | exit 0 with the lockfile |
| Format | `npx prettier --check .` (only with Prettier) | exit 0 |
| Lint | `npx eslint .` (only with ESLint) | exit 0 |
| Tests | `node --test` | exit 0, and the summary shows `fail 0` |
| Coverage | `node --test --experimental-test-coverage` | the summary line shows the figure the plan requires |

Report the commands you ran and the lines that decide each result. Coverage thresholds through `--test-coverage-lines` are experimental in 22; say so if you use them.

## Tool choice

- Use what the repository already has. Add a tool only when the plan names it and the gate needs it.
- Lint and format versions are pinned in `devDependencies`; check the version against the registry before you pin it.
