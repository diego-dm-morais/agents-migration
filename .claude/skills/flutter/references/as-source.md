Read this when the source you migrate from is Dart or Flutter. These are the places where the behavior is easy to miss, because it sits in the runtime, the platform, or the library, not in the line you read.

# Reading Dart and Flutter as the source

## Numbers

- `int` width depends on the target. `9007199254740993` is exact on the Dart VM, which is 64-bit. On the web, `int` is a JavaScript number, and the value is outside the stated web range of -2^53 to 2^53 - 1, so it is not guaranteed exact. Compile the literal for both targets and print it (https://dart.dev/language/built-in-types).
- `5 / 2` is `2.5`; `5 ~/ 2` is `2`. A source that divides integers and expects an integer must use `~/`. The sign direction of `~/` for negative operands is not stated: verify before use (https://dart.dev/language/operators).
- `(2.5).round()` is 3 and `(-2.5).round()` is -3: ties go away from zero (https://api.dart.dev/stable/dart-core/double/round.html).
- `4321.12345678.toStringAsFixed(3)` is `"4321.123"`, and `5.25.toStringAsFixed(0)` is `"5"` (https://api.dart.dev/stable/dart-core/num/toStringAsFixed.html).
- Tie rule of `toStringAsFixed` is not stated. Record the Dart output of exact ties such as `2.5` at 0 digits and `0.125` at 2 digits, on each target, and copy the output the source gives.
- `1.toStringAsFixed(3)` is `"1.000"`: the receiver is converted to double first.
- `-0.0` prints as `"-0.0"`, and positive infinity prints as `"Infinity"` (https://api.dart.dev/stable/dart-core/double/toString.html).
- `toInt()` on a double: the truncation rule was not read in this run. Verify before use.

## Text

- `'\u{1D11E}'.length` is 2 and `'\u{1D11E}'.runes.length` is 1. A source that counts or slices characters counts UTF-16 code units in Dart (https://api.dart.dev/stable/dart-core/String/length.html).
- Interpolating a null value prints `null` (https://api.dart.dev/stable/dart-core/Null-class.html). A source that prints an empty field for a missing value differs.
- Decoding UTF-8 with `utf8` from `dart:convert`: the result on malformed bytes is not stated in the page read. Verify before use.

## Null and late

- `late String code;` followed by a read of `code` throws at run time. The code compiles, and the failure happens on the read (https://dart.dev/null-safety/understanding-null-safety).
- `late int total = computeTotal();` runs `computeTotal` on the first read of `total`. A source that runs the same work at construction differs in timing and in which error is raised.

## Dates and time

- `DateTime.now()` is local time. Output that depends on it depends on the process time zone (https://api.dart.dev/stable/dart-core/DateTime-class.html).
- `DateTime.parse("2002-02-27T14:00:00-0500")` gives the same instant as `"2002-02-27T19:00:00Z"`. A source that keeps the offset text, or the local clock time, differs (https://api.dart.dev/stable/dart-core/DateTime/parse.html).
- `DateTime.parse("2020-01-42")` gives 2020-02-11 and does not throw. A source that rejects day 42 differs: validate the input before parsing.
- A string with no offset is parsed as local time under the class rule. The exact rule for that case: verify before use.

## Async and isolates

- `Future.wait([a(), b()])` returns the value of `a()` at index 0, even when `b()` finishes first (https://api.dart.dev/stable/dart-async/Future/wait.html).
- With the default `eagerError: false`, the result completes after every future completes, and the first error is the one reported. With `eagerError: true`, the result completes with the error at once.
- A closure passed to `Isolate.run` may send more state than the source intends (https://api.dart.dev/stable/dart-isolate/Isolate/run.html).
- `await` lets other event-loop work run. A source that relies on the order of that work is part of the behavior: verify before use.

## Errors and exit

- `throw 'boom';` is legal, because any non-null object can be thrown (https://dart.dev/language/error-handling). A handler written for `Exception` does not match a `String` by type: verify before use.
- `int.parse('0x1F')` accepts a `0x` prefix when no radix is given, which gives 31 by the documented rule. The page states: "If no `radix` is given then it defaults to 10. In this case, the `source` digits may also start with `0x`" (https://api.dart.dev/stable/dart-core/int/parse.html). Not run.
- `exit(1)` drops buffered output and skips `finally` blocks (https://api.dart.dev/stable/dart-io/exit.html).
- Setting `exitCode = 1` and then ending normally exits with 1 (https://api.dart.dev/stable/dart-io/exitCode.html).

## Collections and JSON

- `List.sort` is not guaranteed to be stable: equal elements may come out in any order (https://api.dart.dev/stable/dart-core/List/sort.html).
- A default `Map()` iterates in key insertion order (https://api.dart.dev/stable/dart-core/Map-class.html).
- `jsonEncode` fails on values that are not number, boolean, string, null, list, or a map with string keys, unless `toEncodable` converts them (https://api.dart.dev/stable/dart-convert/jsonEncode.html). The exception class is not named there: verify before use.
- `jsonDecode` returns `dynamic`. A field's type is what the decoded value is at run time, so check each field (https://api.dart.dev/stable/dart-convert/jsonDecode.html).

## Flutter UI state

- A `setState` call after `dispose` is an error (https://api.flutter.dev/flutter/widgets/State-class.html).
- A `BuildContext` used after an `await` without a `mounted` check is flagged by the linter rule `use_build_context_synchronously` (https://dart.dev/tools/linter-rules/use_build_context_synchronously).
- A list item without a key keeps the state of the item that now sits at its index, because matching uses `runtimeType` and position (https://api.flutter.dev/flutter/foundation/Key-class.html).
