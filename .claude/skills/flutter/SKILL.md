---
name: flutter
description: "Flutter 3.47 stable with Dart 3.x for Dart and Flutter code: null safety and late, int and double on the VM and the web, DateTime and UTC, async and isolates, widgets and State, flutter test, dart format and dart analyze gates. Use for Dart code, pubspec.yaml, Flutter widgets, or migrations to or from Dart or Flutter."
metadata:
  baseline: "Flutter 3.47 stable, Dart 3.x (Dart docs reflect 3.13.3)"
  verified: "2026-10-29"
---

# flutter (Flutter 3.47 stable, Dart 3.x)

Practice for Dart and Flutter code, used when Dart or Flutter is the source or the target of a migration. The baseline is Flutter 3.47 stable with Dart 3.x. Facts were checked against the official Dart and Flutter pages on 2026-10-29. No Flutter or Dart toolchain is installed on the machine where this skill was written, so no gate command was run. Sources are listed at the end.

## 1. Scope and versions

- Flutter 3.47 is the newest stable release on https://docs.flutter.dev/release/whats-new (dated 12 August 2026). The release archive page did not load in this run, so a newer stable may exist: verify before use.
- The Dart SDK bundled with Flutter 3.47 is not stated on the pages read: verify before use with `dart --version` in that SDK. The Dart docs state that they reflect Dart 3.13.3 (https://dart.dev/get-dart).
- Flutter and Dart have separate version numbers. Record both in the report: the Flutter SDK version and the Dart SDK version that the project actually runs.
- Dart 3.0 (released 10 May 2023) dropped language versions before 2.12 (https://dart.dev/resources/language/evolution). Every unit is null-safe.
- Target the version the project declares in `environment: sdk:` of `pubspec.yaml`. Flutter SDK constraints also go under `environment:` (https://dart.dev/tools/pub/pubspec). If the project declares none, use this baseline and say so in the report.
- Records and patterns are Dart 3.0 features (https://dart.dev/resources/language/evolution). Use them only when the target is Dart 3.x.

## 2. Layout and build

- `pubspec.yaml` declares `environment`, `dependencies` and `dev_dependencies`. The SDK constraint has this form (https://dart.dev/tools/pub/pubspec):

```yaml
environment:
  sdk: ^3.0.0
```

- The rule for committing `pubspec.lock`: verify before use.
- Tests live in `test/`, and each test file name ends in `_test.dart` (https://docs.flutter.dev/cookbook/testing/unit/introduction).
- Split by responsibility: pure Dart logic in `lib/` files that import no widget code and read no clock; thin adapters for files, network and platform; widgets that only show state. Tests import the pure files.
- Lint configuration (`analysis_options.yaml`): verify before use. Not read in this run.
- Keep the target's package name and folder layout in the plan. Do not invent a package name.

## 3. Idioms

- Types are non-nullable unless marked with `?`. Use `late` only for a variable that is assigned before its first read (references/dart-language.md).
- Use `const` for compile-time values, and use `const` widgets with `const` constructors wherever possible (https://api.flutter.dev/flutter/widgets/StatelessWidget-class.html).
- Asynchronous code uses `async` and `await` (https://dart.dev/language/concurrency).
- Parse input that may be invalid with `int.tryParse` (https://api.dart.dev/stable/dart-core/int/parse.html). Catch `FormatException` only where the source does.

```dart
final count = int.tryParse(text);
if (count == null) {
  // the source's rejection path goes here, with the source's message
}
```

- Widget state lives in a `State` object. Business logic lives in plain Dart classes that the widget calls (references/widgets-and-state.md).
- Pattern and record syntax is a Dart 3.0 feature. Keep the source shape of any value that crosses a boundary.

## 4. Errors, resources and exit

- `Exception` is for errors that indicate something unexpected happened. A program can throw any non-null object (https://dart.dev/language/error-handling).
- Map each source exception to one error class with a stable name. Keep the source message when the source emits it.
- `rethrow` propagates an exception after a partial handle. `finally` runs whether or not an exception is thrown (https://dart.dev/language/error-handling).

```dart
void writeOnce(Resource resource) {
  try {
    resource.write(data);
  } finally {
    resource.close(); // runs even when write throws; Resource is a placeholder
  }
}
```

- `exit(code)` from `dart:io` exits at once. It "does not wait for any asynchronous operations to terminate nor execute `finally` blocks" and "is therefore very likely to lose data" (https://api.dart.dev/stable/dart-io/exit.html).
- In library code, set `exitCode` instead of calling `exit`. It starts at 0, and the last assignment from any isolate sets the code on normal termination (https://api.dart.dev/stable/dart-io/exitCode.html).
- Close files, sockets and stream subscriptions in `finally`. The API for each is not read in this run: verify before use.

## 5. Concurrency

- Each isolate has its own memory and one thread running an event loop. Isolates communicate only by message passing (https://dart.dev/language/concurrency).
- `Isolate.run(computation)` runs `computation` in a new isolate and returns a `Future`. The computation and its result must be sendable. If the computation throws, the isolate ends and the same error is thrown (https://api.dart.dev/stable/dart-isolate/Isolate/run.html).
- A closure passed to `Isolate.run` may send more state than the source intends, because it captures its environment (same page). Pass plain values instead.
- `Future.wait` returns results in input order, not completion order. Its default waits for all futures; `eagerError: true` completes at the first error (https://api.dart.dev/stable/dart-async/Future/wait.html).
- Async code on one isolate runs on one thread. Move CPU-bound work to `Isolate.run`; `async` alone does not make it parallel.
- Other event-loop work can run during an `await`. A value read before an `await` and used after it can be stale: re-read it, or keep the section free of awaits. The official sentence on this was not read: verify before use.

## 6. Data and numbers (parity traps)

- `int` is 64-bit on the Dart VM: -2^63 to 2^63 - 1. On the web, an `int` is a JavaScript number with range -2^53 to 2^53 - 1 (https://dart.dev/language/built-in-types). The same literal can differ by target: see references/as-source.md.
- `double` is a 64-bit IEEE 754 double. `int` and `double` are both subtypes of `num`.
- `/` on two ints returns a double, and `~/` returns an int (https://dart.dev/language/operators).

```dart
print(5 / 2);   // 2.5, a double
print(5 ~/ 2);  // 2, an int
```

- `double.round()` returns an `int` and rounds ties away from zero: `(3.5).round()` is 4 and `(-3.5).round()` is -4 (https://api.dart.dev/stable/dart-core/double/round.html). The pages read show no half-even method: implement it and test both tie directions.
- `num.toStringAsFixed(n)` converts the receiver to double first. Its tie rule is not stated on the page: test exact ties on each target before relying on it (https://api.dart.dev/stable/dart-core/num/toStringAsFixed.html).
- `double.toString()` gives a number literal whose closest double is the value. `-0.0` and `Infinity` print as such (https://api.dart.dev/stable/dart-core/double/toString.html).
- `String.length` counts UTF-16 code units. `'\u{1D11E}'.length` is 2 and its `runes.length` is 1 (https://api.dart.dev/stable/dart-core/String/length.html).
- `Null.toString()` returns `"null"` (https://api.dart.dev/stable/dart-core/Null-class.html). Interpolating a null value prints `null`.

```dart
String? name;
print('user: $name'); // prints "user: null", derived from the two facts above
```

- A `DateTime` is in local time unless created in UTC. `DateTime.now()` is local. `toUtc()` and `toLocal()` convert between them (https://api.dart.dev/stable/dart-core/DateTime-class.html).
- `DateTime.parse` converts an offset to UTC: `"2002-02-27T14:00:00-0500"` is the same instant as `"2002-02-27T19:00:00Z"`. `DateTime.parse("2020-01-42")` gives 2020-02-11 and does not throw (https://api.dart.dev/stable/dart-core/DateTime/parse.html).
- Store instants in UTC, for example with `DateTime.utc(...)` (https://api.dart.dev/stable/dart-core/DateTime/DateTime.utc.html).

## 7. Testing

- Runner: `flutter test`. Unit tests use `package:test/test.dart` (`test` and `expect`). Widget tests use `package:flutter_test/flutter_test.dart` and `testWidgets` (https://docs.flutter.dev/cookbook/testing/widget/introduction).
- Name each test with its rule id when there is one, and keep one behavior per test:

```dart
test('BR-ROUND-002 rounds ties away from zero', () {
  expect((-3.5).round(), -4);
});
```

- Run one file with `flutter test test/counter_test.dart`, or one test by name with `flutter test --plain-name "..."` (https://docs.flutter.dev/cookbook/testing/unit/introduction).
- Golden files: `matchesGoldenFile(key, {version})`. `flutter test --update-goldens` creates or updates them (https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html). The base path for `key` is not stated: verify before use.
- Doubles: hand-written fakes first. The Flutter docs show generated mocks with `mockito` (https://docs.flutter.dev/cookbook/testing/unit/mocking).
- Layout, commands and tool choice: references/testing-and-tooling.md.

## 8. Quality gate

Run each command in the project root and report its real output. A gate that did not run is not a pass. No toolchain was installed in this run, so none of these commands was run here.

1. `dart format --output=none --set-exit-if-changed .` Exit code 1 when a file would change, 0 when none would (https://dart.dev/tools/dart-format). Without `--output`, `dart format .` rewrites the files.
2. `dart analyze` Reports failure on errors or warnings. Info-level issues fail only with `--fatal-infos` (https://dart.dev/tools/dart-analyze). The numeric exit codes are not stated: verify before use.
3. `flutter test` Pass means every test passes. The exit code for a pass is not read in this run: verify before use (https://docs.flutter.dev/testing/overview).

- Run all three, even when the first one fails, and report each command, its exit code, and the line that decides the result.

## 9. Migrating TO Dart / Flutter

- Parity beats idiom. Choose an idiom only when inputs, outputs and errors stay the same. Otherwise keep the source behavior, and mark the difference `deviation` with its reason and source.
- Map each source construct with references/as-target.md: rounding, text, dates, errors, I/O and collections.
- Write a test for each tie, boundary and error path before writing the code.
- Record the expected output from the source, not from the Dart target, and compare against it (golden test).
- Keep the error model: one class per source exception, with the same message where the source has a stable one.
- For UI state, keep the source's state transitions and map them to `State` and `setState` (references/widgets-and-state.md).

## 10. Migrating FROM Dart / Flutter

- Read references/as-source.md for the places where Dart behavior hides: int width on the web, `toStringAsFixed`, `round` ties, DateTime local versus UTC, `late`, null in text, and BuildContext after `await`.
- Read references/dart-language.md and references/widgets-and-state.md for the facts behind each trap.
- Cite the source with `path:line` for each rule, and check each Dart behavior it depends on against the official pages listed in references.

## 11. Anti-patterns

- A `late` variable read before it is assigned, or a `late` initializer whose side effect must happen at a known time.
- `BuildContext` used after an `await` with no `mounted` check.
- `setState` after `dispose`.
- `exit()` in library code, or before pending writes complete.
- `double` for money, or an `int` above 2^53 - 1 in code that is built for the web.
- `toStringAsFixed` used as a rounding rule without a tie test.
- `DateTime.now()` inside logic that a test must control.
- Assuming `List.sort` keeps equal elements in their input order: it is not guaranteed stable.
- Relying on `Map` iteration order for output that the source sorts.

## Library registry

- Registry: pub.dev, https://pub.dev/ (package pages show versions, the SDK constraint, pub points, likes, license and the platform support).
- Before adding a package, check the Dart and Flutter SDK first. Then search pub.dev, open the package page, and confirm: latest version, SDK constraint compatible with the target `environment.sdk`, supported platforms, license, last publish, and the score.
- Pin the version in `pubspec.yaml` and commit `pubspec.lock`. Run `flutter pub add <package>` only with the repository's pinned Flutter version.
- Full procedure and evaluation checks: `.claude/skills/migration-conduct/references/library-research.md`.

## Sources

- pub.dev: https://pub.dev/
- Flutter 3.47: https://docs.flutter.dev/release/whats-new and https://flutter.dev/blog/whats-new-in-flutter-3-47
- Dart SDK and Dart 3.0: https://dart.dev/get-dart and https://dart.dev/resources/language/evolution
- Dart language: https://dart.dev/language/built-in-types, https://dart.dev/language/operators, https://dart.dev/language/variables, https://dart.dev/language/error-handling, https://dart.dev/language/concurrency, https://dart.dev/null-safety, https://dart.dev/null-safety/understanding-null-safety
- Dart libraries: https://api.dart.dev/stable/dart-core/ (num, double, int, String, DateTime, Null, List, Map), https://api.dart.dev/stable/dart-async/Future/wait.html, https://api.dart.dev/stable/dart-isolate/Isolate/run.html, https://api.dart.dev/stable/dart-io/exit.html, https://api.dart.dev/stable/dart-io/exitCode.html, https://api.dart.dev/stable/dart-convert/jsonEncode.html, https://api.dart.dev/stable/dart-convert/jsonDecode.html
- Dart tools: https://dart.dev/tools/dart-format, https://dart.dev/tools/dart-analyze, https://dart.dev/tools/pub/pubspec, https://dart.dev/tools/linter-rules/use_build_context_synchronously
- Flutter testing and API: https://docs.flutter.dev/testing/overview, https://docs.flutter.dev/cookbook/testing/unit/introduction, https://docs.flutter.dev/cookbook/testing/widget/introduction, https://docs.flutter.dev/cookbook/testing/unit/mocking, https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html, https://docs.flutter.dev/reference/flutter-cli
- Flutter widgets: https://api.flutter.dev/flutter/widgets/State-class.html, https://api.flutter.dev/flutter/widgets/State/mounted.html, https://api.flutter.dev/flutter/widgets/StatelessWidget-class.html, https://api.flutter.dev/flutter/widgets/StatefulWidget-class.html, https://api.flutter.dev/flutter/widgets/BuildContext-class.html, https://api.flutter.dev/flutter/foundation/Key-class.html
