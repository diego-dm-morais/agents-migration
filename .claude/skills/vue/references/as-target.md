Read this when you map a source construct to Vue code. The left column is the concept; the middle column is the Vue idiom; the right column is the risk to test. Each idiom cites the page it comes from.

# Writing Vue as the target

| Concept | Idiom in this framework | Parity risk to test |
|---|---|---|
| Component | SFC with `<script setup>` (https://vuejs.org/guide/essentials/component-basics.html) | the source's props and emitted events keep their names and payloads |
| Local state | `ref()`, read and written through `.value` in script (https://vuejs.org/guide/essentials/reactivity-fundamentals.html) | a ref inside a plain object is not unwrapped in templates |
| Object state | `ref()` for the object; `reactive()` only for objects that are never replaced | `reactive()` on a primitive does not work; destructuring loses reactivity |
| Derived value | `computed()` (https://vuejs.org/guide/essentials/computed.html) | a getter with a side effect; the source's value at each read |
| Side effect on change | `watch()` with an explicit source; `{ deep: true }` for nested data (https://vuejs.org/guide/essentials/watchers.html) | `watch` is lazy and shallow by default; the source's callback order |
| Run at setup and on change | `watch(..., { immediate: true })` or `watchEffect()` | `watchEffect` tracks only reads before its first `await` |
| Reusable stateful logic | composable returning an object of refs (https://vuejs.org/guide/reusability/composables.html) | returning a `reactive` object breaks destructuring |
| Mount and unmount work | `onMounted`, `onUnmounted` | a listener or timer that is not removed on unmount |
| Child to parent event | `defineEmits` and `emit` | a payload shape that differs from the source |
| Conditional rendering | `v-if`, `v-else` | the source's empty state and loading state |
| List rendering | `v-for` with a stable `:key` | keys that change on each render reset child state |
| Scoped CSS | `<style scoped>` (https://vuejs.org/api/sfc-css-features.html) | child components styled by the parent only through `:deep()` |
| Route | Vue Router route records and `router.push` (https://router.vuejs.org/guide/essentials/navigation.html) | `params` ignored when `path` is set; the route name in the source |
| Access rule before entry | `beforeEnter` or a global `beforeEach` (https://router.vuejs.org/guide/advanced/navigation-guards.html) | `beforeEnter` does not fire on param or query change |
| Shared state across components | Pinia store with `defineStore` (https://pinia.vuejs.org/core-concepts/) | store id uniqueness; destructuring without `storeToRefs()` |
| Store reads in components | `storeToRefs()` for state and getters | a plain destructure loses reactivity |
| Store actions in tests | `createTestingPinia()` from `@pinia/testing` (https://pinia.vuejs.org/cookbook/testing.html) | actions are stubbed by default; set `stubActions: false` for the real behavior |
| Component test | `mount` or `shallowMount` from `@vue/test-utils` (https://test-utils.vuejs.org/api/) | `shallowMount` stubs child components |
| Unit test runner | Vitest, `vitest run` (https://vitest.dev/guide/) | the environment: `jsdom` or `happy-dom` for DOM tests (https://vitest.dev/config/environment) |
| Date and number display | the source's own format function, copied; `Intl` if the source uses it | the locale and the time zone of the output |
| Text escaping | interpolation `{{ }}` escapes by default; `v-html` does not | `v-html` with untrusted input |

## Notes on idioms

- Choose an idiom only when the inputs, outputs and errors stay the same. Otherwise keep the source behavior and record `deviation`.
- A source that updates state in an event handler and then reads the DOM must be tested for the DOM value after the update. Vue buffers DOM updates until the next tick, and `nextTick()` waits for that flush (https://vuejs.org/api/general.html#nexttick).
- For a form, keep the source's validation order and messages. Vue does not supply a validation library; a package is added only when the plan names it.
