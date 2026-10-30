Read this when a unit has user-facing text that must be translated, dates and numbers that depend on locale, accessibility labels, or calls to native platform code.

# Internationalization, accessibility and platform channels (Flutter 3.47)

## Internationalization (intl and ARB)

- Flutter's official guide uses ARB files (Application Resource Bundle, JSON-based) and generated localization classes. The `flutter_localizations` package provides Material and Cupertino translations (https://docs.flutter.dev/ui/internationalization).
- The `intl` package (publisher dart.dev) formats dates, numbers and plural messages (https://pub.dev/packages/intl). The `NumberFormat` and `DateFormat` class names are from the package docs: verify the constructor arguments on the package page before use.
- ARB file layout and the `gen-l10n` generator: the guide describes the generator and the `l10n.yaml` file. The exact keys and option names were not read in this run: verify before use.
- Parity risks:
  - Keep the source's message keys and placeholders. A placeholder that the source fills with a number must use the same number format.
  - Plurals: the source's plural rule (for example one or other) must be a plural message, not an `if` in code.
  - The locale of the output comes from the device or from `MaterialApp.locale`. A test must set the locale explicitly.
  - `DateFormat` output depends on the locale data loaded: initialize it before the first format call (verify the initialization call on the package page).
- Do not concatenate translated fragments: word order differs by language.

## Accessibility (Semantics)

- `Semantics` is a widget that annotates the semantics tree: labels, values, roles and actions read by assistive technology (https://api.flutter.dev/flutter/widgets/Semantics-class.html).
- `Semantics(label: ..., child: ...)` gives a screen reader a label for a widget that has no text of its own, such as an icon button. `excludeSemantics` removes the child's semantics: use it only when the source hides the child from assistive technology.
- Flutter's accessibility guide: https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility. The exact list of parameters was not read in this run: verify before use.
- Tap targets: the Material guidelines name a minimum size. The guideline test helpers in `flutter_test` (`meetsGuideline`, `androidTapTargetGuideline`) are described on the accessibility guide page: verify the names before use.
- Parity risks:
  - The source's label text is part of the behavior: test it as text, not as a visual.
  - A widget the source hides from assistive technology must stay hidden in the target.
  - Test semantics with `tester.getSemantics` or `find.bySemanticsLabel` in widget tests: verify the finder names on the testing docs before use.

## Platform channels

- A platform channel passes messages between Dart and native code (Kotlin or Java on Android, Swift or Objective-C on iOS, and others per platform). Built-in channel types are `MethodChannel`, `EventChannel` and `BasicMessageChannel` (https://docs.flutter.dev/platform-integration/platform-channels).
- `MethodChannel` sends a named method call and returns a `Future`. The native side replies with a result, an error, or "not implemented" (https://api.flutter.dev/flutter/services/MethodChannel-class.html).
- `EventChannel` streams values from native code to Dart (https://api.flutter.dev/flutter/services/EventChannel-class.html).
- Message values are limited to a standard set of types (null, bool, int, double, String, lists and maps of those, and byte arrays). Other objects must be converted first. Verify the exact list on the platform channel page.
- Parity risks:
  - The channel name and method names are strings: keep the source's names. Mismatched names fail at runtime, not at compile time.
  - An error from native code arrives as a `PlatformException`: map its `code` and `message` the way the source maps its native error.
  - A `MethodChannel` call from a test returns `MissingPluginException` unless the test sets a mock handler. Set the handler with `TestDefaultBinaryMessengerBinding` or `setMockMethodCallHandler`, and verify the exact call on the testing docs before use.
  - Native threads: a reply must be sent on the platform's main thread. The docs state this per platform: verify before writing native code.
- Plugins: prefer an existing published plugin when the plan names one. Check its pub.dev page for supported platforms and last publish date (migration-conduct library-research procedure).

## Parity checklist for i18n, a11y and platform units

- Compare each user-facing string with its key and placeholders; keep the source's locale-dependent output.
- Test one plural case per branch of the source's plural rule.
- Test each semantics label the source sets, and each element the source hides.
- For each channel method, write one test with a mock handler and one for the error path.
