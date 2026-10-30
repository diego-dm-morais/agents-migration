Read this when you write tests, set up the quality gate, or choose an Angular tool. Commands were checked against the official pages on 2026-10-30 where the page states them. None was run on the machine that wrote this file.

# Testing and tooling (Angular v22)

## Test runners

- Default for new projects: Vitest with jsdom (https://angular.dev/guide/testing: "New projects include `vitest` and `jsdom` by default").
- Karma is still supported (https://angular.dev/guide/testing: "Karma is still supported"). Use the runner the project already configured in `angular.json`.
- Vitest setup: "This guide uses Vitest, which Angular CLI projects include by default" (https://angular.dev/guide/testing/services).
- `not verified offline`: the Karma setup steps. The pages read did not state them; check https://angular.dev/cli/test and the project's `angular.json` before use.

## Test layout

- Component and service specs sit next to the source file, named `<name>.spec.ts` (convention; `not verified offline`: the pages read show `.spec.ts` names only as code headings, not as a rule. Verify against the project's `angular.json` test glob before use).
- One spec file per component or service. Name each test with its rule id when there is one, for example `BR-UI-001 shows the initial count`.

## TestBed

- `TestBed.configureTestingModule(moduleDef)` returns `TestBed`; `TestBed.createComponent(component)` returns `ComponentFixture<T>` (https://angular.dev/api/core/testing/TestBed).
- `createComponent` "does not trigger change detection synchronously" (https://angular.dev/guide/testing/components-scenarios). Use `await fixture.whenStable()` to wait for change detection, or `fixture.componentRef.setInput(...)` for inputs (same page).
- `not verified offline`: `fixture.detectChanges()`. The components-scenarios page does not name it (it shows `harness.detectChanges()` only), so this call is unconfirmed. The ComponentFixture API page was not fetched in this run; check it on angular.dev before use.
- Provide fakes for services through `providers`. Prefer a hand-written fake first.

```ts
// BR-UI-001 shows the initial count (sketch; the TestBed API is confirmed, detectChanges is not, see above)
it('BR-UI-001 shows the initial count', () => {
  const fixture = TestBed.createComponent(CounterComponent);
  fixture.detectChanges();
  expect(fixture.nativeElement.textContent).toContain('0');
});
```

## Doubles and fakes

- Put each external dependency behind a service the component receives through DI. Write a fake class with the same method names.
- Time: inject a clock; do not call `Date.now()` inside logic under test.

## Commands (check each against `package.json` scripts before use)

| Command | What it does | What passes |
|---|---|---|
| `ng test [project] [options]` (https://angular.dev/cli/test) | runs the unit tests with the configured runner; `runner` is `karma` or `vitest`, default `vitest` | every test passes; exit code 0 |
| `ng build [project] [options]` (https://angular.dev/cli/build) | builds the app with the Angular CLI | the build finishes without error |
| `npx tsc --noEmit -p tsconfig.app.json` | type-checks the app | no error; exit code 0 |

- `not verified offline`: the `ng version` command and the Karma and Vitest options beyond `runner`. Use `ng help test` and `ng test --help` as the source of truth.
- `not verified offline`: the Angular CLI lint setup. No official page was read for it. Use the project's configured lint script.

## Gate

- Run each gate, even when the first one fails. Report each command, its exit code, and the line that decides the result.
- `not verified offline`: coverage. No official page was read for it. Verify before use.
