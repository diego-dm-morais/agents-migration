Read this when the source code is Rust and its behavior must be reproduced in another language or in a Rust target.

# As source: where Rust behavior hides

Each item names one trap, a concrete input, the output Rust gives, and the check to run before porting. Facts are from the sources listed in `SKILL.md`, checked on 2026-10-29.

## Build profile

- Overflow depends on the build. `cargo build` (dev) panics on `i32::MAX + 1`. `cargo build --release` wraps it to `i32::MIN` (Book, chapter 3.2; Cargo profiles: `overflow-checks` is true in dev and false in release).
- Check: find the profile the source runs in production (`[profile.release]` in `Cargo.toml`, and the build command). A test must cover the profile that production uses.
- Some checks stay on in every profile. `i32::MIN / -1` panics even with overflow checks off (Reference, operator expressions).

## Numbers

- Integer division truncates toward zero. `-7 / 2` is `-3` and `-7 % 2` is `-1` (Reference, operator expressions). A port from a floor-division source gets `-4` and `1`.
- `as` on floats: `-1.9_f64 as i32` is `-1`, `1e20_f64 as i32` is `2147483647`, and `f64::NAN as i32` is `0` (Reference, casts: truncation, saturation and NaN).
- `as` on integers truncates the high bits. `300_i32 as u8` is `44`, with no error.
- Integer widths do not convert implicitly. Coercions are implicit and highly restricted (Reference, type coercions). A source that widens or narrows silently needs an explicit conversion in the port, and a test at the boundary.
- `f64` is IEEE-754 binary64 (Book, chapter 3.2). `0.1 + 0.2` prints `0.30000000000000004`.
- Ties: `f64::round` goes away from zero, so `(-2.5_f64).round()` is `-3.0`. `round_ties_even` goes to even, so `2.5` gives `2.0` (std, `primitive.f64`).
- Formatting: `{:.N}` rounds exact ties to even, so `{:.0}` of `2.5` is `"2"` and of `0.125` with `{:.2}` is `"0.12"` (Rust source, `coretests/tests/fmt/float.rs`).
- Display and Debug differ. `{}` of `1.0` is `1`; `{:?}` is `1.0` (Rust source, `core/src/fmt/float.rs`).

## Text

- `len()` counts bytes, not characters. In `"Здравствуйте"` each Cyrillic letter is 2 bytes (Book, chapter 8.2).
- `&s[a..b]` panics when `a` or `b` is not on a char boundary. `&s[0..1]` panics with `end byte index 1 is not a char boundary` (Book, chapter 8.2).
- `s.get(a..b)` returns None where indexing would panic (std, `primitive.str`). A source that slices by bytes must be ported with that check in mind.
- `String::from_utf8` returns a Result. Invalid bytes are an error, not a replacement (std, `String`).

## Time

- The std library has no calendar or time-zone types. A source that reads the process time zone needs a named zone from a crate, and the crate must be verified before use.
- Reading the system clock is a side effect. Pass the current time in as a value when the unit is tested (see `testing-and-tooling.md`).

## Absent values and errors

- Rust has no `null`. Absence is `Option<T>` (Book, chapter 6.1). A source `None` and a source empty value are different things.
- `unwrap()` on `None` or `Err` panics (Book, chapter 9.2). A panic unwinds by default (Book, chapter 9.1).
- `?` returns the `Err` early from the function. When the error types differ, `?` calls `From::from` to convert the error (Book, chapter 9.2).
- `main` returning `Err` exits with a nonzero status (Book, chapter 9.2). The message that the runtime prints is part of the output the port must match.

## Collections and order

- `HashMap` iteration order is arbitrary and the hash seed is random (std, `collections::HashMap`). Two runs can print the same keys in different orders.
- `BTreeMap` iterates in sorted key order (std, `collections::BTreeMap`).
- `sort`, `sort_by` and `sort_by_key` keep equal elements in input order. `sort_unstable` and its variants do not define that order (std, `primitive.slice`).
- `sort` needs `Ord`. `f64` is not `Ord`, so `Vec<f64>` cannot call `sort()`. A source that sorts floats needs `total_cmp` or a stated rule for NaN.

## Scope, drop and exit

- Values drop in reverse order of declaration at scope end. `let a = Guard("a"); let b = Guard("b");` drops `b`, then `a` (Book, chapter 15.3; Reference, destructors).
- Struct fields drop in declaration order (Reference, destructors).
- A panic unwinds the stack, and values on it are dropped on the way out (Book, chapter 9.1).
- `std::process::exit` runs no destructors on the current stack or on any other thread's stack (std, `process::exit`). A source that flushes a file in `Drop` loses that flush when it calls `exit`.

## Concurrency

- A `Mutex` that a panicking thread held is poisoned. `lock()` then returns an error. `into_inner` on the error returns the guard (std, `sync::Mutex`, "Poisoning").
- `Rc<T>` is for single-threaded sharing. `Arc<T>` is its thread-safe form (Book, chapter 16.3).
- A channel closes when either its sender or its receiver is dropped, and a send with no receiver returns an error (Book, chapter 16.2). Check how the source handles that error.
- An async task runs only inside a runtime. The standard library provides none, and a runtime is a crate (Async Book). Name the runtime the source uses, and verify its behavior before use.

## Build and dependencies

- `Cargo.lock` pins the versions that were built. A port that resolves new versions can change behavior (Cargo guide, "Cargo.toml vs Cargo.lock").
- `rust-version` states the oldest toolchain the crate supports (Cargo manifest reference). A feature added later is not in that baseline.
- Feature flags change the code that compiles. Read `[features]` and `default` in `Cargo.toml` before you read the code paths.
