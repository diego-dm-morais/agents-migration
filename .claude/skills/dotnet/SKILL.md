---
name: dotnet
description: "C# on .NET 10 LTS and later (C# 14): language rules, integer overflow, nullable reference types, decimal and Math.Round, DateTime Kind, culture-sensitive strings, Dictionary order, and the build, test and format gate. Use for C# code, .csproj files, dotnet test suites, or migrations to or from C#."
metadata:
  baseline: "C# 14 on .NET 10 LTS"
  verified: "2026-10-29"
---

# dotnet (C# 14 on .NET 10 LTS)

Practice for C# code that runs on .NET. The baseline is .NET 10 LTS with C# 14. The facts here were checked against the official .NET and C# documentation on 2026-10-29. Sources are listed at the end.

## 1. Scope and versions

- Target the framework the project declares in `<TargetFramework>` in the `.csproj` file. If the repository declares none, use `net10.0` and say so in the report.
- .NET 10 is LTS and in active support. The latest patch on 2026-10-29 is 10.0.14. End of support is November 14, 2028.
- .NET 8 (LTS) and .NET 9 (STS) both reach end of support on November 10, 2026. Do not start new code on them.
- C# 14 ships with .NET 10. The language version follows the target framework unless the project sets `LangVersion`.
- C# 15 is the default only for `net11.0` with the .NET 11 SDK, which is prerelease. Do not use C# 15 syntax in a `net10.0` project.
- Do not set `<LangVersion>latest</LangVersion>`. Its meaning changes from one machine to another.
- Projects from recent templates set `<Nullable>enable</Nullable>`. Older projects need it added, or the nullable rules in section 6 do not apply.

## 2. Layout and build

- Project file: an SDK-style `.csproj` with `<Project Sdk="Microsoft.NET.Sdk">`, a `<PropertyGroup>` with `<TargetFramework>` and `<Nullable>`, and an `<ItemGroup>` for packages.
- The docs use `Directory.Build.props` to set `LangVersion` for several projects at once. Use the same file for other settings shared by a solution.
- `dotnet build` builds the project and its dependencies. It restores implicitly unless `--no-restore` is given.
- Pin the SDK with `global.json` when the repository needs a fixed version. `sdk.version` takes a full version such as `10.0.100`, with no wildcard. `sdk.rollForward` sets the policy: `disable` requires the exact version, and `latestFeature` takes the highest installed feature band and patch of the same major and minor.
- Split by responsibility: pure classes (no I/O) for logic, thin adapters for files, network, clock and environment. Tests call the pure classes. (Practice.)

## 3. Idioms

- Nullable reference types: `string` is non-nullable and `string?` is nullable. Test with `is null` or `is not null`; the null-state analysis follows those tests.
- Collection expressions: `string[] values = ["a", "b", "c"];` initializes every element.
- `required` members: callers must set them through an object initializer. The nullable docs prefer them over `default` for struct fields that must not be null.
- Null-conditional assignment (C# 14): `customer?.Order = GetCurrentOrder();` evaluates the right side only when `customer` is not null.
- Name the comparison in every string call: `string.Equals(a, b, StringComparison.Ordinal)`.
- Format persisted numbers and dates with the invariant culture, not the current culture.
- Use `checked` or `unchecked` blocks wherever the source's overflow behavior matters. Section 6 gives the defaults.

## 4. Errors, resources and exit (use the language's own words)

- Exceptions thrown by the runtime:
  - Integer division by zero: `DivideByZeroException`, always.
  - `int.MinValue / -1`: `ArithmeticException`, even in an unchecked context.
  - Overflow in a checked context: `OverflowException`.
  - `decimal` arithmetic overflow: `OverflowException`, always.
  - `decimal` converted to an integral type out of range: `OverflowException`, in any context.
- `float` and `double` never throw on overflow or division by zero. They give `Infinity` or `NaN`.
- Explicit conversions from `float` or `double` to an integral type follow the same overflow context as integer arithmetic. Source: checked-and-unchecked.
- Map each source exception to one exception type. Keep the source's message text when the source returns it.
- `dotnet test` exits with 0 when all tests pass and with 1 when a test fails or the run is aborted (VSTest mode, the default).

## 5. Concurrency

- Culture is per thread. Comparisons use "the thread's current culture or locale", which defaults to the operating system setting. Code on a worker thread can compare differently from code on another thread. Make the culture explicit where the source relies on the process culture.
- Enumeration order of a `Dictionary` is undefined (section 6). Do not depend on it across threads or runs.
- Shared state that is read, then awaited, then written is a race. Keep such a section synchronous, or guard it. (Practice.)
- Tests must run under the same culture and comparison as production. A test that passes on one machine only is a parity failure.

## 6. Data and numbers (parity traps)

- `Math.Round` rounds midpoints to even by default. `Math.Round(3.75m, 1)` and `Math.Round(3.85m, 1)` both give `3.8`. With `MidpointRounding.AwayFromZero`, `3.85m` gives `3.9`.
- `decimal` keeps trailing zeros in its scale, which runs from 0 to 28. `1.50m == 1.5m` is true, because the scale does not take part in comparison. The scale shows only in text formatted with a format string.
- Integer overflow wraps silently in the default context. With `int a = int.MaxValue; int b = 3;`, the expression `a + b` gives `-2147483646`. A constant expression is checked: `int c = int.MaxValue + 1;` is a compile-time error.
- Integer division truncates toward zero: `-13 / 5` is `-2`. The sign of `a % b` follows `a`: `-5 % 4` is `-1`.
- Binary floating point is inexact: `double a = 0.1; double b = 3 * a;` gives `b == 0.3` as `false`. Use `decimal` for money.
- These string overloads are culture-sensitive by default: `String.Compare` without `StringComparison`, `CompareTo`, `StartsWith(string)`, `EndsWith(string)`, `IndexOf(string)`, `LastIndexOf(string)`. `IndexOf(char)` is ordinal.
- `DateTime.Kind` changes what the conversions do. Comparison does not use it. An `Unspecified` value is treated as local by `ToUniversalTime()`.
- `Dictionary` enumeration order is undefined.
- Integer ranges are fixed by type: `int` is -2,147,483,648 to 2,147,483,647, and `int.MaxValue` is a compile-time constant. Source: https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/integral-numeric-types
- `DateTime.Now` is local time. A value built from it depends on the machine's time zone, so tests build dates from explicit values.
- Nullable reference types are compile-time only. They add no run-time check.
- Details and examples: `references/csharp-language.md` and `references/decimal-and-time.md`.

## 7. Testing

- Runner: `dotnet test`. The frameworks the docs name are MSTest, NUnit and xUnit.net. Use the one the repository already has.
- The default runner is VSTest. With the .NET 10 SDK, `"test": { "runner": "Microsoft.Testing.Platform" }` in `global.json` selects the Microsoft Testing Platform runner, which needs platform version 1.7 or later.
- Filter: `dotnet test --filter "FullyQualifiedName~<text>"`. Operators are `=`, `!=`, `~` and `!~`. Combine expressions with `&` and `|`.
- Filter by category: `TestCategory` for MSTest, `Category` or `TestCategory` for NUnit, and `Traits` for xUnit. The docs give `--filter Category=bvt` for an xUnit trait with the key `Category`.
- `--no-build` runs the existing build output and skips the restore. Build first in the same tree, so the output is the code under test. (Practice.)
- Doubles: put each external dependency behind an interface the code owns, and write a small fake class by hand. Pass the clock, randomness and configuration as parameters. Do not patch globals. (Practice.)
- Golden tests: compare parsed values, and load the expected output from a file written from the source. Never write the expected file from the target's output. (Practice.)
- Pin the culture in tests that touch culture-sensitive code. The docs show the pattern `Thread.CurrentThread.CurrentCulture = new CultureInfo("en-US");`.

## 8. Quality gate (exact commands)

Run each command, read its result, and report the real output. A gate that did not run is not a pass.

1. `dotnet --version`: prints the SDK version the `dotnet` commands use. `global.json` can change it. Expect `10.0.x`.
2. `dotnet build -warnaserror`: `-warnAsError` with no value turns every warning into an error. Switch names are not case-sensitive, and `dotnet build` passes MSBuild switches through. Pass: no errors and no warnings. The exit code of a failed build: verify before use.
3. `dotnet test`: exit 0 when all tests pass, 1 when a test fails (VSTest mode). Pass: exit 0.
4. `dotnet format --verify-no-changes`: exits non-zero when any file would be formatted. Pass: exit 0. `dotnet format` can restore and run analyzers, so run it on trusted code only.
5. Run every command from the repository root. `dotnet` looks for `global.json` from the current directory up through its ancestors. Source: https://learn.microsoft.com/en-us/dotnet/core/tools/global-json

## 9. Migrating TO .NET

- Parity beats idiom. Keep the source's numeric, string, date and ordering semantics. Write a test for each tie, boundary and error path before the code.
- Use `decimal` for money. Round with an explicit `MidpointRounding` value taken from the source's rule, and never rely on the default when the source differs.
- Use `checked` where the source aborts on overflow. Use the default unchecked context only where the source wraps.
- Name `StringComparison` on each comparison and each search.
- Do not enumerate a `Dictionary` when output order matters. Keep the order the source defines.
- Keep one exception type and one message per source error.
- Keep the source's public names only when an external caller depends on them. Otherwise use idiomatic names and record the mapping. (Practice.)
- Name each rounding function for its tie rule, so a reader sees the rule in the name. (Practice.)
- For the constructs a unit usually needs (rounding, text, dates, errors, I/O, collections), see `references/as-target.md`.

## 10. Migrating FROM .NET

- Behavior hides in the runtime: the default overflow context, the `Math.Round` tie rule, culture-sensitive string calls, `DateTime.Kind`, the decimal scale, `Dictionary` order, and nullable annotations, which do not exist at run time.
- Implicit conversions hide type changes: an `int` converts implicitly to `double` and to `decimal`, but `float` and `double` never convert implicitly to `decimal`. Source: https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/numeric-conversions
- Encodings hide in `Encoding.Default`: on .NET Framework it is the system ANSI code page, and on .NET Core and later it always returns `UTF8Encoding`. Source: https://learn.microsoft.com/en-us/dotnet/api/system.text.encoding.default
- Time zones hide in `DateTime.Kind`, which changes what the conversions do, and in `DateTime.Now`, which is the machine's local time. Source: https://learn.microsoft.com/en-us/dotnet/api/system.datetime.kind
- Read `references/as-source.md` first. Then read `references/csharp-language.md` and `references/decimal-and-time.md` for the rules.
- Treat each clock read, environment read and random value in the source as an input in the extraction, never as a constant. (Practice.)

## 11. Anti-patterns

- `double` or `float` for money.
- `Math.Round(x)` with no `MidpointRounding` where the source rounds away from zero.
- String comparison or search with no `StringComparison` on identifiers, codes or protocol values.
- Output that depends on `Dictionary` enumeration order.
- `!` (null-forgiving) to silence a warning without a check.
- A `checked` block around a call, expecting the called method's arithmetic to be checked. The context does not reach into the method.
- `<LangVersion>latest</LangVersion>`.
- Treating `string?` as a run-time check.
- A struct with non-nullable reference fields created with `default`.
- `DateTime.Now` in output that must be the same on every machine.

## Library registry

- Registry: NuGet, https://www.nuget.org/ (package pages show versions, the target frameworks each version supports, license and last publish date).
- Before adding a package, check the .NET base class library first. Then search NuGet, open the package page, and confirm: latest version, supported `TargetFramework` (`netX.0`) compatible with the target project, license, last publish, and dependencies.
- Read the exact versions from the package page or `dotnet package search <name>` and pin them in the `.csproj` (`PackageReference`) already used by the repository. Commit the lock file if the repository uses one.
- Full procedure and evaluation checks: `.claude/skills/migration-conduct/references/library-research.md`.

## Sources

- NuGet: https://www.nuget.org/
- C# guide: https://learn.microsoft.com/en-us/dotnet/csharp/
- What's new in C# 14: https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-14
- What's new in C# 15: https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-15
- Configure language version: https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/configure-language-version
- Nullable reference types: https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/null-safety/nullable-reference-types
- Integral numeric types: https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/integral-numeric-types
- Arithmetic operators: https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/arithmetic-operators
- Checked and unchecked statements: https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/statements/checked-and-unchecked
- Floating point-to-integer conversions are saturating (.NET 9): https://learn.microsoft.com/en-us/dotnet/core/compatibility/jit/9.0/fp-to-integer
- Built-in numeric conversions: https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/numeric-conversions
- Encoding.Default: https://learn.microsoft.com/en-us/dotnet/api/system.text.encoding.default
- Math.Round: https://learn.microsoft.com/en-us/dotnet/api/system.math.round
- Decimal: https://learn.microsoft.com/en-us/dotnet/api/system.decimal
- DateTime.Kind: https://learn.microsoft.com/en-us/dotnet/api/system.datetime.kind
- DateTimeKind: https://learn.microsoft.com/en-us/dotnet/api/system.datetimekind
- Dictionary: https://learn.microsoft.com/en-us/dotnet/api/system.collections.generic.dictionary-2
- Comparing strings in .NET: https://learn.microsoft.com/en-us/dotnet/standard/base-types/best-practices-strings
- dotnet command: https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet
- dotnet build: https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-build
- dotnet test: https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-test
- dotnet test with VSTest: https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-test-vstest
- dotnet format: https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-format
- global.json: https://learn.microsoft.com/en-us/dotnet/core/tools/global-json
- MSBuild command-line reference: https://learn.microsoft.com/en-us/visualstudio/msbuild/msbuild-command-line-reference
- Testing with dotnet test: https://learn.microsoft.com/en-us/dotnet/core/testing/unit-testing-with-dotnet-test (verify before use)
- .NET support policy: https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core
