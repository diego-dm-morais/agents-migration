# Writing Node.js as the target

Read this when you map a source construct to Node.js code. The left column is the concept; the right column is the Node.js idiom and the risk to test.

| Concept | Node.js idiom | Parity risk to test |
|---|---|---|
| Module or package boundary | ESM module per file, named exports, no default export for shared helpers | a name the source exports and the target does not |
| Optional value | `undefined` for absent, `null` only where the source serializes `null` | a field that the source emits as `null` and the target omits |
| Integer arithmetic | safe integers with a range check, or `BigInt` | overflow above 2^53 - 1; division truncation direction |
| Decimal money | `BigInt` minor units with a scale constant; or decimal strings | every tie; scale of the output; negative values |
| Rounding | a named function with the tie rule in its name and tests on both tie directions | `toFixed` and `Math.round` do not match half-even |
| Text | UTF-16 strings; `TextEncoder` for bytes | `.length` counts code units; surrogate pairs; normalization form |
| Date and time | UTC instants; `Intl.DateTimeFormat` with `timeZone` | the process time zone leaking into output |
| Map or dictionary | `Map` when keys are not strings; plain object when the source serializes it | key order: `Map` keeps insertion order; integer-like object keys sort first |
| Collection order | arrays; `toSorted` for a copy | stable sort direction; `localeCompare` depends on locale |
| Exception | `Error` subclass with a `code` string | each source exception to one code and message |
| Result or status | return a value or throw; no mixed style in one module | a failure the source reports as a value, returned here as a throw |
| Null handling | `?.` and `??` only where the source is null-safe | a null the source would have raised on |
| Asynchronous fan-out | `Promise.all` or `allSettled`, with a concurrency limit | the first error versus all errors; partial results |
| Retry | a loop with `AbortSignal.timeout`, a backoff with an injected sleep | the number of attempts; the retry only on the same error classes as the source |
| Logging | one logger module, structured fields | a log line the source emits and the target drops |
| Configuration | one config module with validation at start | a default the source applies silently |
| Serialization | `JSON.stringify` with an explicit replacer for dates, bigints and undefined | `undefined` keys dropped; `NaN` and `Infinity` become `null`; key order |
| Binary data | `Buffer` or `Uint8Array`, explicit encoding | byte order; base64 variant (standard or URL-safe) |
| Random values | `crypto.randomUUID()`, `crypto.getRandomValues()`; inject the source in tests | `Math.random()` is not for identifiers or secrets |
| Timers | `node:timers/promises` with an abort signal | the timer that keeps the process alive |
| HTTP client | `fetch` with an injected function in tests | the timeout; the body read twice; the status the source maps to an error |

## Project shape for a migrated unit

- `src/<unit>.js`: pure logic, no I/O.
- `src/<unit>.adapter.js` (only if the unit does I/O): the thin layer that calls the network, the disk or the environment and passes the values in.
- `test/<unit>.test.js`: the rule tests (one per BR), then the golden tests from `test/golden/<unit>/*.json`.
- Keep `package.json` `scripts.test` as `node --test`.
