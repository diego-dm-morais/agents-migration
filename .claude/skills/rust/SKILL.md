---
name: rust
description: "Rust 1.85 and later (current stable 1.99.1, edition 2024) for Cargo crates, ownership, Result and panics, integer and f64 arithmetic, collections, threads, cargo test, clippy and rustfmt. Use for Rust code, Cargo.toml, or migrations to or from Rust."
metadata:
  baseline: "Rust 1.99.1 stable, edition 2024 (Rust 1.85 or later)"
  verified: "2026-10-29"
---

# rust (Rust 1.85+)

Practice for code written in Rust. The baseline is Rust 1.99.1, the current stable release on 2026-10-29, with edition 2024, which is stable since Rust 1.85.0. Facts here were checked on 2026-10-29 against the Rust release page, The Rust Programming Language book, the std, Cargo and Clippy documentation, the Reference, and the Rust source repository. Sources are listed at the end.

## 1. Scope and versions

- Target the version the crate declares: `rust-version` in `Cargo.toml`. If it declares none, use the current stable toolchain and say so in the report.
- Rust 1.99.1 is the current stable release. The release page lists "Announcing Rust 1.99.1" on Oct. 15, 2026. The std documentation header reads "std 1.99.1 (58cf8f9c3 2026-10-13)".
- New crates use `edition = "2024"`. The Edition Guide gives Rust 1.85.0 as the release version of edition 2024.
- Build on stable only. A `#![feature(...)]` or a nightly-only tool is out of scope unless the plan names it. Verify before use.
- A gate run on one toolchain is evidence for that toolchain only. Record the version the gate ran on.
- Before porting a source, read the Edition Guide for the 2024 changes that touch the source's code.

## 2. Layout and build

- `Cargo.toml` has `[package]` with `name`, `version`, `edition` and `rust-version`, and `[dependencies]` for crates:

```toml
[package]
name = "unit"
version = "0.1.0"
edition = "2024"
rust-version = "1.85"

[dependencies]
```

- Binary code goes in `src/main.rs`; library code in `src/lib.rs`. Integration tests go in `tests/`.
- Commit `Cargo.lock`. It records the exact resolved versions, so a rebuild uses the same dependencies (Cargo guide, "Cargo.toml vs Cargo.lock").
- `cargo build` uses the dev profile, with `overflow-checks = true`. `cargo build --release` uses the release profile, with `overflow-checks = false`. This changes integer results (section 6).
- Put pure logic in modules with no I/O. Keep file, network and environment access in thin adapters at the edge.

## 3. Idioms

- Absent values are `Option<T>`. Rust has no `null` (Book, chapter 6.1).
- Recoverable failures return `Result<T, E>`. Propagate them with `?` (Book, chapter 9.2). Do not use `unwrap()` or `expect()` on a path that input can drive.
- Borrow with `&T` and `&mut T`. At any time a value has either one mutable reference or any number of immutable references (Book, chapter 4.2).
- Prefer iterator chains over index loops when the source is a sequence. Keep the source's order of evaluation.
- Name every variant of an enum that the source handles. Avoid a catch-all arm that hides a case the source reports.
- Keep `unsafe` out unless the plan names it and states the invariant.

```rust
fn first_word(line: &str) -> Option<&str> {
    line.split_whitespace().next()
}

fn parse_count(text: &str) -> Result<u32, std::num::ParseIntError> {
    let n: u32 = text.trim().parse()?;
    Ok(n)
}
```

The first function returns `None` for a blank line, which is the idiom for an absent value. The second returns the parse error for input the source rejects, which is the idiom for a recoverable error. Map the error to the source's error code (section 4).

## 4. Errors, panics and exit

- Recoverable errors: `Result<T, E>`. Define one error enum per unit. Map each source error to one variant, and keep the source message text when the source message is stable.
- Unrecoverable errors: `panic!`, a failed `unwrap()` on `None` or `Err`, an index out of range, and an integer overflow in a debug build. By default a panic unwinds the stack (Book, chapter 9.1).
- `main` returning `Result<(), E>` exits with a value of 0 on `Ok(())` and a nonzero value on `Err` (Book, chapter 9.2). The `Termination` trait uses `EXIT_FAILURE` for failure (std, `process::Termination`). Verify the status value on the target platform before use.
- Pin the source's panic cases with `#[should_panic]` tests, only where the source panics. A port that returns an error where the source panics has changed the contract.
- Values are dropped when they leave scope, in reverse order of declaration (Book, chapter 15.3). A file closes when its value is dropped.
- Library code returns errors. It does not call `std::process::exit`, because that call runs no destructors on the current stack (std, `process::exit`).

## 5. Concurrency

- Threads: `std::thread::spawn`. Channels: `std::sync::mpsc::channel` (Book, chapter 16.2).
- Shared ownership across threads: `Arc<T>`, the thread-safe form of `Rc<T>`. Shared mutable state: `Mutex<T>` (Book, chapter 16.3).
- The marker traits `Send` and `Sync` decide what can cross threads. The compiler checks them (Book, chapter 16.4).
- A thread that panics while it holds a `Mutex` poisons it. Later `lock()` calls return an error. `PoisonError::into_inner` returns the guard anyway (std, `sync::Mutex`, "Poisoning").
- The standard library has no async runtime. A runtime is a crate (Async Book). Verify the runtime before use.

## 6. Data and numbers (parity traps)

- Integers have a fixed width. A debug build panics on overflow. A release build wraps (Book, chapter 3.2; Cargo profiles). State the result the source has with `checked_*`, `wrapping_*`, `saturating_*` or `overflowing_*`.
- Integer `/` and `%` truncate toward zero: `-7 / 2` is `-3`, and `-7 % 2` is `-1` (Reference, operator expressions). `i32::MIN / -1` panics in every profile.
- `as` truncates integers and rounds floats toward zero. A float outside the range saturates, and NaN becomes 0 (Reference, casts). Use `From` for lossless conversions and `TryFrom` for fallible ones (std, `convert`).
- `f64` is an IEEE-754 double (Book, chapter 3.2). `0.1 + 0.2` is not `0.3`.
- `f64::round` rounds ties away from zero. `f64::round_ties_even` rounds ties to even, since 1.77.0 (std, `primitive.f64`). `{:.N}` formatting rounds exact ties to even (Rust source, `library/coretests/tests/fmt/float.rs`). Test a tie in each direction.
- `{}` prints the shortest decimal that round-trips, so `1.0` prints `1`. `{:?}` prints `1.0`, and may use an exponent (`1e16`). Source: `library/core/src/fmt/float.rs`.
- `String` holds UTF-8. `len()` counts bytes. Slicing with `&s[a..b]` panics when `a` or `b` is not on a char boundary (Book, chapter 8.2).
- `HashMap` iteration order is arbitrary, and its hash seed is random (std, `collections::HashMap`). Use `BTreeMap`, which iterates in sorted key order, or sort the keys when the output order matters.
- `sort`, `sort_by` and `sort_by_key` are stable. The `sort_unstable` family may reorder equal elements (std, `primitive.slice`).
- The std library has no calendar or time-zone types. Name the crate and verify it before use.
- Parsing: `str::parse` returns a Result. The accepted syntax belongs to the `FromStr` impl of each type. Verify the syntax for the type before use, and test the inputs the source accepts and rejects.

## 7. Testing

- Runner: the built-in test harness. `cargo test` runs unit tests, integration tests and doc tests (Cargo, `cargo test`).
- Unit tests sit in a `#[cfg(test)] mod tests` in the same file (Book, chapter 11.3). Integration tests sit in `tests/` and call only the public API (Book, chapter 11.3).
- Assertions: `assert!`, `assert_eq!` and `assert_ne!`. A test that must panic has `#[should_panic]` (Book, chapter 11.1).
- Doubles: define a trait for each external dependency, and write a hand-written fake that implements it. Pass the fake through a generic parameter or a trait object.
- Fixtures: keep recorded inputs and outputs in a folder under `tests/`, and read them in the test.
- Golden tests: read the recorded output with `std::fs::read_to_string`, and compare parsed values with `assert_eq!`. Never regenerate the golden file from the new code.
- Run a subset with `cargo test <filter>`. The filter matches test names, so a module path in the name selects the tests of that module (Cargo, `cargo test`, EXAMPLES).
- Details and the gate table: `references/testing-and-tooling.md`.

## 8. Quality gate

Run each command, read its real output, and report it. A command that did not run is not a pass.

1. `rustc --version` and `cargo --version`: stable 1.85 or later, and matching `rust-version`.
2. `cargo fmt --check`: exit 0 when no file needs changes. The rustfmt README documents `cargo fmt --all -- --check`. Verify before use that `cargo fmt --check` is accepted by the installed cargo-fmt.
3. `cargo clippy --all-targets -- -D warnings`: lints every target. `-D warnings` turns each warning into an error (Clippy usage). Exit 0 is a pass.
4. `cargo test`: exit 0 is a pass. Cargo exits with 0 on success and 101 when it fails to complete (Cargo, `cargo test`, EXIT STATUS).
5. When behavior depends on the build mode, also run `cargo test --release`, which turns off overflow checks (Cargo profiles).

Record each command with its exit code and the output line that decides the result. If the toolchain is not installed, write `none installed` and report no result for these commands.

## 9. Migrating TO Rust

- Parity beats idiom. Choose an idiom only when inputs, outputs and errors stay the same. Otherwise keep the source behavior, and mark the difference `deviation` with its reason and source.
- Map each source construct with `references/as-target.md`. It covers integers, rounding, text, dates, errors, I/O, collections, absent values and exit.
- Keep the source's numeric semantics (section 6). Before writing the code, write a test for each tie, each boundary, each overflow and each error path.
- Keep one error variant per source error. Keep the same message text when the source message is stable.
- Keep the source's public names only when an external caller depends on them.
- Order of work: write the tests for the source behavior first, run them against the port, then run the gate in section 8. A test whose expected value was copied from the port's output is not a parity test.

## 10. Migrating FROM Rust

- Read `references/as-source.md`. It lists where Rust behavior hides: the build profile, implicit conversions, rounding, sort stability, map order, text encoding and byte-index slicing, drop order, time zones, panics and exit status.
- For ownership and errors, read `references/ownership-and-errors.md`. For numbers and traits, read `references/numerics-and-traits.md`.
- Find the profile and the toolchain the source ships with, and record them in the report. The profile decides overflow behavior (section 6). The toolchain decides which language and library behavior applies.

## 11. Anti-patterns

- `unwrap()` or `expect()` on a path that input drives.
- An `as` cast on a value that can leave the target range, with no note on the result.
- `f64` for money.
- Output that depends on `HashMap` iteration order.
- `sort_unstable` where the order of equal elements is visible.
- Slicing a `String` by a byte index that comes from input.
- A library function that calls `std::process::exit`.
- `let _ =` on a `Result` that carries a failure the source reports.
- Regenerating a golden file from the port's output and calling the test passed.

## Library registry

- Registry: crates.io, https://crates.io/ (crate pages show versions, `rust-version` (MSRV), features, license, and the last publish date).
- Before adding a crate, check the standard library first. Then search crates.io, open the crate page, and confirm: latest version, `rust-version` not above the target toolchain, enabled features, license, last publish, and open issues.
- Pin the version in `Cargo.toml` and commit `Cargo.lock` (section 2). Check the MSRV with `cargo msrv` only if the repository already uses it.
- Full procedure and evaluation checks: `.claude/skills/migration-conduct/references/library-research.md`.

## Sources

- crates.io: https://crates.io/
- Rust release announcements: https://blog.rust-lang.org/releases/
- The Rust Programming Language (book): https://doc.rust-lang.org/book/
- Standard library: https://doc.rust-lang.org/std/ (`primitive.f64`, `primitive.i32`, `primitive.slice`, `primitive.str`, `collections::HashMap`, `sync::Mutex`, `convert::From`, `convert::TryFrom`, `process::exit`, `process::Termination`, `fs`)
- Reference: https://doc.rust-lang.org/reference/ (operator expressions, destructors, type coercions)
- Cargo: https://doc.rust-lang.org/cargo/ (profiles, manifest, `Cargo.toml` vs `Cargo.lock`, `cargo test`)
- Clippy: https://doc.rust-lang.org/clippy/usage.html
- Edition Guide, 2024: https://doc.rust-lang.org/edition-guide/rust-2024/index.html
- rustfmt: https://github.com/rust-lang/rustfmt
- Async Book: https://rust-lang.github.io/async-book/
- Rust source, master, checked 2026-10-29: https://github.com/rust-lang/rust (`library/core/src/fmt/float.rs`, `library/coretests/tests/fmt/float.rs`)
