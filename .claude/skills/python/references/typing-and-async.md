Read this when you add type annotations, choose an optional or union type, use generics, or write asyncio code in a migration.

## Annotations at run time

- The interpreter does not enforce function and variable annotations; type checkers, IDEs and linters use them (typing docs). Run here: `def f(x: int) -> int` returned `"a"` for `f("a")` with no error.
- Annotations are stored on the function: `f.__annotations__` is `{'x': <class 'int'>, 'return': <class 'int'>}` (run).
- `Optional[X]` is equivalent to `X | None` (typing docs). `X | None` is valid from 3.10 (typing docs). Run here: `Optional[int] == (int | None)` is `True`.
- An optional argument and an optional value are different: `Optional[X]` says the value may be `None`, not that the argument may be left out (typing docs).
- `typing.Final`, `ReadOnly` and `NewType` carry no runtime check; only a static checker enforces them (typing docs).

## Type checking

- mypy checks annotated function bodies. Unannotated bodies are not checked by default (mypy getting started). `--check-untyped-defs` checks every body (mypy command line).
- A migrated function gets the same name and the same parameter order as the source. Annotate the public functions first; the checker then finds the call sites that break.
- Run the checker on the whole package in the gate (SKILL.md section 8).

## Generic syntax (3.12 and later)

- PEP 695 type parameters: `def first[T](items: list[T]) -> T:` (What's New in 3.12). Run here: `first([3, 4])` returned `3`.
- The `type` statement declares an alias: `type Point = tuple[float, float]` (What's New in 3.12). Run here: `Point.__value__` is `tuple[float, float]`.
- The 3.12 floor allows this syntax. A repository that supports an older version must use the older spelling; check its declared minimum first.

## Mutable defaults and None

- A default value is evaluated once, at the `def` statement (compound statements docs). A mutable default is shared by every call.
- Use `None` and create the object in the body:

```python
def collect(item, acc=None):
    if acc is None:
        acc = []
    acc.append(item)
    return acc
```

Run here: `collect(1)` returned `[1]` and `collect(2)` returned `[2]`.

## asyncio entry and tasks

- `asyncio.run()` is the top-level entry point (asyncio docs). Call it once per process, from synchronous code.
- `asyncio.gather(*aws)` with the default `return_exceptions=False`: the first exception propagates to the task that awaits `gather()`; the other awaitables are not cancelled and keep running (asyncio-task docs).
- `asyncio.gather(*aws, return_exceptions=True)`: exceptions are returned as results. Run here with one failing coroutine: the results were `['a', 'ValueError']`.
- `asyncio.create_task(coro)`: keep the returned task in a variable or a set. The event loop keeps only weak references (asyncio-task docs).
- Keyword-only `context` on `create_task()` (since 3.11) sets the context the coroutine runs in. When it is not given, the task copies the current context (asyncio-task docs).
- Context variables work in asyncio without extra configuration (contextvars docs).
- `time.sleep()` suspends the calling thread (time docs). In `async def`, use `await asyncio.sleep(s)`.
- A bounded fan-out (a concurrency limit) is a loop over a queue or a semaphore; verify the exact class in the asyncio docs before use.

## Shared state across tasks

- `contextvars.copy_context()` returns a copy of the current context (contextvars docs).
- A decimal context is a `Context` object. Inside a copied context, `getcontext()` returns the same object as the parent (run: `True`), so changing its `prec` inside a task changes the parent too. Run here: the parent's precision went from 28 to 7 after a task set 7.
- Fix: enter `decimal.localcontext()` inside the task, or call `setcontext(Context(...))` inside the task. Run here: a `localcontext()` in each of two tasks gave `Decimal('0.33333')` and `Decimal('0.333333333333')`, and the parent kept 28. `setcontext(Context(prec=4))` in a task left the parent at 28.
- Threads do not share the context: a new thread starts with the default context (decimal docs; run).

## Errors in async code

- `KeyboardInterrupt` and `SystemExit` are `BaseException` subclasses (exceptions docs). A broad `except Exception` in a coroutine does not catch them.
