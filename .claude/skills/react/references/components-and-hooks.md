Read this when a migrated unit has components, hooks, state, routing, styling, accessibility or i18n work. Facts were checked against the official react.dev and nextjs.org pages on 2026-10-30.

# Components, hooks and state (React 19.x, Next.js App Router)

## Components

- A component is a function that returns JSX. It must be pure with respect to its inputs: the same props and state give the same output (https://react.dev/learn/keeping-components-pure).
- Props are read-only. A component does not change the props it receives (same page).
- Server Components are the App Router default. They fetch data and render on the server; their code and imports are not sent to the client (https://nextjs.org/docs/app/getting-started/server-and-client-components).
- Client Components start at a `'use client'` directive, placed above the imports. Everything the file imports and renders directly joins the client bundle (same page).
- Put `'use client'` on the smallest interactive component, not on a whole page (same page: "Reducing JS bundle size").
- Pass Server Components as `children` into a Client Component to keep them on the server (same page: "Interleaving Server and Client Components").

## Hooks

- Hooks start with `use` and are called at the top level of a component or a custom hook, never in a condition or loop (https://react.dev/reference/rules/rules-of-hooks). Not verified offline: exact wording; the rule is stated here from the React docs index and should be checked.
- `useState` returns the state and a setter. The setter schedules a re-render; the value does not change in place (https://react.dev/reference/react/useState). Not verified offline: exact wording.
- `useEffect` synchronizes with an external system (https://react.dev/reference/react/useEffect). It is not a place for user-action logic (https://react.dev/learn/you-might-not-need-an-effect).
- Custom hooks share stateful logic between components (https://react.dev/learn/reusing-logic-with-custom-hooks).
- `use` reads a Promise or context in a component. It is used in the Next.js docs to stream data from a Server Component (https://nextjs.org/docs/app/getting-started/server-and-client-components). Not verified offline: its full API page.

## State

- Keep state in the lowest component that needs it. Lift it up when two siblings need it (https://react.dev/learn/sharing-state-between-components).
- Do not store a value that can be computed from props or other state. Compute it during render (https://react.dev/learn/you-might-not-need-an-effect).
- Context passes shared values down a subtree. In the App Router it lives in a Client Component (https://nextjs.org/docs/app/getting-started/server-and-client-components, "Context providers").
- Not verified offline: the choice of an external store library. Record the choice in the plan if the project uses one.

## Routing

- Route folders and `page` files define the URL (https://nextjs.org/docs/app/getting-started/layouts-and-pages).
- `[slug]` is a dynamic segment; read it with `await params` (same page).
- Use `<Link href="...">` from `next/link` between routes (https://nextjs.org/docs/app/getting-started/linking-and-navigating).
- `useSearchParams` in a Client Component reads search params; the `searchParams` prop in a page does the same on the server and makes the page dynamic (https://nextjs.org/docs/app/getting-started/layouts-and-pages, "What to use and when").
- `proxy` runs before a route renders and can rewrite, redirect or respond. It is not a substitute for checks inside Server Functions (https://nextjs.org/docs/app/api-reference/file-conventions/proxy).

## Styling

- Styling options listed by the Next.js CSS guide: Tailwind CSS, CSS Modules, Global CSS, External Stylesheets, Sass, CSS-in-JS (https://nextjs.org/docs/app/getting-started/css).
- Keep the source's visual rules: colors, spacing, breakpoints, font sizes. Any visible change is a `deviation`.
- Import global styles from the root layout only (not verified offline: the Next.js rule on where global CSS may be imported).

## Accessibility

- Use the native element for the role: `button` for an action, `a` for navigation, `label` with `input` for a form field (https://testing-library.com/docs/guide-which-query, which ties `getByRole` to the accessibility tree).
- Give each icon-only button an accessible name. Not verified offline: the React docs page on this topic.
- Keep focus visible and reachable with the keyboard. Not verified offline: exact WCAG success criterion numbers; the standard is at https://www.w3.org/TR/WCAG22/.
- An accessibility gap in the source is kept as the source behavior and recorded as `known-issue`.

## Internationalization

- Not verified offline: the Next.js i18n guide (https://nextjs.org/docs/app/guides/internationalization).
- Keep the source's message keys and fallback order. Do not translate keys.
- Dates and numbers: format with the runtime's `Intl` APIs using the locale the source uses. Not verified offline: exact `Intl` page.
- Test each supported locale with at least one value that differs by locale, for example a decimal separator.

## Parity checklist for UI units

- List each source state transition and write one test per transition.
- Check the source's behavior when the user leaves the screen during a request. The target must match it.
- Check list reorders with keys, not only with indexes.
- Check each Effect in the target: it must synchronize with something external, and its cleanup must undo its setup.
- Check each Server/Client split: no secret or browser-only API in a Server Component, and no server-only import in a Client Component.
