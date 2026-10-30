Read this when a migrated unit uses Dart language features: null safety, late, numbers, text, errors, async, isolates, or Dart 3 patterns and records.

# Dart language (Dart 3.x)

## Null safety

- A type is non-nullable unless it has a `?` suffix. Variables of non-nullable types must be initialized and can only be assigned non-null values (https://dart.dev/null-safety).
- Dart 3.0 dropped support for language versions before 2.12 (https://dart.dev/resources/language/evolution). A migrated unit is always null-safe.
- `late` declares a non-nullable variable that is initialized after its declaration, or that is initialized lazily (https://dart.dev/language/variables).

```dart
late String code;  // never assigned
print(code);       // runtime error on this read
```

- Each read of a `late` variable runs a runtime check. If the variable was never assigned, an exception is thrown (https://dart.dev/null-safety/understanding-null-safety). The error class is not named in the pages read: verify before use.
- A `late` variable with an initializer runs the initializer the first time it is used, not when the instance is constructed (https://dart.dev/language/variables).

```dart
late int total = computeTotal();  // computeTotal runs on the first read of total
```

- Parity risk: a side effect or an exception that the source raises at declaration time moves to the first read.

## Null in text

- `Null` is the only class that does not implement `Object`. `Null.toString()` returns the string `"null"` (https://api.dart.dev/stable/dart-core/Null-class.html).
- Dart calls an object's `toString()` to get its string form (https://dart.dev/language/built-in-types).
- Derived from the two facts above: `String? name; print('user: $name');` prints `user: null`. Verify by running it before use.

## Numbers

- `int` is 64-bit on native platforms, from -2^63 to 2^63 - 1. On the web, `int` values are JavaScript numbers, from -2^53 to 2^53 - 1 (https://dart.dev/language/built-in-types). The page read does not say what happens outside the web range.
- `double` is a 64-bit IEEE 754 double-precision number. `int` and `double` are subtypes of `num`.
- `/` on two ints gives a double: `5 / 2 == 2.5`. `~/` gives an int: `5 ~/ 2 == 2` (https://dart.dev/language/operators). The rounding direction of `~/` for negative operands is not stated: verify before use.
- `double.round()` returns an `int` and rounds ties away from zero: `(3.5).round() == 4`, `(-3.5).round() == -4` (https://api.dart.dev/stable/dart-core/double/round.html).
- `num.toStringAsFixed(n)` converts to double first and returns exactly `n` digits after the point. Its tie rule is not stated (https://api.dart.dev/stable/dart-core/num/toStringAsFixed.html).

```dart
print(3.5.round());                 // 4
print((-3.5).round());              // -4
print(4321.12345678.toStringAsFixed(3)); // 4321.123
print(1.toStringAsFixed(3));        // 1.000
```

- `double.toString()` gives a number literal whose closest double is the value. `-0.0` prints as `-0.0`, and infinity prints as `Infinity` (https://api.dart.dev/stable/dart-core/double/toString.html).

## Text

- `String.length` counts UTF-16 code units, not characters. `'Dart'.length` is 4. `'\u{1D11E}'.length` is 2, and `'\u{1D11E}'.runes.length` is 1 (https://api.dart.dev/stable/dart-core/String/length.html).
- Use `runes` when the unit of a migrated rule is a code point.

## Dates and time

- A `DateTime` object is in the local time zone unless it is explicitly created in UTC. `DateTime.now()` is local (https://api.dart.dev/stable/dart-core/DateTime-class.html).
- `toUtc()` returns the value in UTC; `toLocal()` returns it in local time. `timeZoneOffset` is the difference between local time and UTC.
- `DateTime.utc(...)` creates a UTC value (https://api.dart.dev/stable/dart-core/DateTime/DateTime.utc.html).
- `DateTime.parse` gives a local time or UTC. An offset is converted to the equivalent UTC time (https://api.dart.dev/stable/dart-core/DateTime/parse.html).

## Errors

- `Exception` covers errors that indicate something unexpected happened. A program can throw any non-null object (https://dart.dev/language/error-handling). The page read does not define `Error` as the type for programming errors: verify before use.
- `rethrow` propagates an exception after a partial handle. `finally` runs whether or not an exception is thrown (https://dart.dev/language/error-handling).
- `int.parse` throws `FormatException` when the source is not a valid integer literal. The docs recommend `int.tryParse` for input that may be invalid (https://api.dart.dev/stable/dart-core/int/parse.html).
- `int.parse` takes an optional sign. The `radix` must be from 2 to 36, and it defaults to 10. Without a `radix`, the digits may start with `0x` (same page).

## Async and isolates

- `async` and `await` define asynchronous functions and use their results (https://dart.dev/language/concurrency).
- `Future.wait` returns results in the order of the input list, not completion order. The default `eagerError: false` waits for every future. `eagerError: true` completes with the first error at once (https://api.dart.dev/stable/dart-async/Future/wait.html).

```dart
final results = await Future.wait([fetchA(), fetchB()]); // results[0] is fetchA's value
```

- Each isolate has its own memory and runs one event loop on one thread. Isolates communicate only by message passing (https://dart.dev/language/concurrency).
- `Isolate.run` runs a computation in a new isolate and returns a `Future`. The computation and its result must be sendable. A closure may send unexpected state to the isolate (https://api.dart.dev/stable/dart-isolate/Isolate/run.html).

## Patterns and records (Dart 3.0)

- Dart 3.0 added patterns, which match and destructure values, and records, which combine several values of different types in one return (https://dart.dev/resources/language/evolution).
- Use them only when the target is Dart 3.x. The shape of a record returned across a boundary is part of the parity contract.
