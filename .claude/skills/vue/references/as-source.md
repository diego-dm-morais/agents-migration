Read this when the source you migrate from is Vue. These are the places where the behavior is easy to miss, because it sits in the reactivity system, the compiler or the router, not in the line you read.

# Reading Vue as the source

## Reactivity

- `ref()` returns an object with a `.value` property. Script code must use `.value`; templates unwrap top-level refs automatically (https://vuejs.org/guide/essentials/reactivity-fundamentals.html).
- A ref inside a plain object is not unwrapped in a template: `{{ object.id + 1 }}` renders `[object Object]1` for `{ id: ref(1) }`. A ref that is the final value of a `{{ }}` tag is unwrapped (same page).
- A ref accessed as a property of a `reactive` object is unwrapped. A ref in a reactive array or `Map` is not (same page).
- `reactive()` returns a Proxy that is not equal to the original object. Mutating the original does not trigger updates (same page).
- `reactive()` cannot hold primitives. Destructuring a primitive property loses reactivity (same page).
- A composable that returns a `reactive` object loses reactivity when the caller destructures it. Refs keep it (https://vuejs.org/guide/reusability/composables.html).

## Computed and watchers

- A computed value is cached and re-evaluates only when a reactive dependency changes (https://vuejs.org/guide/essentials/computed.html). A source that reads a value that is not reactive will not update the computed.
- Side effects inside a computed getter are a defect in the source that the target must keep only if the source relies on them: record it as `known-issue` (same page).
- `watch` is lazy: its callback does not run at setup unless `immediate: true` is set (https://vuejs.org/guide/essentials/watchers.html).
- `watch` is shallow: a nested change does not run the callback unless `deep: true` is set (same page).
- `watchEffect` runs at once and tracks only the reads before its first `await` (same page).
- Watchers run just prior to component rendering by default; `flush: 'post'` runs them after rendering and `flush: 'sync'` runs them immediately on change (https://vuejs.org/api/reactivity-core.html). DOM updates are buffered until the next tick (https://vuejs.org/api/general.html). When a source reads the DOM right after a state change, test that read before writing the target.

## Components and props

- `defineProps` and `defineEmits` are compile-time macros in `<script setup>` (https://vuejs.org/guide/essentials/component-basics.html).
- A prop value can be any type unless the component declares a type (same page).
- Declared emits are not applied as native listeners to the root element; undeclared listeners may fall through to the root (same page). The attribute-inheritance page states that undeclared `v-on` listeners are added to the root element, and that declared props and listeners are "consumed" and not forwarded (https://vuejs.org/guide/components/attrs.html).
- `<style scoped>` adds a `data-v-xxxx` attribute to the component's elements. A child component's root is styled by both the parent's and the child's scoped CSS (https://vuejs.org/api/sfc-css-features.html).
- `:deep()` reaches into child components. Content created with `v-html` is not affected by scoped styles (same page).
- `<style module>` exposes classes under `$style`, hashed to avoid collision (same page).

## Router

- `router.push` pushes a new history entry; `router-link` is "the equivalent of calling `router.push(...)`" (https://router.vuejs.org/guide/essentials/navigation.html).
- `params` are ignored when `path` is given (same page). Non-string params are stringified (same page).
- A `beforeEnter` guard runs only when entering a route from a different route; a change of params, query or hash does not fire it (https://router.vuejs.org/guide/advanced/navigation-guards.html).
- Global `beforeEach` guards run in registration order, and async guards keep the navigation pending until they resolve (same page).
- Guard return values: `false` cancels, a route location redirects, `undefined` or `true` accepts (same page).
- `beforeRouteEnter` inside a component has no `this`, because the component is not created yet (same page).
- The `next` argument of a guard "was a common source of mistakes"; when used, it must be called exactly once per pass (same page).

## Pinia

- A store id is "a unique id of the store across your application" (https://pinia.vuejs.org/core-concepts/).
- Option stores map `state` to `data`, and `getters` to `computed` (same page).
- Setup stores map `ref()` to state, `computed()` to getters, and `function()` to actions (same page).
- Destructuring a store loses reactivity; use `storeToRefs()` for state and getters. Actions can be destructured (same page).

## Testing and build

- Vitest's default environment is Node. Component tests that touch the DOM need `jsdom` or `happy-dom` (https://vitest.dev/config/environment).
- `createTestingPinia()` stubs all actions unless `stubActions: false` is set (https://pinia.vuejs.org/cookbook/testing.html).
- `shallowMount` stubs all child components by default; `mount` does not (https://test-utils.vuejs.org/api/). A source test that assumed one or the other must match it.

## Anything else

- Vue templates are compiled. A template expression that the source evaluates at render time is evaluated at render time in the target too: record the render-time dependencies.
- The Options API is supported in Vue 3 (https://vuejs.org/guide/introduction.html). A source written in it maps to the same behavior, but its `this` and lifecycle order must be checked against the source's own code.
- Cite the source with `path:line` for each rule, and check each Vue behavior it depends on against the official pages in the references.
