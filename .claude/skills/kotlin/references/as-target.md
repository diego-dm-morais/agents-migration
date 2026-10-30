Read this when you map a source construct to Kotlin or Android Compose code. The left column is the concept; the middle column is the Kotlin or Android idiom; the right column is the risk to test.

# Writing Kotlin and Android UI as the target

| Concept | Idiom in this language | Parity risk to test |
|---|---|---|
| Integer arithmetic | `Int` or `Long` with an explicit overflow check where the source has one | `Int` wraps silently (https://kotlinlang.org/docs/numbers.html); `2147483647 + 1` is `-2147483648` |
| Decimal money | integer minor units; avoid `Double` | every tie; output scale; negative values |
| Integer division | `/` on two `Int` values truncates | `5 / 2` is `2`; negative operands: test on the target |
| Rounding to an integer | the rounding function the source names; test ties | tie direction and half-even: verify before use |
| Fixed decimal text | `String.format` or the formatter the source uses | locale of the output; tie rule: test it |
| Absent value | `T?`; `?:` only where the source falls back | `!!` fails where the source handles absence |
| Null in text | explicit check before the template | `"$x"` prints `null`; the source may print nothing |
| Ordered collection | `List` (read-only) or `mutableStateListOf` for Compose state | in-place mutation does not recompose a plain `ArrayList` |
| Keyed collection | `Map`; iteration order: not verified offline (read the `mapOf` and `LinkedHashMap` API pages) | key order in output; copy before sorting |
| UI state, local to a screen | `remember { mutableStateOf(...) }` | lost on rotation; use `rememberSaveable` where the source keeps it |
| UI state across rotation | `rememberSaveable` with a `Saver` for non-primitive types | large values in the Bundle; non-`Parcelable` types |
| Business state across rotation | ViewModel with `StateFlow` | the ViewModel is cleared when its owner goes away |
| Screen-level state holder | ViewModel exposing `StateFlow`, collected with `collectAsStateWithLifecycle()` | reads after the owner is cleared |
| Side effect after state change | `LaunchedEffect(key)`, `DisposableEffect` with `onDispose`, `SideEffect` | effect restarts on key change; `LaunchedEffect(true)` runs once |
| Event-driven coroutine | `rememberCoroutineScope().launch { ... }` in a callback | cancels when the composable leaves the Composition |
| Current value inside a long effect | `rememberUpdatedState` | a stale callback if not wrapped |
| Navigation | Navigation Compose: `NavHost`, `composable`, `NavController` | route identity and back-stack behavior the source defines |
| Error model | one class per source exception; the source message kept | `!!` throwing `NullPointerException` where the source does not |
| Activity-level state | ViewModel and `rememberSaveable`; not a field on the Activity | the Activity is recreated on rotation (https://developer.android.com/guide/components/activities/state-changes) |
| Background work | a coroutine in the ViewModel (`viewModelScope`; API not verified offline) | the work continues across rotation (https://developer.android.com/topic/libraries/architecture/viewmodel); a source that cancels it differs |
| Locale formatting | the platform formatter or a library the plan names | the locale of the output; the device locale |

## Compose notes

- Do not put side effects in the composable body. Use an effect API (https://developer.android.com/develop/ui/compose/side-effects).
- Pass `value` and `onValueChange` into a stateless composable; keep the state in the caller (https://developer.android.com/develop/ui/compose/state).
- Keep one source of truth. Hoist shared state to the lowest common parent.

## ViewModel notes

- Do not hold `Context`, `Resources`, `Activity` or a view in a ViewModel (https://developer.android.com/topic/libraries/architecture/viewmodel).
- Use `onCleared` for cleanup that follows the ViewModel's lifecycle.
- Expose state as `StateFlow` and read `.value` only where the source reads the current value synchronously.

## Test each mapping

- Write one test per source rule before the code: the tie, the boundary, the error, and each state transition.
- Record the expected output from the source, not from the target, and compare against it.
