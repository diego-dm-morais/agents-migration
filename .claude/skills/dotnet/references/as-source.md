# Reading C# as the source

Read this when the source you migrate from is C#. These are the places where the behavior is easy to miss, because it is in the runtime or the compiler, not in the code you read. Each trap has an input and the output the documentation gives.

## Integers and overflow

- Integer arithmetic wraps silently by default. With `int a = int.MaxValue; int b = 3;`, the value of `unchecked(a + b)` is `-2147483646`. Look for counters, sums and identifiers in `int` or `long`. Source: https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/arithmetic-operators
- A `checked` block does not reach into called methods. `int Multiply(int a, int b) => a * b;` called as `Multiply(2, int.MaxValue)` inside a `checked` block returns `-2` and throws nothing. Check each method body for its own context. Source: https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/statements/checked-and-unchecked
- A `checked` overflow throws `OverflowException`. The docs example prints "Arithmetic operation resulted in an overflow." for `uint.MaxValue + 3` in a checked context, and `2` in an unchecked one.
- Integer division by zero throws `DivideByZeroException`. `int.MinValue / -1` throws `ArithmeticException` even in an unchecked context.
- Integer division truncates: `-13 / 5` is `-2`. Remainder follows the left operand: `-5 % 4` is `-1`.

## Explicit conversions

- On .NET 9 and later, on x86 and x64, the unchecked `(int)x` saturates: `x` above `int.MaxValue` gives `int.MaxValue` (2147483647), `x` below `int.MinValue` gives `int.MinValue`, and `NaN` gives `0`. `checked((int)x)` still throws `OverflowException` when `x` is out of range. Sources: https://learn.microsoft.com/en-us/dotnet/core/compatibility/jit/9.0/fp-to-integer; checked-and-unchecked. The checked-and-unchecked example still prints `-2147483648` for `unchecked((int)double.MaxValue)`, which conflicts with the breaking-change page; verify before use on the target runtime.
- A `decimal` converted to an integral type out of range throws `OverflowException` in any context.

## Floating point

- `double a = 0.1; double b = 3 * a;` gives `b == 0.3` as `false`, and `b - 0.3` prints `5.55111512312578E-17`. Source: arithmetic-operators.
- `.41f % .2f` prints `0.00999999`. Look for money or counts kept as `double` or `float`.
- `float` and `double` overflow and division by zero do not throw. `1.0 / 0.0` is `Infinity`, and `0.0 / 0.0` is `NaN`.

## Decimal and rounding

- `Math.Round` rounds midpoints to even by default. `Math.Round(3.75m, 1)` and `Math.Round(3.85m, 1)` both give `3.8`. A source that rounds half up, or away from zero, gives `3.9` for `3.85`. Source: https://learn.microsoft.com/en-us/dotnet/api/system.math.round
- `decimal` keeps trailing zeros in its scale (0 to 28). `1.50m == 1.5m` is true. The scale shows only in text formatted with a format string. Look for string output of money. Source: https://learn.microsoft.com/en-us/dotnet/api/system.decimal
- `16.8m / 4.1m` prints `4.0975609756097560975609756098`. The same division with `double` prints `4.09756097560976`. Source: arithmetic-operators.
- A `float` or `double` does not convert implicitly to `decimal`. A source that mixes them has an explicit cast; find it.

## Strings and culture

- Comparisons use the thread's current culture. That culture defaults to the operating system setting. A source that relies on the default is not portable. Source: https://learn.microsoft.com/en-us/dotnet/standard/base-types/best-practices-strings
- Culture-sensitive by default: `String.Compare` without `StringComparison`, `CompareTo`, `StartsWith(string)`, `EndsWith(string)`, `IndexOf(string)`, `LastIndexOf(string)`. `IndexOf(char)` is ordinal.
- Ordinal search looks for the exact characters, with no linguistic rules. `"resume".IndexOf('e', StringComparison.Ordinal)` is `1`. The precomposed `"r\u00E9sum\u00E9"` gives `-1`. The decomposed `"r\u00E9sume\u0301"` (the `e` followed by U+0301) gives `5`. Source: https://learn.microsoft.com/en-us/dotnet/standard/base-types/best-practices-strings
- `OrdinalIgnoreCase` makes `'d'` and `'D'` equal, and `'a'` and `'á'` not equal. `"windows"` does not match `"Windows"` under `Ordinal`.
- Turkish casing: in `tr-TR`, the uppercase of `i` is `İ` (U+0130), and `ı` (U+0131) uppercases to `I` (verify before use). A check that uppercases text, or compares it without an ordinal mode, changes with the culture.

## Dates and time

- `DateTimeKind` is `Unspecified` (0), `Utc` (1) or `Local` (2). The default for a new `DateTime` is `Unspecified`. Source: https://learn.microsoft.com/en-us/dotnet/api/system.datetime.kind
- `ToUniversalTime()` treats an `Unspecified` value as local. `ToLocalTime()` treats it as UTC. Source: DateTime.Kind remarks and example.
- The docs sample shows one wall-clock value, `5/6/2005 02:34:42 PM`, as `Unspecified`: `ToLocalTime` gives `07:34:42 AM` and `ToUniversalTime` gives `09:34:42 PM`. The sample does not state its machine's zone, so the result depends on the machine. Check the source's zone rule.
- `Kind` is used by conversions and not by comparison or arithmetic (DateTimeKind remarks). Two values that differ only in `Kind` compare by their ticks. Verify with a test before relying on it.
- `DateTime.Now` is local and `DateTime.UtcNow` is UTC. Output built from `Now` depends on the machine.
- `DateTimeOffset` can reflect a single point in time in any time zone. A source that keeps an offset should map to it, not to `DateTime`.

## Collections and order

- `Dictionary` enumeration order is undefined. Look for output that lists a dictionary without sorting. Source: https://learn.microsoft.com/en-us/dotnet/api/system.collections.generic.dictionary-2
- `foreach` over a `Dictionary` only reads. It does not write back. Source: the same page.

## Nullability

- Nullable reference types are compile-time only. The runtime behavior of the program is unchanged. Look for each null that the source checks at run time. Source: https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/null-safety/nullable-reference-types
- `Student s = default;` gives no warning, and its non-nullable reference fields are null at run time.
- `new string[3]` holds three elements that are null at run time, until each one is assigned. Source: the nullable reference types page, "Arrays of references and structs".
- `!` (null-forgiving) silences the warning and checks nothing.

## Language version and syntax

- `LangVersion` in the project file sets the language. A source built with C# 14 features (for example the `field` keyword or null-conditional assignment) changes syntax, not the run-time rules (verify before use). Source: https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-14
- A source on `LangVersion` `latest` can build differently on another machine. Record the value the source sets. Source: https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/configure-language-version

## Test and exit behavior

- `dotnet test` exits 0 when all tests pass and 1 on failure, in VSTest mode. A source gate that reads the exit code depends on that value. Source: https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-test-vstest
