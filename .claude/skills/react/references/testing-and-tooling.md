Read this when you write tests, set up the quality gate, or choose a React or Next.js tool. Facts were checked against the official Testing Library and Playwright pages on 2026-10-30. None of the commands below was run on the machine that wrote this file.

# Testing and tooling (React 19.x, Next.js App Router)

## Test layout

- Use the layout the project already has. If it has none, put component tests next to the component file or under `__tests__/`, and end-to-end tests under `e2e/`. Not verified offline: which convention a given project uses.
- One test file per unit. Name each test with its rule id when there is one, for example `BR-UI-001 shows the initial count`.
- Keep the rule id in the test name, not in a comment. A reader can then find the test by the id in the source doc.

## Component tests with Testing Library

- Query by what the user sees, in this order (https://testing-library.com/docs/guide-which-query):
  1. `getByRole`
  2. `getByLabelText`
  3. `getByPlaceholderText`
  4. `getByText`
  5. `getByDisplayValue`
  6. `getByAltText`
  7. `getByTitle`
  8. `getByTestId`
- `getByRole` is the default. If it cannot find an element, the UI may be inaccessible (same page).
- Simulate a user with `userEvent` rather than `fireEvent`. Not verified offline: the exact docs page; read https://testing-library.com/docs/user-event/intro before stating the difference.
- The React-specific package for rendering in tests is `@testing-library/react`. Not verified offline: its current version and setup steps.

```tsx
import { render, screen } from '@testing-library/react'

test('BR-UI-001 shows the initial count', () => {
  render(<Counter />)
  expect(screen.getByRole('button', { name: '0' })).toBeInTheDocument()
})
```

- `toBeInTheDocument` comes from `@testing-library/jest-dom`. Not verified offline: the matcher setup for the project's runner.

## Async UI

- Use `findBy*` or `waitFor` for UI that appears after a promise. Not verified offline: exact docs wording; read https://testing-library.com/docs/dom-testing-library/api-async before stating the rule.
- Do not wait with a fixed timeout. Assert on the state the user sees.

## Doubles and fakes

- Put each external call behind a module or function that the test can replace. Write a hand-made fake first. This is the default.
- Mock the network at the boundary. Not verified offline: which tool the project uses (for example MSW). Record the choice in the plan.
- Time: pass a clock or use fake timers. Not verified offline: the runner's fake-timer API.

## End-to-end tests with Playwright

- Test user-visible behavior, not implementation details (https://playwright.dev/docs/best-practices).
- Prefer user-facing locators, for example `page.getByRole('button', { name: 'submit' })`. The guide recommends them over XPath or CSS selectors (same page).
- Use web-first assertions such as `toBeVisible()`. They retry until the condition holds. The guide warns against `expect(await locator.isVisible()).toBe(true)`, because it does not wait (same page).
- Keep `@playwright/test` current with the version the project pins. The guide points to the release notes for the newest release (same page). The exact version is not verified offline.
- Run one file with `npx playwright test e2e/checkout.spec.ts`. Non-option arguments are regular expressions matched against the test file path; `-g`/`--grep` filters test titles and `--project` selects projects (https://playwright.dev/docs/test-cli).
- Record the browser and the base URL in the report.

## Gate commands

Run each command in the project root and report its real output. A gate that did not run is not a pass. The commands below are the usual forms; the scripts in the project's `package.json` take precedence when they exist. Not verified offline: exit-code behavior of each command.

| Gate | Command | What passes |
|---|---|---|
| Type check | `npx tsc --noEmit` | no error reported |
| Lint | the project's `lint` script | no error; the project's rule set decides warnings |
| Format | the project's `format:check` script, or `npx prettier --check .` | no file reported |
| Unit and component tests | the project's `test` script, or `npx vitest run` / `npx jest` | every test passes |
| End-to-end | `npx playwright test` | every test passes |
| Build | `npx next build` | build completes with no error |

- Run every gate, even when the first one fails. Report each command, its exit code and the line that decides the result.
- Coverage: not verified offline.

## Tool choice

- Use what the project already has. Add a package only when the plan names it and a gate needs it.
- Add `@testing-library/react` and `@playwright/test` only when the project does not have them.
- The React docs on testing and the Next.js docs on testing are the reference for the framework. Not verified offline: exact page paths.
