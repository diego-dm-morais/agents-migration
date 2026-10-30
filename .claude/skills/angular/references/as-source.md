Read this when the source you migrate from is Angular. These are the places where the behavior is easy to miss, because it sits in the framework runtime, not in the line you read.

# Reading Angular as the source

## Change detection and signals

- A signal write does not run the template at once. Angular re-runs the consumer "eventually" (https://angular.dev/guide/signals). A source that reads the DOM right after a write sees the old value.
- `computed()` "does not run to calculate its value until the first time you read" it, and its value is cached (https://angular.dev/guide/signals). A source that expects every read to recompute differs when the input is unchanged.
- Assigning to a `computed()` with `.set()` is a compilation error (same page). A source that compiles has no such write.
- "you might find yourself needing a writable state that is dependent on other signals": the page points to `linkedSignal` for it (https://angular.dev/guide/signals). `not verified offline`: the `linkedSignal` API details.
- The reactive context is "only active for synchronous code": a signal read after an `await` is not tracked (https://angular.dev/guide/signals).

## RxJS

- `not verified offline`: observables are lazy (nothing runs until `subscribe`) (https://rxjs.dev/guide/observable). The rxjs.dev pages returned only their title when fetched; check the page directly before citing.
- `not verified offline`: flattening operators differ (`switchMap`, `concatMap`, `mergeMap`, `exhaustMap`). A source that fires each request and keeps every reply differs from one that uses `switchMap`. Verify the semantics on https://rxjs.dev/api/operators/switchMap and https://rxjs.dev/api/operators/concatMap before citing.

## Forms

- Since Angular 14, reactive forms are strictly typed by default (https://angular.dev/guide/forms/typed-forms). Template-driven forms are not typed this way.
- `reset()` on a control sets `null` unless the control was created with `nonNullable: true`. With that option, `reset()` restores the initial value (same page).
- `form.value` omits disabled controls and is typed as `Partial`. `getRawValue()` includes them (same page). A source that sends `value` to the server drops disabled fields.

## Routing

- Route order matters: "Angular uses a first-match wins strategy" (https://angular.dev/guide/routing/define-routes).
- Resolvers fetch data "before route activation" (https://angular.dev/guide/routing/define-routes). A source that renders the screen first and loads after differs in the visible order.
- `withComponentInputBinding()` binds route params and resolver data to component inputs, and the page states that resolver data has a priority order (https://angular.dev/guide/routing/common-router-tasks).

## Testing

- The default runner for new projects is Vitest with jsdom. Karma is still supported (https://angular.dev/guide/testing). A source test suite on Karma and Jasmine has different timing and hooks.

## Template and event timing

- Template expressions run on each change detection pass. A source expression with a side effect runs more often than a single call would suggest. Record the number of calls the source makes, from the code, not from memory.
- Event handler order and the value of `$event` are the source's observable behavior; keep them.

## Version

- The source's Angular version is in `package.json` (`@angular/core`). Behavior differs between versions; cite the version used in the source for each rule.
