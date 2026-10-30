Read this when the source uses threads, async tasks, timers, cancellation or shared state, and the target is Go. Facts are for the Go 1.26 line, checked on 2026-10-29.

# Concurrency and context in Go

## Goroutines and program exit

- `go f()` starts a goroutine. When `main` returns, the program exits and does not wait for other goroutines (https://go.dev/ref/spec, Program execution).
- A source that lets background work finish after its entry point returns has no direct equivalent. The Go target must wait for that work explicitly, with a `sync.WaitGroup` or a channel. Test that the output is complete before the process exits.

## Waiting for goroutines

- `sync.WaitGroup.Add(delta)` adds to the counter. A call with a positive delta, made while the counter is zero, must happen before a `Wait`. When the counter becomes zero, every goroutine blocked in `Wait` is released (https://pkg.go.dev/sync).
- `WaitGroup.Go(f)` runs `f` in a new goroutine and adds that task to the group. The `Add` doc says callers should prefer `Go` (https://pkg.go.dev/sync; added in go1.25.0).
- Reuse: new `Add` calls must happen after every previous `Wait` has returned (https://pkg.go.dev/sync).
- Keep source order without a lock: give each goroutine its own index.

```go
results := make([]int, len(items))
var wg sync.WaitGroup
for i := range items {
	wg.Go(func() { results[i] = work(items[i]) })
}
wg.Wait()
```

Each goroutine writes its own element, so the result keeps the input order. `work` stands for the source's per-item function. Since Go 1.22 each iteration has its own loop variable, so `i` is not shared between the goroutines (https://go.dev/doc/go1.22). The go.mod condition: verify before use. A probe on go1.26.0 printed `0 1 2` with a `go 1.22` line and `3 3 3` with a `go 1.21` line.

## Mutex and shared state

- A `sync.Mutex` must not be copied after its first use (https://pkg.go.dev/sync). Pass a pointer to a struct that holds one.
- Keep the locked section short, and do not hold a lock while calling out to code you do not own (practice).
- Shared writes without synchronization can be a data race that the output does not show. When the race detector finds one, it prints a report (https://go.dev/doc/articles/race_detector).

## Channels

- Sending on a closed channel panics. Closing a closed channel panics. Closing a nil channel panics (https://go.dev/ref/spec).
- Receiving from or sending to a nil channel blocks forever (https://go.dev/ref/spec).
- A `range` over a channel yields the values sent until the channel is closed (https://go.dev/ref/spec, For statements with range).
- Only the sender should close a channel. This is a design rule, not a Go rule (practice).

## Context

- `context.Context` is the first parameter of a function that takes one. Do not store a Context in a struct; pass it to each method that needs it (https://pkg.go.dev/context; https://go.dev/wiki/CodeReviewComments, Contexts).
- Do not pass a nil Context, even if a function accepts it. Pass `context.TODO` when you are not sure which Context to use (https://pkg.go.dev/context).
- When a Context is canceled, every Context derived from it is canceled too (https://pkg.go.dev/context).
- Call the cancel function that `WithCancel`, `WithTimeout` or `WithDeadline` returns, as soon as the work it guards is done. The cancel releases resources (https://pkg.go.dev/context).

```go
ctx, cancel := context.WithTimeout(parent, 100*time.Millisecond)
defer cancel()
```

- `context.Err` returns `context.DeadlineExceeded` after a deadline passes and `context.Canceled` after a plain cancel (https://pkg.go.dev/context). Match them with `errors.Is`.
- `WithCancelCause` takes a cause. `context.Cause(ctx)` returns a non-nil error that explains the first cancellation (https://pkg.go.dev/context). Verify the exact cause rules before use with a multi-level cancel.
- `context.AfterFunc(ctx, f)` and `context.WithoutCancel(parent)` exist in the 1.26.0 package (https://pkg.go.dev/context). `WithoutCancel` returns a context that is not canceled when the parent is canceled, and its `Done` channel is nil. Verify the details before use.
- Do not use a Context to pass optional function parameters. Pass them as arguments (https://pkg.go.dev/context).

## Parity traps for concurrency

- Result order: goroutines finish in any order. If the source order matters, write results by index, or sort them with a stable sort (see as-source.md, Maps and order).
- First error versus all errors: a source that stops at the first failure needs a cancel after the first error; a source that reports every failure needs all results collected. Pick the one the source shows, and test both.
- Timeouts: a timeout in the source maps to a context deadline or an `http.Client` timeout. The error text the caller sees comes from the Go code path; test the text against the source.
- Loop variables: before Go 1.22 the variables declared by a `for` loop were created once and updated by each iteration, so a closure that captured one saw later values. Check the loop semantics of the source's version before you port a closure (https://go.dev/doc/go1.22).

## Race detector

- Run `go test -race ./...`. It needs cgo enabled and, on non-Darwin systems, an installed C compiler. On Windows it needs a C compiler with mingw-w64 runtime version 8 or later (https://go.dev/doc/articles/race_detector).
- The report lists the stacks of the conflicting accesses and the stacks where the goroutines were created (https://go.dev/doc/articles/race_detector).
- Write a test for each concurrent path of the source, so that `-race` runs over each one (practice).

## Patterns to avoid

- A goroutine that nothing waits for and nothing cancels (practice).
- A `sync.Mutex` copied by value, including as a struct field passed by value (https://pkg.go.dev/sync).
- A `time`-based sleep used as a synchronization step. Use a channel or a WaitGroup (practice).
- Reading a field from one goroutine while another writes it, without a lock or channel (see the race detector above).
