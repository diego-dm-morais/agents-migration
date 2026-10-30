Read this when the source you migrate from is Kotlin or Android UI. These are the places where the behavior is easy to miss, because it sits in the runtime, the framework or the lifecycle, not in the line you read.

# Reading Kotlin and Android UI as the source

## Numbers

- `Int` is 32 bits, from -2,147,483,648 to 2,147,483,647. "The compiler does not automatically produce an error when integer overflow occurs." `2147483647 + 1` gives `-2147483648` (https://kotlinlang.org/docs/numbers.html).
- `Long` is wider; a source that mixes `Int` and `Long` in one expression may overflow in the `Int` part first. Check each operand's type at `path:line`.
- `5 / 2` is `2`: integer division truncates the fractional part (https://kotlinlang.org/docs/numbers.html). Truncation toward zero for negative operands: not verified offline. Test `-5 / 2` on the target.
- `Double` is IEEE 754 double precision (https://kotlinlang.org/docs/numbers.html). `10.0 / 3` prints `3.3333333333333335` on the page. The `toString` rules for `-0.0`, `NaN` and exponents: not verified offline.
- Rounding (`roundToInt`, `round`, `String.format`) tie and locale behavior: not verified offline. Record the source output of each exact tie and copy it.

## Null

- `T?` may hold `null`. `?.` returns `null` when the receiver is `null`, and `?:` evaluates the right side only when the left is `null` (https://kotlinlang.org/docs/null-safety.html).
- `!!` "forces it to be treated as non-nullable, which results in an NPE" (same page). A source that uses `!!` fails at that point; record the failure.
- Smart casts work only when "the compiler can guarantee that `b` doesn't change between the check and its usage" (same page). A mutable property may not smart-cast.
- Interpolating `null` in a Kotlin string prints `null`. The Kotlin string-template behavior: not verified offline. Read the source's text.

## Compose state

- `remember` keeps a value across recompositions only. "The state is not retained across configuration changes" (https://developer.android.com/develop/ui/compose/state). A source that expects its UI state to survive rotation must use `rememberSaveable` or a ViewModel, and the target must match.
- `rememberSaveable` survives configuration changes and system-initiated process death, but "won't retain state if the activity is completely dismissed by the user" (https://developer.android.com/develop/ui/compose/state-saving).
- Recomposition may run "as often as every frame" and any composable may be skipped (https://developer.android.com/develop/ui/compose/mental-model). A source side effect inside a composable body runs at a time the framework chooses. Record it.
- `remember(key)` recomputes when a key changes. A source that caches on a value that is not a key may show a stale result.
- `LaunchedEffect` restarts its coroutine when keys change, and cancels the old one (https://developer.android.com/develop/ui/compose/side-effects). An effect keyed on an unstable value restarts more often than the source.
- `rememberCoroutineScope` cancels when the call leaves the Composition (same page).

## Mutable state and lists

- A mutable non-observable object such as `ArrayList` or a mutable data class does not trigger recomposition when it changes (https://developer.android.com/develop/ui/compose/state). A source that mutates a list in place and expects the UI to update shows different behavior on the target unless the target observes it. Record what the source shows.

## ViewModel and lifecycle

- A ViewModel "remains in memory until the `ViewModelStoreOwner` to which it is scoped disappears" (https://developer.android.com/topic/libraries/architecture/viewmodel). A source that reads a dependency after the screen is gone reads a value the target has cleared.
- `onCleared` is called when the owner destroys the ViewModel (same page).
- Async work "continues in the ViewModel" across configuration changes (same page). A source that cancels work on rotation differs.
- On configuration change the activity is destroyed and recreated. The old instance gets `onPause`, `onStop`, `onDestroy`; the new one gets `onCreate`, `onStart`, `onResume` (https://developer.android.com/guide/components/activities/state-changes). A source that does work in `onDestroy` runs it on every rotation.
- "When an activity is recreated due to a configuration change, the initial composition is disposed of" (same page).

## Navigation

- Navigation Compose destinations are composables; the back stack holds the destination entries (https://developer.android.com/develop/ui/compose/navigation). A source that pops to a screen by name must match the target's route identity.
- The back and up actions "are handled correctly by default" on that page. A source that overrides back behavior must be recorded explicitly.

## Flows and StateFlow

- `StateFlow` "requires an initial state" and is hot: "collecting from the flow doesn't trigger any producer code" (https://developer.android.com/kotlin/flow/stateflow-and-sharedflow). A source that expects a cold `Flow` behavior, such as a fresh request on each collect, differs.
- `StateFlow` conflation and equality rules: see the API reference linked from that page. Not quoted here: verify before use.
