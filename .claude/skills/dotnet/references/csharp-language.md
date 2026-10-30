# C# language rules (C# 14 on .NET 10)

Read this when you decide the language version, the overflow context, nullable annotations, string comparison, or the order of a collection.

## Language version

- C# 14 ships with .NET 10. Source: https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-14
- C# 14 features that change syntax, not the run-time rules (verify before use):
  - Extension members, including extension properties and static extension members.
  - The `field` keyword in property accessors. A member named `field` needs `@field` or `this.field` to disambiguate.
  - Null-conditional assignment: `customer?.Order = GetCurrentOrder();`. The right side is evaluated only when `customer` is not null.
  - `nameof` accepts an unbound generic type: `nameof(List<>)` is `List`.
  - Implicit conversions between `T[]`, `Span<T>` and `ReadOnlySpan<T>`.
  - Modifiers on simple lambda parameters: `(text, out result) => ...`.
  - Partial constructors and partial events.
  - User-defined compound assignment operators.
- C# 15 features need the .NET 11 SDK: collection expression arguments, union types, closed hierarchies, extension indexers, labeled `break` and `continue`, non-virtual static interface members, and a memory safety preview. Do not use them in a `net10.0` project. A language version newer than the target framework is not supported. Source: https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/configure-language-version
- Set `LangVersion` only to a fixed value. Do not use `latest`.

## Integer overflow context

- The default context for non-constant expressions is unchecked. The compiler option `CheckForOverflowUnderflow` is unset by default. Source: https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/statements/checked-and-unchecked
- `unchecked` truncates: `uint a = uint.MaxValue; unchecked(a + 3)` is `2`. `checked(a + 3)` throws `OverflowException`.
- Constant expressions are checked by default. `int c = int.MaxValue + 1;` is a compile-time error. `unchecked(int.MaxValue + 1)` compiles and gives `-2147483648`, because addition wraps from the maximum to the minimum value.
- `checked` and `unchecked` affect only the operations textually inside them. A method called from a `checked` block keeps its own context. Source: the same page.
- `int.MinValue / -1` throws `ArithmeticException` even in an unchecked context. Source: https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/arithmetic-operators
- `decimal` arithmetic overflow throws `OverflowException` in every context. Other `decimal` rules are in `decimal-and-time.md`.

## Nullable reference types

- Nullable reference types are a compile-time feature. The run-time behavior is unchanged. `string` and `string?` are both `System.String` at run time. Source: https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/null-safety/nullable-reference-types
- Null-state analysis classifies each reference as not-null or maybe-null. Assignments and null checks update that state. The analysis does not trace into method bodies. Use the nullable analysis attributes, such as `NotNullWhen`, to express a contract on a signature.
- `!` tells the compiler to trust the expression. Nothing is checked at run time. The docs say to use it sparingly.
- Pitfalls the docs describe:
  - `Student s = default;` gives no warning. Its non-nullable reference fields are null.
  - `new string[3]` holds null elements until each one is assigned.
  - Prefer `required` members or a constructor for a struct with reference fields.

## Strings and comparison

- Culture-sensitive by default: `String.Compare` without `StringComparison`, `String.CompareTo`, `StartsWith(string)`, `EndsWith(string)`, `IndexOf(string)`, `LastIndexOf(string)`. `IndexOf(char)` is ordinal. Source: https://learn.microsoft.com/en-us/dotnet/standard/base-types/best-practices-strings
- Comparisons use the thread's current culture. It defaults to the operating system setting.
- `StringComparison.Ordinal` compares characters with no linguistic rules: `"windows"` does not match `"Windows"`.
- `StringComparison.OrdinalIgnoreCase` ignores case for ASCII letters and for accented pairs such as `á` and `Á`, but `a` and `á` stay different.
- Ordinal search: `"resume".IndexOf('e', StringComparison.Ordinal)` is `1`. The precomposed `"r\u00E9sum\u00E9"` (é as one character) gives `-1`. The decomposed `"r\u00E9sume\u0301"` (the `e` followed by the combining accent U+0301) gives `5`. Source: https://learn.microsoft.com/en-us/dotnet/standard/base-types/best-practices-strings
- Turkish casing: in `tr-TR`, `i` uppercases to `İ` (U+0130), and `ı` (U+0131) uppercases to `I` (verify before use). The docs name this as the Turkish-I problem.
- Use the invariant culture to persist non-string data as text. Source: the same string page.

## Collections

- `Dictionary<TKey, TValue>` enumerates in an order the docs leave undefined. Source: https://learn.microsoft.com/en-us/dotnet/api/system.collections.generic.dictionary-2
- `foreach` over a `Dictionary` allows only reading from the collection. Source: the same page.
- Collection expressions use the `[1, 2, 3]` syntax. Source: https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/null-safety/nullable-reference-types

## Operators

- Integer `/` rounds toward zero. The remainder `%` has the sign of the left operand. Source: https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/arithmetic-operators
- Integer division by zero throws `DivideByZeroException`. `decimal` division by zero throws `DivideByZeroException` too.
- `float` and `double` do not throw on overflow or division by zero. `1.0 / 0.0` is `Infinity` and `0.0 / 0.0` is `NaN`.

## Explicit conversions

- On .NET 9 and later, on x86 and x64, floating-point-to-integer conversions saturate. For `unchecked((int)x)`: `x` above `int.MaxValue` gives `int.MaxValue` (2147483647), `x` below `int.MinValue` gives `int.MinValue`, and `NaN` gives `0`. `checked((int)x)` still throws `OverflowException` when `x` is out of range. Sources: https://learn.microsoft.com/en-us/dotnet/core/compatibility/jit/9.0/fp-to-integer; checked-and-unchecked. The checked-and-unchecked example still prints `-2147483648` for `unchecked((int)double.MaxValue)`, which conflicts with the breaking-change page; verify before use on the target runtime.
- A `decimal` converted to an integral type out of range throws `OverflowException` in any context. Source: the same page.

## Sources

- https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-14
- https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-15
- https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/configure-language-version
- https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/statements/checked-and-unchecked
- https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/arithmetic-operators
- https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/null-safety/nullable-reference-types
- https://learn.microsoft.com/en-us/dotnet/standard/base-types/best-practices-strings
- https://learn.microsoft.com/en-us/dotnet/api/system.collections.generic.dictionary-2
