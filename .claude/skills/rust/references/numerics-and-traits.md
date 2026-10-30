Read this when a migrated unit does integer or float arithmetic, numeric conversion, rounding, number formatting or numeric sort keys, or when it uses traits and generics for behavior.

# Numerics and traits (Rust 1.99.1 stable)

## Integer types

- Signed types are `i8` to `i128` and `isize`. Unsigned types are `u8` to `u128` and `usize`. `isize` and `usize` depend on the target architecture (Book, chapter 3.2).
- A source integer with no stated width needs an explicit width from the source's contract. Test its boundaries: the largest and smallest value of that width.
- Overflow panics in a debug build and wraps in a release build (Book, chapter 3.2; Cargo profiles).
- The explicit families state the result in code: `checked_*` returns `Option`, `wrapping_*` wraps, `saturating_*` clamps, and `overflowing_*` returns the value with a flag (Book, chapter 3.2; std, `primitive.i32`).
- The Book calls relying on the wrapping behavior an error (Book, chapter 3.2). A port must not depend on it by accident.

## Division, remainder and sign

- `/` and `%` on integers truncate toward zero. The remainder takes the sign of the dividend (Reference, operator expressions).
- `i32::MIN / -1` panics, and the same holds for `%`, even when overflow checks are off (Reference, operator expressions). Division by zero panics for integers (Reference, operator expressions).
- `checked_div` returns `None` for a zero divisor or an overflowing division, and does not panic (std, `primitive.i32`).
- A port from a floor-division source must use an explicit floor function on the float, or explicit sign handling on the integer. Test a negative dividend.

## Conversions

- `From` is for conversions that cannot fail and lose nothing. `TryFrom` is for conversions that can fail (std, `convert::From`: "The conversion is infallible: if the conversion can fail, use TryFrom").
- `as` between integer widths truncates the high bits (Reference, casts). `u8::try_from(300_i32)` returns an error instead.
- Coercions are implicit and highly restricted (Reference, type coercions). A value of one integer type where another is expected is a compile error. Convert it explicitly.
- A source that narrows or widens silently must get a boundary test. Decide whether the port returns the source's error or the source's wrapped value.

## Floats

- `f64` is an IEEE-754 binary64 double (Book, chapter 3.2; std, `primitive.f64`).
- `total_cmp` orders `f64` by the IEEE-754 totalOrder predicate, which gives a total order where `partial_cmp` does not (std, `primitive.f64`). Sort floats with it, and state how the source orders NaN.
- Rounding functions: `round` goes half away from zero and gives the precise result. `round_ties_even` goes to even, from 1.77.0 (std, `primitive.f64`). `floor`, `ceil` and `trunc` are also on `f64`.
- `0.1 + 0.2` is `0.30000000000000004` in `{}` output. Compare the formatted text, or a tolerance the source defines.

## Formatting numbers

- `{}` (Display) prints the shortest decimal that round-trips, with no exponent. `1.0` prints `1` (Rust source, `library/core/src/fmt/float.rs`).
- `{:?}` (Debug) prints at least one digit after the point, and uses an exponent for large and small magnitudes. `-3.0` prints `-3.0`, `1e16` prints `1e16`, and `0.0001` prints `0.0001` (Rust source, `library/coretests/tests/fmt/float.rs`).
- `{:.N}` prints N digits after the point. Exact ties go to even: `{:.0}` of `0.5` is `0`, of `1.5` is `2`, of `2.5` is `2`, and of `3.5` is `4` (Rust source, `coretests/tests/fmt/float.rs`).
- `{:e}` and `{:E}` print the exponent form, for example `1.23456789e6` (Rust source, `coretests/tests/fmt/float.rs`).
- The format grammar is `[[fill]align][sign]['#']['0'][width]['.' precision][type]` (std, `fmt`, grammar block).

## Traits and generics

- A trait is a set of method signatures that a type implements. A bound states what a generic parameter must support (Book, chapter 10.2, "Trait Bound Syntax").
- `slice::sort` requires `T: Ord`. `f64` is not `Ord`, so `Vec<f64>` cannot use `sort()` (std, `primitive.slice`).
- A `HashMap` key must satisfy `Eq + Hash` (std, `collections::HashMap`). `f64` does not implement `Eq`, so it cannot be a key. Verify with the compiler before use.
- Static dispatch uses a generic parameter. Dynamic dispatch uses `&dyn Trait`. Pick the one the source's design implies, and keep the set of implementations the source has.
- A source that uses inheritance or duck typing maps each method to a trait method. Test each implementation against the source's output.

## Parity tests for numbers

- Ties: for each rounding function the source uses, test `0.5`, `1.5`, `2.5` and the negative values of each.
- Boundaries: the largest and smallest value of each integer width, `i32::MIN / -1`, and a negative dividend in each division.
- Conversions: one value inside the range, one at the edge, and one outside, for each `as` cast and each `TryFrom`.
- Formatting: the same value through `{}`, `{:?}` and each precision the source prints, including `0.0` and `-0.0`.
- Floats in sorts: equal keys, and NaN if the source can produce it.
