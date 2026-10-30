Read this when you map a source construct to Dart or Flutter code. The left column is the concept; the middle column is the Dart idiom; the right column is the risk to test.

# Writing Dart and Flutter as the target

| Concept | Idiom in this language | Parity risk to test |
|---|---|---|
| Integer arithmetic | `int` with an explicit range check against the target platform | the VM is 64-bit; on the web an `int` is a JavaScript number, exact only to 2^53 - 1 |
| Decimal money | `int` in minor units with a fixed scale; never `double` | every tie; the scale of the output; negative values |
| Integer division | `~/` returns an `int` | `5 ~/ 2` is 2 and `5 / 2` is the double 2.5; sign direction for negatives: verify before use |
| Rounding to an integer | `double.round()`, which rounds ties away from zero | `(-3.5).round()` is -4; half-even is not built in, so implement and test it |
| Fixed decimal text | `toStringAsFixed(n)` on `num`, after conversion to double | the tie rule is not stated; test `2.5` at 0 digits and `0.125` at 2 digits |
| Text of a double | `toString()`; `-0.0` and `Infinity` print as such | the source's digits and exponent format; `-0.0` against `0.0` |
| Text length | `length` counts UTF-16 code units; `runes` counts code points | a surrogate pair: `'\u{1D11E}'.length` is 2, `runes.length` is 1 |
| Absent value | nullable type `T?`; `??` only where the source is null-safe | a null that the source omits, or emits as an empty string |
| Null in text | an explicit check before interpolation | `'$x'` prints `null` for a null value; the source may print nothing |
| Instant in time | `DateTime.utc(...)`; store and compare in UTC | local time leaking into output; `isUtc` on a parsed value |
| Parsing an offset | `DateTime.parse` converts the offset to UTC | `-0500` and `Z` give the same instant; the source may keep the offset text |
| Invalid date text | validate the text before `DateTime.parse` | `"2020-01-42"` gives 2020-02-11 and does not throw |
| Current time | inject a clock; call `DateTime.now()` only at the edge | the process time zone; the test must control the value |
| Ordered collection | `List`; `sort` is not stable | equal elements may reorder; copy first if the source keeps the input order |
| Keyed collection | `Map()` iterates in insertion order | key order in output and in JSON; unmodifiable copies with `Map.unmodifiable` |
| Error model | one class per source exception; the source message kept | one code and one message per source exception; `throw` of a non-`Exception` object |
| Integer from text | `int.tryParse` for the non-throwing form | `int.parse` throws `FormatException`; sign, `0x` prefix and whitespace: verify before use |
| JSON out | `jsonEncode`, with `toEncodable` for other objects | non-encodable objects; key order; null against omitted field |
| JSON in | `jsonDecode` returns `dynamic`; check each field's type | the runtime type of each number after decode: verify before use; missing keys |
| Parallel calls | `Future.wait`, results in input order | the first error against all errors (`eagerError`) |
| CPU-bound work | `Isolate.run`; the computation and its result must be sendable | a closure that sends extra state; the isolate ends on error |
| UTF-8 bytes | the `utf8` codec from `dart:convert` | the behavior on malformed bytes is not stated: verify before use |
| Process exit | set `exitCode` once at the entry point | `exit` drops buffered data and skips `finally` blocks |
| Widget state | a `StatefulWidget` with a `State`; `setState` | `setState` after `dispose` is an error |
| Action after await | check `mounted` (in a `State`) or `context.mounted` | the screen is gone when the await returns |
| Locale formatting | the `intl` package, publisher dart.dev (https://pub.dev/packages/intl) | the locale of the output; the process locale |
