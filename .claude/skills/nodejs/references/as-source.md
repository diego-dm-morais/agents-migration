# Reading Node.js as the source

Read this when the source you migrate from is Node.js. These are the places where the behavior is easy to miss, because it is in the runtime, not in the code you read.

## Numbers

- Every number is a double. `a + b` loses precision above 2^53 - 1. Look for money, counters and identifiers that cross that line.
- `toFixed(d)` rounds ties away from zero on the absolute value, using the exact binary value. `(1.005).toFixed(2)` is `"1.00"`. Copy the output exactly; do not "fix" it in the target.
- `Math.round` rounds ties toward +infinity: `Math.round(-2.5)` is `-2`, `Math.round(2.5)` is `3`.
- `parseInt`, `parseFloat` and `Number()` differ on leading zeros, whitespace, and `"0x"` prefixes. Note which one the source calls.
- `NaN` and `Infinity` in `JSON.stringify` become `null`. Check whether the source's output depends on that.
- `Math.random()`, `Date.now()` and `crypto.randomUUID()` make outputs non-deterministic. Mark each one as an input in the extraction.

## Strings and encoding

- `.length` and indexing use UTF-16 code units. An emoji has length 2. Code that slices, pads or counts characters behaves differently in other languages.
- `String.prototype.normalize()` is not applied unless the code calls it. Check whether the source normalizes input.
- `localeCompare` and `Intl.*` depend on the locale and ICU data; a missing locale argument means the environment decides.
- `Buffer.from(string)` defaults to UTF-8. `btoa` and `atob` work on Latin-1 only.

## Dates and time

- `new Date(string)` parses non-ISO strings in an implementation-defined way. Look for it on input.
- Without a `timeZone` option, formatting depends on the process `TZ`. A server and a laptop can differ.
- `Date` months are zero-based: `new Date(2026, 0, 31)` is January.
- `setTimeout` delays are minimums, not exact times.

## Asynchronous behavior

- Event order: `process.nextTick` callbacks run before promise callbacks, and both run before timers. Code that depends on that order is part of the behavior.
- `Promise.all` rejects on the first failure but does not cancel the others; their side effects still happen. Note which calls have side effects.
- An unhandled rejection terminates the process (since v15). A source that logs and continues is different behavior.
- A shared object mutated across `await` points can interleave.

## Errors and exit

- `throw` of a non-`Error` value is possible; check what the source catches and how it reports it.
- `process.exit(code)` stops without flushing pending writes. Check whether the source relies on the exit code.
- An error's `message` is part of the output only when the source returns it; `stack` is never a stable output.

## Serialization

- `JSON.stringify` omits `undefined` values in objects, turns them into `null` in arrays, and throws on `BigInt`. Check each field's type.
- Key order follows insertion, except integer-like keys, which come first in ascending order.
- `toJSON` methods change the output of nested values. Check whether a class defines one.

## Configuration

- `process.env` values are always strings. `"false"` is truthy. Find each comparison and check how the source parses it.
- A missing environment variable often falls back to a default in code. List each default as a behavior.
- `.env` loading order matters when several files exist; the source may rely on the environment winning over the file.

## Modules and globals

- A module-level variable is shared by every caller in the process. Look for caches, counters and singletons.
- Monkey patches on built-ins (`Array.prototype`, `Date`, `fetch`) change every module. Find them with Grep on the snapshot.
