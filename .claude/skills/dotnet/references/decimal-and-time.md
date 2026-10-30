# Decimal, rounding and time (.NET 10)

Read this when a source computes money or rounds values, or when it reads, stores or converts dates and times.

## decimal

- A `decimal` is a sign, a numeric value of decimal digits, and a scaling factor that places the decimal point. Source: https://learn.microsoft.com/en-us/dotnet/api/system.decimal
- The scale runs from 0 to 28 digits (`Decimal.Scale`).
- Trailing zeros are kept in the scale. They do not affect arithmetic or comparison. They can show in text when a format string is applied. `1.50m == 1.5m` is true. Verify the exact text of a formatted value with a test before use.
- Division keeps many digits: `16.8m / 4.1m` prints `4.0975609756097560975609756098`. The same division with `double` prints `4.09756097560976`. Source: https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/arithmetic-operators
- Multiplication: `0.1m * 23.4m` prints `2.34`.
- Remainder: `5.9m % 3.1m` prints `2.8`.
- Overflow of `decimal` arithmetic throws `OverflowException` in every context. Division by zero throws `DivideByZeroException`.
- A `float` or `double` does not convert implicitly to `decimal`. Use an explicit conversion, and check that the source does the same.
- A `decimal` converted to an integral type out of range throws `OverflowException` in any context.

## Rounding with Math.Round

- Overloads, from the `Math.Round` page: `Round(Decimal)`, `Round(Double)`, `Round(Decimal, Int32)`, `Round(Decimal, MidpointRounding)`, `Round(Double, Int32)`, `Round(Double, MidpointRounding)`, `Round(Decimal, Int32, MidpointRounding)` and `Round(Double, Int32, MidpointRounding)`. Source: https://learn.microsoft.com/en-us/dotnet/api/system.math.round
- The overloads without a `MidpointRounding` argument use `ToEven`. The page states: "By default, the Round method uses the round to nearest even convention."
- With `MidpointRounding.AwayFromZero`, midpoints go to the next number away from zero: "3.75 rounds to 3.8, 3.85 rounds to 3.9, -3.75 rounds to -3.8, and -3.85 rounds to -3.9."
- With `MidpointRounding.ToEven`, midpoints go to the nearest even number: "both 3.75 and 3.85 round to 3.8, and both -3.75 and -3.85 round to -3.8."
- Concrete values on `decimal`, which is exact: `Math.Round(3.75m, 1)` is `3.8` and `Math.Round(3.85m, 1)` is `3.8` under `ToEven`. `Math.Round(3.85m, 1, MidpointRounding.AwayFromZero)` is `3.9`.
- Derived from the rule: `Math.Round(2.5m)` is `2` and `Math.Round(3.5m)` is `4` under the default.
- The page says rounding to nearest even "is the standard in financial and statistical operations". It also says repeated rounding with `ToEven` "reduces the rounding error that is caused by consistently rounding midpoint values in a single direction".
- `MidpointRounding` has more members since .NET Core 3.0. Verify their names before use.

## Floating point

- `double a = 0.1; double b = 3 * a;` gives `b == 0.3` as `false`. `b - 0.3` prints `5.55111512312578E-17`. Source: https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/arithmetic-operators
- `.41f % .2f` prints `0.00999999`. Same source.
- `float` and `double` never throw on overflow or division by zero. `1.0 / 0.0` is `Infinity`, and `0.0 / 0.0` is `NaN`.
- Use `decimal` where the source is decimal. Use `double` only where the source is floating point, and compare its output text with the source's output. (Practice.)

## DateTime and DateTimeKind

- `DateTimeKind` values: `Unspecified` (0), `Utc` (1), `Local` (2). The `DateTime.Kind` property defaults to `Unspecified`. Source: https://learn.microsoft.com/en-us/dotnet/api/system.datetime.kind and https://learn.microsoft.com/en-us/dotnet/api/system.datetimekind
- `DateTime.Now` is the current time in the local zone, with `Kind` `Local`. `DateTime.UtcNow` is the current UTC time, with `Kind` `Utc`.
- `SpecifyKind` sets `Kind` and keeps the wall-clock value. The sample shows `SpecifyKind(saveNow, DateTimeKind.Utc)` displaying the same `02:34:42 PM` with `Kind = Utc`.
- `ToLocalTime()`:
  - `Utc`: converted.
  - `Local`: not converted.
  - `Unspecified`: treated as UTC, then converted.
- `ToUniversalTime()`:
  - `Utc`: not converted.
  - `Local`: converted.
  - `Unspecified`: treated as local, then converted.
- The docs sample shows the same `Unspecified` wall-clock value as `ToLocalTime` `07:34:42 AM` and `ToUniversalTime` `09:34:42 PM`. The sample does not state its machine's zone.
- `DateTimeKind` is used in conversions. It is not used in comparison or arithmetic (DateTimeKind remarks). Verify with a test before relying on how two values that differ only in `Kind` compare.
- `DateTimeOffset` reflects a single point in time in any time zone. A source that keeps an offset maps to it. (DateTime.Kind remarks.)
- The time zone conversion articles are linked from the `DateTime` pages (converting between time zones). Verify before use.

## Checks for a migrated unit

- Each money value: its scale in the source's output, and a test for each tie.
- Each rounding call: the `MidpointRounding` the source uses, and a test on both tie directions.
- Each date: its `Kind` at creation, and the conversion the source performs.
- Each `Math.Round` overload: default `ToEven`, unless the source states another mode.

## Sources

- https://learn.microsoft.com/en-us/dotnet/api/system.decimal
- https://learn.microsoft.com/en-us/dotnet/api/system.math.round
- https://learn.microsoft.com/en-us/dotnet/api/system.datetime.kind
- https://learn.microsoft.com/en-us/dotnet/api/system.datetimekind
- https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/arithmetic-operators
