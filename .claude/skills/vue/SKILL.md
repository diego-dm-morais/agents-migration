---
name: vue
description: "Vue 3 for UI code: single-file components (SFC) with script setup, Composition API (ref, reactive, computed, watch, watchEffect, composables), Vue Router navigation and guards, Pinia stores, and tests with Vitest and Vue Test Utils. Use for .vue files, Vue components, router and store code, or migrations of a UI to or from Vue."
metadata:
  baseline: "Vue 3 (current minor not verified offline: check npm before use); Vue Router, Pinia, Vitest and @vue/test-utils versions not verified offline: read the project lockfile"
  verified: "2026-10-30"
---

# vue (Vue 3, Composition API)

Practice for Vue 3 code, used when Vue is the source or the target of a migration of a UI. The baseline is Vue 3 with the Composition API and single-file components. Facts were checked against the official Vue, Vue Router, Pinia, Vue Test Utils and Vitest pages on 2026-10-30. No Vue toolchain was installed on the machine where this skill was written, so no gate command was run. Every claim cites its official URL; a detail that was not verified is marked "not verified offline". Sources are listed at the end.

## 1. Scope and versions

- Vue 3 is the baseline. The Vue 3 release page (https://vuejs.org/about/releases.html) did not show the current stable version when read in this run ("Checking latest version..."). Verify the current minor version with `npm view vue version` before use, and record it in the report.
- The release page states the policy: minor releases add features, typically 3 to 6 months apart, and go through a beta phase (https://vuejs.org/about/releases.html).
- Target the versions the project pins in `package.json` and its lockfile. Record Vue, Vue Router, Pinia, Vitest and @vue/test-utils versions in the report.
- Vitest requires Vite 6.4.0 or later and Node 22.12.0 or later (https://vitest.dev/guide/). Check these against the project's pins.
- Vue 2 is a different major version with its own end of life. This skill covers Vue 3 only. Vue 2 reached end of life on December 31, 2023 (https://v2.vuejs.org/eol/).

## 2. Layout and build

- A single-file component (SFC) is a `.vue` file that holds a `<template>`, a `<script>` or `<script setup>` block, and an optional `<style>` block. The docs say that with a build step, components are "typically" defined in a dedicated `.vue` file (https://vuejs.org/guide/essentials/component-basics.html; https://vuejs.org/guide/scaling-up/sfc.html).
- Use `<script setup>`: the docs present it as the main form. Imported components are available to the template without registration. `defineProps` and `defineEmits` are compile-time macros that need no import (https://vuejs.org/guide/essentials/component-basics.html).
- Use `<style scoped>` to limit CSS to one component. Scoped CSS is applied with a `data-v-xxxx` attribute added to the component's elements. The parent's scoped styles do not leak into child components, but a child's root node is affected by both (https://vuejs.org/api/sfc-css-features.html).
- Tests live beside the code or in `test/`. Each test file name ends in `.spec.ts` or `.test.ts` in the usual layout. The Vitest default include pattern is `['**/*.{test,spec}.?(c|m)[jt]s?(x)']` (https://vitest.dev/config/include).
- Split by responsibility: pure TypeScript or JavaScript logic in composables and plain modules that read no clock and touch no DOM; stores for shared state; components that show state and emit events. Tests import the pure modules.
- Keep the target's folder layout and route names in the plan. Do not invent a router path or store id.

## 3. Idioms

- Declare reactive state with `ref()`. `reactive()` works only on object types and returns a Proxy. Destructuring a reactive object loses reactivity: "Not destructure-friendly" (https://vuejs.org/guide/essentials/reactivity-fundamentals.html). Use `ref()` as the primary API, as the docs recommend.
- Use `.value` in script code. Refs are unwrapped in templates when they are top-level properties of the render context (https://vuejs.org/guide/essentials/reactivity-fundamentals.html).
- Use `computed()` for derived values. Computed values "are cached based on their reactive dependencies" and getters "should only perform pure computation and be free of side effects" (https://vuejs.org/guide/essentials/computed.html).
- Use `watch()` for side effects that follow one or more sources. It is lazy by default. Its sources can be a ref, a reactive object, a getter function, or an array. It is shallow by default, so use `{ deep: true }` for nested changes. `{ immediate: true }` runs it once at setup (https://vuejs.org/guide/essentials/watchers.html).
- `watchEffect()` tracks its dependencies automatically during its synchronous run, and runs immediately. Dependencies read after the first `await` are not tracked (https://vuejs.org/guide/essentials/watchers.html).
- Put reusable stateful logic in a composable: a `use`-prefixed function that returns "a plain, non-reactive object containing multiple refs" so the caller can destructure it (https://vuejs.org/guide/reusability/composables.html).
- Parse input that may be invalid with an explicit check. The Vue docs do not define a parse helper: use the language's own function (`Number.parseInt`, `Number.isNaN`) and keep the source's rejection path.
- Options API is a legacy-style form. Vue 3 still supports it: the docs state that "both API styles are fully capable of covering common use cases", and recommend the Options API for low-complexity work without build tools and the Composition API with SFCs for full applications (https://vuejs.org/guide/introduction.html). When the source uses the Options API, map `data` to `ref`, `computed` to `computed`, `methods` to functions and `watch` to `watch` (see references/sfc-composition-router-pinia.md).

```vue
<script setup lang="ts">
import { ref, computed } from 'vue'

const count = ref(0)
const doubled = computed(() => count.value * 2)
</script>

<template>
  <button @click="count++">{{ count }} / {{ doubled }}</button>
</template>
```

- Props flow down and events flow up. Declare emitted events with `defineEmits`; the docs say this "documents all the events that a component emits" (https://vuejs.org/guide/essentials/component-basics.html).
- Render functions and JSX are available. The docs say "Vue recommends using templates to build applications in the vast majority of cases", and that the Vue JSX transform "is different from React's JSX transform" (https://vuejs.org/guide/extras/render-function.html).

## 4. Errors, side effects and cleanup

- A computed getter must not mutate state, make async requests, or mutate the DOM (https://vuejs.org/guide/essentials/computed.html). Move those into `watch` or an event handler.
- `onMounted` and `onUnmounted` (and the other lifecycle hooks) set up and tear down side effects, as the `useMouse` example shows (https://vuejs.org/guide/reusability/composables.html). Remove event listeners in the unmount hook.
- Navigation guards that return `false` cancel the navigation; a location redirects; `undefined` or `true` accepts it (https://router.vuejs.org/guide/advanced/navigation-guards.html).
- Map each source error to one error model. Keep the source's message when it is observable.

## 5. Reactivity and concurrency

- The Vue scheduler batches DOM updates: "Vue buffers them until the 'next tick'" (https://vuejs.org/api/general.html). Watchers run before component rendering by default, and `flush: 'post'` defers them until after rendering (https://vuejs.org/api/reactivity-core.html). Use `nextTick` from `vue` only when a test or the source requires a DOM read after a change; it "can be used immediately after a state change to wait for the DOM updates to complete" (https://vuejs.org/api/general.html).
- `watchEffect` with an async callback tracks only the dependencies read before the first `await` (https://vuejs.org/guide/essentials/watchers.html).
- A store action that awaits a request must check whether the result is still wanted before it writes state the source would not write. The source's behavior decides.

## 6. Data and parity traps

- Ref unwrapping differs by position: a ref inside a plain object is not unwrapped in a template, but a ref that is the final value of `{{ }}` is unwrapped. A ref in a reactive array is not unwrapped on access (https://vuejs.org/guide/essentials/reactivity-fundamentals.html).
- `reactive()` on a primitive does not work (https://vuejs.org/guide/essentials/reactivity-fundamentals.html).
- A `reactive()` object cannot be replaced as a whole; keep the same reference (same page).
- `watch(obj.count, ...)` on a reactive property does not work; use a getter: `watch(() => obj.count, ...)` (https://vuejs.org/guide/essentials/watchers.html).
- A router `beforeEnter` guard fires only when entering a route from a different one, not when only params, query or hash change (https://router.vuejs.org/guide/advanced/navigation-guards.html).
- Pinia: destructuring a store loses reactivity. Use `storeToRefs()` for state and getters; actions can be destructured directly (https://pinia.vuejs.org/core-concepts/).

## 7. Testing

- Runner: Vitest. "To run tests once without watching for file changes, use `vitest run`" (https://vitest.dev/guide/). Vitest is "powered by Vite" and reads `vite.config.*` by default (same page).
- Component tests use Vue Test Utils (VTU): "a set of utility functions aimed to simplify testing Vue.js components" (https://test-utils.vuejs.org/guide/). Its main method is `mount`. `shallowMount` "behaves exactly like `mount`, but it stubs all child components by default" (https://test-utils.vuejs.org/api/).
- Wrapper methods: `find` "Finds an element and returns a `DOMWrapper`", `text` "Returns the text content of an element", `trigger` "Triggers a DOM event", `setProps` "Updates component props" (https://test-utils.vuejs.org/api/). `global.plugins` installs plugins, and `global.stubs` sets global stubs (same page).
- The Vitest default environment is Node. The `environment` option accepts `'node' | 'jsdom' | 'happy-dom' | 'edge-runtime' | string` and can be set per file with a `@vitest-environment` comment (https://vitest.dev/config/environment). Component tests need `jsdom` or `happy-dom`; the config key is `environment` (https://vitest.dev/config/environment) (see references/testing-and-tooling.md).
- Stores in tests: `createTestingPinia()` from `@pinia/testing` "stubs out all store actions unless told otherwise"; `stubActions: false` runs the real actions (https://pinia.vuejs.org/cookbook/testing.html).
- Name each test with its rule id when there is one, and keep one behavior per test:

```ts
import { describe, it, expect } from 'vitest'

describe('BR-CART-002', () => {
  it('BR-CART-002 sums line totals with the source rounding', () => {
    expect(total([{ price: 2.5, qty: 1 }])).toBe(2.5)
  })
})
```

- Layout, commands and tool choice: references/testing-and-tooling.md.

## 8. Quality gate

Run each command in the project root and report its real output. A gate that did not run is not a pass. No toolchain was installed in this run, so none of these commands was run here.

1. Type check: a project-declared command, for example `vue-tsc --noEmit`. Not verified offline and not in the official pages read: read `package.json` scripts first.
2. Unit and component tests: `npx vitest run`. Pass means every test passes. Read the exit code from the process, not the summary text alone.
3. Build: the project's `build` script (for Vite projects, `vite build`). Not verified offline.
4. Lint and format: the project's configured tool (ESLint, Prettier or Biome). Not verified offline: use the project's scripts.

- Run all gates, even when the first one fails. Report each command, its exit code and the line that decides the result.

## 9. Migrating TO Vue

- Parity beats idiom. Choose an idiom only when inputs, outputs and events stay the same. Otherwise keep the source behavior, and mark the difference `deviation` with its reason and source.
- Map each source construct with references/as-target.md: components, state, computed values, effects, routing, shared stores and styling.
- Write a test for each state transition and each rule before writing the component.
- Record the expected output from the source, not from the Vue target, and compare against it.
- Keep the error model and the source's visible text, including empty states and loading states.

## 10. Migrating FROM Vue

- Read references/as-source.md for the places where Vue behavior hides: ref unwrapping, `reactive` destructuring, watcher timing, `watchEffect` after `await`, scoped CSS, guard timing and store destructuring.
- Read references/sfc-composition-router-pinia.md for the facts behind each trap.
- Cite the source with `path:line` for each rule, and check each Vue behavior it depends on against the official pages listed in the references.

## 11. Anti-patterns

- Reading a `reactive` object's primitive property into a local variable and expecting updates.
- Side effects inside `computed`.
- `watch` on a non-reactive value, or on `obj.prop` instead of a getter.
- Returning a `reactive` object from a composable and destructuring it.
- `v-html` with untrusted input.
- Relying on watcher or DOM update order that the source does not guarantee.
- Options API mixed with `<script setup>` in one component without a reason recorded in the plan.
- Global stores used for state that belongs to one component.
- Router guards that call `next()` more than once.

## Library registry

- Registry: npm, https://www.npmjs.com/. Check the package page, the version, the peer dependencies (`vue`), the license and the last publish.
- Official packages: `vue`, `vue-router`, `pinia`, `@pinia/testing`, `@vue/test-utils`, `vitest`. Check each against the project's pinned `vue` version.
- Pin the version in `package.json` and commit the lockfile.
- Full procedure and evaluation checks: `.claude/skills/migration-conduct/references/library-research.md`.

## Sources

- Vue guide: https://vuejs.org/guide/introduction.html, https://vuejs.org/guide/essentials/component-basics.html, https://vuejs.org/guide/essentials/reactivity-fundamentals.html, https://vuejs.org/guide/essentials/computed.html, https://vuejs.org/guide/essentials/watchers.html, https://vuejs.org/guide/reusability/composables.html, https://vuejs.org/guide/extras/render-function.html, https://vuejs.org/guide/scaling-up/sfc.html
- Vue API: https://vuejs.org/api/sfc-css-features.html, https://vuejs.org/about/releases.html
- Vue Router: https://router.vuejs.org/guide/essentials/navigation.html, https://router.vuejs.org/guide/advanced/navigation-guards.html
- Pinia: https://pinia.vuejs.org/core-concepts/, https://pinia.vuejs.org/cookbook/testing.html
- Vue Test Utils: https://test-utils.vuejs.org/guide/, https://test-utils.vuejs.org/api/
- Vitest: https://vitest.dev/guide/, https://vitest.dev/config/environment
