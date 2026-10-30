Read this when a migrated unit uses Compose state, side effects, ViewModel, Navigation Compose, or the activity lifecycle. Facts were checked against the official Android pages on 2026-10-30.

# Compose, ViewModel, Navigation and lifecycle

## Recomposition and composable rules

- Compose is declarative: "the only way to update it is by calling the same composable with new arguments" (https://developer.android.com/develop/ui/compose/state).
- "Recomposition is the process of calling your composable functions again when inputs change. When Compose recomposes based on new inputs, it calls only the functions or lambdas that might have changed, and skips the rest" (https://developer.android.com/develop/ui/compose/mental-model).
- "Never depend on side-effects from executing composable functions, since a function's recomposition may be skipped" (same page).
- Composable functions "might be re-executed as often as every frame" and "should be fast to avoid jank during animations" (same page).
- The lifecycle of a composable: "entering the Composition, getting recomposed 0 or more times, and leaving the Composition" (https://developer.android.com/develop/ui/compose/lifecycle).

## remember and rememberSaveable

- `remember`: "A value computed by `remember` is stored in the Composition during initial composition, and the stored value is returned during recomposition." It "forgets the object when the composable that called `remember` is removed from the Composition." It "is not retained across configuration changes" (https://developer.android.com/develop/ui/compose/state).
- `remember` with keys: "If any of these keys change, the next time the function recomposes, `remember` invalidates the cache and executes the calculation lambda block again" (same page).
- `rememberSaveable` "retains state across recompositions, and also across activity or process recreation using the saved instance state mechanism." It "won't retain state if the activity is completely dismissed by the user" (same page).
- `rememberSaveable` stores values in a `Bundle`. Primitive types are saved automatically. Other types need `@Parcelize`, `listSaver`/`mapSaver`, or a custom `Saver` (https://developer.android.com/develop/ui/compose/state-saving).
- "You should not store large complex objects or lists of objects in the bundle" (same page).
- Survival by event (same page): configuration change: `rememberSaveable` for UI state, automatic for ViewModel. System-initiated process death: `rememberSaveable` for UI state, `SavedStateHandle` for ViewModel state. User-initiated process death: loss of transient UI state "is generally reasonable".

```kotlin
@Composable
fun ChatBubble(message: Message) {
    var showDetails by rememberSaveable { mutableStateOf(false) }
    // ...
}
```

## mutableStateOf and state hoisting

- `mutableStateOf` creates an observable `MutableState<T>`. "Any changes to `value` schedule recomposition of any composable functions that read `value`" (https://developer.android.com/develop/ui/compose/state).
- Non-observable mutable objects "such as `ArrayList<T>` or a mutable data class, are not observable by Compose and don't trigger a recomposition when they change" (same page).
- State hoisting: the composable takes `value: T` and `onValueChange: (T) -> Unit`. State is hoisted "to at _least_ the lowest common parent of all composables that use the state (read)" and "to at _least_ the highest level it may be changed (write)". "If two states change in response to the same events they should be hoisted together" (same page).

## Side effects

- `LaunchedEffect`: "To perform work over the life of a composable and have the ability to call suspend functions." If recomposed with different keys, "the existing coroutine will be cancelled and the new suspend function will be launched in a new coroutine." "`LaunchedEffect(true)` is as suspicious as a `while(true)`" (https://developer.android.com/develop/ui/compose/side-effects).
- `DisposableEffect`: for effects "that need to be _cleaned up_ after the keys change or if the composable leaves the Composition." It "must include an `onDispose` clause as the final statement in its block of code" (same page).
- `SideEffect`: no keys. "Using a `SideEffect` guarantees that the effect executes after every successful recomposition." Used to share Compose state with objects not managed by Compose (same page).
- `rememberCoroutineScope`: "obtain a composition-aware scope to launch a coroutine outside a composable." "The scope will be cancelled when the call leaves the Composition." Used for event-driven coroutines such as `onClick` handlers (same page).
- `rememberUpdatedState`: "reference a value in an effect that shouldn't restart if the value changes." Wrap the value with `rememberUpdatedState` and use the state in an effect with a constant key (same page).
- `derivedStateOf`: for "inputs to a composable are changing more often than you need to recompose." Written as `remember { derivedStateOf { ... } }`. "`derivedStateOf` is expensive" and combining two states, such as `"$firstName $lastName"`, "is purely overhead" (same page).

## ViewModel and StateFlow

- ViewModel "caches state and persists it through configuration changes." Asynchronous work "continues in the ViewModel" across a configuration change (https://developer.android.com/topic/libraries/architecture/viewmodel).
- Scope: a ViewModel is scoped to a `ViewModelStoreOwner`: an activity, a Navigation destination or graph, or a composable through `rememberViewModelStoreOwner`. "A `ViewModel` remains in memory until the `ViewModelStoreOwner` to which it is scoped disappears" (same page).
- `onCleared` is called "when the `ViewModelStoreOwner` destroys it" (same page).
- "ViewModels shouldn't hold any references of lifecycle-related APIs such as the `Context` or `Resources` to prevent memory leaks." The page names `Context` and `Resources`; it does not name `Activity` or `View` (same page).
- Compose usage: `viewModel()` from the `lifecycle-viewmodel-compose` artifact, and `collectAsStateWithLifecycle()` to collect a flow as state (same page). The `collectAsStateWithLifecycle` API page: not verified offline.
- `StateFlow`: "a state-holder observable flow that emits the current and new state updates to its collectors. The current state value can also be read through its `value` property." It is hot: "collecting from the flow doesn't trigger any producer code." It "requires an initial state to be passed in to the constructor" (https://developer.android.com/kotlin/flow/stateflow-and-sharedflow).
- To update: "assign a new value to the `value` property of the `MutableStateFlow` class." To convert a flow: the `stateIn` operator (same page).
- `SharingStarted.WhileSubscribed()` keeps the upstream active while there are subscribers. `Eagerly` starts it at once. `Lazily` starts it after the first subscriber and keeps it forever (same page; this text describes `shareIn`).
- StateFlow conflation and `distinctUntilChanged` equality: the page links to the API reference (https://kotlin.github.io/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.flow/-state-flow/); not quoted here. Verify before use.

## Navigation Compose

- Navigation Compose is for apps built with Compose: "Destinations in your graph are composables" (https://developer.android.com/develop/ui/compose/navigation).
- Core terms on that page: `NavHost` (the host: "A UI element that contains the current navigation destination"), `NavController` ("The central coordinator for managing navigation between destinations ... managing the back stack"), and routes ("Uniquely identifies a destination and any data required by it").
- Type-safe routes: the page says navigation supports "passing data between destinations with type safety" and that routes can be "Any serializable data type", and it lists the Kotlin serialization plugin. The `@Serializable` annotation is not named on that page: verify the exact route-declaration form on https://developer.android.com/guide/navigation/design/type-safety before use.
- Dependency artifact: `androidx.navigation:navigation-compose`. The example version on the page is `2.10.2`; verify the current one before use.
- Back and up "are handled correctly by default" (same page). The back stack page: not verified offline.

## Activity lifecycle and configuration changes

- "When a configuration change occurs, the activity is destroyed and recreated." The old instance receives `onPause`, `onStop`, `onDestroy`. The new instance receives `onCreate`, `onStart`, `onResume` (https://developer.android.com/guide/components/activities/state-changes).
- Configuration changes include orientation, language settings and input device changes (same page).
- "For most use cases, you should hoist state into a `ViewModel` and use `rememberSaveable` to ensure state persists through both configuration changes and system-initiated process death." (same page).
- "When an activity is recreated due to a configuration change, the initial composition is disposed of" (same page).
- Fragment lifecycle callbacks and `onSaveInstanceState` order: not verified offline. Read the Fragment lifecycle page before stating any order.
