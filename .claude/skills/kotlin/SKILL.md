---
name: kotlin
description: "Kotlin for Android UI: Jetpack Compose state, recomposition, remember, rememberSaveable and side effects, ViewModel and StateFlow, Navigation Compose, activity and configuration-change lifecycle, JUnit, Compose UI tests, Robolectric and instrumented tests, plus Kotlin null safety, Int overflow, integer division and Double facts. Use for Kotlin code, build.gradle.kts, Android UI, or migrations to or from Kotlin and Android UI."
metadata:
  baseline: "Kotlin language and Android UI docs as published on developer.android.com and kotlinlang.org; exact Kotlin, Compose BOM, Navigation and AGP versions are the project's own (not verified offline)"
  verified: "2026-10-30"
---

# kotlin (Android UI, Jetpack Compose, Kotlin language)

Practice for Kotlin code that builds Android UI, used when Kotlin or Android UI is the source or the target of a migration. Facts were checked against the official Android and Kotlin pages on 2026-10-30. No Kotlin toolchain or Android SDK was run on the machine where this skill was written, so no gate command was run. Every library or framework claim cites its official URL in the references; anything not verified is marked "not verified offline".

## 1. Scope and versions

- The project's versions are the source of truth: `build.gradle.kts` or `libs.versions.toml` (Kotlin plugin, Compose BOM, `androidx.navigation:navigation-compose`, `androidx.lifecycle` artifacts, AGP). Record them in the report. Do not assume a version.
- The Navigation Compose page shows `androidx.navigation:navigation-compose` with `nav_version = "2.10.2"` and the Kotlin serialization plugin at `2.0.21` as examples, not as current releases (https://developer.android.com/develop/ui/compose/navigation). Verify the current versions before use.
- The Compose test artifacts are `androidx.compose.ui:ui-test-junit4` and `androidx.compose.ui:ui-test-manifest` (https://developer.android.com/develop/ui/compose/testing).
- Latest stable Kotlin and Compose versions: not verified offline.

## 2. Layout and build

- Local unit tests live in `module-name/src/test/`. Instrumented tests live in `src/androidTest/` (https://developer.android.com/training/testing/local-tests).
- Split by responsibility: pure Kotlin logic (no Android types) in plain classes that tests run on the JVM; ViewModels that hold UI state; composables that only show state and emit events. Tests import the pure classes.
- Keep the target's package name and module layout in the plan. Do not invent a package name.

## 3. Idioms

- Compose UI is declarative. A composable describes the screen for its current inputs; it does not return a view (https://developer.android.com/develop/ui/compose/mental-model). See references/compose-viewmodel-navigation.md.
- State that the UI changes is held in `mutableStateOf` (or a `StateFlow` in a ViewModel) and read by composables. Mutable non-observable objects such as `ArrayList` or a mutable data class do not trigger recomposition (https://developer.android.com/develop/ui/compose/state).
- Hoist state: the composable receives `value` and `onValueChange`, and its caller owns the state (https://developer.android.com/develop/ui/compose/state).
- Nullable types are `T?`. Use `?.` and `?:` where the source handles absence, and `!!` only where the source would fail (https://kotlinlang.org/docs/null-safety.html).

```kotlin
val length: Int? = name?.length
val shown: String = name ?: "" // only where the source prints an empty field for a missing value
```

## 4. Errors, resources and exit

- Map each source exception to one error class with a stable name. Keep the source message when the source emits it.
- Release resources in `DisposableEffect`'s `onDispose`, or in the ViewModel's `onCleared` (https://developer.android.com/develop/ui/compose/side-effects; https://developer.android.com/topic/libraries/architecture/viewmodel).
- `NullPointerException` from `!!` is an error the source may not raise. Record which error the source raises for the same input.

## 5. Concurrency

- Compose calls composables again on recomposition, possibly every frame. Do not run side effects in the composable body. Use effect APIs (https://developer.android.com/develop/ui/compose/side-effects).
- `LaunchedEffect` runs a suspend block for the life of the composable and restarts when its keys change (same page).
- A ViewModel keeps asynchronous work running across configuration changes (https://developer.android.com/topic/libraries/architecture/viewmodel).
- Coroutine dispatcher and `Flow` operator details: not verified offline. Read the linked API reference before using them.

## 6. Data and numbers (parity traps)

- `Int` is 32 bits, from -2,147,483,648 to 2,147,483,647. Overflow wraps silently: `2147483647 + 1` is `-2147483648` (https://kotlinlang.org/docs/numbers.html).
- Integer division truncates: `5 / 2` is `2` (https://kotlinlang.org/docs/numbers.html).
- `Double` is IEEE 754 double precision, 64 bits (https://kotlinlang.org/docs/numbers.html). The Kotlin page shows `10.0 / 3` printing `3.3333333333333335`. Its `toString` format rules for exponents and `-0.0`: not verified offline.
- Rounding functions (`roundToInt`, `round`), `String.format` locale behavior and `Long` overflow: not verified offline. Test each tie and boundary on the target before relying on it.

## 7. Testing

- Local tests run on the JVM and cannot use the Android framework. Use fakes, or Robolectric shadows for Android classes (https://developer.android.com/training/testing/local-tests).
- Robolectric is an optional local environment: the page adds `testImplementation "androidx.test:core:$androidXTestVersion"` with the comment "Optional -- Robolectric environment" (same page). The Robolectric version and its supported SDK levels: not verified offline.
- Compose UI tests: `createComposeRule()` for content without an activity, `createAndroidComposeRule<YourActivity>()` when the test needs the activity. `createComposeRule` needs `debugImplementation("androidx.compose.ui:ui-test-manifest:$compose_version")` (https://developer.android.com/develop/ui/compose/testing).
- Layout, commands and tool choice: references/testing-and-tooling.md.

## 8. Quality gate

Run each command in the project root and report its real output. A gate that did not run is not a pass. No toolchain was run in this skill's authoring, so none of these was run here.

1. `./gradlew test` runs local JVM unit tests (including Robolectric tests placed under `src/test`). Exit code 0 means the build and tests passed. Verify the exact task names for the project: not verified offline.
2. `./gradlew connectedAndroidTest` runs instrumented tests on a device or emulator (including `createComposeRule` tests under `src/androidTest`). Requires a running device: not verified offline for exit codes.
3. Lint: `./gradlew lint`. Task name and exit behavior: not verified offline.
4. Formatting, if the project uses ktlint or spotless: the project's own task. Not verified offline.

- Run each gate, even when an earlier one fails. Report each command, its exit code and the line that decides the result.

## 9. Migrating TO Kotlin / Android Compose

- Parity beats idiom. Choose an idiom only when inputs, outputs and errors stay the same. Otherwise keep the source behavior, and mark the difference `deviation` with its reason and source.
- Map each source construct with references/as-target.md: state, lists, navigation, lifecycle, numbers and text.
- Write a test for each state transition and each configuration-change path before writing the code.
- Keep state that must survive rotation in a ViewModel, and UI-only state in `rememberSaveable` (https://developer.android.com/develop/ui/compose/state-saving).
- For each source screen, record the source's transitions and map each to a test.

## 10. Migrating FROM Kotlin / Android UI

- Read references/as-source.md for the places where Kotlin and Android behavior hide: Int wrap-around, integer division, null in text, state lost on process death, and effects that restart.
- Read references/compose-viewmodel-navigation.md for the facts behind each trap.
- Cite the source with `path:line` for each rule, and check each Kotlin or Android behavior it depends on against the official pages listed in the references.

## 11. Anti-patterns

- Side effects in a composable body, outside an effect API.
- `LaunchedEffect(true)` used as a one-time setup when the work depends on a key (https://developer.android.com/develop/ui/compose/side-effects warns it is "as suspicious as a while(true)").
- `remember` used for state that must survive configuration changes; use `rememberSaveable` or a ViewModel.
- Large objects or lists stored in `rememberSaveable` or the saved-state Bundle (https://developer.android.com/develop/ui/compose/state-saving).
- ViewModel holding `Context`, `Resources`, or a view reference (https://developer.android.com/topic/libraries/architecture/viewmodel).
- Mutable collections as Compose state without `mutableStateListOf` or an immutable copy.
- `!!` where the source handles a missing value.
- `Int` used for values that can exceed 2^31 - 1 without a check.
- `derivedStateOf` used for a simple combination of two values; the page calls that overhead (https://developer.android.com/develop/ui/compose/side-effects).

## Library registry

- Official registry for Android libraries: Google Maven, https://maven.google.com, and the Android developer pages for each artifact. Maven Central holds Kotlin and kotlinx artifacts (https://central.sonatype.com).
- Before adding a library, read its release notes, confirm the minimum Kotlin and AGP versions, and check the license. Exact procedure: `.claude/skills/migration-conduct/references/library-research.md`.
- Pin the version in `libs.versions.toml` or the build file.

## Sources

- Compose state: https://developer.android.com/develop/ui/compose/state
- Compose state saving: https://developer.android.com/develop/ui/compose/state-saving
- Compose side effects: https://developer.android.com/develop/ui/compose/side-effects
- Compose mental model: https://developer.android.com/develop/ui/compose/mental-model
- Compose lifecycle: https://developer.android.com/develop/ui/compose/lifecycle
- Compose testing: https://developer.android.com/develop/ui/compose/testing
- Navigation Compose: https://developer.android.com/develop/ui/compose/navigation
- ViewModel: https://developer.android.com/topic/libraries/architecture/viewmodel
- StateFlow: https://developer.android.com/kotlin/flow/stateflow-and-sharedflow
- Activity state changes: https://developer.android.com/guide/components/activities/state-changes
- Local tests: https://developer.android.com/training/testing/local-tests
- Kotlin null safety: https://kotlinlang.org/docs/null-safety.html
- Kotlin numbers: https://kotlinlang.org/docs/numbers.html
- Central registry: https://central.sonatype.com
