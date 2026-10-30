---
name: golang
description: "Go 1.26 line: Go code, go.mod, go test suites, goroutines and context, errors and net/http, encoding/json, time layouts, integer and float rounding parity, the gofmt and go vet gate, and migrations to or from Go."
metadata:
  baseline: "Go 1.26 line (go1.26.0 toolchain checked on 2026-10-29)"
  verified: "2026-10-29"
---

# golang (Go 1.26 line)

Practice for code written in Go: the language, the standard library and the go command, with the traps a migration meets. The baseline is the Go 1.26 line. Facts were checked on 2026-10-29 against the go1.26.0 toolchain installed on the machine (`go doc`, `go help`, the spec in GOROOT, probe runs) and the official pages in Sources. The current stable release on the release page is go1.27.3 (2026-10-19); this skill does not move the baseline to it.

## 1. Scope and versions

- Target the version in `go.mod`. The `go` line sets the module's language version. Check it before you use a feature from a later release.
- Release history (https://go.dev/doc/devel/release): go1.26.0 was released 2026-02-10. The latest stable release seen on 2026-10-29 is go1.27.3, released 2026-10-19. The latest go1.26 patch on the same page is go1.26.10 (2026-10-19), read from a page summary; verify before use.
- Go 1.22 gave each loop iteration its own loop variable (https://go.dev/doc/go1.22). Whether the new behavior depends on the go line of `go.mod`: verify before use. A probe on go1.26.0 printed `0 1 2` with a `go 1.22` line and `3 3 3` with a `go 1.21` line.
- Record the toolchain you ran with `go version`. The probe in this run used `go1.26.0 windows/amd64`.
- Check names offline with the installed toolchain: `go doc <package>.<Name>` prints the documentation of that version, and `go env GOROOT` leads to `doc/go_spec.html`, the language spec (observed on go1.26.0).

## 2. Layout and build

- A module is a directory with `go.mod` at its root. `go.sum` holds checksums of required modules. A module with no requirements has no `go.sum` (probe).
- Commands go in `cmd/<name>/`; library code goes in packages (practice). Each directory is one package.
- Check with `go build ./...`, `go vet ./...` and `go test ./...`. `go test` runs a high-confidence subset of the vet checks before the tests and fails the build when they report (`go help test`; probe: build failed on a `Println` format directive).
- Do not add a module for what the standard library does. `go mod tidy` adds missing requirements and removes unused ones (https://go.dev/ref/mod; verify before use).
- Keep pure logic in packages that do no I/O, and call them from thin adapters. This is a design practice, not a Go rule.

## 3. Idioms

- Formatting is gofmt's output. `gofmt -l` lists the files whose formatting differs (https://pkg.go.dev/cmd/gofmt).
- Return the error as a result value and check it. Do not discard an error with `_` (https://go.dev/wiki/CodeReviewComments, Handle Errors).
- Error strings are not capitalized, unless they begin with a proper noun or an acronym, and do not end with punctuation (https://go.dev/wiki/CodeReviewComments, Error Strings).
- Most functions that take a `context.Context` take it as the first parameter; a method whose signature must match an interface is the exception. Do not store a Context in a struct (https://go.dev/wiki/CodeReviewComments, Contexts).
- Receiver names are short, often one or two letters, and the same in every method (https://go.dev/wiki/CodeReviewComments, Receiver Names).
- Wrap an error with `%w` in `fmt.Errorf` so that `errors.Is` and `errors.As` can match it (https://pkg.go.dev/fmt).
- Name a file, a package or a field the way the source does when parity needs it. Idiomatic names are a choice that you record (practice).

## 4. Errors, resources and exit

- An error is any value with an `Error() string` method. `errors.New` makes a sentinel. `fmt.Errorf` with one `%w` wraps the error; with several `%w` it returns an error whose `Unwrap() []error` returns all of them (https://pkg.go.dev/fmt).
- `errors.Is` walks the chain. `errors.As` finds the first error of a type and panics when its target is not a non-nil pointer. `errors.AsType` is the generic form in the go1.26.0 package. `errors.Join` combines errors (https://pkg.go.dev/errors).
- `os.Exit` ends the program at once, and deferred functions do not run (https://pkg.go.dev/os). Return from `main` when cleanup must run.
- A wrapped error keeps its chain: `errors.Is(err, ErrX)` finds `ErrX` through any number of `%w` wrappers, and a comparison of the message text does not (https://pkg.go.dev/errors; https://pkg.go.dev/fmt).
- The caller of an HTTP request must close `resp.Body` (https://pkg.go.dev/net/http).
- Do not use `panic` for normal error handling (https://go.dev/wiki/CodeReviewComments, Don't Panic).

## 5. Concurrency

- `go f()` starts a goroutine. When `main` returns, the program exits; it does not wait for other goroutines (https://go.dev/ref/spec, Program execution).
- Wait with `sync.WaitGroup`: call `Add` before the `go` statement and `Done` in the goroutine. `WaitGroup.Go` starts a goroutine and adds its task (https://pkg.go.dev/sync).
- A `sync.Mutex` must not be copied after first use (https://pkg.go.dev/sync).
- Sending on a closed channel panics, and so does closing a closed channel or a nil channel (https://go.dev/ref/spec).
- Cancel with `context.WithCancel`, `WithTimeout` or `WithDeadline`, and call the returned cancel function (`defer cancel()`) (https://pkg.go.dev/context).
- Run `go test -race ./...`. The race detector prints stack traces for the conflicting accesses (https://go.dev/doc/articles/race_detector). Details are in references/concurrency-and-context.md.
- Wait for a set of goroutines and keep the input order by writing each result to its own index (probe-style pattern; `WaitGroup.Go` per https://pkg.go.dev/sync):

```go
results := make([]int, len(items))
var wg sync.WaitGroup
for i := range items {
	wg.Go(func() { results[i] = work(items[i]) })
}
wg.Wait()
```

## 6. Data and numbers (parity traps)

- Integer `/` truncates toward zero: `-7/2` is `-3` and `-7%2` is `-1` (https://go.dev/ref/spec, Integer operators; probe).
- Integer overflow wraps without an error: an `int8` holding 127 plus 1 is -128 (https://go.dev/ref/spec; probe).
- `math.Round` rounds half away from zero: `math.Round(-2.5)` is `-3`. `math.RoundToEven` rounds ties to even: `math.RoundToEven(2.5)` is `2` (https://pkg.go.dev/math; probe).
- `fmt.Sprintf("%.0f", 2.5)` is `"2"`, `3.5` is `"4"` and `-2.5` is `"-2"`. `%.2f` of `1.005` is `"1.00"` (probe). The strconv doc says the result is rounded but does not name the tie rule; verify before use.
- Map iteration order is not specified and is not the same from one iteration to the next (https://go.dev/ref/spec, For statements; probe).
- Slices share a backing array. `append` within capacity writes into it (https://go.dev/blog/slices-intro; probe).
- A time layout uses the reference time `Mon Jan 2 15:04:05 MST 2006` (https://pkg.go.dev/time). `2006-02-01` is the wrong order, and `go vet` reports it.
- A JSON number decodes into a `float64` inside an interface. `Decoder.UseNumber` keeps it as a `json.Number` (https://pkg.go.dev/encoding/json; probe).
- An interface holding a nil pointer is not nil (https://go.dev/doc/faq; probe).
- Every variable without an initializer gets the zero value of its type (https://go.dev/ref/spec, The zero value). Reading a nil map returns the zero value; writing to it panics (probe).
- `len` on a string counts bytes. `utf8.RuneCountInString` counts runes (https://go.dev/ref/spec; https://pkg.go.dev/unicode/utf8).
- `sort.Slice` is not stable. `sort.SliceStable` and `slices.SortStableFunc` keep the order of equal elements (https://pkg.go.dev/sort; https://pkg.go.dev/slices).
- `==` on `time.Time` compares more than the instant; use `Equal` (https://pkg.go.dev/time).
- On Unix systems, `time.Local` consults the `TZ` environment variable (https://pkg.go.dev/time). The doc does not describe Windows; on the Windows host of the probe (go1.26.0), `TZ` had no effect on `time.Local`.
- `math/big` implements arbitrary-precision arithmetic (https://pkg.go.dev/math/big).
- To check a trap, write a small program in a scratch directory outside the repository, print the value, and record the toolchain version with the output. A probe is evidence for that version only.

## 7. Testing

- Runner: `testing`. A test is `func TestX(t *testing.T)` in a `_test.go` file. Subtests use `t.Run`. Use `t.Helper`, `t.Cleanup`, `t.TempDir`. `t.Setenv` cannot be used in parallel tests (https://pkg.go.dev/testing).
- Run `go test ./...`. `-run` selects tests, `-v` prints them, `-shuffle=on` randomizes order, `-cover` enables coverage (`go help testflag`).
- Doubles are fakes behind an interface that the consuming package owns (practice). HTTP is tested with `httptest.NewServer` or `httptest.NewRecorder` (https://pkg.go.dev/net/http/httptest).
- Table-driven cases use `t.Run` with one subtest per row. This is the pattern for a rounding tie in both directions:

```go
func TestMathRound(t *testing.T) {
	cases := []struct {
		name string
		in   float64
		want float64
	}{
		{"tie away from zero, positive", 2.5, 3},
		{"tie away from zero, negative", -2.5, -3},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			if got := math.Round(c.in); got != c.want {
				t.Fatalf("math.Round(%v) = %v, want %v", c.in, got, c.want)
			}
		})
	}
}
```

- Golden comparison loads the recorded output and compares parsed values. Never regenerate the golden from the new code (practice).
- Test names state the behavior, and one test checks one behavior (practice).

## 8. Quality gate

Run each command, read its result, and report the real output. A gate that did not run is not a pass. Probe results are from go1.26.0 windows/amd64 on 2026-10-29. This gate is the default of a migration to Go: the planner records each tool it names as an `ID-` with `status: proposed`, with its version and URL, and does not ask the user for it.

1. `gofmt -l .` must print nothing. Probe: no output.
2. `go vet ./...` must exit 0. Probe: exit 0.
3. `go test -race ./...` must exit 0. The race detector needs cgo enabled and, on non-Darwin systems, an installed C compiler (https://go.dev/doc/articles/race_detector). Probe: `ok probe`, exit 0.
4. `go mod tidy` must leave `go.mod` and `go.sum` unchanged. Compare file hashes before and after. `go mod tidy -diff` prints the diff and exits non-zero when it is not empty (`go help mod tidy`). Probe: `go.mod` unchanged, exit 0.
5. Coverage, when the plan sets a minimum: `go test -cover ./...`.

Failures seen in the probe: `go vet` reported `2006-02-01 should be 2006-01-02` at a `Format` call (exit 1); `go test` stopped at build with a `Printf formatting directive` report from a `Println` call. Read each report and fix the code; do not suppress the check.

A file without a final newline fails `gofmt -l`. In the probe, `go mod tidy` rewrote a `go.mod` that lacked one. Write every file with a final newline.

## 9. Migrating TO Go

- Parity beats idiom. Choose an idiom only when inputs, outputs and errors stay the same. Otherwise keep the source behavior and mark the difference with its reason and source.
- Map each source construct with references/as-target.md. The constructs that migrations usually need are rounding, text, dates, errors, I/O and collections.
- Write a test for each tie, boundary and error path before the code (references/testing-and-tooling.md).
- Keep one error value per source error kind, and keep the source message text when the source has a stable one.
- Keep exported names only when an outside caller depends on them.

## 10. Migrating FROM Go

- Read references/as-source.md for where Go behavior hides: numeric conversions and integer overflow, rounding, map order, zero values and nil interfaces, JSON number defaults, UTF-8 bytes, time layouts and time zones.
- Read references/concurrency-and-context.md for goroutines, channels and cancellation, and references/errors-and-http.md for error chains, panics, exit and HTTP.

## 11. Anti-patterns

- Floats for money, or `math.Round` used without a note on its tie direction.
- `==` on `time.Time` values.
- Relying on map iteration order, or on `sort.Slice` to keep equal elements in order.
- A goroutine that nothing waits for and nothing cancels.
- `os.Exit` in library code, or in a function that has deferred cleanup.
- Returning a nil pointer of a concrete type as an `error`.
- Discarding an error with `_`.
- `http.DefaultClient` for a call that needs a timeout: its `Client` has `Timeout` zero, which means no timeout.
- Copying a `sync.Mutex`, or a struct that holds one, after first use.
- Comparing errors by their message text instead of with `errors.Is` or `errors.As`.
- `%v` in `fmt.Errorf` where the error chain must be kept. Use `%w`.
- A table-driven test that checks only the happy path of a rounding or parsing rule.

## Version deltas (older source lines)

Read this section only when the source's `go` line (in `go.mod`) is older than the baseline above (Go 1.26). Each entry gives the release it changed in, its official URL and the probe that shows it. A behavior of an older line that this section does not list is not stated from this skill: verify it on the toolchain the source pins, or record it as a `deferred-capture` (conduct section 1a).

- go1.22: a `for` loop variable is new in each iteration when the `go` line of `go.mod` is 1.22 or later (https://go.dev/doc/go1.22). Probe on go1.26.0 windows/amd64: `0 1 2` with `go 1.22`, `3 3 3` with `go 1.21` (section 1).

## Library registry

- Registry: https://pkg.go.dev/ (search and module pages; versions and `go` directive in each module's page).
- Before adding a module, check the standard library first. Then search pkg.go.dev, open the module page, and confirm: latest version, `go` directive compatible with the target `go.mod`, license, last release, and the import path.
- Confirm exact versions locally with `go list -m -versions <module>` and pin them with `go get <module>@<version>`. Read `go.sum` after adding.
- Full procedure and evaluation checks: `.claude/skills/migration-conduct/references/library-research.md`.

## Sources

- Go release history: https://go.dev/doc/devel/release
- Go module registry: https://pkg.go.dev/
- Go 1.22 release notes: https://go.dev/doc/go1.22
- Go language specification: https://go.dev/ref/spec
- Effective Go: https://go.dev/doc/effective_go
- Go Code Review Comments: https://go.dev/wiki/CodeReviewComments
- Go Modules Reference: https://go.dev/ref/mod
- Data Race Detector: https://go.dev/doc/articles/race_detector
- Go Slices: usage and internals: https://go.dev/blog/slices-intro
- Go FAQ: https://go.dev/doc/faq
- Package docs: https://pkg.go.dev/testing, https://pkg.go.dev/cmd/go, https://pkg.go.dev/cmd/gofmt, https://pkg.go.dev/cmd/vet, https://pkg.go.dev/context, https://pkg.go.dev/errors, https://pkg.go.dev/fmt, https://pkg.go.dev/math, https://pkg.go.dev/math/big, https://pkg.go.dev/encoding/json, https://pkg.go.dev/net/http, https://pkg.go.dev/net/http/httptest, https://pkg.go.dev/os, https://pkg.go.dev/sort, https://pkg.go.dev/slices, https://pkg.go.dev/sync, https://pkg.go.dev/time, https://pkg.go.dev/unicode/utf8
