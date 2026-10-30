Read this when the source you migrate from is Go. These are the places where the behavior is easy to miss, because it is in the language or the runtime, not in the line you read. Each trap names the input, the output Go gives, and the source.

# Reading Go as the source

## Integers

- Integer division truncates toward zero: `-7 / 2` is `-3`, not `-4`, and `-7 % 2` is `-1` (https://go.dev/ref/spec, Integer operators; probe).
- Integer overflow wraps: `var x int8 = 127; x++` leaves `x` at `-128`. The spec says overflow of a signed integer is legal and its result is deterministically defined; it says programs may rely on wrap around for unsigned integers (https://go.dev/ref/spec, Integer operators; probe).
- A float converted to an integer drops the fraction: `int(-2.7)` is `-2` (https://go.dev/ref/spec, Conversions between numeric types).

## Floats and rounding

- `math.Round` rounds half away from zero: `math.Round(2.5)` is `3` and `math.Round(-2.5)` is `-3` (https://pkg.go.dev/math; probe).
- `math.RoundToEven` rounds ties to even: `math.RoundToEven(2.5)` is `2` (https://pkg.go.dev/math; probe).
- `fmt.Sprintf("%.0f", 2.5)` is `"2"`, `"%.0f"` of `3.5` is `"4"` and of `-2.5` is `"-2"` (probe). A source that rounds ties up will differ on every exact tie.
- `fmt.Sprintf("%.2f", 1.005)` is `"1.00"`, because the binary value is below the tie (probe). Copy the source's output; do not correct it.
- Floating-point comparison follows IEEE 754 (https://go.dev/ref/spec, Comparison operators; verify before use).

## Text and bytes

- `len` on a string counts bytes, not characters: the spec says the number of bytes is the length of the string (https://go.dev/ref/spec). `utf8.RuneCountInString("é")` is `1` (https://pkg.go.dev/unicode/utf8).
- A `range` over a string with an invalid UTF-8 byte yields `0xFFFD` for that byte and advances one byte (https://go.dev/ref/spec, For statements with range).
- Strings compare byte by byte: `"é"` (bytes `0xC3 0xA9`) sorts after `"z"` (https://go.dev/ref/spec, Comparison operators). Sorting by a locale collation gives another order.

## Maps and order

- Map iteration order is not specified and is not the same from one iteration to the next (https://go.dev/ref/spec, For statements). In the probe, 200 ranges over one map produced more than one first key.
- Output built by ranging over a map has no fixed order. Find the sort, if any, in the source.
- `encoding/json` writes the keys of a map in sorted order, so JSON output of a map is stable (https://pkg.go.dev/encoding/json).

## Nil and zero values

- Each variable without an initializer gets the zero value of its type: `0` for numbers, `""` for strings, `nil` for pointers, slices, maps and interfaces (https://go.dev/ref/spec, The zero value).
- Reading a nil map returns the zero value; writing to a nil map panics with `assignment to entry in nil map` (probe).
- An interface holding a nil pointer is not nil: a `*MyErr` nil stored in an `error` gives `err != nil` true (https://go.dev/doc/faq; probe).
- A nil slice encodes as the JSON value `null` (https://pkg.go.dev/encoding/json).

## Slices

- A slice shares its array. `t := s[:2]; t = append(t, 99)` writes into `s[2]`, so `s` becomes `[1 2 99 4]` (https://go.dev/blog/slices-intro; probe).
- `append` past the capacity allocates a new array. Later writes to the new slice do not reach the old one (probe).

## Time

- The layout is the reference time `Mon Jan 2 15:04:05 MST 2006`. A source token such as `YYYY-MM-DD` is not a Go token: `Format("YYYY-MM-DD HH:mm:ss")` prints the letters unchanged (probe).
- `Format("2006-02-01")` on 2026-10-29 gives `2026-29-10`. The `timeformat` check of `go vet` reports this layout (https://pkg.go.dev/cmd/vet; probe).
- On Unix systems, `time.Local` consults the `TZ` environment variable, and `TZ=""` means UTC (https://pkg.go.dev/time). The doc does not describe Windows; on the Windows host of the probe (go1.26.0), `TZ` had no effect on `time.Local`. A result that uses it differs between machines.
- `==` on `time.Time` compares more than the instant; the doc says to prefer `Equal` (https://pkg.go.dev/time).

## JSON

- A JSON number decodes into `float64` when the target is an interface: `{"id":9007199254740993}` gives `9.007199254740992e+15` (https://pkg.go.dev/encoding/json; probe).
- `Decoder.UseNumber` keeps the literal as a `json.Number` string: the same input gives `9007199254740993` (probe).
- An exact key match is preferred over a case-insensitive match when decoding a struct (https://pkg.go.dev/encoding/json, Unmarshal).
- With `Decoder.DisallowUnknownFields`, the decoder returns an error for keys that match no exported field of the struct. Without it, unknown keys are ignored (https://pkg.go.dev/encoding/json).
- `omitempty` omits a field whose value is `false`, `0`, a nil pointer, a nil interface, or an array, slice, map or string of length zero (https://pkg.go.dev/encoding/json).

## Errors and panics

- `errors.As` panics when its target is not a non-nil pointer (https://pkg.go.dev/errors).
- Sending on a closed channel panics; so do closing a closed channel and closing a nil channel (https://go.dev/ref/spec).
- A panic in a handler is recovered by `net/http`: the server logs a stack trace and closes the connection, or sends an HTTP/2 `RST_STREAM`. `http.ErrAbortHandler` aborts without the log (https://pkg.go.dev/net/http).

## Concurrency

- `main` returning ends the program. It does not wait for other goroutines (https://go.dev/ref/spec, Program execution).
- A value written by one goroutine and read by another without synchronization can be a data race that the output does not show. When `go test -race` finds one, it prints a report (https://go.dev/doc/articles/race_detector).
- `sort.Slice` does not keep equal elements in order (https://pkg.go.dev/sort).

## Exit, I/O and HTTP

- `os.Exit` ends the program at once; deferred functions are not run (https://pkg.go.dev/os).
- The caller must close the body of an HTTP response (https://pkg.go.dev/net/http, Response).
- `http.DefaultClient` is `&Client{}`, and a `Client` with `Timeout` zero means no timeout (https://pkg.go.dev/net/http).
- `ReadHeaderTimeout` set to zero means no timeout when `ReadTimeout` is also zero or negative (https://pkg.go.dev/net/http, Server).
