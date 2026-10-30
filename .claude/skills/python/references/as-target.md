Read this when you map a source construct to Python code. The left column is the concept; the middle column is the Python idiom; the right column is the risk to test. Facts marked "run" were checked on CPython 3.14.6 on 2026-10-29; the others are in SKILL.md Sources.

| Concept | Python idiom | Parity risk to test |
|---|---|---|
| Module or package boundary | one module per unit; import the names a caller needs | a name the source exports that the target does not |
| Optional value | an optional type (`Optional[X]` or `X \| None`); `None` for absent | a field the source emits as null, and the target omits it, or the reverse |
| Integer arithmetic | `int`, which has unlimited precision | a source with a fixed width wraps or fails there; state the width and test the edge |
| Fixed-width integer | `int` with a range check in one function | the source's width, its overflow rule and its error |
| Decimal money | `decimal.Decimal` with `localcontext()` and the source's rounding mode | precision 28 by default; the default traps raise; the output scale (`quantize`) |
| Half-even rounding | `value.quantize(exp, rounding=ROUND_HALF_EVEN)` | `round()` on a float uses the binary value: `round(2.675, 2)` is `2.67` (run) |
| Half-up rounding (ties away from zero) | `value.quantize(exp, rounding=ROUND_HALF_UP)` | `round()` is half-even; `-2.5` becomes `-3` with ROUND_HALF_UP (run) |
| Floor division and modulo | `//` and `%` | `-7 // 2` is `-4` and `-7 % 2` is `1` (run); a truncating source gives other values |
| Truncation to integer | `int(x)` | `int(-2.7)` is `-2` (run); `math.floor(-2.7)` is `-3` (run) |
| Division of integers | `/` gives a float; `//` gives an int | `7 / 2` is `3.5` (run); using `/` where the source divides integers |
| Text | `str`, a sequence of code points | `len` counts code points, not bytes or UTF-16 units (run: `len` of an emoji is 1) |
| Bytes and encoding | `bytes`; `.encode(enc)` and `.decode(enc)` with an explicit `enc` | `UnicodeDecodeError` on invalid input (run); the default encoding of `open()` |
| Instant in time | aware `datetime` with `timezone.utc` | naive and aware values are never equal and ordering raises `TypeError` (run) |
| Current time | `datetime.now(timezone.utc)` | `datetime.now()` returns a naive local time (run) |
| Local time zone | `zoneinfo.ZoneInfo(key)` | `ZoneInfoNotFoundError` when no tz database or `tzdata` is available (run on Windows) |
| Map or dictionary | `dict`, insertion order since 3.7 | key order in output; `1` and `True` are one key (run) |
| Mutation while iterating | iterate over a copy, such as `list(d)` | a dict changed while iterated raises `RuntimeError` (run) |
| Exception | a class derived from `Exception` with a stable name | `except Exception` does not catch `SystemExit` or `KeyboardInterrupt` (run) |
| Exception chain | `raise New(...) from cause` | `__cause__` is set; a source that drops the cause loses it |
| Process exit | `sys.exit(int)` in the entry point only | `sys.exit("text")` prints the text and exits 1 (run) |
| Concurrent fan-out | `asyncio.gather(...)` | the default propagates the first exception and does not cancel the rest; `return_exceptions=True` changes the result |
| Wait inside async code | `await asyncio.sleep(s)` | `time.sleep` suspends the calling thread |
| Retry | a loop with an injected sleep and a fixed attempt count | the number of attempts; retry only on the source's error classes |
| Configuration | environment read in one module, with validation at start | `os.environ` values are `str`; `bool("false")` is `True` (run) |
| JSON output | `json.dumps` after an explicit conversion of `Decimal` | `TypeError` for `Decimal` without a conversion (run) |
| Mutable default | `None` default and a new object in the body | a list shared across calls (run) |
| Decimal context | `localcontext()` around the computation | a changed global context leaks to other tasks (run) |
| Logging | the `logging` module, one named logger per unit | a log line the source emits and the target drops |

## Project shape for a migrated unit

- `src/<unit>.py`: pure logic, no I/O.
- `src/<unit>_adapter.py` (only if the unit does I/O): the thin layer that calls files, the network or the environment and passes the values in.
- `tests/test_<unit>.py`: one test per rule id, then the golden tests from `tests/golden/<unit>/`.
- Run the gate of SKILL.md section 8 on the whole tree.
