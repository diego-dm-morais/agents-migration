Read this when the source returns failures as values, raises exceptions, reports status codes, or calls or serves HTTP. Facts are for the Go 1.26 line, checked on 2026-10-29.

# Errors, panics and HTTP in Go

## Error values

- The predeclared type `error` is `interface { Error() string }` (https://go.dev/ref/spec, Errors).
- `errors.New(text)` returns an error that formats as the text. Each call returns a distinct value even when the text is identical, so compare a sentinel with `errors.Is`, not with the text (https://pkg.go.dev/errors).
- `fmt.Errorf` with one `%w` wraps that error. With several `%w` verbs the result has `Unwrap() []error` that returns all of them (https://pkg.go.dev/fmt).
- `errors.Unwrap` returns the result of the `Unwrap` method of `err`, if its type has one, and nil otherwise (https://pkg.go.dev/errors).
- `errors.Join(errs...)` returns an error that wraps the non-nil errors. It returns nil when every value is nil (https://pkg.go.dev/errors).

## Matching errors

- `errors.Is(err, target)` reports whether any error in `err`'s tree matches `target`. The target must be comparable (https://pkg.go.dev/errors).
- `errors.As(err, target)` finds the first error in `err`'s tree that matches `target`, sets `target` to it and returns true; otherwise it returns false. It panics if `target` is not a non-nil pointer to a type that implements `error` or to an interface type (https://pkg.go.dev/errors).
- `errors.AsType[E error](err)` is the generic form. It returns the first error in the tree that matches `E` and reports whether one was found (https://pkg.go.dev/errors; go1.26.0).
- A source that branches on the message text needs the same text in Go, and the branch must stay on the same kind. Test the text and the kind separately.

## Messages

- Error strings are not capitalized and do not end with punctuation, because callers print them inside other messages (https://go.dev/wiki/CodeReviewComments, Error Strings).
- The parity rule wins: copy the source's message exactly, even when it breaks this convention. Record the difference when the text changes.

## Panics

- Do not use `panic` for normal error handling. Return an error (https://go.dev/wiki/CodeReviewComments, Don't Panic; https://go.dev/doc/effective_go).
- Map each source exception to a returned error, not to a panic, unless the source itself panics (practice).
- `os.Exit` ends the program without running deferred functions (https://pkg.go.dev/os). A `main` that returns lets its defers run.

## HTTP client

- `http.DefaultClient` is `&Client{}`. Its `Get`, `Head` and `Post` functions use it (https://pkg.go.dev/net/http).
- `Client.Timeout` is the time limit for a request made by the client. A zero `Timeout` means no timeout (https://pkg.go.dev/net/http).
- `http.NewRequestWithContext(ctx, method, url, body)` builds a request that the context can cancel (https://pkg.go.dev/net/http).
- The caller must close the response body. The Go client does not close it for you (https://pkg.go.dev/net/http, Response).
- A source timeout maps to a `Client.Timeout`, a context deadline, or both. Test the error the caller sees for each case.

## HTTP server

- A `Handler` has the method `ServeHTTP(ResponseWriter, *Request)`. It writes headers and data to the `ResponseWriter` and then returns. Using the writer or reading the body after `ServeHTTP` returns is not valid (https://pkg.go.dev/net/http).
- Read the request body before you write the response, when the client may not allow a read after a write (https://pkg.go.dev/net/http).
- A panic in `ServeHTTP` is recovered by the server. The server logs a stack trace and closes the connection, or sends an HTTP/2 `RST_STREAM`. Panicking with `http.ErrAbortHandler` aborts the response without the log (https://pkg.go.dev/net/http).
- `Server.ReadTimeout` set to zero or a negative value means no timeout for reading the whole request. `ReadHeaderTimeout` set to a negative value, or to zero while `ReadTimeout` is zero or negative, means no timeout (https://pkg.go.dev/net/http, Server).
- Test handlers with `httptest.NewRecorder` for a single call, and with `httptest.NewServer`, which starts a server that the caller closes when finished (https://pkg.go.dev/net/http/httptest).

## Status codes and bodies

- The source decides the status code and the body of each failure. Copy them from the source. If the source does not define a status for a failure, for example an unhandled exception, record it as a gap; do not pick a default from this skill.
- Keep the body text and the field names of the source's error response. A change in any of them is a parity break.
- Do not add a status code or a header the source does not send. Note the difference if one is needed.
