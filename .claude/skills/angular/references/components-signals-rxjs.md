Read this when a migrated unit has components, component state, signals, effects or RxJS streams.

# Components, signals and RxJS (Angular v22)

## Signals

- `signal(initial)` creates a writable signal of type `WritableSignal`. Update it with `.set(value)` or `.update(fn)`. Expose a read-only view with `asReadonly()` (https://angular.dev/guide/signals).
- Read a signal by calling it: `count()`.
- `computed(fn)` creates a read-only signal derived from other signals. It is lazy and cached, and assigning to it with `.set()` is a compilation error (https://angular.dev/guide/signals).
- Dependencies of `computed` are dynamic: only the signals read during the derivation are tracked (same page).

```ts
const count = signal(0);
const doubled = computed(() => count() * 2);
count.update((n) => n + 1);
```

## Effects

- `effect(fn)` runs its callback in a reactive context. The page recommends it for side effects on non-reactive APIs (https://angular.dev/guide/signals).
- When a tracked signal changes, Angular "will _eventually_ re-run the consumer". Do not assume a synchronous re-run.
- The reactive context is active for synchronous code only. A signal read after an `await` is not tracked (same page).

## Components

- Component state, inputs and outputs: the Angular component API (https://angular.dev/guide/components). Lifecycle hooks, as the lifecycle page lists them: `constructor`, `ngOnInit`, `ngOnChanges`, `ngDoCheck`, `ngAfterContentInit`, `ngAfterContentChecked`, `ngAfterViewInit`, `ngAfterViewChecked`, `afterNextRender`, `afterEveryRender`, `ngOnDestroy` (https://angular.dev/guide/components/lifecycle).
- Standalone components list their template dependencies in `imports`. "By default, Angular components are _standalone_" (https://angular.dev/guide/components); before Angular 19.0.0 the default was `false`.

## RxJS

- `not verified offline`: an `Observable` is lazy, and teardown runs on `unsubscribe` (https://rxjs.dev/guide/observable). The rxjs.dev page returned only its title when fetched; check the page before citing.
- `not verified offline`: flattening operators (`switchMap` cancels the previous inner subscription; `concatMap` queues; `mergeMap` runs in parallel; `exhaustMap` ignores new values while one runs). The rxjs.dev operator pages returned only their title when fetched; verify the text on https://rxjs.dev/api/operators/switchMap and https://rxjs.dev/api/operators/concatMap before citing.
- In a template, the `async` pipe "subscribes to an Observable or Promise" and "unsubscribes automatically" when the component is destroyed (https://angular.dev/api/common/AsyncPipe).
- `toSignal` (from `@angular/core/rxjs-interop`) returns `Signal<T | undefined>` unless `requireSync: true`, in which case "No `initialValue` is needed" and the type has no `undefined` (https://angular.dev/api/core/rxjs-interop/toSignal).

## Parity checklist for component units

- List each source state transition, and write one test per transition.
- Check the source's behavior when the component is destroyed during a request: cancellation must match.
- Check the order of loading, success and error states in the template.
- Check that a value read before an `await` is not used as if it were fresh.
