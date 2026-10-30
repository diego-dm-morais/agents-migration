Read this when a migrated unit has routes, guards, resolvers, reactive forms or template-driven forms.

# Router and forms (Angular v22)

## Router

- Set up routes with `provideRouter(routes)` in the app config, and an optional feature such as `withComponentInputBinding()` (https://angular.dev/guide/routing/common-router-tasks).
- `Routes` is the array type for the route config. Each route has a `path` and a `component` (https://angular.dev/guide/routing/define-routes).
- `<router-outlet />` appears in the examples on https://angular.dev/guide/routing/common-router-tasks. The page's prose does not say what it does, so that role is not confirmed from the page.
- Navigation links use `RouterLink` with a link array (same page).
- Guards: https://angular.dev/guide/routing lists "Navigation guards" and links to "Control route access with guards". `not verified offline`: the guard API (`canActivate`, functional guards). The page read did not name it; check the guard guide on angular.dev before use.
- Resolvers: "Fetch data before route activation using resolver functions" (https://angular.dev/guide/routing/define-routes). A title resolver is typed with `ResolveFn`, for example `const titleResolver: ResolveFn<string> = (route) => ...` (same page).
- Lazy loading: `loadComponent: () => import('./...')` and `loadChildren: () => import('./...')` (https://angular.dev/guide/routing/loading-strategies). `loadComponent` lazily loads a component when its route is active; `loadChildren` lazily loads child routes.

```ts
export const routes: Routes = [
  { path: 'admin', component: AdminPage },
];
```

## Reactive forms

- The form model classes are `FormControl`, `FormGroup` and `FormArray`. `FormBuilder` has `control()`, `group()` and `array()` factory methods (https://angular.dev/guide/forms/reactive-forms).
- The examples import them from `@angular/forms` and add `ReactiveFormsModule` to the component's `imports` (same page).
- `FormControl` corresponds to an input or select; `FormGroup` manages a set of controls; `FormArray` is a numerically indexed array of controls (same page).

## Typed forms

- Since Angular 14, reactive forms are strictly typed by default. This applies to reactive forms, not template-driven ones (https://angular.dev/guide/forms/typed-forms).
- `new FormControl('x')` is inferred as `FormControl<string | null>`. Set the type with `new FormControl<string | null>(null)`.
- `{ nonNullable: true }` makes `reset()` restore the initial value instead of `null`. `FormBuilder.nonNullable` returns a `NonNullableFormBuilder` that applies it to every control it creates (same page).
- `value` omits disabled controls and is typed as `Partial`. `getRawValue()` includes them (same page).

```ts
const name = new FormControl('', { nonNullable: true });
name.reset(); // back to '' rather than null
```

## Template-driven forms

- Template-driven forms "rely on directives defined in the FormsModule", named `NgModel` and `NgForm` (https://angular.dev/guide/forms/template-driven-forms).
- `not verified offline`: the template-driven API details beyond those directive names. That page does not discuss typing.
- They are not typed by the strict typed-forms rule above.

## Parity checklist for route and form units

- Check the route order: "Angular uses a first-match wins strategy" (https://angular.dev/guide/routing/define-routes).
- Check the source's 404 and redirect behavior.
- Check the form reset value and the value sent on submit, including disabled fields.
- Check the validation message text and when each message appears.
- Check the guard and resolver order against the source.
