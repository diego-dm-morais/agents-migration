Read this when a migrated unit has SFC components, Composition API logic, routes, or shared stores. Each fact cites its official page.

# SFC, Composition API, Router and Pinia (Vue 3)

## Single-file components

- An SFC is a `.vue` file with a `<template>`, a `<script>` or `<script setup>` block, and an optional `<style>` block (https://vuejs.org/guide/essentials/component-basics.html; https://vuejs.org/guide/scaling-up/sfc.html).
- `<script setup>` makes imported components available to the template without registration, and declares props and emits with `defineProps` and `defineEmits` (https://vuejs.org/guide/essentials/component-basics.html).
- `defineProps` also returns an object with all passed props; by default any value can be passed to any prop (same page).
- A child emits with `$emit('event-name', payload)` or `emit` from `defineEmits`; the parent listens with `@event-name` (same page).
- `<style scoped>` applies CSS to the component's elements only, using a `data-v-xxxx` attribute (https://vuejs.org/api/sfc-css-features.html).
- `<style module>` exposes hashed classes under `$style`, or under a custom key set by the `module` attribute; `useCssModule` reads them in `<script setup>` (same page).

## Composition API

- `ref(value)` returns a ref object with `.value`; `reactive(object)` returns a Proxy of an object type only (https://vuejs.org/guide/essentials/reactivity-fundamentals.html).
- `computed(getter)` is cached on its reactive dependencies. A writable computed takes `{ get, set }` (https://vuejs.org/guide/essentials/computed.html).
- `watch(source, callback, options)` takes a ref, reactive object, getter or array of sources. Options include `immediate` and `deep`. It is lazy by default (https://vuejs.org/guide/essentials/watchers.html).
- `watchEffect(fn)` runs at once and tracks synchronous reads (same page).
- A composable is a `use`-prefixed function that returns refs. It may call `onMounted` and `onUnmounted` to set up and tear down effects (https://vuejs.org/guide/reusability/composables.html).
- Options API: `data`, `computed`, `methods`, `watch`, lifecycle hooks. It is supported in Vue 3. The docs recommend the Composition API with SFCs for full applications (https://vuejs.org/guide/introduction.html).

### Mapping the Options API

| Options API | Composition API |
|---|---|
| `data()` | `ref()` or `reactive()` in `setup` |
| `computed` | `computed()` |
| `methods` | plain functions |
| `watch` | `watch()` |
| `mounted`, `unmounted` | `onMounted`, `onUnmounted` |

- The mapping is a shape guide. Check `this` uses and the order of lifecycle hooks against the source's own code before writing the target.

## Vue Router

- Routes are declared with `createRouter`; navigation uses `router.push`, and `<router-link>` is the equivalent of `router.push(...)` (https://router.vuejs.org/guide/essentials/navigation.html).
- `params` are ignored when `path` is provided. Non-string values are stringified (same page).
- Navigation methods return a Promise that resolves when navigation finishes (same page).
- Global guards: `beforeEach` runs in creation order on each navigation (https://router.vuejs.org/guide/advanced/navigation-guards.html).
- Per-route `beforeEnter` runs only on entering the route from a different one.
- In-component guards: `beforeRouteEnter` (no `this`), `beforeRouteUpdate`, `beforeRouteLeave`.
- Return values: `false` cancels; a route location redirects; `undefined` or `true` accepts.
- The third argument `next` is still supported, and "you must call `next` exactly once" in a pass through a guard (same page).

## Pinia

- `defineStore(id, setupOrOptions)`: the id must be unique across the application (https://pinia.vuejs.org/core-concepts/).
- Option stores: `state`, `getters` and `actions`. Setup stores: `ref()` becomes state, `computed()` becomes a getter, a function becomes an action (same page).
- `storeToRefs(store)` keeps reactivity when state or getters are extracted. Destructuring the store directly breaks reactivity (same page).
- Testing: `createTestingPinia()` from `@pinia/testing` (https://pinia.vuejs.org/cookbook/testing.html).

## Parity checklist for UI units

- List each source screen state (loading, empty, error, loaded) and write one test per state.
- List each source event and its payload; keep names and payload shapes.
- Check route guards against the source's access rule, including the case where only params change.
- Check each store read in a component uses `storeToRefs` for state and getters.
- Check each `v-for` uses a key the source would use to keep row state.
- Check `<style scoped>` against the source's styling: child components need `:deep()` if the source styles them from the parent.
