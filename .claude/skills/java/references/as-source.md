# Reading Java as the source

Read this when the source you migrate from is Java. These are the places where Java behavior is easy to miss, because it is in the runtime or the machine, not in the code you read. Each trap is followed by its check: the JLS or the API page, and the run on this session's check machine (Amazon Corretto 25.0.5) where a run is possible. A value marked "earlier run" comes from OpenJDK 17.0.19.

## Numbers

- Integer overflow is silent. `Integer.MAX_VALUE + 1` is `-2147483648` (JLS 4.2.2; run). Look for counters, sums and identifiers near 2^31 or 2^63.
- Integer `/` and `%` by zero throw `ArithmeticException` (JLS 4.2.2; run). Find the call sites that can receive zero.
- `double` is binary. `0.1 + 0.2` prints `0.30000000000000004` (run). Money held in `double` is a parity risk even when it prints well.
- `new BigDecimal(0.1)` is the exact binary value `0.1000000000000000055511151231257827021181583404541015625`; `BigDecimal.valueOf(0.1)` is `0.1` (run).
- `BigDecimal.equals` compares scale: `2.0` and `2.00` are not equal, and `compareTo` returns 0 (run). Find each `equals` on amounts.
- `setScale(n)` without a `RoundingMode` throws `Rounding necessary` when rounding is needed (run). A source that rounds earlier hides the difference.
- `Math.round` rounds ties toward positive infinity: `Math.round(-2.5)` is `-2`; `Math.round(2.5)` is `3`; `Math.round(0.49999999999999994)` is `0` (run). `Math.round(NaN)` is `0` (run).

## Formatting and locale

- `String.format` and `%f` use the default FORMAT locale when none is given (Java SE API). On the check machine the default FORMAT locale is `pt_BR` (run); the same format with `Locale.GERMANY` printed `1,50` (run). Find each call without a `Locale`.
- `%f` rounds half up from the shortest decimal form of the double: `String.format(Locale.ROOT, "%.2f", 1.005)` is `1.01` (run). `new BigDecimal(1.005).setScale(2, RoundingMode.HALF_UP)` is `1.00` (run), and `BigDecimal.valueOf(1.005)` with the same call is `1.01` (run). Copy the source's output; do not choose the other one.
- `DecimalFormat` uses `RoundingMode.HALF_EVEN` by default (run: `2.5` gives `2`, `3.5` gives `4`).
- `toLowerCase()` and `toUpperCase()` without a `Locale` use the default locale (Java SE API). `"TITLE".toLowerCase(new Locale("tr"))` gives the dotless `ı` (U+0131; run). On the check machine the same text without a locale gives `title` (run).

## Text and encoding

- `getBytes()` and `new String(bytes)` use the default charset. On 25.0.5 the default is UTF-8 (run; JEP 400, JDK 18). On the OpenJDK 17.0.19 check machine it was `windows-1252` (earlier run).
- A source file compiled without `-encoding` is read with the platform default converter (javac 25 manual). On 25.0.5 the file with the emoji literal gave length 2 with and without the flag (run). On OpenJDK 17.0.19 the same file without the flag gave length 4 (earlier run).
- `length()` counts UTF-16 units. The grinning-face emoji has `length()` 2 and one code point (run).
- `strip()` removes U+2003 and `trim()` keeps it: lengths 1 and 3 for `U+2003 x U+2003` (run). `strip()` keeps U+00A0 (run).
- `isBlank()` is false for U+00A0 (run) and true for U+2003 (run).

## Dates and time

- `ZoneId.systemDefault()` queries the default time zone (Java SE API). The check machine returned `America/Sao_Paulo` (run). Find every call that depends on it.
- `Calendar` months are zero-based: `Calendar.JANUARY` is 0 (run). `java.time` months are one-based: `LocalDate.of(2026, 1, 31)` prints `2026-01-31` (run).
- `Calendar` is lenient by default (Java SE API): `set(2026, 0, 32)` rolls over to February 1 (run). Check what the source does with the same out-of-range input.
- The same instant prints differently by zone: `2026-03-29T00:30:00Z` is `2026-03-28T21:30-03:00[America/Sao_Paulo]` in one zone and `2026-03-29T00:30Z[UTC]` in UTC (run).

## Absent values and collections

- `Optional.get()` throws `NoSuchElementException` when empty, with the message `No value present` (run). Find each `get()`.
- Do not compare an `Optional` with `==` against `Optional.empty()` (Java SE API).
- `HashMap` makes no iteration-order guarantee, and the order may change over time (Java SE API). Run: keys `banana, apple, cherry, date` iterate as `[banana, date, apple, cherry]` (run).
- `HashMap` is unsynchronized (Java SE API). A shared map read and written by several threads is a race in the source.

## Errors, resources and exit

- `ArithmeticException` is a `RuntimeException`, so it is unchecked (Java SE API). A catch clause that names `Exception` also catches it.
- try-with-resources closes resources in reverse order of initialization, and a close failure during a failing body is added as a suppressed exception (JLS 14.20.3; run: `close b`, `close a`, then `caught: body failed` with suppressed `close failed b` and `close failed a`).
- `System.exit` ends the JVM with the status it is given. Find each call and the status it passes.

## Concurrency

- A virtual thread that blocks inside `synchronized` pins its carrier thread (JEP 444). Code that relied on lock ordering needs the same locks.

## Build and runtime

- The release of the compiler decides the language rules. A class file built for release 11 can still call a newer API if the build sets only the source and target levels; verify before use, and check the build file for `release`.
- Default locale, default time zone and default charset come from the machine and the JVM settings. The same code and the same jar can print different text on another machine. The check machine's default FORMAT locale and default zone are in "Formatting and locale" and "Dates and time" above (run).
