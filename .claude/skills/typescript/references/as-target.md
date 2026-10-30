Read this when you map a source construct to TypeScript code. The left column is the concept; the middle column is the TypeScript idiom; the right column is the parity risk to test.

# Writing TypeScript as the target

Parity beats idiom. An idiom is used only when inputs, outputs and errors stay the same. Otherwise keep the source behavior and mark the difference `deviation` with its reason and source. "verified" means checked with `tsc` 7.0.2 or Node v22.23.1 on 2026-10-29.

| Concept | Idiom in this language | Parity risk to test |
|---|---|---|
| Optional field | `field?: T`; the key may be absent | An explicit `undefined` is not the same as an absent key in `in`; JSON drops it (verified) |
| Nullable value | `T \| null` under `strict` | The source emits `null` and the target omits the key, or the reverse |
| Fixed set of names | literal union such as `"open" \| "closed"` | The source's runtime object and key order, when the source reads one |
| Enum read at runtime | non-const `enum`, which emits an object | Numeric enums get reverse mappings; string enums do not (enums page) |
| Integer arithmetic | `number` with a `Number.isSafeInteger` check, or `bigint` | Values above 2^53 - 1 lose precision (verified) |
| Money | `bigint` in minor units with a fixed scale, or a decimal string | Every tie, the output scale, negative values; no float |
| Rounding | a named function with the tie rule in its name | `toFixed` ties away from zero; `Math.round` ties toward +infinity (verified) |
| Text | `string` (UTF-16 code units) | `.length` counts code units: `"\u{1F600}".length` is 2 (verified) |
| Date and time | `Date` holding UTC instants; `Intl.DateTimeFormat` with `timeZone` | Date-only and date-time strings parse differently; the process time zone (verified) |
| Map with non-string keys | `Map<K, V>` | A plain object turns each key into a string (verify before use) |
| Record written as JSON | `interface`, or `Record<string, V>` | Key order: integer-like keys come first (verified) |
| Collection and sort | `readonly T[]`; copy before sorting | `sort()` changes the array in place (verified) |
| Exception | `class XError extends Error` with a `code` property | Each source exception maps to one code; the message text when the source has one |
| Caught error | `catch (e: unknown)`, then narrow with `instanceof` | A source that wraps or rethrows; `cause` needs an ES2022 library (verified) |
| Result or status | discriminated union `{ ok: true; value: T } \| { ok: false; error: E }` | A failure the source reports as a throw, returned here as a value, or the reverse |
| Runtime input | `unknown` and a guard (references/runtime-validation.md) | A cast skips the check (verified) |
| JSON output | `JSON.stringify` with an explicit replacer for dates and bigints | `undefined` dropped; `NaN` and `Infinity` become `null`; `1n` throws (verified) |
| Async fan-out | `Promise.all` or `Promise.allSettled` | The first error versus all results; side effects of calls that keep running |
| Shape of data | `interface` | An extra member passes a variable check and is still serialized (verified) |
| Injected dependency | `interface` parameter, with a typed fake in tests | A fake that misses a method fails to compile (verified, TS2741) |
| Configuration | one typed `Config` object, read once at start | A default the source applies silently |
| Module boundary | named exports | A name the source exports and the target does not |
