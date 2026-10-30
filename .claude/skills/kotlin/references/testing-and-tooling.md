Read this when you write tests, set up the quality gate, or choose a Kotlin or Android tool. Facts were checked against the official pages on 2026-10-30. None was run on the machine that wrote this file.

# Testing and tooling (Kotlin, Android UI)

## Test layout

- Local JVM tests: `module-name/src/test/` (https://developer.android.com/training/testing/local-tests).
- Instrumented tests: `module-name/src/androidTest/`. They run on a device or emulator (same page; the Compose testing page uses `androidTest` for `ui-test-junit4`, https://developer.android.com/develop/ui/compose/testing).
- One test file per unit: `<UnitName>Test.kt`. Name each test with its rule id when there is one, for example `BR-ROUND-002 rounds ties away from zero`.

## Local unit tests with JUnit

- "A _local_ test runs directly on your own workstation, rather than an Android device or emulator. As such, it uses your local Java Virtual Machine (JVM)" (https://developer.android.com/training/testing/local-tests).
- Local tests "enable you to evaluate your app's logic more quickly. However, not being able to interact with the Android framework creates a limitation in the types of tests you can run" (same page).

```kotlin
import org.junit.Assert.assertEquals
import org.junit.Test

class RoundingTest {
    @Test
    fun `BR-ROUND-002 integer division truncates`() {
        assertEquals(2, 5 / 2)
    }
}
```

- The JUnit version, the assertion library and the runner: not verified offline. Use the versions the project pins.

## Doubles and fakes

- "Consider using the real implementation of the dependency in an instrumentation test" (https://developer.android.com/training/testing/local-tests).
- Use fakes (hand-written) first. The page says: "you can use different types of test doubles such as fakes, or Robolectric shadows if they are Android classes" (same page).
- Mocking library (for example MockK) and its version: not verified offline.
- Time: pass a clock as a value. Do not read the system clock inside the logic under test. The clock API the project uses: read the project code.

## Robolectric

- Robolectric runs Android framework code on the JVM. The local-tests page links to it (http://robolectric.org/) and adds an optional dependency: `testImplementation "androidx.test:core:$androidXTestVersion"` with the comment "Optional -- Robolectric environment" (https://developer.android.com/training/testing/local-tests).
- The Robolectric version, supported SDK levels and runner setup: not verified offline. Read http://robolectric.org/ at the pinned version before use.

## Compose UI tests

- `createComposeRule()` sets Compose content without an activity. `createAndroidComposeRule<YourActivity>()` gives access to an activity (https://developer.android.com/develop/ui/compose/testing).
- Dependencies (the page's module-level snippet):

```kotlin
androidTestImplementation("androidx.compose.ui:ui-test-junit4:$compose_version")
// Needed for createComposeRule(), but not for createAndroidComposeRule<YourActivity>():
debugImplementation("androidx.compose.ui:ui-test-manifest:$compose_version")
```

- Rule and content example from the page:

```kotlin
@get:Rule val composeTestRule = createComposeRule()

@Test
fun myTest() {
    composeTestRule.setContent {
        MyAppTheme { MainScreen(uiState = fakeUiState) }
    }
    composeTestRule.onNodeWithText("Continue").performClick()
    composeTestRule.onNodeWithText("Welcome").assertIsDisplayed()
}
```

- `setContent` and `createComposeRule` are described in prose on https://developer.android.com/develop/ui/compose/testing. `onNodeWithText`, `performClick` and `assertIsDisplayed` appear there in sample code only (same page).
- State restoration in tests: the saved-state page mentions `StateRestorationTester` for verifying restoration (https://developer.android.com/develop/ui/compose/state-saving). Its API: not verified offline.

## ViewModel and Flow tests

- Test a ViewModel on the JVM: create it with fake dependencies, collect its `StateFlow`, and call its actions.
- Coroutine test dispatchers (`kotlinx-coroutines-test`) and their APIs: not verified offline.

## Gate commands

Verify each task name against the project's Gradle setup before use. The exit-code behavior of Gradle tasks: a failed task makes Gradle exit non-zero (not verified offline for this run).

| Gate | Command | What passes | Verified in this run |
|---|---|---|---|
| Local tests | `./gradlew test` | all JVM unit tests pass, including Robolectric tests under `src/test` | the task name: not verified offline |
| Instrumented tests | `./gradlew connectedAndroidTest` | all tests on the device pass; needs a device or emulator | not verified offline |
| Lint | `./gradlew lint` | no lint error that fails the build | not verified offline |
| Format, if configured | project's own task (ktlint or spotless) | the tool's own pass condition | not verified offline |

- Report each gate with its command, its exit code and the line that decides the result.
- Coverage: the JaCoCo task name is not verified offline.

## Tool choice

- Use what the project already has. Add a library only when the plan names it and the gate needs it.
- Pin versions in `gradle/libs.versions.toml` or the build file.
- Read the flags of any Gradle task with `./gradlew help --task <name>`, and record the version you ran.
