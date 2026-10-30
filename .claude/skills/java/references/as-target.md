# Writing Java as the target

Read this when you map a source construct to Java code. The left column is the concept; the middle column is the Java idiom; the right column is the risk to test. Parity beats idiom: choose the idiom only when inputs, outputs and errors stay the same. The runs cited in the right column were executed on Amazon Corretto 25.0.5 unless marked "earlier run".

| Concept | Idiom in this language | Parity risk to test |
|---|---|---|
| 32-bit or 64-bit integer arithmetic | `int` or `long`; `Math.addExact` where the source fails on overflow | silent wrap at 2^31 - 1 and 2^63 - 1 (JLS 4.2.2; run); `Math.addExact` throws `integer overflow` (run) |
| Integer division | `/` and `%` on integers | division by zero throws `ArithmeticException` with `/ by zero` (JLS 4.2.2; run); the source may return a value instead |
| Money | `BigDecimal` with a fixed scale and an explicit `RoundingMode` | output scale (`2.0` and `2.00` differ under `equals`; run); negative amounts |
| Rounding to a scale | `setScale(n, RoundingMode.X)`, with the mode named in the function | `setScale(n)` without a mode throws `Rounding necessary` (run); HALF_UP, HALF_EVEN and HALF_DOWN differ on ties (run) |
| Rounding a double to an integer | `Math.round` only where its tie rule (toward positive infinity) is the source's rule | `Math.round(-2.5)` is `-2`; `Math.round(2.5)` is `3` (run) |
| Decimal from a double | `BigDecimal.valueOf(double)` (uses `Double.toString`) | `new BigDecimal(double)` keeps the exact binary expansion (run) |
| Binary floating point (source uses double) | `double` with the same operation order as the source | `0.1 + 0.2` is `0.30000000000000004` (run); comparison with `==` |
| Number to text | `String.format(Locale.ROOT, ...)` or `DecimalFormat` with an explicit locale | the default FORMAT locale changes the decimal separator (`pt_BR` on the check machine; `1,50` in GERMANY; run) |
| Fixed-precision text (`%f`) | the same precision as the source, with the rounding checked | `%f` rounds half up from the shortest decimal form: `1.005` gives `1.01`, not `1.00` (run) |
| Case conversion | `toLowerCase(Locale.ROOT)` | the default locale changes the mapping (`tr` gives U+0131 for `I`; run); `new Locale(String)` is deprecated on 25.0.5 (run) |
| Text to bytes | `getBytes(StandardCharsets.UTF_8)` | `getBytes()` uses the default charset (UTF-8 on 25.0.5; `windows-1252` on the OpenJDK 17.0.19 check machine, earlier run) |
| Bytes to text | `new String(bytes, StandardCharsets.UTF_8)`; `Files.readString(path)` (UTF-8) | malformed input; the source's charset |
| Text length | `codePointCount` or `codePoints()` where the source counts characters | `length()` counts UTF-16 units; an emoji is length 2 and one code point (run) |
| Trim white space | `strip()` (Unicode white space) or `trim()` (code points up to U+0020), chosen by the source's definition | U+2003 is removed by `strip()` and kept by `trim()` (run); U+00A0 is kept by `strip()` (run) |
| Blank check | `isBlank()` (JDK 11 API) | U+00A0 is not blank (run); U+2003 is blank (run) |
| Ordered output | `LinkedHashMap` for insertion order; `TreeMap` for sorted keys (verify before use) | `HashMap` gives no order guarantee; order may change over time |
| Unordered map or set | `HashMap` or `HashSet` only when order is never observed | output built from iteration order differs between runs or releases |
| Absent value | `null` only where the source serializes null; `Optional` only as a return type | `Optional.get()` throws `NoSuchElementException` when empty (run) |
| Immutable data record | `record` (JDK 16); on the 11 floor, a final class with final fields | `equals`, `hashCode` and `toString` output of the target type against the source |
| Sealed set of variants | `sealed` with `permits` (JDK 17), and a `switch` over it (JDK 21) | a new subtype in the source that the target's switch does not cover |
| Error type | one exception class per source error, message and cause kept | checked versus unchecked changes the method signature; one type per source exception |
| Resource cleanup | try-with-resources (JLS 14.20.3) | resources close in reverse order; a close failure becomes a suppressed exception (run) |
| Date and time | `java.time` (`Instant`, `LocalDate`, `ZonedDateTime`) with an explicit `ZoneId` | `ZoneId.systemDefault()` depends on the machine (`America/Sao_Paulo` on the check machine; run) |
| Legacy calendar | `java.time` for new code; `Calendar` only when the source's behavior needs it | `Calendar` months are zero-based (`JANUARY` is 0; run); `Calendar` is lenient by default (`set(2026, 0, 32)` rolls over; run) |
| Concurrent tasks | one virtual thread per task (JDK 21, JEP 444) or an executor | a blocking call inside `synchronized` pins the carrier thread |
| Sequenced access | `getFirst()`, `getLast()`, `reversed()` (JDK 21, JEP 431) | an empty collection throws `NoSuchElementException` (run); the source may return `null` |
| HTTP client | `java.net.http.HttpClient` (JDK 11, JEP 321) | timeouts; status codes that the source maps to errors; the body read once |
| Resource release on error | try-with-resources | a close failure during a failing body is reachable through `getSuppressed()` (run) |
| Configuration | one class that reads the environment, validates at start, and fails with the key name | a default the source applies silently; `System.getenv` values are strings |
| Serialization of the result | the JSON library the repository already uses (verify before use) | field order, `null` versus absent field, number precision above 2^53 |

## Project shape for a migrated unit

- `src/main/java/<pkg>/<Unit>.java`: pure logic, no I/O, no clock, no environment.
- `src/main/java/<pkg>/<Unit>Adapter.java`, only when the unit does I/O: the thin layer that calls files, the network or the environment and passes the values in.
- `src/test/java/<pkg>/<Unit>Test.java`: one test per rule id, then the golden tests from the golden folder.
- Keep the build's test command as the gate (`references/testing-and-tooling.md`).
