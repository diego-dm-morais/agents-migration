Read this when a migrated unit has screens, widgets, widget state, keys, or UI work that waits on async results.

# Widgets and state (Flutter 3.47)

## Widget kinds

- `StatelessWidget` is "A widget that does not require mutable state." Its `build` method "Describes the part of the user interface represented by this widget." The method is typically called on initial placement, when the parent's configuration changes, and when an InheritedWidget it depends on changes (https://api.flutter.dev/flutter/widgets/StatelessWidget-class.html).
- Use `const` widgets where possible, and give them a `const` constructor (same page).
- `StatefulWidget` is "A widget that has mutable state." The framework calls `createState` when it inflates the widget. If the widget is removed and later reinserted, `createState` runs again and a fresh `State` object is created (https://api.flutter.dev/flutter/widgets/StatefulWidget-class.html).

## State lifecycle

- `initState` is called when the object is inserted into the tree. Use it for one-time setup that depends on the context or the widget. It runs before `didChangeDependencies`.
- `didChangeDependencies` is called after `initState`, and again when an inherited widget the state depends on changes (https://api.flutter.dev/flutter/widgets/State-class.html).
- `setState(fn)` notifies the framework that the internal state of the object has changed. It is an error to call `setState` after `dispose` (https://api.flutter.dev/flutter/widgets/State-class.html).
- `dispose` is called when the object is removed from the tree permanently. Release timers, controllers and subscriptions here.
- `mounted` is "Whether this State object is currently in a tree." After `dispose`, `mounted` is false (https://api.flutter.dev/flutter/widgets/State/mounted.html).

```dart
class _CounterState extends State<Counter> {
  int count = 0;

  void increment() {
    setState(() {
      count++;
    });
  }
}
```

## BuildContext and async gaps

- A `BuildContext` is "A handle to the location of a widget in the widget tree" (https://api.flutter.dev/flutter/widgets/BuildContext-class.html).
- The linter rule `use_build_context_synchronously` says "Do not use BuildContext across asynchronous gaps" (https://dart.dev/tools/linter-rules/use_build_context_synchronously).
- Inside a `State`, check `mounted` before using `context` after an `await`. For a `BuildContext` passed in as an argument, check `context.mounted` (same rule page).

```dart
Future<void> save() async {
  await repo.save(item);
  if (!mounted) return; // inside a State subclass
  Navigator.of(context).pop();
}
```

- Parity risk: the source may act on the screen after a request; the target must skip the action when the widget is gone, and the skipped action must match the source's observable output.

## Keys

- "A Key is an identifier for Widgets, Elements and SemanticsNodes" (https://api.flutter.dev/flutter/foundation/Key-class.html).
- Without a key, Flutter matches widgets by `runtimeType` and position in the tree during rebuilds. A new widget updates an existing element only when the keys are the same.
- `ValueKey<String>` is built from a `String`. A `GlobalKey` keeps the same `State` object when the widget moves to another place in the tree (https://api.flutter.dev/flutter/widgets/StatefulWidget-class.html).
- Parity risk: after a list is reordered, state follows the key, not the index. Test a reorder with state in each row.

## Rebuild scope

- The Flutter state docs describe a `ChangeNotifier` model: "Call this method any time the model changes in a way that might change your app's UI" (https://docs.flutter.dev/data-and-backend/state-mgmt/simple). `ChangeNotifier` is part of `flutter:foundation` (https://docs.flutter.dev/data-and-backend/state-mgmt/simple).
- The same page says that `notifyListeners()` calls the builder of every matching `Consumer`, and that a `Consumer` should sit "as deep in the tree as possible".

## Widget tests

- `testWidgets` creates a new `WidgetTester` for each test case and is used in place of `test()` for widget tests (https://docs.flutter.dev/cookbook/testing/widget/introduction).
- Import `package:flutter_test/flutter_test.dart`. It ships with the Flutter SDK.

## Parity checklist for UI units

- List each source state transition, and write one test per transition.
- Check the source's behavior when the user leaves the screen during a request: the `mounted` check must match it.
- Check the source's setup order: `initState` runs before `didChangeDependencies`.
- Check list reorders with keys, not only with indexes.
