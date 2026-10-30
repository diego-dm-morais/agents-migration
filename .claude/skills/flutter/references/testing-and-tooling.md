Read this when you write tests, set up the quality gate, or choose a Dart or Flutter tool. Commands were checked against the official pages on 2026-10-29. None was run on the machine that wrote this file.

# Testing and tooling (Flutter 3.47, Dart 3.x)

## Test layout

- Tests live in `test/` at the package root. Each test file name ends in `_test.dart` (https://docs.flutter.dev/cookbook/testing/unit/introduction).
- One test file per unit: `test/<unit>_test.dart`. Name each test with its rule id when there is one, for example `BR-ROUND-002 rounds ties away from zero`.
- Golden files are compared with `matchesGoldenFile`. The base path for the golden key is not stated in the page read: record the base you use, and verify before use.
- Integration tests: the Flutter SDK includes the `integration_test` package. It cannot interact with native platform UI, such as permission dialogs. The Flutter docs name the `patrol` package for that case (https://pub.dev/packages/patrol; https://docs.flutter.dev/testing/overview).

## Commands

| Command | What it does | What passes |
|---|---|---|
| `flutter test` | runs the tests under `test/` | every test passes; the exit code for a pass: verify before use |
| `flutter test test/counter_test.dart` | runs one file | as above |
| `flutter test --plain-name "name"` | runs the tests whose name matches | as above (https://docs.flutter.dev/cookbook/testing/unit/introduction) |
| `flutter test --update-goldens` | creates or updates golden files | run it to create a new golden, then review the file; never to hide a diff (https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html) |
| `flutter help test` | lists every flag of `flutter test` | the flags are not listed on the docs pages read; read them here |
| `dart format -o show <file>` | prints the formatted contents of the file, without writing it | no pass or fail; it is a view of the output (https://dart.dev/tools/dart-format) |

## Unit test with package:test

```dart
import 'package:test/test.dart';

void main() {
  test('BR-ROUND-002 rounds ties away from zero', () {
    expect(3.5.round(), 4);
    expect((-3.5).round(), -4);
  });
}
```

- `test` and `expect` are the top-level functions the cookbook uses (https://docs.flutter.dev/cookbook/testing/unit/introduction).

## Widget test with flutter_test

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BR-UI-001 shows the initial count', (WidgetTester tester) async {
    // pump the widget under test, then assert on what the tree shows
  });
}
```

- `testWidgets` creates a new `WidgetTester` for each test case (https://docs.flutter.dev/cookbook/testing/widget/introduction).

## Doubles and fakes

- Put each external dependency behind an interface that the unit receives as a parameter. Write a hand-made fake for it. This is the default.
- Generated mocks: the Flutter docs add `mockito` and `build_runner` with `flutter pub add dev:mockito dev:build_runner`, then generate with `dart run build_runner build`. `mockito` 5.0.0 supports null safety through code generation (https://docs.flutter.dev/cookbook/testing/unit/mocking; https://pub.dev/packages/mockito).
- Time: pass a clock as a value. Call `DateTime.now()` only at the edge of the program, never inside the logic under test.
- Randomness: pass the source as a parameter. The Dart random API was not read in this run: verify before use.

## Gate commands

| Gate | Command | What passes | Verified in this run |
|---|---|---|---|
| Format | `dart format --output=none --set-exit-if-changed .` | exit code 0 when no file would change; 1 when a file would change | yes: https://dart.dev/tools/dart-format |
| Analyze | `dart analyze` | no error and no warning reported; info-level issues do not fail by default | yes for the rule; numeric exit codes: verify before use (https://dart.dev/tools/dart-analyze) |
| Test | `flutter test` | every test passes | the command: yes; the exit code: verify before use |

- Report each gate with its command, its exit code and the line that decides the result.
- Coverage: `flutter test --coverage` is the usual form. It is not in the pages read in this run: verify before use.

## Tool choice

- Use what the project already has. Add a package only when the plan names it and the gate needs it.
- The Flutter SDK includes the full Dart SDK and the `dart` CLI (https://dart.dev/get-dart).
- The `intl` package is published by dart.dev for localized messages, dates and numbers (https://pub.dev/packages/intl). Its API is not read in this run: verify before use.
- Read the flags of any command with its `help` output, and record the version you ran.
