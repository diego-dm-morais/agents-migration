---
name: angular
description: "Angular v22 (angular.dev) with TypeScript for Angular UI code: components, signals and RxJS, router, reactive and template-driven forms, Vitest or Karma/Jasmine with TestBed, and the build and test gate. Use for Angular components, templates, angular.json, route and form code, or migrations to or from Angular."
metadata:
  baseline: "Angular v22 (angular.dev home page read on 2026-10-30; the version number is stated there, the release notes were not read)"
  verified: "2026-10-30"
---

# angular (Angular v22, TypeScript)

Practice for Angular code, used when Angular is the source or the target of a migration. The baseline is the Angular version the official site shows as current on 2026-10-30 (v22). Facts were checked against angular.dev, rxjs.dev and the pages listed at the end. Where a fact could not be confirmed, the file says `not verified offline` and gives the reason. RxJS facts cite the RxJS 7.8.2 source on unpkg, because the rxjs.dev pages returned only their title. Nothing here was run: no Angular toolchain was installed where this skill was written, so no gate command was run.

## 1. Scope and versions

- The current major version is v22: "Angular v22 is here!" (https://angular.dev/releases). The support table (https://angular.dev/reference/versions) lists Angular `22.0.x`, Node.js `^22.22.3 || ^24.15.0 || ^26.0.0` and TypeScript `>=6.0.0 <6.1.0` for v22.
- Target the version in `package.json` (`@angular/core`). Record it in the report, with the Node.js and TypeScript versions the project runs. If the project declares none, use the baseline and say so.
- Use the target's `angular.json` and `tsconfig.json`. Keep the project's file layout and package name.

## 2. Layout and build

- Source under `src/app/`. Components, services and routes are in their own files. The app entry is `src/main.ts` with a bootstrap call: `bootstrapApplication(rootComponent, options?)` from `@angular/platform-browser` (https://angular.dev/api/platform-browser/bootstrapApplication). The guide https://angular.dev/guide/bootstrapping returned only the home page when fetched, so it is not cited for this fact.
- Standalone components: the `imports` array of each component lists what its template uses (see references/components-signals-rxjs.md). "By default, Angular components are _standalone_" (https://angular.dev/guide/components); before Angular 19.0.0 the default was `false`.
- Build and test commands come from `angular.json` and `package.json` scripts. Use the project's scripts, not invented ones.

## 3. Idioms

- Component state in signals: `signal()`, `computed()`, and `.set()` / `.update()` on writable signals (https://angular.dev/guide/signals). Read signals in templates by calling them: `count()`.
- Side effects in `effect()`. Keep effects for work that the signal graph cannot express. The page says Angular "will _eventually_ re-run the consumer" after a change, so do not rely on a synchronous re-run.
- Async data: RxJS `Observable` with the `async` pipe, or `toSignal` where the project uses signals. `toSignal` is imported from `@angular/core/rxjs-interop` and returns `Signal<T | undefined>` unless `requireSync: true` (https://angular.dev/api/core/rxjs-interop/toSignal). The async pipe "subscribes to an Observable or Promise" and "unsubscribes automatically" when the component is destroyed (https://angular.dev/api/common/AsyncPipe).
- Forms: `FormControl`, `FormGroup`, `FormArray`, with `nonNullable` where the source resets to a default value (references/router-and-forms.md).

## 4. Errors, resources and exit

- An Angular error handler receives uncaught errors: `ErrorHandler` is "a hook for centralized exception handling" with `handleError(error: any): void` (https://angular.dev/api/core/ErrorHandler). Map each source error to one class or code with the source's message.
- Unsubscribe from long-lived streams, or use `takeUntilDestroyed` in an injection context. It is imported from `@angular/core/rxjs-interop` (https://angular.dev/api/core/rxjs-interop/takeUntilDestroyed). The lifecycle guide names `DestroyRef` as "an alternative to the ngOnDestroy method" (https://angular.dev/guide/components/lifecycle).
- Subscriptions and timers that are not cleaned up keep running after the component is destroyed. Test this when the source does cleanup.

## 5. Concurrency and async

- Observables are lazy: "calling `subscribe` is actually the moment when Observable starts its work, not when it is created" (https://unpkg.com/rxjs@7.8.2/src/internal/Observable.ts, doc comment of `subscribe`). Teardown runs on `unsubscribe`: `Subscription.add()` adds "a finalizer to this subscription, so that finalization will be unsubscribed/called", and `unsubscribe()` runs it through `execFinalizer` (https://unpkg.com/rxjs@7.8.2/src/internal/Subscription.ts).
- Flattening operators (RxJS 7.8.2 source doc comments): `switchMap` stops emitting from the earlier inner Observable when a new one arrives (https://unpkg.com/rxjs@7.8.2/src/internal/operators/switchMap.ts); `concatMap` runs "in a serialized fashion waiting for each one to complete before merging the next" (https://unpkg.com/rxjs@7.8.2/src/internal/operators/concatMap.ts); `mergeMap` has `concurrent: number = Infinity`, i.e. inner subscriptions run in parallel by default (https://unpkg.com/rxjs@7.8.2/src/internal/operators/mergeMap.ts); `exhaustMap` "ignores every new projected Observable if the previous projected Observable has not yet completed" (https://unpkg.com/rxjs@7.8.2/src/internal/operators/exhaustMap.ts).
- Change detection without Zone.js: "Angular relies on notifications from core APIs in order to determine when to run change detection and on which views." Angular v21 and later already default to zoneless (https://angular.dev/guide/zoneless).

## 6. Data and numbers (parity traps)

- Angular does not own number formatting. TypeScript `number` is an IEEE 754 double (the JavaScript rule; cite the ECMAScript spec or MDN when a claim depends on it).
- Locale formatting goes through `DatePipe`, `DecimalPipe` or the `Intl` API. `DecimalPipe` rounds a truncated value "using the 'to-nearest' method" and uses `LOCALE_ID` when no locale is given, which is `en-US` by default (https://angular.dev/api/common/DecimalPipe). `DatePipe` uses `LOCALE_ID` the same way; without `DATE_PIPE_DEFAULT_OPTIONS`, the timezone is "the end-user's local system timezone" (https://angular.dev/api/common/DatePipe).
- Dates: `Date` objects are local time unless the source stores UTC. Record which one the source uses.

## 7. Testing

- Default test runner for new projects: Vitest with jsdom. The testing page says "New projects include `vitest` and `jsdom` by default" (https://angular.dev/guide/testing). "Karma is still supported" (same page). The Jasmine assertion style of the Karma setup is named only in a navigation link on that page ("Testing with Karma and Jasmine").
- TestBed: `TestBed.configureTestingModule(moduleDef)` returns `TestBed`; `TestBed.createComponent(component)` returns `ComponentFixture<T>` (https://angular.dev/api/core/testing/TestBed). `createComponent` "does not trigger change detection synchronously" (https://angular.dev/guide/testing/components-scenarios). `fixture.detectChanges()` is documented as "Trigger a change detection cycle for the component" (https://angular.dev/api/core/testing/ComponentFixture).
- Name each test with its rule id when there is one, and keep one behavior per test. Test state transitions, not only the final render.
- Details: references/testing-and-tooling.md.

## 8. Quality gate

Run each command in the project root and report its real output. A gate that did not run is not a pass. No toolchain was run here.

1. The project's type check: `npx tsc --noEmit -p tsconfig.app.json` (verify the tsconfig file name in the project).
2. The project's build: `ng build [project] [options]` (https://angular.dev/cli/build). The `ng version` command is `not verified offline`: check `ng help` before citing it.
3. The project's tests: `ng test [project] [options]` (https://angular.dev/cli/test). The `runner` option accepts `karma` or `vitest` and defaults to `vitest`. Report pass or fail, the count and the exit code.

- Run all three even when the first one fails, and report each command, its exit code and the line that decides the result.
- `not verified offline`: the Angular CLI lint setup. No official page was read for it. Use the project's configured lint command only.

## 9. Migrating TO Angular

- Parity beats idiom. Choose an Angular idiom only when inputs, outputs and visible behavior stay the same. Otherwise keep the source behavior and mark the difference `deviation` with its reason and source.
- Map each source construct with references/as-target.md: components, state, events, forms, routes, HTTP, and error display.
- Write a test for each state transition and each validation rule before writing the component.
- Record the expected output from the source, not from the Angular target.

## 10. Migrating FROM Angular

- Read references/as-source.md for the places where Angular behavior hides: change detection timing, lazy subscriptions, `switchMap` cancellation, form reset values, route guards and resolvers, and template expressions.
- Read references/components-signals-rxjs.md and references/router-and-forms.md for the facts behind each trap.
- Cite the source with `path:line` for each rule, and check each Angular behavior it depends on against the official pages listed in references.

## 11. Anti-patterns

- Writing to a signal inside a `computed()`.
- Subscribing in a component and never unsubscribing when the source cleans up.
- `switchMap` where the source processes every request in order (use `concatMap`).
- Relying on a synchronous effect re-run after a signal write.
- `FormControl` without `nonNullable` where the source resets to a default value (reset gives `null`).
- Using `any` on form values to skip the typed forms check.
- Hard-coding route paths in templates instead of the router API the project already uses.

## Library registry

- Registry: npm, https://www.npmjs.com/. Check the Angular peer dependency, the supported Angular version range and the license before adding a package.
- Pin the version in `package.json` and commit the lockfile. Use the project's package manager.
- Full procedure: `.claude/skills/migration-conduct/references/library-research.md`.

## Sources

- Versions and releases: https://angular.dev/releases, https://angular.dev/reference/versions (fetched 2026-10-30)
- Signals: https://angular.dev/guide/signals
- Components and bootstrap: https://angular.dev/guide/components, https://angular.dev/guide/components/lifecycle, https://angular.dev/api/platform-browser/bootstrapApplication
- Forms: https://angular.dev/guide/forms/typed-forms, https://angular.dev/guide/forms/template-driven-forms
- Routing: https://angular.dev/guide/routing/common-router-tasks, https://angular.dev/guide/routing/define-routes, https://angular.dev/guide/routing/loading-strategies, https://angular.dev/guide/routing
- Testing: https://angular.dev/guide/testing, https://angular.dev/guide/testing/components-scenarios, https://angular.dev/api/core/testing/TestBed
- RxJS interop and pipes: https://angular.dev/api/core/rxjs-interop/toSignal, https://angular.dev/api/core/rxjs-interop/takeUntilDestroyed, https://angular.dev/api/common/AsyncPipe, https://angular.dev/api/common/DecimalPipe, https://angular.dev/api/common/DatePipe, https://angular.dev/api/core/ErrorHandler
- Zoneless: https://angular.dev/guide/zoneless
- RxJS 7.8.2 source (fetched bodies): https://unpkg.com/rxjs@7.8.2/src/internal/Observable.ts, https://unpkg.com/rxjs@7.8.2/src/internal/Subscription.ts, https://unpkg.com/rxjs@7.8.2/src/internal/operators/switchMap.ts, https://unpkg.com/rxjs@7.8.2/src/internal/operators/concatMap.ts, https://unpkg.com/rxjs@7.8.2/src/internal/operators/mergeMap.ts, https://unpkg.com/rxjs@7.8.2/src/internal/operators/exhaustMap.ts
- Tooling: https://angular.dev/cli/build, https://angular.dev/cli/test
