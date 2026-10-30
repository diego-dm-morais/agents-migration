Read this when a migrated unit computes money, rates, rounding or exact decimals, or when the source uses float or int arithmetic. "Run" marks a result checked on CPython 3.14.6 on 2026-10-29.

## Default context

- Each thread has its own current context, read with `getcontext()` (decimal docs).
- The defaults (decimal docs): precision 28; rounding `ROUND_HALF_EVEN`; traps enabled for `Overflow`, `InvalidOperation` and `DivisionByZero`.
- Run here: `prec 28`, `rounding ROUND_HALF_EVEN`, traps `['DivisionByZero', 'InvalidOperation', 'Overflow']`.
- A trap raises an exception instead of returning a value. `Decimal(1) / Decimal(0)` raises `decimal.DivisionByZero`; `Decimal("abc")` raises `decimal.InvalidOperation`; `Decimal(0) / Decimal(0)` raises `decimal.InvalidOperation` (run).
- `Inexact`, `Rounded` and `Subnormal` are not trapped by default (decimal docs).

## Context scope

- Use `localcontext()` for a block with its own settings. It sets a copy of the context for the `with` block and restores the previous one on exit (decimal docs).

```python
from decimal import ROUND_HALF_EVEN, Decimal, localcontext

with localcontext() as ctx:
    ctx.prec = 12
    ctx.rounding = ROUND_HALF_EVEN
    value = Decimal(1) / Decimal(3)
```

- A global `getcontext().prec = n` changes every later call in the thread. Run here: in a `localcontext()` block with `prec = 5`, `Decimal(1) / Decimal(3)` gave `0.33333`; with the default it gave `0.3333333333333333333333333333` (28 digits).
- A new thread starts with the default context: inside `localcontext()` with `prec = 5` in the main thread, a new thread read `prec 28` (run).
- Inside asyncio the `Context` object is shared by reference between a task and its copy. A change to `prec` made inside a task reached the parent (run: parent went from 28 to 7). Use `localcontext()` inside each task that needs its own precision (run: two tasks with precisions 5 and 12 kept their own results, and the parent kept 28). See `typing-and-async.md`.

## Constructing values

- `Decimal(3.14)` converts the binary float exactly: `Decimal('3.140000000000000124344978758017532527446746826171875')` (decimal docs; run). Use `Decimal(str)` for a source value written as text.
- `Decimal("3.14")` keeps the digits as written (run: `3.14`).
- `Decimal("1.10") == Decimal("1.1")` is `True`, but `str(Decimal("1.10"))` is `1.10` (run). The scale is kept; a migrated output that prints money must match the source's scale.
- `str(Decimal("1E+2"))` is `1E+2` (run). Exponent notation appears in output when the source's value was built that way.
- The context precision does not limit the digits stored by a constructor: "The context precision does not affect how many digits are stored" (decimal docs).

## Rounding modes

Quoted from the decimal docs, rounding options:

- `ROUND_HALF_UP`: round to nearest with ties going away from zero.
- `ROUND_HALF_DOWN`: round to nearest with ties going towards zero.
- `ROUND_HALF_EVEN`: round to nearest with ties going to the nearest even integer. This is the default context rounding.
- `ROUND_DOWN`: round towards zero.

Run here with `Decimal(v).quantize(Decimal("1"), rounding=mode)`:

| Input | ROUND_HALF_EVEN | ROUND_HALF_UP | ROUND_HALF_DOWN | ROUND_DOWN |
|---|---|---|---|---|
| 2.5 | 2 | 3 | 2 | 2 |
| 3.5 | 4 | 4 | 3 | 3 |
| -2.5 | -2 | -3 | -2 | -2 |
| 2.9 | 3 | 3 | 3 | 2 |

- `quantize(exp, rounding=None, context=None)` returns a value with the exponent of `exp`; the result's exponent is always that of the right-hand operand (decimal docs). `Decimal("2.5").quantize(Decimal("1"))` is `2` (run); `Decimal("0.125").quantize(Decimal("0.01"))` is `0.12`, and `Decimal("0.135").quantize(Decimal("0.01"))` is `0.14` (run).
- A tie is decided on the exact decimal value. Test both tie directions for each rounding the source performs.

## Float rounding versus decimal rounding

- `round(x, n)` on a float rounds the binary value (functions docs): `round(2.675, 2)` is `2.67` (run).
- `Decimal("2.675").quantize(Decimal("0.01"), rounding=ROUND_HALF_EVEN)` is `2.68` (run).
- `Decimal(2.675).quantize(Decimal("0.01"), rounding=ROUND_HALF_EVEN)` is `2.67` (run), because the float is `2.67499999...` in binary.
- A source that rounds a decimal string and a source that rounds a float give different results on the same visible number. Find the input type first.

## Integers and floats

- `int` has unlimited precision (stdtypes docs). The source's fixed width is a parity fact: state it and test the overflow edge.
- `float` is binary (tutorial). `repr` shows the shortest string that reads back to the same float (tutorial): `repr(0.1 + 0.2)` is `'0.30000000000000004'` (run).
- `float(2**53 + 1) == 2**53` is `True` (run).
- `/` gives a float for ints (expressions docs): `7 / 2` is `3.5` (run). `10 ** -2` is `0.01` (expressions docs).
- `//` floors and `%` takes the sign of the divisor (expressions docs): `-7 // 2` is `-4`, `-7 % 2` is `1` (run). `int(-2.7)` is `-2`; `math.floor(-2.7)` is `-3` (run).
- `float('nan') != float('nan')` is `True` (run).
- The tutorial example `0.1 + 0.1 + 0.1 == 0.3` is `False` (run).

## Money

- Store money as `Decimal` with an explicit scale, or as an `int` count of minor units, with the scale in one named constant. Never `float`.
- Convert at the boundary: parse input text to `Decimal` once; round only at the output step the source uses; format the output with the source's scale.
- Test every tie, every boundary and every error path before the code (the Decimal `InvalidOperation` and `DivisionByZero` traps raise).
