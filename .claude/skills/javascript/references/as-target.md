# Writing JavaScript as the target

Read this when you map a source construct to JavaScript code. The middle column is the JavaScript idiom; the right column is the parity risk to test. Probe results are from Node.js 22.23.1 on 2026-10-29.

| Concept | Idiom in this language | Parity risk to test |
|---|---|---|
| Integer arithmetic | `Number` up to `Number.MAX_SAFE_INTEGER` (`9007199254740991`); `BigInt` above it | `2 ** 53 + 1 === 2 ** 53` is `true`; integers above 2^53 lose precision |
| Integers parsed from text | `BigInt(text)` for exact values; `Number(text)` only when the source is a double | `Number("9007199254740993")` is `9007199254740992`; `JSON.parse` does the same |
| Decimal money | `BigInt` minor units with a scale constant, or decimal strings with a fixed scale | `0.1 + 0.2` is `0.30000000000000004`; scale and sign of the output |
| Rounding half toward +infinity | a named function that calls `Math.round` and says so in its name | `Math.round(-2.5)` is `-2`; `Math.round(0.49999999999999994)` is `0` |
| Rounding half-even | integer arithmetic on `BigInt`, or on decimal strings; no built-in | `Math.round` and `toFixed` do not match half-even; `2.5` must give `2` |
| Fixed decimal text | `toFixed(d)` only when the source rounds the same way on ties | `(2.5).toFixed(0)` is `"3"`; `(-2.5).toFixed(0)` is `"-3"`; `(1.005).toFixed(2)` is `"1.00"` |
| Digits argument out of range | check `d` before `toFixed(d)` | `toFixed` throws RangeError when `d` is outside 0 to 100 (MDN) |
| Text length | `.length` counts UTF-16 code units; iterate code points with `for...of` or spread | `"\u{1F600}".length` is `2`; `[..."\u{1F600}"].length` is `1` |
| Text equality | compare after `String.prototype.normalize("NFC")` only when the source normalizes | `"\u00e9"` and `"e\u0301"` differ until normalized |
| Text order | default `sort()` compares UTF-16 code units; `localeCompare` only when the source is locale-aware | `["b", "B", "a"].sort()` is `["B", "a", "b"]` |
| Absent value | `undefined` for absent; `null` only where the source serializes `null` | `JSON.stringify({ a: undefined })` drops `a`; `JSON.stringify([undefined])` gives `[null]` |
| Date and time | epoch milliseconds or ISO 8601 UTC strings; `Intl.DateTimeFormat` with `timeZone` | months are zero-based: `Date.UTC(2026, 0, 31)` is January; `Date.UTC(2026, 1, 31)` is `2026-03-03` |
| Date format | `Intl.DateTimeFormat(locale, { timeZone })` with an explicit zone | the process time zone leaking into output |
| Map or dictionary | `Map` for any key type; a plain object only when the source serializes an object | `new Map([[-0, "x"]]).get(0)` is `"x"`; object keys: integer-like keys come first (`Object.keys({ b: 1, 2: 1, a: 1, 1: 1 })` gives `["1","2","b","a"]`) |
| Set of values | `Set`; keys use SameValueZero | `new Set([NaN, NaN]).size` is `1`; `new Set([0, -0]).size` is `1` |
| Sorted copy | `toSorted(comparator)` (MDN baseline July 2023) | `sort()` mutates and returns the same array; `[10, 9, 1, 80].toSorted()` is `[1, 10, 80, 9]` |
| Numeric sort | comparator `(a, b) => a - b` | default sort compares strings; a comparator that returns `NaN` counts as equal (MDN Array/sort) |
| Grouping | `Object.groupBy(items, key)` (MDN baseline March 2024) | the result has a null prototype; `hasOwnProperty` is not on it |
| Equality | `===`; `Object.is` when NaN or -0 must be told apart | `[] == false` is `true`; `NaN === NaN` is `false` |
| Exception | `Error` subclass or an `Error` with a `code` property, and `cause` when wrapping | a thrown string is legal; each source exception maps to one code and message |
| Async fan-out | `Promise.all` (first rejection) or `Promise.allSettled` (every outcome) | `Promise.all` rejects early; `allSettled` keeps input order |
| Retry | a loop with an injected sleep and an attempt counter | the attempt count; retry only on the same error kinds as the source |
| Serialization | `JSON.stringify` with a replacer for `Date`, `BigInt` and `undefined` | `NaN` and `Infinity` become `null`; `BigInt` throws TypeError |
| Binary data | `Uint8Array`, `TextEncoder`, `TextDecoder` with an explicit encoding | byte order; base64 variant |
| Random values | `crypto.randomUUID()` in the runtime; inject the source in tests | `Math.random()` is not for identifiers or secrets |
| Clock | an injected `now()` function | the source reads the wall clock at a different point |
| HTTP client | `fetch` with an injected function in tests | the timeout; the body read twice; the status the source maps to an error |
| Promise.try | not available on Node.js 22.23.1 (probe); use `new Promise` or an `async` function | MDN marks `Promise.try` Baseline 2025, so older runtimes lack it |

## Project shape for a migrated unit

- `src/<unit>.js` (or `.mjs`): pure logic, no I/O.
- `src/<unit>.adapter.js`, only if the unit does I/O: the thin layer that calls the network, the disk or the environment, and passes the values in.
- `test/<unit>.test.js`: one test per rule, then the golden tests from `test/golden/<unit>/*.json`.
- `package.json` `scripts.test`: `node --test`.
