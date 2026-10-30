---
name: python
description: "Python 3.12 and later (CPython; current stable 3.15) for code that runs on Python: annotations and asyncio, decimal and float numbers, datetime and zoneinfo, exceptions and exit codes, and the pytest, ruff and mypy gate. Use for Python code, pyproject.toml, pytest suites, or migrations to or from Python."
metadata:
  baseline: "Python 3.12 or later (floor 3.12; current stable 3.15.2)"
  verified: "2026-10-29"
---

# python (Python 3.12+)

Practice for code that runs on CPython. The baseline is Python 3.12, the floor of the migration project. Facts here were checked against docs.python.org, the devguide, the PyPI pages and local runs on 2026-10-29. Sources are listed at the end.

## 1. Scope and versions

- Target the minimum version the repository declares in its project metadata. If it declares none, use `>=3.12` and say so in the report.
- Support phases (devguide, read 2026-10-29): 3.12 and 3.13 are in the security phase, ending 2028-10 and 2029-10. 3.14 and 3.15 are in the bugfix phase. 3.16 is in development. Pick the target from the repository, not from this list.
- Current stable release: 3.15.2, dated 2026-10-25 (python.org downloads page). Record the version you target in the report.
- Version-gated syntax: PEP 695 type parameters (`def first[T](items: list[T]) -> T`) and the `type` statement are in 3.12 (What's New in 3.12). The 3.12 floor allows them.
- Version-gated behavior: the default encoding of `open()` changed in 3.15 (section 6). Read the What's New page of the target version before you rely on any default.
- Deprecated: the `-b` and `-bb` options are deprecated since 3.15 and become no-ops in 3.17 (command-line docs). Do not use BytesWarning as a check in a new gate.
- Local toolchain in this run: CPython 3.14.6. Version 3.12 was not run here, so no 3.12 result is claimed.

## 2. Layout and build

- Keep tool settings in `pyproject.toml`: `[tool.ruff]` (ruff ignores a `pyproject.toml` without that table), `[tool.mypy]` and `[tool.pytest.ini_options]` (ruff configuration docs, mypy running docs, pytest customize docs).
- pytest looks for its own file first. The candidates are `pytest.toml`, `.pytest.toml`, `pytest.ini`, `.pytest.ini`, `pyproject.toml`, `tox.ini` and `setup.cfg`, in that order. The first match wins; options are never merged across files.
- Pin dependencies with the tool the repository already uses. Do not add a second manager.
- Split by responsibility: pure functions (no I/O) hold the logic; thin adapters hold files, network and environment. Tests import the pure functions directly.
- Only an entry point calls `sys.exit()`. Library modules raise (section 4).

## 3. Idioms

- Annotate public functions. The interpreter does not enforce annotations (typing docs); a type checker does (section 8). Details: `references/typing-and-async.md`.
- Optional values: `X | None`, or `typing.Optional[X]`, which is equivalent (typing docs). Run here: `Optional[int] == (int | None)` is `True`.
- Resources: `with open(...) as f:`, locks and connections. The block closes the resource on exit.
- Pass `encoding=` to `open()` explicitly (section 6 explains the default).
- Paths: `pathlib.Path` for path operations.
- Mutable default arguments: use `None` and create the object in the body (section 6).

## 4. Errors, resources and exit

- Raise an instance of `BaseException` or a subclass. Any other value fails: `raise "text"` gives `TypeError: exceptions must derive from BaseException` (raise docs; run here).
- Catch `Exception`, not a bare `except:`. `KeyboardInterrupt` and `SystemExit` derive from `BaseException`, not `Exception` (exceptions docs; run here: `issubclass(SystemExit, Exception)` is `False`).
- Chain a wrapped error with `raise New(...) from cause`. The cause is stored in `__cause__` (raise docs; run here).
- Give each source exception one class. Keep the source's message text only when the source outputs it.
- `sys.exit(arg)` raises `SystemExit`. An integer is the exit status; `None` means 0; any other object is printed to stderr and the status is 1 (sys docs; run here: `sys.exit('boom')` prints `boom` and exits 1, `sys.exit(3)` exits 3).
- `assert` is not an input check. With `-O` the compiler emits no code for it (simple statements docs; run here: the assert was skipped and the exit status was 0).
- Close handles with `with`, or in `try`/`finally`.

## 5. Concurrency

- CPython default builds run one thread of bytecode at a time, through the GIL (glossary). Since 3.13 a free-threaded build can be configured with `--disable-gil` (glossary). The build is part of the target; do not assume one.
- `asyncio.run()` is the top-level entry point (asyncio docs).
- `asyncio.gather()` with the default `return_exceptions=False` propagates the first exception to the awaiting task. The other awaitables are not cancelled and keep running. With `return_exceptions=True` the exceptions come back as results (asyncio-task docs; run here: `['a', 'ValueError']`).
- `create_task()`: keep a reference to the task. The event loop keeps only weak references, so an unreferenced task can be garbage collected before it finishes (asyncio-task docs).
- Inside `async def`, use `await asyncio.sleep(s)`. `time.sleep()` suspends the calling thread (time docs), so other coroutines on that thread wait.
- A task runs in a copy of the context (asyncio-task docs, since 3.11). A `Context` object is shared by reference, so a decimal context changed in place inside a task changes the parent's (section 6; `references/decimal-and-numbers.md`).

## 6. Data and numbers (parity traps)

- `int` has unlimited precision (stdtypes docs). `float` is binary: `repr(0.1 + 0.2)` is `'0.30000000000000004'` and `0.1 + 0.1 + 0.1 == 0.3` is `False` (tutorial; run here). `repr` gives the shortest string that reads back to the same float (tutorial).
- `round(x)` with no `ndigits` returns an int; ties go to the even choice (functions docs). `round(2.675, 2)` is `2.67` (functions docs; run here). With `ndigits` the result has the type of the input: `round(2.5, 0)` is `2.0`.
- Money and exact decimals: `decimal.Decimal` with an explicit context and rounding mode. See `references/decimal-and-numbers.md`.
- `//` floors and `%` takes the sign of the divisor (expressions docs): `-7 // 2` is `-4`, `-7 % 2` is `1` (run here). `int()` truncates: `int(-2.7)` is `-2`, `math.floor(-2.7)` is `-3` (run here).
- `/` on two ints gives a float: `7 / 2` is `3.5` (expressions docs). `1 // 0` raises `ZeroDivisionError` (run here).
- `bool` is a subclass of `int` (functions docs): `True + True` is `2`; `{1: 'a', True: 'b'}` has one key, `{1: 'b'}` (run here).
- `dict` keeps insertion order, guaranteed since 3.7 (stdtypes docs; run here: `['b', 'a', 'c']`).
- A mutable default argument is evaluated once, at definition (compound statements docs). `def g(item, acc=[])` returns the same list on every call (run here).
- `str` is a sequence of Unicode code points (stdtypes docs): `len("é")` is `1`, its UTF-8 encoding is 2 bytes, and `len("\U0001F600")` is `1` (run here).
- `str` and `bytes` never compare equal: `b"abc" == "abc"` is `False` (stdtypes docs: objects of different types never compare equal; run here). `"a" + b"b"` raises `TypeError` (run here). Under `-b` the comparison issues a `BytesWarning` (command-line docs).
- Invalid input: `b"\xff".decode("utf-8")` raises `UnicodeDecodeError`; `"é".encode("ascii")` raises `UnicodeEncodeError` (run here).
- `open()` default encoding: UTF-8 from 3.15 (PEP 686, open docs, "Changed in version 3.15"). Before 3.15 it is the locale encoding, which was `cp1252` on the machine checked here (`locale.getpreferredencoding(False)`, CPython 3.14.6).
- Naive and aware datetimes: `naive == aware` is `False`; ordering raises `TypeError` (datetime docs; run here). `datetime.now()` returns naive local time; `datetime.now(timezone.utc)` returns aware UTC (datetime docs; run here).
- `zoneinfo` reads the system time zone database or the `tzdata` package; Windows needs `tzdata` (zoneinfo docs). On the machine checked, `ZoneInfo("America/Sao_Paulo")` raised `ZoneInfoNotFoundError` because `tzdata` was absent (run here). `ZoneInfoNotFoundError` is a `KeyError` (zoneinfo docs).
- `os.environ` values are always `str`; `bool("false")` is `True` (run here).
- `json.dumps({"a": Decimal("1.10")})` raises `TypeError` (run here).
- Iterating a dict while adding keys raises `RuntimeError: dictionary changed size during iteration` (run here).

## 7. Testing

- Runner: pytest, the de facto third-party test runner (docs.pytest.org). `unittest` is in the standard library; use it when the repository already uses it.
- Layout: `tests/test_<unit>.py`. Name each test with its rule id, for example `test_br_round_001_rounds_2_5_to_2`.
- Doubles: `unittest.mock.patch` replaces a name where it is looked up, not where it is defined, and restores it when the block ends (mock docs). The pytest `monkeypatch` fixture undoes its changes after the test (monkeypatch docs).
- Inject the clock, randomness and HTTP client as parameters. Patch a global only when no parameter can carry it.
- Golden tests: load recorded output from a file and compare parsed values. Never regenerate a golden from the new code.
- Decimal tests: enter `decimal.localcontext()` inside the test. Do not change the global context.
- Run: `pytest -q`. Exit codes (pytest exit-codes docs): 0, all collected tests passed; 1, some tests failed; 5, no tests collected. Run here with pytest 8.4.2: two passing tests printed `2 passed` and exit 0; a failing test exit 1; an empty directory exit 5.
- Coverage tool: not checked in this run; verify before use.

## 8. Quality gate

Run each command, read its result, and report the real output. A gate that did not run is not a pass.

1. `python --version`: 3.12 or later, matching the declared minimum. Run here: `Python 3.14.6`.
2. Install from the repository's lock or requirements file, with the command the repository documents.
3. `ruff check .`: exit 0 means no violations; exit 1 means violations found; exit 2 means abnormal termination, such as invalid configuration (ruff linter docs). Current release 0.17.3 (PyPI, 2026-10-27). Not installed here: not run.
4. `ruff format --check .`: exit 0 means no file would be reformatted; exit 1 means one or more would be; exit 2 means abnormal termination (ruff formatter docs). Not installed here: not run.
5. Type checker: mypy. `mypy <dir>` checks a directory recursively; `mypy -p <package>` checks a package (mypy running docs). Bodies of unannotated functions are not checked unless `--check-untyped-defs` is set (mypy docs). Current release 2.4.1 (PyPI, 2026-10-28). The pages checked do not state the exit status on errors: verify before use. Not installed here: not run. pyright was not checked.
6. `pytest -q`: exit 0, all passed; exit 1, some failed; exit 5, nothing collected (pytest exit-codes docs). Run here with pytest 8.4.2; the current release is 9.2.0 (PyPI, 2026-10-27, Requires-Python `>=3.10`).

## 9. Migrating TO Python

- Parity beats idiom. Choose an idiom only when inputs, outputs and errors stay the same. Otherwise keep the source behavior and mark the difference `deviation` with its reason and its source.
- Map each source construct with `references/as-target.md`: numbers and rounding, text and bytes, dates and time zones, collections, exceptions, process exit, file and I/O encodings, async fan-out, configuration and serialization.
- Money and exact decimals: `decimal.Decimal` with a local context and the source's rounding mode. Never `float`. Write a test for each tie direction before the code.
- Keep the source's error model: one exception class per source error, and the source's message text when the source outputs it.
- Keep the source's public names only when an outside caller depends on them.

## 10. Migrating FROM Python

- Read `references/as-source.md` for the places where Python behavior hides: runtime defaults, mutable defaults, implicit conversions (`bool` as `int`), dict order, encodings, naive datetimes, time zones and the decimal context.

## 11. Anti-patterns

- `float` for money, or `round()` on a float used as a money rule.
- Mutable default arguments, such as `def f(items=[])`.
- A bare `except:`, or `except BaseException` in library code.
- `sys.exit()` in a library module.
- `assert` as the only check on input.
- Naive `datetime.now()` for stored instants.
- `getcontext().prec = n` inside a task or a library function. Use `localcontext()`.
- `time.sleep()` inside `async def`.
- A task from `create_task()` with no stored reference.
- `ZoneInfo` on Windows without `tzdata`.
- `open()` without `encoding=` in code that runs on more than one Python version.

## Library registry

- Registry: https://pypi.org/ (project pages list the release history, `Requires-Python`, license and the wheel files).
- Before adding a package, check the standard library first. Then search PyPI, open the project page, and confirm: latest release date, `Requires-Python` compatible with the target `pyproject.toml`, license, and maintainers.
- Pin the exact version with the tool the repository already uses (section 2). Read the lockfile after adding.
- Full procedure and evaluation checks: `.claude/skills/migration-conduct/references/library-research.md`.

## Sources

- Python downloads, current stable release: https://www.python.org/downloads/
- Python Package Index: https://pypi.org/
- Devguide, version support phases: https://devguide.python.org/versions/
- Built-in functions (round, bool, open): https://docs.python.org/3/library/functions.html
- Built-in types (int, dict, str, bytes): https://docs.python.org/3/library/stdtypes.html
- Expressions (arithmetic, comparisons): https://docs.python.org/3/reference/expressions.html
- Compound statements (default arguments): https://docs.python.org/3/reference/compound_stmts.html
- Simple statements (raise, assert): https://docs.python.org/3/reference/simple_stmts.html
- Floating point tutorial: https://docs.python.org/3/tutorial/floatingpoint.html
- Exceptions: https://docs.python.org/3/library/exceptions.html
- sys: https://docs.python.org/3/library/sys.html
- Command-line options (-b, -bb): https://docs.python.org/3/using/cmdline.html
- Glossary (GIL, free-threaded build): https://docs.python.org/3/glossary.html
- What's New in 3.12 (PEP 695, type statement): https://docs.python.org/3/whatsnew/3.12.html
- decimal: https://docs.python.org/3/library/decimal.html
- datetime: https://docs.python.org/3/library/datetime.html
- zoneinfo: https://docs.python.org/3/library/zoneinfo.html
- typing: https://docs.python.org/3/library/typing.html
- asyncio tasks: https://docs.python.org/3/library/asyncio-task.html
- contextvars: https://docs.python.org/3/library/contextvars.html
- time: https://docs.python.org/3/library/time.html
- unittest.mock: https://docs.python.org/3/library/unittest.mock.html
- pytest exit codes: https://docs.pytest.org/en/stable/reference/exit-codes.html
- pytest monkeypatch: https://docs.pytest.org/en/stable/how-to/monkeypatch.html
- pytest configuration files: https://docs.pytest.org/en/stable/reference/customize.html
- pytest on PyPI: https://pypi.org/project/pytest/
- ruff linter: https://docs.astral.sh/ruff/linter/
- ruff formatter: https://docs.astral.sh/ruff/formatter/
- ruff configuration: https://docs.astral.sh/ruff/configuration/
- ruff on PyPI: https://pypi.org/project/ruff/
- mypy running: https://mypy.readthedocs.io/en/stable/running_mypy.html
- mypy command line: https://mypy.readthedocs.io/en/stable/command_line.html
- mypy getting started: https://mypy.readthedocs.io/en/stable/getting_started.html
- mypy on PyPI: https://pypi.org/project/mypy/
