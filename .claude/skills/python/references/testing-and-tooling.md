Read this when you write tests, set up the gate, or choose a tool. Commands and versions were checked on 2026-10-29 against the pytest, ruff and mypy docs and PyPI, and the pytest runs were done locally on CPython 3.14.6.

## Test file layout

- `tests/test_<unit>.py` for behavior tests, one file per unit.
- `tests/golden/<unit>/<case>.json` for recorded outputs. The file records the input and the source output. It is written from the source, never from the target.
- A test name carries the rule id when there is one: `test_br_round_001_rounds_2_5_to_2`.

## Runner (pytest)

pytest is the de facto third-party test runner (https://docs.pytest.org/). `unittest` ships with the standard library; use it when the repository already uses it.

Code that was run here (pytest 8.4.2, `python -m pytest -q`, output `2 passed in 0.01s`, exit 0):

```python
from decimal import Decimal


def round_half_even(value: str) -> str:
    from decimal import ROUND_HALF_EVEN

    return str(Decimal(value).quantize(Decimal("1"), rounding=ROUND_HALF_EVEN))


def test_br_round_001_rounds_2_5_to_2() -> None:
    assert round_half_even("2.5") == "2"


def test_br_round_002_rounds_3_5_to_4() -> None:
    assert round_half_even("3.5") == "4"
```

- Plain `assert` is the assertion. pytest rewrites it to show the values on failure.
- Collect and run with `pytest -q` from the project root. Limit the search with a path, for example `pytest -q tests/`.
- Keep the file names and test names stable; a golden and a rule id depend on them.

## Doubles and environment

- `unittest.mock.patch` replaces a name at the place where it is looked up, not where it is defined. The docs give the rule: patch `b.SomeClass` when `b.py` runs `from a import SomeClass`; patch `a.SomeClass` when `b.py` runs `import a` (https://docs.python.org/3/library/unittest.mock.html). `patch()` works as a decorator, a class decorator or a context manager, and it is undone when the function or `with` block exits.
- pytest `monkeypatch` (https://docs.pytest.org/en/stable/how-to/monkeypatch.html): `monkeypatch.setattr(obj, name, value, raising=True)`, `monkeypatch.setenv(name, value)` and `monkeypatch.delenv(name)`. All changes are undone after the test or fixture finishes.
- Inject the clock, randomness and the HTTP client as parameters. A test then passes a fixed value. Patch a module-level global only when no parameter can carry it.
- Decimal context: enter `decimal.localcontext()` inside the test. A test that sets `getcontext().prec` changes the context that other tests in the same thread read (see `decimal-and-numbers.md`).

## Golden comparison

- Load the recorded output from `tests/golden/<unit>/<case>.json` and compare parsed values, not raw text, unless the source output is text.
- Money and other exact values are compared as strings or integers, never as floats.
- A missing golden file fails the test. Do not create it from the target's output.
- Write the golden from the source run, with the source's version and commit recorded next to the input.

## Gate commands

| Gate | Command | Pass means | Source |
|---|---|---|---|
| Runtime | `python --version` | 3.12 or later | What's New and devguide |
| Lint | `ruff check .` | exit 0 | ruff linter docs: 0 no violations, 1 violations, 2 abnormal |
| Format | `ruff format --check .` | exit 0 | ruff formatter docs: 0 nothing to format, 1 files would change, 2 abnormal |
| Types | `mypy <dir>` or `mypy -p <package>` | no error lines; exit status verify before use | mypy running docs; exit status not stated on the pages checked |
| Tests | `pytest -q` | exit 0 | pytest exit codes: 0 passed, 1 failed, 5 none collected |

Run each command and report its real output. Run here: `pytest -q` in a folder with two passing tests printed `2 passed` and exit 0; with one failing test it exited 1; in an empty folder it printed `no tests ran` and exited 5.

Not run here: `ruff` and `mypy` are not installed on the machine checked (`ruff --version` and `mypy --version` gave "command not found"; `python -m ruff` and `python -m mypy` gave "No module named"). A gate that did not run is `NOT RUN`, never a pass.

Mypy checks only annotated function bodies by default; `--check-untyped-defs` checks every body (https://mypy.readthedocs.io/en/stable/command_line.html). Mypy checks a directory recursively (https://mypy.readthedocs.io/en/stable/running_mypy.html).

## Tool choice

- Use what the repository already has. Add a tool only when the plan names it and the gate needs it.
- Versions on PyPI, read 2026-10-29: pytest 9.2.0 (2026-10-27, Requires-Python `>=3.10`); ruff 0.17.3 (2026-10-27); mypy 2.4.1 (2026-10-28, Requires-Python `>=3.10`). Check the version on the registry before you pin it.
- Tool settings live in `pyproject.toml` under `[tool.ruff]`, `[tool.mypy]` and `[tool.pytest.ini_options]`. pytest reads its own file first (`pytest.toml`, `pytest.ini`, and others) and never merges options across files.
- Coverage: no coverage tool was checked in this run. Verify before use.
