Read this when you map a source construct to Angular code. The left column is the concept; the middle column is the Angular idiom; the right column is the risk to test. Facts are cited in references/components-signals-rxjs.md and references/router-and-forms.md.

# Writing Angular as the target

| Concept | Idiom in this framework | Parity risk to test |
|---|---|---|
| Screen state | `signal()` with `.set()` / `.update()`; read in template as `s()` | a write that the source makes visible only after a request completes |
| Derived value | `computed()`, read-only and cached | a `computed` that must not write; a stale value when the source recalculates on every read |
| Side effect on change | `effect()` | the re-run is eventually, not synchronous; a write the source does at once |
| Async request | RxJS `Observable`, `async` pipe or `toSignal` | cancellation on re-request (`switchMap` vs `concatMap`); the loading and error states |
| Form field | `FormControl` with `nonNullable` when the source resets to a default | `reset()` gives `null` unless `nonNullable: true` |
| Form group | `FormGroup`, `FormBuilder` or `NonNullableFormBuilder` | disabled controls: `value` omits them, `getRawValue()` includes them |
| Dynamic list of fields | `FormArray` | order of controls after add or remove |
| Validation message | a validator and a template that reads its error key | the source's message text and when it appears |
| Route | `Routes` array with `path` and `component` | matching order of the routes; the source's 404 behavior |
| Route data before render | a resolver (`resolve`) | the source's behavior when the data call fails |
| Route guard | a functional guard (`canActivate`) | the redirect target and the source's order of checks |
| Lazy part of the app | `loadComponent` or `loadChildren` with `import()` (https://angular.dev/guide/routing/loading-strategies) | the first-load delay; the error when a chunk fails to load |
| Navigation link | `RouterLink` in the template | a link that the source builds as a plain string |
| Error display | the source's message in the template, from the same error class | a message that the Angular error handler replaces |
| Date and number text | `DatePipe`, `DecimalPipe`, or `Intl` with an explicit locale | the locale and the rounding of the pipe: `DecimalPipe` rounds "to-nearest" and defaults to `LOCALE_ID` `en-US` (https://angular.dev/api/common/DecimalPipe); `DatePipe` falls back to the local system timezone (https://angular.dev/api/common/DatePipe) |
| Unit of UI behavior | a component test with TestBed | the test must use the component's public input and output, not internals |
| Destroy and cleanup | unsubscribe or `takeUntilDestroyed` from `@angular/core/rxjs-interop` (https://angular.dev/api/core/rxjs-interop/takeUntilDestroyed) | a timer or subscription that keeps running after the screen is gone |
