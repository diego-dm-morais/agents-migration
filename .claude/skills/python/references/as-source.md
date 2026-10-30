Read this when the source you migrate from is Python. These are the places where the behavior is easy to miss, because it is in the runtime or the standard library, not in the code you read. "Run" marks a result checked on CPython 3.14.6 on 2026-10-29.

## Numbers

- `bool` is an `int` (functions docs). `True + True` is `2` (run). `{1: "a", True: "b"}` is `{1: "b"}` (run): one key. Count flags as `int` exactly as the source does.
- `round(x)` on a float rounds ties to the even choice on the binary value: `round(2.5)` is `2`, `round(0.5)` is `0`, `round(2.675, 2)` is `2.67` (functions docs; run).
- Floats are binary: `0.1 + 0.1 + 0.1 == 0.3` is `False` (tutorial; run). A source that sums money as floats keeps the drift; the target must reproduce it or the source must be shown to use exact values.
- `//` floors and `%` takes the sign of the divisor: `-7 // 2` is `-4`, `-7 % 2` is `1` (expressions docs; run). Find each `//` and `%` on a negative operand. A source that truncates gives other values; verify its semantics before use.
- `int(x)` truncates toward zero: `int(-2.7)` is `-2` (run). `math.floor(-2.7)` is `-3` (run).
- `/` on ints gives a float: `7 / 2` is `3.5` (expressions docs; run). A source that divides integers and keeps an int must use `//` in the target.
- `float(2**53 + 1) == 2**53` is `True` (run): a large integer loses digits when it passes through a float.
- `1 // 0` raises `ZeroDivisionError` (run). `decimal.DivisionByZero` is a `ZeroDivisionError` subclass (run).
- `Decimal` rounding modes differ on ties: for `2.5`, ROUND_HALF_EVEN gives `2`, ROUND_HALF_UP gives `3`, ROUND_HALF_DOWN gives `2`, ROUND_DOWN gives `2` (run; mode meanings in the decimal docs).

## Text and bytes

- `str` is a sequence of Unicode code points (stdtypes docs). `len("é")` is `1` (run); its UTF-8 encoding is 2 bytes (run). A source that counts UTF-16 units gets other numbers for emoji: `len("\U0001F600")` is `1` here (run).
- `"a" + b"b"` raises `TypeError: can only concatenate str (not "bytes") to str` (run).
- `b"abc" == "abc"` is `False` (run). Under `-b` the same comparison issues a `BytesWarning` (command-line docs; run).
- `b"\xff".decode("utf-8")` raises `UnicodeDecodeError` (run). `"é".encode("ascii")` raises `UnicodeEncodeError` (run).
- `open()` without `encoding=` uses UTF-8 from 3.15 (open docs, PEP 686). Before 3.15 it uses the locale encoding; on the machine checked it was `cp1252` (run: `locale.getpreferredencoding(False)`). A source read on one machine can differ on another.

## Dates and time

- A naive `datetime` and an aware one are never equal: `naive == aware` is `False` (datetime docs; run). Ordering them raises `TypeError: can't compare offset-naive and offset-aware datetimes` (run).
- `datetime.now()` returns the local wall-clock time with no zone; `datetime.now(timezone.utc)` returns UTC with a zone (datetime docs; run). Find each `now()` call and check which one the source uses.
- `zoneinfo` needs the system time zone database or the `tzdata` package; Windows needs `tzdata` (zoneinfo docs). On the machine checked, `ZoneInfo("America/Sao_Paulo")` raised `ZoneInfoNotFoundError` (run).
- `ZoneInfoNotFoundError` is a `KeyError` (zoneinfo docs; run). A source that catches `KeyError` for a bad zone catches it too.

## Collections and mutation

- `dict` keeps insertion order, guaranteed since 3.7 (stdtypes docs; run). In 3.6 it was a CPython detail.
- Adding keys while iterating a dict raises `RuntimeError: dictionary changed size during iteration` (run).
- A mutable default argument is created once, at definition (compound statements docs). `def g(item, acc=[])` returns the same list on every call (run). Find each `=[]`, `={}` and `=set()` default in the source.

## Errors and exit

- `except Exception` does not catch `SystemExit` or `KeyboardInterrupt` (exceptions docs; run: `issubclass(SystemExit, Exception)` is `False`). A bare `except:` catches them. Check which one the source uses.
- `raise "text"` is not a Python exception: it raises `TypeError: exceptions must derive from BaseException` (raise docs; run).
- `sys.exit("text")` prints `text` to stderr and exits with status 1 (sys docs; run). `sys.exit(None)` exits 0 (sys docs).
- `assert` emits no code under `-O` (simple statements docs; run: the assert was skipped). A source that uses `assert` as a check has different behavior under `-O`.
- `raise New(...) from cause` stores the cause in `__cause__` (raise docs; run). Check whether the source wraps errors and which message it returns.

## Async and context

- `asyncio.gather()` with the default `return_exceptions=False` propagates the first exception and does not cancel the other awaitables; they keep running (asyncio-task docs). Note which calls have side effects.
- `return_exceptions=True` returns the exception objects as results (run: `['a', 'ValueError']`).
- The event loop keeps only weak references to tasks (asyncio-task docs). A task that nothing references can be collected before it finishes.
- `time.sleep()` suspends the calling thread (time docs). Inside a coroutine it stops the other coroutines on that thread.
- A decimal context is per thread (decimal docs). A new thread starts with the default context: precision 28 (run). Inside asyncio, a task copies the context, but the `Context` object is shared, so `getcontext().prec = 7` in a task changed the parent's precision from 28 to 7 (run). Check where the source sets the context.

## Configuration and environment

- `os.environ` values are always `str` (run). `bool("false")` is `True` (run). Find each comparison on an environment value and check how the source parses it.
- A missing key with a default in code is a behavior: list the default.

## Serialization

- `json.dumps` raises `TypeError: Object of type Decimal is not JSON serializable` (run). A source that writes money must say how it converts `Decimal`.
- A source's output field present with `null` and a field omitted are different outputs. Check each field's type before the target serializes it.
