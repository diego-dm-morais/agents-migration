# Testing and tooling (.NET 10)

Read this when you write tests, set up the gate, or choose a tool. Commands here were checked against the official .NET CLI pages on 2026-10-29.

## Test project layout

- One test project per production project. The name `<Project>.Tests` is a convention, not a tool rule.
- One test class per unit. Test method names carry the rule id: `BR_ROUND_002_rounds_ties_to_even`. C# identifiers cannot hold hyphens.
- Golden files live in a folder per unit, for example `tests/golden/<unit>/<case>.json`. They are written from the source, never from the target. (Practice.)

## Project file

The structure of a test project, from the sample in the `dotnet test` page. The sample targets `net8.0` and pins package versions; this skeleton targets `net10.0`, and the versions are placeholders to fill from NuGet before pinning:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="x.y.z" />
    <PackageReference Include="xunit" Version="x.y.z" />
    <PackageReference Include="xunit.runner.visualstudio" Version="x.y.z" />
  </ItemGroup>
</Project>
```

- `Microsoft.NET.Test.Sdk` is the test host. `xunit` is the framework. `xunit.runner.visualstudio` is the adapter that lets xUnit work with the test host. Source: https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-test
- The docs name MSTest, NUnit and xUnit.net as the frameworks. Use the one the repository already has. For the adapter of another framework, verify before use.

## Running

- `dotnet test` builds the solution and runs the tests of each test project. Source: https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-test
- `dotnet test --no-build` runs the existing build output. It also implies `--no-restore`. Source: https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-test-vstest
- `dotnet test --filter "FullyQualifiedName~BR_ROUND"` runs the tests whose full name contains the text. Operators: `=` exact match, `!=` not exact, `~` contains, `!~` not contains. Join expressions with `&` (AND) or `|` (OR). A bare expression means `FullyQualifiedName~`. Source: dotnet-test-vstest.
- `dotnet test --logger "trx;logfilename=testResults.trx"` writes a TRX file into the `TestResults` folder of the test project folder. Source: dotnet-test-vstest.
- Runner: VSTest is the default. The SDK setting `"test": { "runner": "Microsoft.Testing.Platform" }` in `global.json` selects the Microsoft Testing Platform runner. The setting is available from the .NET 10 SDK, and that runner needs platform version 1.7 or later. Source: https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-test

## Doubles and fakes

- Put each external dependency behind an interface that the code owns. Write a small fake class by hand. It returns the answers the test sets and records the calls it receives. (Practice.)
- Pass the clock, randomness and configuration in as parameters. A unit test never reads the real environment. (Practice.)
- Do not replace a global or a static member for one test. Another test in the same process may read it. (Practice.)

## Golden comparison

- Load the expected output from a file written from the source. Compare parsed values, not raw text, unless the source output is text.
- Money: compare the text of a `decimal` when the scale is part of the behavior. `1.50m == 1.5m` is true, so an equality check does not see the scale.
- A missing golden file fails the test. Never create it from the target's output. (Practice.)

## Gate commands

| Gate | Command | Pass means |
|---|---|---|
| SDK | `dotnet --version` | Prints the SDK version the `dotnet` commands use. `global.json` can change it. Source: https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet |
| Build | `dotnet build -warnaserror` | No errors and no warnings. `-warnAsError` with no value treats all warnings as errors. Source: https://learn.microsoft.com/en-us/visualstudio/msbuild/msbuild-command-line-reference. The exit code of a failed build: verify before use. |
| Tests | `dotnet test` | Exit 0 when all tests pass. Exit 1 when a test fails or the run is aborted (VSTest mode). Source: dotnet-test-vstest. |
| Format | `dotnet format --verify-no-changes` | Exit 0. Non-zero when any file would be formatted. Source: https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-format |

Report each command, its exit code, and the line that decides the result. Do not report a gate that did not run.

## Tool choice

- Use what the repository already has. Add a tool only when the plan names it and the gate needs it.
- `dotnet format` reads `.editorconfig`. Without one, it uses a default set of preferences. Options include `--include`, `--exclude` and `--severity`. Subcommands: `whitespace`, `style` and `analyzers`.
- `dotnet build`, `dotnet test` and `dotnet format` restore implicitly. `--no-restore` skips the restore. Source: dotnet-build, dotnet-format.
- Restore state is a file the SDK writes. Do not edit it by hand. (Practice.)

## Sources

- https://learn.microsoft.com/en-us/dotnet/core/testing/unit-testing-with-dotnet-test (verify before use)
- https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-test
- https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-test-vstest
- https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-build
- https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-format
- https://learn.microsoft.com/en-us/dotnet/core/tools/global-json
- https://learn.microsoft.com/en-us/visualstudio/msbuild/msbuild-command-line-reference
