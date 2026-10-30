---
name: java
description: "Java on Amazon Corretto 25 LTS, with the Java 11 floor: .java sources, Maven and Gradle builds, JUnit tests, java.time and BigDecimal money, records, sealed types, switch patterns, virtual threads and the quality gate. Use for Java code, pom.xml or build.gradle, or migrations to or from Java."
metadata:
  baseline: "Amazon Corretto 25 LTS (25.0.5 run on 2026-10-29), with the Java 11 floor (javac --release 11 run)"
  verified: "2026-10-29"
---

# java (Amazon Corretto 25 LTS, Java 11 floor)

Practice for Java code: language features by release, the standard library, build tools, tests, and the parity traps of numbers, text, time and absent values. The standard distribution is Amazon Corretto (https://aws.amazon.com/pt/corretto/). The baseline is Corretto 25 LTS, and the floor is Java 11. Facts were checked on 2026-10-29 against the Corretto FAQ and the Corretto 25 user guide, the Java SE 25 API index, JLS 25 chapters 4 and 14, the javac 25 manual, the JDK 21 and JDK 11 API pages and the JEP pages. A fact marked `run` was executed on Amazon Corretto 25.0.5 (`openjdk version "25.0.5" 2026-10-20 LTS`). A fact marked `earlier run` comes from OpenJDK 17.0.19. Sources are listed at the end.

## 1. Scope and versions

- Target the release the repository declares. Read it from the build file (Maven `maven.compiler.release` or `release`, or the Gradle toolchain); verify the exact property names before use. If none is declared, use 25 and say so in the report.
- Corretto 25 is the default because it is the newest LTS in the Corretto support calendar. The FAQ lists its GA on September 16, 2025, its last planned update in July 2032 and its end of life in October 2032 (https://aws.amazon.com/corretto/faqs/). The older LTS lines are Corretto 21 (end of life October 2030) and Corretto 17 (end of life October 2029). A repository on one of them keeps its release and says so in the report.
- The floor for the code this skill covers is Java 11. Corretto 11 LTS ends in January 2032, with its last planned update in October 2031 (Corretto FAQ). Under 11, do not use records, text blocks, switch expressions, sealed types, pattern matching, sequenced collections or virtual threads. Check the floor with `javac --release 11` (section 8, check 4).
- Choose features by the release the code must run on, not by the JDK installed on the machine. A compile on JDK 25 does not prove the floor.
- Oracle's Java SE support roadmap is not used. Its page returned HTTP 403 to the fetch tool on 2026-10-29.
- JUnit 6.1.3 needs Java 17 at runtime (docs.junit.org). For an 11 floor, use a JUnit 5 line; verify before use.
- Preview features (for example JEP 430 string templates, a JDK 21 preview) are not used in shipped code.
- Record three versions in the report: the JDK, the build tool and the test library. Each one can change the result.

## 2. Layout and build

- Maven: `pom.xml`, tests under `src/test/java`. Gradle: `build.gradle` or `build.gradle.kts`, with the `./gradlew` wrapper. Use the build tool the repository has; do not add a second one. Verify before use: the standard directory layout of each tool.
- The check machine of this toolkit had no Java build file or source on 2026-10-29. The gate in section 8 lists both tools; the migrated project names one.
- Split by responsibility: plain classes for logic (no I/O, no clock, no environment); thin adapters for files, network, database and environment. Tests use the plain classes directly.
- Pass the clock, the randomness source and the configuration in through constructors. Use `java.time.Clock` for "now" (verify before use).
- Keep the JDK version in the build file, not in a local path. Section 8 runs against the JDK on PATH, and its check 1 reads the vendor, so the report names the vendor and the version.
- Pin the build plugin and JUnit versions in the build file, and check each one against its release page before pinning (verify before use).

## 3. Idioms

- `var` for a local variable whose type the right-hand side makes obvious (JEP 286, JDK 10).
- Records for immutable data carriers (JEP 395, JDK 16). Sealed types with `permits` (JEP 409, JDK 17). Switch expressions (JEP 361, JDK 14). Pattern matching for `instanceof` (JEP 394, JDK 16). Pattern matching for `switch` and record patterns (JEP 441 and JEP 440, JDK 21). Details: `references/language-features-by-version.md`.
- Whitespace: `strip()` removes Unicode white space; `trim()` removes only code points up to U+0020. They differ on U+2003 (section 6). `isBlank()` is true for an empty string or one with only white-space code points (JDK 11 API).
- Files: `Files.readString(path)` decodes with UTF-8 (JDK 11 API). Pass an explicit charset to every other byte-to-text conversion.
- HTTP: `java.net.http.HttpClient` is the standard client from JDK 11 (JEP 321).
- Sequenced collections (JDK 21, JEP 431): `getFirst()` and `getLast()` throw `NoSuchElementException` on an empty collection; `reversed()` returns a view linked to the original (run).
- `Optional` is a method return type only (section 6).
- For new date code, use `java.time`; keep `Calendar` only where the source's lenient rules must be copied (section 6).

## 4. Errors, resources and exit

- Throw exceptions with a message and the cause: `Exception(String message, Throwable cause)` (Java SE API). Do not throw strings.
- `ArithmeticException` extends `RuntimeException`, so it is unchecked (Java SE API). Integer `/` and `%` by zero throw it (JLS 4.2.2; run).
- Give each source exception one stable error type. Keep the source's message text when the source has a stable message.
- Close resources with try-with-resources. Resources close in the reverse order of their initialization. An exception thrown by `close` while the body is failing is added to the suppressed list (JLS 14.20.3; run: both close failures are suppressed under the body's exception, in the order the resources closed).
- Read suppressed exceptions with `getSuppressed()` in tests, so a failing `close` is not lost (run).
- Stack traces and generated class names are not a stable output. Compare the exception type, the error code and the stable message only (verify before use).
- A source that catches a broad error and returns a value keeps that path: map it to the same value, not to a new thrown exception, unless the spec says otherwise (parity beats idiom).
- Library code does not call `System.exit`. Only `main` sets the exit status.

## 5. Concurrency

- Virtual threads (JDK 21, JEP 444): `Thread.ofVirtual()` and `Thread.startVirtualThread(Runnable)` (Java SE API). A run on 25.0.5 shows `Thread.ofVirtual().unstarted(...).isVirtual()` is `true` (run). Create one virtual thread per task; do not pool them. Limit concurrency with a semaphore.
- Virtual threads are not faster threads: they run code no faster than platform threads, and they help when most tasks wait on I/O (JEP 444).
- Blocking inside `synchronized` pins the carrier thread. JEP 444 recommends `ReentrantLock` for long I/O under a lock.
- `HashMap` is unsynchronized (Java SE API). A map shared between threads needs a lock or a concurrent type chosen for the access pattern; verify before use.
- A read, a blocking call, then a write on shared state is a race. Keep the section atomic or guard it.
- Fan-out: keep the results in input order and map each failure to the source's error. The failure behavior of each executor and future API is verify before use.

## 6. Data and numbers (parity traps)

Each value marked `run` was executed on Amazon Corretto 25.0.5 on the check machine. A value marked `earlier run` comes from OpenJDK 17.0.19.

- Money: `BigDecimal` with an explicit scale and `RoundingMode`. Never `double`: `0.1 + 0.2` prints `0.30000000000000004` (run).
- Parse decimal input as text into `BigDecimal` (`new BigDecimal(String)`). Parsing it as a `double` first loses digits: `new BigDecimal(0.1)` is the exact binary value `0.1000000000000000055511151231257827021181583404541015625`, while `BigDecimal.valueOf(0.1)` is `0.1` (run).
- `BigDecimal.equals` compares scale; `compareTo` does not. `new BigDecimal("2.0").equals(new BigDecimal("2.00"))` is false and `compareTo` is 0 (run).
- `setScale(n)` without a `RoundingMode` throws `ArithmeticException` with the message `Rounding necessary` when rounding is needed (run). `setScale(2, RoundingMode.HALF_EVEN)` on `2.345` is `2.34` (run).
- Integer overflow wraps silently: `Integer.MAX_VALUE + 1` is `-2147483648` (JLS 4.2.2; run). `Math.addExact` throws `ArithmeticException` with the message `integer overflow` instead (run).
- Integer `/` and `%` by zero throw `ArithmeticException` with the message `/ by zero` (JLS 4.2.2; run). Floating-point division by zero is a different case; verify the result before use, and check the source's own guard.
- `Math.round` rounds ties toward positive infinity: `Math.round(-2.5)` is `-2`, `Math.round(2.5)` is `3`, and `Math.round(0.49999999999999994)` is `0` (run). `Math.round(NaN)` is `0`, and `Math.round(1e30)` is `9223372036854775807` (run).
- `String.format` and `%f` use the default FORMAT locale when none is given (Java SE API). On the check machine that locale is `pt_BR` (run), and `String.format(Locale.GERMANY, "%.2f", 1.5)` is `1,50` (run). `%f` rounds half up from the shortest decimal form: `String.format(Locale.ROOT, "%.2f", 1.005)` is `1.01`, `new BigDecimal(1.005)` with `HALF_UP` at scale 2 is `1.00`, and `BigDecimal.valueOf(1.005)` with `HALF_UP` at scale 2 is `1.01` (run). `String.format(Locale.ROOT, "%.1f", 0.25)` is `0.3` (run).
- `toLowerCase()` and `toUpperCase()` without a `Locale` use the default locale (Java SE API). `"TITLE".toLowerCase(new Locale("tr"))` gives the dotless `ı` (U+0131, code point 305; run). On the check machine the same call without a locale gives `title` (run). `new Locale("tr")` is deprecated on 25.0.5: `javac -Xlint:deprecation` warns (run).
- `HashMap` gives no iteration-order guarantee, and the order may change over time (Java SE API). Run: keys `banana, apple, cherry, date` iterate as `[banana, date, apple, cherry]` (run).
- Default charset: `Charset.defaultCharset()` is UTF-8 unless the JVM is configured otherwise (JEP 400, JDK 18). On 25.0.5 here, `Charset.defaultCharset()` and `file.encoding` are UTF-8, and `native.encoding` is `Cp1252` (run). On the OpenJDK 17.0.19 check machine the default was `windows-1252` (earlier run). `getBytes()` and `new String(bytes)` without a charset use the default, so their output depends on the JDK and its settings.
- Source files: javac reads them with the platform default converter unless `-encoding` is given (javac 25 manual). On 25.0.5 here, a literal `😀` (U+1F600) gave `length()` 2 and one code point, with and without `-encoding UTF-8` (run). On OpenJDK 17.0.19 the same file without the flag gave length 4 (earlier run). Pass the flag anyway (section 8, check 5).
- `Optional.get()` throws `NoSuchElementException` when empty, with the message `No value present` (run). `Optional` is for a return type only; never compare with `==` against `Optional.empty()` (Java SE API).
- Text length: a supplementary character (U+1F600, a surrogate pair in UTF-16) has `length()` 2 and one code point (run). Count code points where the source counts characters.
- Edge white space: on a string with U+2003 at both ends, `strip()` leaves length 1 and `trim()` leaves length 3 (run). `strip()` keeps U+00A0 (run: length 3 for `U+00A0 x U+00A0`). `isBlank()` is false for U+00A0 and true for U+2003 (run).
- Time: zones, offsets and the `Calendar` month base are in `references/numbers-and-time.md`.

## 7. Testing

- Runner: JUnit (https://junit.org/). JUnit 6.1.3 is "JUnit Platform + JUnit Jupiter + JUnit Vintage" and needs Java 17 at runtime (docs.junit.org). Use the line that matches the floor (section 1).
- Layout: one test class per unit. Test names state the behavior or the rule id, one behavior per test.
- One test per rule id and one per error path, named with the rule id, for example `BR_ROUND_002_roundsHalfEvenTieDown`.
- Doubles: hand-written fakes for interfaces the code owns. Use a mocking library only when the repository has one; verify before use.
- Do not change the JVM default locale or time zone inside a test. Pass the `Locale` and `ZoneId` into the code under test.
- Money assertions: compare with `equals` only when scale is part of the contract. Otherwise use `compareTo` and say so in the test name.
- Golden tests: load the recorded output, written from the source, and compare parsed values. Never regenerate the golden from the target's output.
- A parity claim needs a test against the source's recorded output. A unit test written from the same reading of a rule shows only that the code matches that reading.

## 8. Quality gate

Run each command, read its result, and report the real output. A gate that did not run is not a pass. Tools that are not installed on the check machine are marked "not run".

1. Runtime: `java -XshowSettings:properties -version 2>&1 | grep 'java.vendor.version'`. The line must contain `Corretto`, and `java -version` must report 25.x. Run on 25.0.5 (portable Corretto zip, not on the system PATH): `java.vendor.version = Corretto-25.0.5.0.10` and `openjdk version "25.0.5" 2026-10-20 LTS` (run). The system `java` on the check machine is Microsoft OpenJDK 17.0.19 (`java.vendor.version = Microsoft-13877129`, checked on 2026-10-29), so this check fails until Corretto is first on PATH.
2. Maven: `mvn -B -ntp verify`. `-B` is batch mode and `-ntp` hides transfer progress (Maven 3.9.11 CLI page). `verify` is listed after `test` in the default lifecycle (Maven lifecycle page). Not run: `mvn` is not installed.
3. Gradle: `./gradlew check`. The `check` lifecycle task is where verification tasks such as tests attach (Gradle 9.8.2 base plugin page). Not run: `gradle` is not installed; the wrapper script is verify before use.
4. Floor: `javac --release 11 -d <out> <sources>`, with `<out>` new and empty. Run on 25.0.5: a file using `var`, `List.of`, `strip()` and `repeat()` compiles with exit 0 and prints `[a, b] xabab` (run). A file with a `record`, a text block and a switch expression fails with exit 1 and four errors: `records are not supported in -source 11`, `text blocks are not supported in -source 11`, `switch expressions are not supported in -source 11` and `switch rules are not supported in -source 11` (run). A file with an `instanceof` pattern fails with exit 1: `pattern matching in instanceof is not supported in -source 11` (run). The exit code decides, not the warning count: an earlier JDK 17 run reported the record as a warning only.
5. Encoding: `javac -encoding UTF-8 -d <out> <sources>` for every source with non-ASCII text. Run on 25.0.5: the emoji literal gives `2 1` (length 2, one code point) with and without the flag (run). Keep the flag: the javac manual defines the default as the platform default converter, and the earlier JDK 17 run gave another result (section 6).
6. Tests: the test command of the chosen tool. Pass means exit code 0 and the tool's summary reports no failure. Coverage thresholds are verify before use.

Pass rule: exit code 0 from the shell, plus the tool's own result line quoted in the report. The meaning of each tool's exit code is verify before use.
Run the checks in the order listed. A failing check blocks the checks after it; report the failure and stop the gate.
The runs in this skill used Amazon Corretto 25.0.5, unless a line says "earlier run" and names its JDK. Earlier OpenJDK 17.0.19 results show that JDK's behavior only.

## 9. Migrating TO Java

- Parity beats idiom. Choose an idiom only when inputs, outputs and errors stay the same. Otherwise keep the source behavior and mark the difference `deviation`, with its reason and its source.
- Map each source construct with `references/as-target.md`.
- Money: `BigDecimal` with the source's scale and an explicit `RoundingMode` on every rounding call. Test each tie direction.
- Output text, not only the value: `2.50` and `2.5` are equal in value and differ in scale and in text (section 6).
- Text and time: an explicit charset for every byte conversion, and an explicit zone for every formatted instant (`references/numbers-and-time.md`).
- Error model: one exception type per source exception; keep the source message when it is stable.
- Keep the source's public names only when an external caller depends on them.
- Build with the release the repository declares, and check the floor (section 8, check 4).
- Order of work: release and floor first, then numbers and money, text and encoding, time, errors and resources, and concurrency last. Write the tests for each step before its code.

## 10. Migrating FROM Java

- Read `references/as-source.md` for where Java behavior hides: the default charset, the default locale, the default time zone, BigDecimal scale, HashMap order, silent overflow, and `Optional`.
- Read the source's build file first: the release, the encoding setting and the test setup are part of the behavior (sections 1 and 8).
- Record each runtime default you find in the source as a behavior, with the line that reads it. A default the code never sets is still a default of the machine it runs on.
- For each parity-sensitive output, name the Java type it is stored in and the line that produces it.

## 11. Anti-patterns

- `double` or `float` for money.
- `new BigDecimal(double)` for a decimal value. Use `BigDecimal.valueOf(double)` or a string, and say which in the code.
- `setScale(n)` without a `RoundingMode` where rounding may be needed.
- `equals` to compare amounts when scale is not part of the contract.
- `String.format`, `toLowerCase` or `toUpperCase` without an explicit `Locale` in parity-sensitive code.
- The `new Locale(...)` constructors, deprecated on 25.0.5 (run). Use a form the floor accepts (verify before use).
- `getBytes()` or `new String(bytes)` without a charset.
- Relying on `HashMap` iteration order.
- Sorting text with `String.compareTo` when the source sorts with a locale collation (verify before use).
- `Optional.get()` without a presence check; `Optional` as a field or a parameter.
- A blocking call inside `synchronized` on a virtual thread.
- `System.exit` in library code.
- A catch-all `catch (Exception e)` that hides a failure the source reports as a value.
- Compiling sources with non-ASCII text without `-encoding`.

## Library registry

- Registry: Maven Central, https://central.sonatype.com/ (artifact pages show coordinates, versions, the POM and the required Java release).
- Before adding an artifact, check the JDK standard library first. Then search Maven Central, open the artifact page, and confirm: latest version, the Java release it is compiled for (bytecode level) against the target, license, last release, and transitive dependencies.
- Read the exact coordinates and versions from the artifact page and pin them in the build file already used by the repository (Maven or Gradle). Do not add a second build tool.
- Full procedure and evaluation checks: `.claude/skills/migration-conduct/references/library-research.md`.

## Sources

- Maven Central: https://central.sonatype.com/
- Amazon Corretto download page, the standard (pt-BR): https://aws.amazon.com/pt/corretto/
- Amazon Corretto FAQ, support calendar and LTS: https://aws.amazon.com/corretto/faqs/
- Amazon Corretto 25 User Guide, "What is Amazon Corretto 25?": https://docs.aws.amazon.com/corretto/latest/corretto-25-ug/what-is-corretto-25.html
- Java SE 25 API index: https://docs.oracle.com/en/java/javase/25/docs/api/index.html
- Java SE 21 API (read on 2026-10-29; an API fact without a run is verify before use on 25): https://docs.oracle.com/en/java/javase/21/docs/api/
- Java SE 11 API: https://docs.oracle.com/en/java/javase/11/docs/api/
- Java Language Specification, SE 25, chapter 4 (section 4.2.2) and chapter 14 (section 14.20.3): https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html and https://docs.oracle.com/javase/specs/jls/se25/html/jls-14.html
- javac manual, SE 25 (`--release`, `-encoding`): https://docs.oracle.com/en/java/javase/25/docs/specs/man/javac.html
- JEP index and JEP pages: https://openjdk.org/jeps/
- Maven 3.9.11 CLI: https://maven.apache.org/ref/3.9.11/maven-embedder/cli.html
- Maven 3.9.11 default lifecycle: https://maven.apache.org/ref/3.9.11/maven-core/lifecycles.html
- Gradle 9.8.2 base plugin: https://docs.gradle.org/current/userguide/base_plugin.html
- JUnit user guide: https://docs.junit.org/current/user-guide/
