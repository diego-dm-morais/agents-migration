Read this when a source construct must be written in Rust, to choose the idiom and the parity test that goes with it.

# As target: Rust (1.99.1 stable)

Parity rule: an idiom is used only when inputs, outputs and errors stay the same. Otherwise keep the source behavior and mark the difference `deviation`, with its reason and source.

| Concept | Idiom in this language | Parity risk to test |
| --- | --- | --- |
| Signed and unsigned integers | `i32`, `u8`, `i64` and the other fixed-width types | Overflow panics in a debug build and wraps in a release build |
| Overflow with a defined result | `checked_add` (None), `wrapping_add`, `saturating_add`, `overflowing_add` | Pick the one that matches the source |
| Integer division and remainder | `/` and `%` truncate toward zero | Negative operands differ from floor division |
| Lossless width change | `i64::from(x)`, `u16::from(b)` | An implicit change does not compile; a silent one is a parity bug |
| Checked width change | `u8::try_from(n)` returns a Result | An out-of-range input must map to the source's error |
| Narrowing integer cast | `as` truncates the high bits | `300_i32 as u8` is 44, with no error |
| Float to integer | `as` truncates toward zero, saturates, and maps NaN to 0 | Out-of-range and NaN inputs |
| Money | integer minor units in `i64` with checked arithmetic | Binary float error, for example `0.1 + 0.2` |
| Rounding, ties away from zero | `f64::round` | Tie direction of the source |
| Rounding, ties to even | `f64::round_ties_even` (since 1.77.0) | Tie direction of the source |
| Fixed decimals in text | `format!("{:.2}", x)`, ties to even on the exact value | The source's rounding mode |
| Float as text | `format!("{}", x)` prints the shortest round-trip form | `1` and `1.0` differ in output |
| Debug text of a float | `format!("{:?}", x)` keeps `.0` and may use an exponent | `1e16` in debug output |
| Text length | `s.len()` counts bytes; `s.chars().count()` counts scalar values | Byte count versus character count |
| Text slice by position | `s.get(a..b)` returns None instead of panicking | A panic in the source is an error here |
| Bytes to text | `String::from_utf8(bytes)` returns a Result | Invalid bytes must map to the source's error |
| File and stream I/O | `std::fs::read_to_string` returns a Result; `std::io::Read` and `std::io::Write` traits | A missing file, a failed read, and invalid UTF-8 each map to the source's error |
| Absent value | `Option<T>`, `Some` and `None` | An empty string or 0 is present, not absent |
| Recoverable error | `Result<T, E>` with `?` | Error mapping; panic versus Err |
| Ordered map | `BTreeMap<K, V>`, iterated in key order | `HashMap` order is arbitrary |
| Hash map | `HashMap<K, V>` with keys that are `Eq + Hash` | Iteration order; `f64` cannot be a key |
| Stable sort | `sort`, `sort_by`, `sort_by_key` | Equal elements keep their input order |
| Unstable sort | `sort_unstable` and its variants | Order of equal elements is not defined |
| Float sort | `sort_by` with `total_cmp` | `sort()` needs `Ord`, and `f64` is not `Ord` |
| Cleanup at scope end | the `Drop` trait, in reverse declaration order | Order of side effects |
| Shared state across threads | `Arc<Mutex<T>>` | A panic while locked poisons the mutex |
| Message passing | `std::sync::mpsc::channel` | Order of messages and disconnect errors |
| Calendar dates and time zones | a crate chosen and verified before use | Time zone and leap-year rules |
| Process exit status | `main` returns `Result<(), E>` | Nonzero status, and the error text on stderr |

## Traps with examples

### Integer overflow

- Source: `let x: u8 = 255; let y = x + 1;`
- Debug build: panics at runtime, because overflow checks are on.
- Release build: `y` is `0`, because overflow wraps (Book, chapter 3.2, says 256 becomes 0 for `u8`).
- Port: find the build the source ran. Use `x.wrapping_add(1)` for `0` in both builds, or `x.checked_add(1)` for `None`. Write a test for each build.

### f64 Display

- `println!("{}", 1.0_f64)` prints `1`. `println!("{:?}", 1.0_f64)` prints `1.0`.
- `println!("{}", 1e16_f64)` prints `10000000000000000`. `println!("{:?}", 1e16_f64)` prints `1e16`.
- `format!("{:.1}", 0.25_f64)` is `"0.2"`, and `format!("{:.0}", 2.5_f64)` is `"2"`. Exact ties go to even (Rust source test `test_format_f64_rounds_ties_to_even`).
- `2.5_f64.round()` is `3.0`. `2.5_f64.round_ties_even()` is `2.0`.

### sort_unstable

- Input by key: `[(1, 'a'), (0, 'b'), (1, 'c'), (0, 'd')]`.
- `sort_by_key(|p| p.0)` is stable and gives `[(0, 'b'), (0, 'd'), (1, 'a'), (1, 'c')]`.
- `sort_unstable_by_key(|p| p.0)` may reorder equal keys, and the order is not defined. Do not write a test that pins it.

### String slicing

- Source: `let s = "Здравствуйте";` Then `&s[0..4]` is `"Зд"`.
- `&s[0..1]` panics with `end byte index 1 is not a char boundary; it is inside 'З' (bytes 0..2 of string)` (Book, chapter 8.2).
- Port: check `s.is_char_boundary(i)` first, or use `s.get(a..b)`, which returns None.

### HashMap order

- Insert `"a"`, `"b"` and `"c"`, then iterate. The order is arbitrary, and the hash seed is random (std, `HashMap`).
- Port: when output order matters, use `BTreeMap`, or collect the keys and sort them.

### Option instead of null

- A source `null` that means "no value" becomes `None`. A source `""` or `0` becomes `Some("")` or `Some(0)`.
- Rust has no `null` (Book, chapter 6.1). An `Option` must be matched, or unwrapped with a stated default.

### Drop order

- With `let a = Guard("a"); let b = Guard("b");` at the end of a scope, `Guard`'s `Drop` runs for `b`, then for `a` (Book, chapter 15.3).
- A struct with fields `first` and `second` drops `first`, then `second`, which is the declaration order (Reference, destructors).
