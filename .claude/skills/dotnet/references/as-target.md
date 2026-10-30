# Writing C# as the target

Read this when you map a source construct to C# code. The left column is the concept; the middle column is the C# idiom; the right column is the risk to test. Parity beats idiom: use the middle column only when inputs, outputs and errors stay the same.

| Concept | Idiom in this language | Parity risk to test |
|---|---|---|
| Money amount | `decimal`, scaled as the source's rule says | Scale of the output text; `decimal` overflow throws `OverflowException` |
| Rounding to a number of digits | `Math.Round(value, digits, MidpointRounding.X)` with X taken from the source | Default is `ToEven`: `Math.Round(3.85m, 1)` is `3.8`; `AwayFromZero` gives `3.9` |
| Rounding to an integer | `Math.Round(value, MidpointRounding.X)` | `Math.Round(2.5m)` is `2` under the default; check each tie direction |
| Integer arithmetic that must not wrap | `checked { ... }` around the operation | Default context is unchecked; `OverflowException` is thrown only inside the block |
| Integer arithmetic that wraps | Plain operators in the default context | Wrap-around value, for example `-2147483646` for `int.MaxValue + 3` |
| Constant arithmetic | Constant expressions | Overflow in a constant expression is a compile-time error, not a run-time wrap |
| Integer division and remainder | `/` and `%` on integers | Truncation toward zero: `-13 / 5` is `-2`; remainder sign follows the left operand |
| Optional value type | `T?` on value types | A `null` operand the source treats as zero or as an error; check the operator results on `T?` (verify before use) |
| Optional reference | `string?` with `is null` checks | Nullable annotations are compile-time only; the run-time null must be handled |
| Required reference field | Non-nullable field set in the constructor | `default(T)` and `new T[n]` leave reference fields null without a warning |
| Text equality, identifiers and codes | `string.Equals(a, b, StringComparison.Ordinal)` | Culture-sensitive overloads when no `StringComparison` is passed |
| Case-insensitive ASCII match | `StringComparison.OrdinalIgnoreCase` | Culture case mapping: in `tr-TR`, the uppercase of `i` is `İ` (U+0130) (verify before use) |
| Text search | `IndexOf(s, StringComparison.Ordinal)` | `IndexOf(string)` is culture-sensitive; `IndexOf(char)` is ordinal by default |
| Persisted number or date text | Formatting with the invariant culture | Output that changes with the process culture |
| Instant in time | UTC `DateTime` with `Kind` `Utc`, or `DateTimeOffset` | `Kind` does not take part in comparison; conversions depend on `Kind` |
| Local time for display | `DateTime.Now` or a converted value, only where the source uses local time | Output depends on the machine's time zone; tests need a fixed zone input |
| Value with unknown kind | `DateTime` with `Kind` `Unspecified` only when the source keeps no zone | `ToUniversalTime()` treats `Unspecified` as local; `ToLocalTime()` treats it as UTC |
| Map where output order matters | An ordered list of pairs, sorted by the rule the source states | `Dictionary` enumeration order is undefined |
| Map where order does not matter | `Dictionary<TKey, TValue>` | Any output that enumerates the map without sorting |
| Source error | One exception type per source error, with the source's message | Exception types and message text differ from the source's; map each source error explicitly |
| Failure reported as a value | Return a result value, not a thrown exception | A failure that the source returns as a value must not become a throw |
| Floating-point measurement | `double` where the source uses floating point | Round-off: `double a = 0.1; double b = 3 * a;` gives `b == 0.3` as `false` |
| Floating-point overflow or division by zero | Check the result for `Infinity` or `NaN` | The runtime does not throw; the source may expect an error |
| Serialized text of a decimal | Formatting with an explicit format string | Trailing zeros show only with a format string |
| Retry or deadline | Loop with an injected clock; verify the cancellation API before use | Number of attempts; the errors that trigger a retry |
| Environment or configuration | One configuration type, read at start | A default the source applies silently; values read from the real environment in tests |

## Project shape for a migrated unit

- `src/<Unit>/<Unit>.cs`: pure logic, no I/O.
- `src/<Unit>/<Unit>.Adapter.cs`: only when the unit does I/O. It calls the file, the network or the environment and passes the values in.
- `tests/<Unit>.Tests/`: one test per rule id, then the golden tests.
- Keep `dotnet test` as the test command. Keep `dotnet build -warnaserror` and `dotnet format --verify-no-changes` in the gate.
