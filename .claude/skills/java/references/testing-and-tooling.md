# Testing and tooling (Corretto 25, Java 11 floor)

Read this when you write tests, set up the gate, or choose a build tool for Java. Commands here were checked against the Maven 3.9.11 and Gradle 9.8.2 docs, the javac 25 manual and the JUnit user guide on 2026-10-29. Runs were made on Amazon Corretto 25.0.5, except where a row says "earlier run".

## Test file layout

- One test class per unit: `src/test/java/<package>/<Unit>Test.java`. Verify before use: the default test directory of the chosen tool.
- Golden files: `src/test/resources/golden/<unit>/<case>.json`. Each file records the input and the output of the source. Write it from the source, never from the target. The path is a convention; the plan names it.
- A test name carries the rule id when there is one, for example `BR_ROUND_002_roundsTiesToEven`.

## Runner

JUnit is the runner named here (https://junit.org/). Its user guide states that JUnit 6.1.3 is "JUnit Platform + JUnit Jupiter + JUnit Vintage" and that "JUnit requires Java 17 (or higher) at runtime" (docs.junit.org). For an 11 floor, pick a JUnit line that runs on Java 11; verify before use.

```java
import static org.junit.jupiter.api.Assertions.assertEquals;

import java.math.BigDecimal;
import java.math.RoundingMode;
import org.junit.jupiter.api.Test;

class RoundTest {
    @Test
    void BR_ROUND_002_roundsHalfEvenTieDown() {
        assertEquals(0, new BigDecimal("2.5").setScale(0, RoundingMode.HALF_EVEN).compareTo(new BigDecimal("2")));
    }
}
```

The annotation and assertion names in this example are verify before use against the JUnit user guide of the chosen line. The example compares with `compareTo`, so the expected scale is not part of the check; a test that needs the scale uses `equals` and says so in its name.

## Doubles and isolation

- Interfaces the code owns get hand-written fakes. A mocking library is used only when the repository already has one; verify before use.
- Pass the clock, the randomness source, the `Locale`, the `ZoneId` and the configuration into the code under test. Do not change the JVM default locale or the default time zone inside a test, because other tests read them.
- A test that must touch a file or a socket uses a temporary directory or an in-process server, and is marked as such in its name. Verify before use: the JUnit annotation for temporary directories.

## Golden comparison

- Load the recorded output from the golden file and compare parsed values, not raw text, unless the source output is text.
- Money: compare as strings in the canonical form the source prints, or with `BigDecimal.compareTo` when scale is not part of the contract (Java SE API: `equals` also compares scale).
- A missing golden file fails the test. Do not create it from the target's output.

## Gate commands

| Gate | Command | Pass means | Run on 2026-10-29 |
|---|---|---|---|
| Runtime | `java -XshowSettings:properties -version 2>&1 \| grep 'java.vendor.version'` | version 25.x and a `Corretto` vendor line | `java.vendor.version = Corretto-25.0.5.0.10` on 25.0.5 (run). The system `java` is Microsoft OpenJDK 17.0.19 (`Microsoft-13877129`), so this row fails until Corretto is first on PATH |
| Floor | `javac --release 11 -d <out> <sources>` | exit 0 | exit 0 for `var`, `List.of`, `strip()`, `repeat()`; exit 1 for a record, a text block and a switch expression; exit 1 for an `instanceof` pattern (run) |
| Encoding | `javac -encoding UTF-8 -d <out> <sources>` | exit 0, and the sources decode as UTF-8 | exit 0; the emoji literal gives `2 1` (run) |
| Maven build and tests | `mvn -B -ntp verify` | exit 0 and the summary shows no failing test | not run: `mvn` not installed |
| Gradle build and tests | `./gradlew check` | exit 0 and no failing test | not run: `gradle` not installed |
| Coverage | the coverage plugin of the chosen tool | the figure the plan requires | verify before use |

Report the command, the exit code, and the line that decides the result. A gate that did not run is "not run", never a pass.

## Build tool choice

- Use what the repository already has. Maven reads `pom.xml`; Gradle reads `build.gradle` or `build.gradle.kts` and is run through the `./gradlew` wrapper. Do not add a second tool.
- Maven: `-B` runs in batch mode and disables colored output; `-ntp` disables the transfer progress (Maven 3.9.11 CLI page). The default lifecycle lists `test` before `verify` (Maven lifecycle page); the page lists the order and does not restate the run rule, so confirm the test run in the build output.
- Gradle: the `check` lifecycle task is where plugins attach their verification tasks, such as tests. The `build` task depends on `check` and `assemble` (Gradle 9.8.2 base plugin page).
- Versions of build plugins and of JUnit are pinned in the build file. Check each version against its release page before pinning it; verify before use.
