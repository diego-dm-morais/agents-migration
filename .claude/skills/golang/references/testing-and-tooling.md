Read this when you write or run Go tests, choose test doubles, compare golden output, or run the gate of a Go unit. Facts are for the Go 1.26 line, checked on 2026-10-29 with the go1.26.0 toolchain (`go doc`, `go help`, probe runs).

# Testing and tooling for Go

## Runner and layout

- A test file name ends in `_test.go`. A test is `func TestXxx(t *testing.T)` (`go doc testing`).
- `t.Run(name, f)` runs `f` as a subtest, in its own goroutine (`go doc testing.T.Run`). Use it for table-driven cases, one subtest per row.
- `t.Parallel()` marks a test to run in parallel with other parallel tests (`go doc testing.T.Parallel`).
- `t.Setenv(key, value)` restores the variable when the test ends. It cannot be used in parallel tests or in tests with parallel ancestors (`go doc testing.T.Setenv`).
- `t.Cleanup(f)` registers a function that runs when the test ends. `t.TempDir()` returns a directory that is removed at the end. `t.Helper()` marks a helper so that failures report the caller's line. `t.Chdir(dir)` and `t.Context()` exist in the 1.26.0 package (`go doc testing.T`).
- A benchmark loop uses `b.Loop()`, which returns true while the benchmark should keep running (`go doc testing.B.Loop`).

## Running

- `go test ./...` runs every package. `-run <regexp>` selects tests, `-v` prints each one, `-count n` runs each test n times, `-shuffle=on` randomizes order, `-cover` enables coverage, `-parallel n` sets the parallel limit (`go help testflag`).
- In package list mode `go test` caches successful results. A cached result is printed as `(cached)` (`go help test`). Read the output before you trust a pass.
- `go test` runs a high-confidence subset of the vet checks before the tests. The build fails when they report (`go help test`).
- `-race` needs cgo and a C compiler on non-Darwin systems (https://go.dev/doc/articles/race_detector; see concurrency-and-context.md).

## Doubles and fakes

- Put the interface in the package that consumes it. Write the fake in the test file as a small struct that implements the methods it needs.
- Inject time, randomness and configuration through parameters or a struct. Do not read the wall clock inside the code under test (practice).
- A fake that records calls makes order and count checks possible. Keep the fake small.

## HTTP tests

- `httptest.NewRecorder()` returns a `*ResponseRecorder` that records a handler's response without a network (`go doc net/http/httptest`).
- `httptest.NewServer(handler)` starts a server; call `Close` when finished (`go doc net/http/httptest`).
- For a client under test, point its base URL at the `httptest.Server` URL. Do not call a real host from a test (practice).

## Golden comparison

- Load the recorded output from a file, parse it, and compare the parsed values. Never regenerate the golden file from the new code, because that hides the change (practice).
- Compare numbers as numbers, not as text, only when the source compares them that way. The source's text format is part of the parity.

## Gate commands and what passes

Run each command and read the output. Probe results are from go1.26.0 windows/amd64, on a small module with one package, one `main.go` and one `main_test.go`.

| Command | Pass | Probe result |
|---|---|---|
| `gofmt -l .` | prints nothing | no output |
| `go vet ./...` | exit 0 | exit 0 |
| `go test -race -count=1 -v ./...` | every test prints `--- PASS`, the last line is `ok`, exit 0 | three `--- PASS` lines, `ok  	probe`, exit 0 |
| `go mod tidy -diff` | exit 0; no diff printed | exit 0, no output |
| `go mod tidy` then compare `go.mod` hash | hash unchanged | unchanged when the file ends with a newline |

Failures seen in the probe, and what they showed:

- `go vet ./...` on a timeformat mistake: `main.go:54:25: 2006-02-01 should be 2006-01-02`, exit 1.
- `go test` on a `Println` with a `%.0f` in its text: `fmt.Println call has possible Printf formatting directive %.0f`, then `FAIL probe [build failed]`.
- `gofmt -l .` on a file without a final newline lists the file. `gofmt -d` prints `\ No newline at end of file`.
- `go mod tidy` rewrote a `go.mod` that had no final newline (a change from 21 to 22 bytes was not reproduced; verify before use).

## Tools and how to choose

- `gofmt`: the formatter; `-l` lists files that differ, `-d` prints the diff (`gofmt -h`).
- `go vet`: built-in checks. `go tool vet help` lists 30 analyzers on go1.26.0, among them `appends`, `asmdecl`, `assign`, `atomic`, `bools`, `copylocks`, `errorsas`, `loopclosure`, `printf`, `timeformat` and `unusedresult`.
- `go test -race`: data races seen while tests run.
- `go doc` and `go help`: the documentation of the toolchain you run. Use them to check a name before you use it.
- Third-party linters such as staticcheck and golangci-lint are common. They were not checked in this run; verify before use at https://staticcheck.dev and https://golangci-lint.run.
- A CI job should run the same commands as the local gate, with the toolchain named in `go.mod` (practice).
