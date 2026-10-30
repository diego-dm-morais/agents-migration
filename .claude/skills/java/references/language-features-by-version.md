# Language features by version (Java 11 floor, Corretto 25 baseline)

Read this when a migration or a change depends on the Java release: which language feature or API exists from which release, and how to check the floor. The baseline is Corretto 25 LTS; the floor for this skill is Java 11. The table lists the features from 10 to 21 that this skill uses. Features added in 22 to 25 are not listed here: verify them on the JDK 25 release notes before use.

## Table

| Feature | Release | Source | Status | Note |
|---|---|---|---|---|
| Local-variable type inference (`var`) | 10 | JEP 286 | Final | Local variables only, per the JEP summary |
| `java.net.http.HttpClient` | 11 | JEP 321 | Final | Standard HTTP client, from the incubated client of JDK 9 and 10 |
| `String.isBlank()`, `strip()`, `lines()`, `repeat(int)` | 11 | JDK 11 String API | Final | `isBlank()` tests white-space code points; `strip()` keeps U+00A0 (run) |
| `Files.readString(Path)` | 11 | JDK 11 Files API | Final | Decodes with UTF-8 |
| Switch expressions | 14 | JEP 361 | Final | `switch` as a statement or an expression; `--release 11` rejects them (run) |
| Text blocks | 15 | JEP 378 | Final | Trailing white space is removed; `--release 11` rejects them (run) |
| Records | 16 | JEP 395 | Final | Transparent carriers for immutable data; `--release 11` rejects them (run) |
| Pattern matching for `instanceof` | 16 | JEP 394 | Final | `--release 11` rejects it (run) |
| Sealed classes and interfaces | 17 | JEP 409 | Final | `permits` names the subtypes; each permitted subclass is `final`, `sealed` or `non-sealed` |
| UTF-8 default charset | 18 | JEP 400 | Release 18 (status verify before use) | `Charset.defaultCharset()` is UTF-8 unless `file.encoding` overrides it (run on 25.0.5: UTF-8) |
| Pattern matching for `switch` | 21 | JEP 441 | Final | Exhaustiveness over sealed types is checked with the `permits` clause |
| Record patterns | 21 | JEP 440 | Final | Deconstruction of records, nested |
| Virtual threads | 21 | JEP 444 | Final | `Thread.ofVirtual()` and `Thread.startVirtualThread(Runnable)` since 21; `isVirtual()` is `true` (run) |
| Sequenced collections | 21 | JEP 431 | Final | `getFirst()`, `getLast()`, `reversed()`; `getFirst()` on an empty `ArrayList` throws `NoSuchElementException` (run); `reversed()` is a view (run) |
| String templates | 21 | JEP 430 | Preview | Not used in shipped code |

## Baseline and floor

- Baseline: Corretto 25 LTS (SKILL.md, section 1). The LTS calendar comes from the Corretto FAQ. Oracle's roadmap was not used: its page returned HTTP 403 on 2026-10-29.
- Floor: Java 11. Under 11, the code uses none of: records, text blocks, switch expressions, pattern matching, sealed types, virtual threads, sequenced collections.
- `javac --release N` compiles code for release N of the platform (javac 25 manual, section "Compiling for Earlier Releases of the Platform"). The runs below show the language rules; the API part is verify before use.

## Floor checks run on Corretto 25.0.5

- `Ok11.java` with `var`, `List.of`, `"  x ".strip()` and `"ab".repeat(2)`: `javac --release 11` exit 0; `java` printed `[a, b] xabab` and `U+0131 305` (run).
- `Bad11.java` with a `record`, a text block and a switch expression: `javac --release 11` exit 1 with four errors: `records are not supported in -source 11` (use `-source 16` or higher), `text blocks are not supported in -source 11` (use `-source 15` or higher), `switch expressions are not supported in -source 11` and `switch rules are not supported in -source 11` (both use `-source 14` or higher) (run).
- `Inst11.java` with `o instanceof String s`: `javac --release 11` exit 1: `pattern matching in instanceof is not supported in -source 11` (use `-source 16` or higher) (run). Without `--release`, the same file compiles and `java` prints `x` (run).
- Earlier run on OpenJDK 17.0.19: the record line gave only a warning (`'record' may become a restricted type name`), not an error. The 25.0.5 run gives an error for the record, so the exit code decides, not the warnings.
- Virtual threads and sequenced collections were run on 25.0.5 (see the table). Pattern matching for `switch` and record patterns were not run; verify before use.

## Rules when a feature is newer than the floor

- Do not use a feature newer than the floor in code the floor must run, even if the local JDK compiles it.
- A `--release` check is needed for the build; a local JDK newer than the floor does not prove the floor.
- Record the release of each feature in the plan, with its JEP or API page.

## Notes on specific features

- `var` hides the type. Use it when the right-hand side names the type; write the type when it is a parity check of a numeric or money value.
- Records: the component list defines the record's members (verify before use for the generated `equals`, `hashCode` and `toString`). A source class with hand-written methods needs a test per method before the switch.
- Sealed types: the coverage check can use the `permits` clause, so a `default` label may not be needed (JEP 441). A new subtype added later changes which switches are exhaustive; verify the compiler behavior before use, and treat it as a parity point for the plan.
- Virtual threads: create one per task and do not pool them; limit concurrency with a semaphore (JEP 444). Blocking in `synchronized` pins the carrier thread; use `ReentrantLock` for long I/O under a lock (JEP 444).
