# Numbers and time (Corretto 25, Java 11 floor)

Read this when a migration depends on integers, money, rounding, number formatting, dates, time zones or the zone of an instant. A value marked "run" was executed on Amazon Corretto 25.0.5 on the check machine, and the check machine's default locale and time zone are part of those results. A value marked "earlier run" comes from OpenJDK 17.0.19. A value with no run mark cites a Java SE or JLS page; verify it before use on 25.

## Integers

| Input | Java result | Source |
|---|---|---|
| `Integer.MAX_VALUE + 1` | `-2147483648` | JLS 4.2.2 (wrap); run |
| `Math.addExact(Integer.MAX_VALUE, 1)` | `ArithmeticException: integer overflow` | Java SE API; run |
| `1 / 0` (int) | `ArithmeticException: / by zero` | JLS 4.2.2; run |

- Integer arithmetic wraps; the wrap is the language rule (JLS 4.2.2, example 4.2.2-1: `i * i` wraps). A source that fails on overflow needs `Math.addExact`, `Math.multiplyExact` or an explicit range check (verify before use for `multiplyExact`).
- `long` wraps at 2^63 - 1 the same way (JLS 4.2.2).

## Floating point

- `double` is a binary floating-point value. `0.1 + 0.2` prints `0.30000000000000004` (run).
- `new BigDecimal(double)` gives the exact binary value; `BigDecimal.valueOf(double)` uses `Double.toString(double)` (Java SE API). Run: `new BigDecimal(0.1)` prints `0.1000000000000000055511151231257827021181583404541015625`; `BigDecimal.valueOf(0.1)` prints `0.1` (run).
- `BigDecimal.valueOf(1.005).setScale(2, RoundingMode.HALF_UP)` is `1.01`, while `new BigDecimal(1.005).setScale(2, RoundingMode.HALF_UP)` is `1.00` (run). Copy the source's output; do not choose the other one.

## BigDecimal: scale, equality and rounding

- Scale is the number of digits after the decimal point. `equals` compares value and scale; `compareTo` compares value only (Java SE API; run: `equals` is false and `compareTo` is 0 for `2.0` and `2.00`).
- `setScale(n)` without a rounding mode throws `ArithmeticException: Rounding necessary` when the value needs rounding (run).
- `RoundingMode` values on the same inputs, `setScale(0, mode)` (run on 25.0.5):

| Input | HALF_UP | HALF_DOWN | HALF_EVEN | UP | DOWN | FLOOR | CEILING |
|---|---|---|---|---|---|---|---|
| 2.5 | 3 | 2 | 2 | 3 | 2 | 2 | 3 |
| -2.5 | -3 | -2 | -2 | -3 | -2 | -3 | -2 |
| 2.6 | 3 | 3 | 3 | 3 | 2 | 2 | 3 |
| 2.4 | 2 | 2 | 2 | 3 | 2 | 2 | 3 |

- `RoundingMode.UNNECESSARY` throws `Rounding necessary` for `2.5` and returns `2` for `2.0` (run). The API says it throws an `ArithmeticException` for an inexact result (Java SE API).
- HALF_UP rounds ties away from zero: `-2.5` becomes `-3`. HALF_EVEN rounds ties to the even neighbor: `2.5` becomes `2`. HALF_DOWN rounds ties toward zero (run: the table above).
- `setScale(2, RoundingMode.HALF_EVEN)` on `2.345` is `2.34` (run).

## Math.round and ties

- `Math.round(double)` rounds ties toward positive infinity: `Math.round(-2.5)` is `-2`, `Math.round(2.5)` is `3`, and `Math.round(0.49999999999999994)` is `0` (run).
- `Math.round(NaN)` is `0`, and `Math.round(1e30)` is `9223372036854775807`, the `long` maximum (run).
- For half-even or half-up on a decimal value, use `BigDecimal` with an explicit `RoundingMode`, not `Math.round`.

## Formatting numbers and locale

- Default FORMAT locale: `Locale.getDefault(Locale.Category.FORMAT)` is `pt_BR` on the check machine (run). `String.format` and `%f` use the default FORMAT locale when no `Locale` is given (Java SE API).
- `String.format(Locale.GERMANY, "%.2f", 1.5)` is `1,50` (run). `String.format(Locale.ROOT, "%.1f", 0.25)` is `0.3` (run).
- `%f` rounds half up from the shortest decimal form: `String.format(Locale.ROOT, "%.2f", 1.005)` is `1.01` (run). The `%f` default precision is 6 (Java SE API; verify before use).
- `DecimalFormat` with the default rounding mode gives `2` for `2.5` and `4` for `3.5`, so its default is `HALF_EVEN` (run). Its locale follows the default FORMAT locale (Java SE API; verify before use).

## Money checklist

- Store amounts as `BigDecimal` with the source's scale. Do not store them as `double`.
- Round only with `setScale(n, mode)`, or with a `divide` overload that takes a scale and a mode (verify before use); name the mode in the function.
- Test each tie direction (`2.5` and `-2.5`) and each boundary of the scale.
- Compare amounts with `compareTo` unless the scale is part of the contract.
- Output: format with an explicit locale or fixed digits; never with the default locale.

## Dates and time

- `java.time` is the main API for dates, times, instants and durations; its classes are immutable and thread-safe (Java SE API).
- `ZoneId.systemDefault()` queries the default time zone (Java SE API). Run: `America/Sao_Paulo` on the check machine.
- `ZoneId` gives the rules for converting between an `Instant` and a `LocalDateTime` (Java SE API). The same instant prints differently by zone (run): `Instant.parse("2026-03-29T00:30:00Z").atZone(ZoneId.of("America/Sao_Paulo"))` is `2026-03-28T21:30-03:00[America/Sao_Paulo]`; with `ZoneId.of("UTC")` it is `2026-03-29T00:30Z[UTC]`.
- `LocalDate.of(2026, 1, 31)` prints `2026-01-31` (run): `java.time` months are one-based.
- `Calendar.JANUARY` is 0 (run). `Calendar.set(2026, 0, 32)` rolls over to February 1 (run): `Calendar` is lenient by default (Java SE API).

## Time checklist

- Store instants as UTC `Instant`. Convert with an explicit `ZoneId` taken from the source's data or config, never from `ZoneId.systemDefault()` in the target code.
- Format with an explicit `Locale` and zone; do not rely on the machine.
- Check every call that reads the default zone or the default locale; these are run-time values, not constants in the code.
- Month arithmetic: check whether the source uses one-based or zero-based months before copying the numbers.
- Test a value on each side of a zone change, and an instant that prints differently in two zones (run example above).
