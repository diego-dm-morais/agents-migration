Read this when you map a source construct to Go code. The left column is the concept; the middle column is the Go idiom; the right column is the risk to test. Choose the idiom only when inputs, outputs and errors stay the same. Otherwise keep the source behavior and mark the difference.

# Writing Go as the target

| Concept | Idiom in this language | Parity risk to test |
|---|---|---|
| Integer division and remainder | `/` and `%` on signed integers | sign of the result for negative operands: `-7/2` is `-3`, `-7%2` is `-1` |
| Fixed-width integers | `int64`, `uint32` and so on, with an explicit range check before the operation | silent wrap: an `int8` holding 127 plus 1 is -128 |
| Money | `int64` minor units with a range check; or `math/big` `Rat` with a fixed scale | every tie; the scale of the output; negative values |
| Rounding half away from zero | `math.Round` | `math.Round(-2.5)` is `-3` and `math.Round(2.5)` is `3`; test both directions |
| Rounding half to even | `math.RoundToEven` | `math.RoundToEven(2.5)` is `2`; differs from `math.Round` on every tie |
| Fixed decimal text | `strconv.FormatFloat(x, 'f', d, 64)` or `fmt.Sprintf("%.2f", x)` | tie rule on exact binary halves (probe: `"%.0f"` of `2.5` is `"2"`); `1.005` gives `"1.00"` |
| Text length | `len(s)` counts bytes; `utf8.RuneCountInString` counts runes | byte and rune counts differ on non-ASCII text |
| Text building | `strings.Builder` | output order of concatenated parts |
| Bytes and text | `[]byte(s)` and `string(b)` | invalid UTF-8: `range` over a string yields `0xFFFD` for each bad byte and advances one byte |
| String order | `<` on strings, or `slices.Sort` | comparison is byte-wise: `"é"` sorts after `"z"`; the source's collation may differ |
| Date and time | `time.Date`, `time.Parse` and `Format` with the reference layout `2006-01-02 15:04:05` | `2006-02-01` is the wrong order and `go vet` reports it; source tokens such as `YYYY` print literally |
| Time zone | `time.UTC`, or a `*time.Location` from `time.LoadLocation` | `time.Local` consults `TZ` on Unix systems only (https://pkg.go.dev/time); on Windows the probe showed `TZ` had no effect; output differs between machines |
| Instant comparison | `t.Equal(u)` | `==` on `time.Time` compares more than the instant |
| Map or dictionary | `map[K]V`; sort the keys before writing output | iteration order is not specified; output order must come from a sort |
| Ordered collection | `slices.Sort`, `slices.SortStableFunc`, `sort.SliceStable` | `sort.Slice` is not stable; equal elements may swap places |
| Optional value | zero value with an `ok` result, or a pointer | a nil pointer stored in an `error` or `any` is not nil |
| Nullable JSON field | a pointer field `*T` with `omitempty` where the source omits the field | JSON `null`, an omitted key and the zero value are three different outputs; `omitempty` also drops `0`, `false` and `""` |
| Exact JSON number | `json.Decoder` with `UseNumber`, or a typed field such as `int64` | default `float64` loses integers above 2^53 - 1 |
| JSON map output | `map[string]T` marshalled by `encoding/json` | keys are written in sorted order; a nil slice encodes as `null` |
| Error with cause | `fmt.Errorf("...: %w", err)` | the text of the message; `errors.Is` matches the chain, a string comparison does not |
| Sentinel error | `var ErrX = errors.New("...")` and `errors.Is` | a source that compares message text instead of the error kind |
| Exception or panic in the source | return an `error`; recover only at a boundary | where the source stops; a panic is not an expected error |
| Exit status | return from `main`; `os.Exit(n)` only in `main` | deferred cleanup does not run on `os.Exit` |
| HTTP client call | `http.NewRequestWithContext` and an `http.Client` with `Timeout` set | `http.DefaultClient` has no timeout; a body that is not closed keeps the connection |
| HTTP server handler | an `http.Handler` that writes through `http.ResponseWriter` | a panic in a handler is recovered by net/http, which logs it and closes the connection or resets the stream |
| Fan-out work | goroutines, a `sync.WaitGroup`, and results written to a slice by index | result order; first error versus all errors |
| Cancellation | `context.WithTimeout` or `context.WithCancelCause` with `defer cancel()` | the timeout error text; the cause reported by `context.Cause` |
