Read this when you write tests, set up the quality gate, or choose a Vue tool. Facts were checked against the official pages on 2026-10-30. None was run on the machine that wrote this file.

# Testing and tooling (Vue 3)

## Test layout

- One test file per unit: `<unit>.spec.ts` or `<unit>.test.ts`, next to the code or in `test/`. Name each test with its rule id when there is one, for example `BR-CART-002 sums line totals`. The Vitest default include pattern is `['**/*.{test,spec}.?(c|m)[jt]s?(x)']` (https://vitest.dev/config/include).
- Component tests: Vue Test Utils (VTU). Store tests: Pinia with `@pinia/testing` (https://pinia.vuejs.org/cookbook/testing.html). Pure composable tests: plain Vitest, no DOM.

## Commands

| Command | What it does | What passes |
|---|---|---|
| `npx vitest run` | runs the tests once, without watching (https://vitest.dev/guide/) | every test passes; read the process exit code |
| `npx vitest run path/to/file.spec.ts` | runs one file (filter argument, https://vitest.dev/guide/cli) | as above |
| `npx vitest run -t "name"` | runs tests whose full names match a regexp (https://vitest.dev/guide/cli) | as above |
| `npx vitest --environment=jsdom` | sets the environment for the run (https://vitest.dev/config/environment) | as above |

## Environment

- The default environment is Node (https://vitest.dev/config/environment). A component test needs `jsdom` or `happy-dom`.
- Per file: a `@vitest-environment jsdom` comment at the top of the file (same page).
- The config file key for the environment is `environment` (https://vitest.dev/config/environment).
- Vitest reads `vite.config.*` by default (https://vitest.dev/guide/). Vitest requires Vite 6.4.0 or later and Node 22.12.0 or later (same page).

## Unit test with Vitest

```ts
import { describe, it, expect } from 'vitest'
import { lineTotal } from './cart'

describe('BR-CART-002', () => {
  it('BR-CART-002 rounds a line total with the source rule', () => {
    expect(lineTotal(2.5, 1)).toBe(2.5)
  })
})
```

- `describe`, `it` and `expect` are the usual Vitest functions. The page read shows `test` and `expect` (https://vitest.dev/guide/); `describe` was not listed there, so verify before relying on the name list.

## Component test with Vue Test Utils

```ts
import { mount } from '@vue/test-utils'
import { it, expect } from 'vitest'
import Counter from './Counter.vue'

it('BR-UI-001 shows the initial count', () => {
  const wrapper = mount(Counter, { props: { start: 3 } })
  expect(wrapper.text()).toContain('3')
})
```

- `mount` is the main method; `shallowMount` stubs all child components by default (https://test-utils.vuejs.org/api/).
- `find` returns a `DOMWrapper` when the element exists; `text` returns the text content; `trigger` dispatches a DOM event such as `click`; `setProps` updates props (https://test-utils.vuejs.org/api/).
- `global.plugins` installs plugins on the mounted component; `global.stubs` sets global stubs (same page).
- Test the output a user sees and the events a component emits, not its internal refs.

## Store test with Pinia

```ts
import { createTestingPinia } from '@pinia/testing'
import { mount } from '@vue/test-utils'

const wrapper = mount(Cart, {
  global: {
    plugins: [createTestingPinia({ stubActions: false })],
  },
})
```

- Install `@pinia/testing` with `npm i -D @pinia/testing` (https://pinia.vuejs.org/cookbook/testing.html).
- `createTestingPinia()` stubs all actions by default. Pass plugins through its options, not with `testingPinia.use(...)` afterward (same page).

## Doubles and fakes

- Put each external dependency behind a function or module that the unit receives as a parameter. Write a hand-made fake for it. This is the default.
- Mocking the router: VTU documents `global.mocks` for `$route` and `$router` (https://test-utils.vuejs.org/guide/advanced/vue-router.html, which lists the stubs, not the router API). The exact router-mock API was not verified in the official pages read. Use a real router with `createRouter` and `createMemoryHistory` from `vue-router` when the route matters: `createRouter` "Creates a Router instance that can be used by a Vue app" and `createMemoryHistory` "Creates an in-memory based history" (https://router.vuejs.org/api/).
- Time: pass a clock as a value. Use fake timers only where the source uses timers (Vitest timer API not verified offline).

## Gate commands

| Gate | Command | What passes | Verified in this run |
|---|---|---|---|
| Test | `npx vitest run` | every test passes | command and purpose: yes (https://vitest.dev/guide/); exit code: read from the process |
| Type check | project script, for example `vue-tsc --noEmit` | no type error | not verified offline: read `package.json` |
| Build | project `build` script | build succeeds | not verified offline |
| Lint and format | project's ESLint, Prettier or Biome | no error | not verified offline |

- Report each gate with its command, its exit code and the line that decides the result.
- Coverage: the `--coverage` CLI option overrides `coverage.enabled` (default `false`) (https://vitest.dev/guide/cli). The default coverage provider is `v8`; `istanbul` is the other built-in option (https://vitest.dev/guide/coverage).

## Tool choice

- Use what the project already has. Add a package only when the plan names it and the gate needs it.
- Official packages: `vue`, `vue-router`, `pinia`, `@pinia/testing`, `@vue/test-utils`, `vitest`. Pin them in `package.json` and commit the lockfile.
- Read the flags of any command with its `--help` output, and record the version you ran.
