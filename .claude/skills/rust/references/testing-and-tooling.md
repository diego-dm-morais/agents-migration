Read this when writing Rust tests, choosing a fake or golden comparison, or running the Rust quality gate.

# Testing and tooling (Rust 1.99.1 stable)

## Test layout

- Unit tests: a `#[cfg(test)] mod tests` block in the same file as the code, with `use super::*;` and `#[test]` functions. The `cfg(test)` attribute compiles the module only for test builds (Book, chapter 11.3).
- Integration tests: files in `tests/`. Each file is its own crate and calls only the public API of the library (Book, chapter 11.3).
- Doc tests: code blocks in `///` doc comments are compiled and run by `cargo test` for the library target (Cargo, `cargo test`).
- Keep unit tests free of real network, database, file system and clock access. Pass those in as values or traits.

## Commands

- `cargo test`: runs unit, integration and doc tests. Exit 0 on success. Exit 101 when Cargo fails to complete (Cargo, `cargo test`, EXIT STATUS).
- `cargo test <name_filter>`: runs only the tests whose names match the filter (Cargo, `cargo test`, EXAMPLES).
- `cargo test --test <file>`: runs one integration test file. The Cargo page describes running a specific test within a specific integration test. Verify the exact form before use.
- `cargo test --release`: runs the same tests with the release profile, where `overflow-checks` is false (Cargo, profiles). Run it when a result may depend on the build mode.

## Assertions and expected panics

- `assert!(cond)`, `assert_eq!(left, right)` and `assert_ne!(left, right)` (Book, chapter 11.1).
- `#[should_panic]` marks a test that passes only when the code panics (Book, chapter 11.1). The `expected = "..."` argument is not checked here; verify before use.
- `assert_eq!` compares with `==`. For `f64`, `0.1 + 0.2 == 0.3` is false, so compare the formatted text the source produces, or use a tolerance the source defines (see `numerics-and-traits.md`).
- One behavior per test. The test name states the behavior or the rule id, for example `rounds_half_to_even_on_format`.

## Doubles and fakes

- No mocking framework is assumed by this skill. For each external dependency the unit reaches (clock, file, HTTP client, database), define a trait with the methods the unit calls.
- Production code takes the trait through a generic parameter (`fn run<C: Clock>(clock: &C)`) or a trait object (`clock: &dyn Clock`). Both are plain Rust.
- A fixed clock is a struct with a field holding the value it returns. A recording fake is a struct with a `Vec` that stores each call, read back by the test.
- Build fakes inside the test. Do not share a mutable fake across tests.

## Golden and recorded output

- Read the recorded file with `std::fs::read_to_string` (std, `fs`). Parse it into values, then compare with `assert_eq!`.
- Keep the golden file in version control. Regenerate it only from the source's recorded output, never from the new code's output.
- When the source compares text, compare the text the same way the source formats it. Section 6 of `SKILL.md` lists the formats that differ.

## Gate: what passes

| Command | Passes when | Source |
| --- | --- | --- |
| `cargo fmt --check` | exit 0; no file needs changes | rustfmt README |
| `cargo clippy --all-targets -- -D warnings` | exit 0; no warning on any target | Clippy usage |
| `cargo test` | exit 0; every test passes | Cargo, `cargo test` |
| `cargo test --release` | exit 0 with overflow checks off | Cargo, profiles |

- `cargo fmt` runs rustfmt for the crate. The rustfmt README documents `cargo fmt --all -- --check` as the check form. Verify before use that `cargo fmt --check` is accepted by the installed cargo-fmt.
- `--all-targets` covers the library, the binaries, the tests, the examples and the benches. The Clippy page states that `--fix` implies `--all-targets`.
- `-D warnings` is the same as `-Dwarnings`, which turns warnings into errors (Clippy usage).

## Tools and how to choose

- rustfmt: the formatter. Use its check form in the gate. Do not reformat the source's files in a parity commit, because that hides the real diff.
- Clippy: the lint tool. Run it on every target, with warnings as errors, in the gate.
- Doc tests: use them for examples in public functions. They run with `cargo test`.
- Third-party crates for mocking, property testing, snapshots or coverage are not named here. Check the project's dependency policy first, then verify the crate and its official page before use.
- Record each command with its exit code and its decisive output line. A command that did not run is reported as not run.

## Test checklist for a migrated unit

- One test per tie (`0.5`, `1.5`, `2.5`, and the negative values), for each rounding function the source uses.
- One test per boundary: the largest and smallest value of each integer type the source accepts.
- One test per overflow case, run in the debug profile and in the release profile.
- One test per error path, asserting the variant or the code, and the message text when the source message is stable.
- One test per output format: `{}` against `{:?}`, precision, and the empty and zero values.
- One test per ordering rule: equal keys in a stable sort, and map output in sorted order.
