---
name: react
description: "React 19.x with Next.js App Router for React and Next.js UI code: components and hooks, state and Effects, App Router routing and Server/Client Component boundary, CSS and styling, accessibility (a11y), i18n, Testing Library and Playwright gates. Use for React or Next.js code, package.json with react or next, JSX or TSX components, or migrations to or from React."
metadata:
  baseline: "React 19.x (latest release post checked: React 19.3, 2026-09-09), Next.js App Router (docs checked 2026-10)"
  verified: "2026-10-30"
---

# react (React 19.x, Next.js App Router)

Practice for React and Next.js UI code, used when React or Next.js is the source or the target of a migration. Facts were checked against the official react.dev and nextjs.org pages on 2026-10-30. Items marked "not verified offline" were not read in this run and must be checked before use. No React or Next.js toolchain was run on the machine that wrote this file, so no gate command was run. Sources are listed at the end.

## 1. Scope and versions

- The latest React release post read in this run is React 19.3, dated 2026-09-09 (https://react.dev/blog). Before use, check the version the project pins in `package.json` and record it in the report.
- Next.js docs read in this run were last updated in 2026-08 to 2026-10 (https://nextjs.org/docs/app/getting-started/layouts-and-pages). Next.js version: verify before use with the project's lockfile.
- The App Router is the target of this skill. The Pages Router is out of scope unless the plan names it.
- Target the version the project declares. If the project declares none, use this baseline and say so in the report.
- Next.js 16 renamed the `middleware` file convention to `proxy` (https://nextjs.org/docs/app/api-reference/file-conventions/proxy). Use the name the pinned version uses.

## 2. Layout and build

- App Router files live under `app/`. A route is a folder with a `page` file; shared UI is a `layout` file (https://nextjs.org/docs/app/getting-started/layouts-and-pages).
- The root layout is required and must contain `<html>` and `<body>` (same page).
- Keep the target's package name, folder layout and path aliases in the plan. Do not invent them.
- Tests live where the project already puts them. Do not add a second test runner (see references/testing-and-tooling.md).

## 3. Idioms

- Components are functions. Props are read-only; a component does not mutate its props (https://react.dev/learn/keeping-components-pure).
- Add `'use client'` only at the boundary where interactivity starts. A file marked with it, and everything it imports and renders directly, is in the client bundle (https://nextjs.org/docs/app/getting-started/server-and-client-components).
- Server Components are the default in the App Router. They can fetch data and read secrets (same page).
- Props passed from a Server Component to a Client Component must be serializable (same page).
- React context is not supported in Server Components. Put a provider in a Client Component that accepts `children` (same page).
- Keep the source's state transitions. Derive values during render instead of copying them into state where the source derives them (https://react.dev/learn/you-might-not-need-an-effect).

## 4. Hooks and Effects

- `useEffect` "lets you synchronize a component with an external system" (https://react.dev/reference/react/useEffect). If the code does not synchronize with something outside React, it probably does not need an Effect (same page).
- Effects run after commit. The cleanup of the previous Effect runs before the next setup, and once more on unmount (same page).
- In development with Strict Mode, React runs one extra setup and cleanup cycle before the first real setup. The cleanup must undo the setup (same page).
- Event handlers belong in event handlers, not in Effects, when the trigger is a user action (https://react.dev/learn/you-might-not-need-an-effect).
- Custom hooks reuse stateful logic and keep the name starting with `use` (https://react.dev/learn/reusing-logic-with-custom-hooks). The page says custom hooks share stateful logic but not state itself, and hook names must start with `use` followed by a capital letter.
- Data fetching in Client Components: the Next.js docs show Server Components fetching and streaming with the `use` API, and community libraries SWR and React Query for Client Components (https://nextjs.org/docs/app/getting-started/fetching-data).

```tsx
'use client'

import { useState } from 'react'

export default function Counter() {
  const [count, setCount] = useState(0)
  return <button onClick={() => setCount(count + 1)}>{count}</button>
}
```

(The example is the shape shown on https://nextjs.org/docs/app/getting-started/server-and-client-components.)

## 5. State and data flow

- Local state is `useState` in the component that owns it. Lift state up when two siblings need it (https://react.dev/learn/sharing-state-between-components).
- Shared state across a subtree: context, or a store the project already uses. Not verified offline: which store library to prefer.
- Keep the source's state machine. Write one test per transition.
- A `key` decides whether React keeps the state of an item. Use a stable key from the data, not the array index, when the list can reorder (https://react.dev/learn/rendering-lists). Not verified offline: exact wording.

## 6. Routing (Next.js App Router)

- Folders define URL segments. `app/blog/[slug]/page.tsx` defines `/blog/:slug` (https://nextjs.org/docs/app/getting-started/layouts-and-pages).
- In a page, `params` is a Promise in the current docs: `const { slug } = await params` (same page).
- In a page, `searchParams` is a Promise. Using it makes the page dynamically rendered (same page).
- `useSearchParams` reads search params in Client Components. Use the prop when the page loads data from them (same page).
- Navigation between routes uses `<Link>` from `next/link`. It adds prefetching and client-side navigation (same page; https://nextjs.org/docs/app/getting-started/linking-and-navigating).
- Layouts keep their state and do not re-render on navigation between their child pages (same page).
- `proxy` (formerly `middleware`) runs before a request is completed. It runs on every route unless a `matcher` limits it. It does not replace checks inside a Server Function: "Always verify authentication and authorization inside each Server Function" (https://nextjs.org/docs/app/api-reference/file-conventions/proxy).

## 7. CSS and styling

- Not verified offline: the CSS options that the Next.js docs list (CSS Modules, global CSS, Tailwind). Read the Next.js styling guide before writing a rule about any of them.
- Keep the source's visual rules. A migration that changes colors, spacing or breakpoints changes behavior; record it as `deviation`.
- Do not use a CSS-in-JS library in a Server Component unless the project already uses it and its docs say it works there. Not verified offline.

## 8. Accessibility (a11y)

- Prefer native elements (`button`, `a`, `label`, `input`) over `div` with handlers. The Testing Library guide says `getByRole` matches "every element that is exposed in the accessibility tree" (https://testing-library.com/docs/guide-which-query).
- Every form control needs a label. Every image needs text alternatives in `alt` (https://testing-library.com/docs/queries/about). Not verified offline: exact `alt` rule text.
- Keyboard: every control reachable with Tab and operable with Enter or Space. Not verified offline: the React docs section on this.
- Standard: WCAG 2.2 at https://www.w3.org/TR/WCAG22/. Not verified offline: the specific success criterion that a rule maps to.
- A source's accessibility behavior is the behavior to keep. If the source lacks a label, the migration keeps the behavior and records the gap as `known-issue`.

## 9. Internationalization (i18n)

- Not verified offline: the Next.js i18n routing docs. Read https://nextjs.org/docs/app/guides/internationalization before writing a locale rule.
- Keep the source's message keys, plural rules and date and number formats. Do not translate identifiers, keys or literals.
- Locale-dependent formatting uses the `Intl` APIs of the runtime. Not verified offline: the exact MDN page.
- A test that checks text uses the locale the source uses, not the machine locale.

## 10. Errors, resources and the Server boundary

- In a Server Component, a thrown error goes to the nearest `error` file, not to a try/catch in the page. Not verified offline: the exact error-file rules; read https://nextjs.org/docs/app/getting-started/error-handling.
- Close subscriptions and timers in an Effect cleanup (https://react.dev/reference/react/useEffect).
- Do not read secrets in a Client Component. Only variables prefixed `NEXT_PUBLIC_` reach the client bundle; others are replaced with an empty string (https://nextjs.org/docs/app/getting-started/server-and-client-components).
- Use the `server-only` package to fail the build when server code is imported into the client. It is optional (same page).

## 11. Migrating TO React / Next.js

- Parity beats idiom. Choose a React idiom only when inputs, outputs and errors stay the same. Otherwise keep the source behavior and mark the difference `deviation` with its reason and source.
- Map each source screen with references/as-target.md: events, state, forms, lists, routing, styling.
- Write a test for each state transition and each error path before writing the component.
- Record expected output from the source, not from React. Compare against it.
- For each Effect in the target, check that it synchronizes with something external. If it only derives data, move the work into render.

## 12. Migrating FROM React / Next.js

- Read references/as-source.md for the places where React behavior hides: Strict Mode double runs, Effect timing, keys, the Server/Client split, `params` and `searchParams` as Promises, and stale closures.
- Cite the source with `path:line` for each rule, and check each React or Next.js behavior it depends on against the official pages in references.

## 13. Anti-patterns

- An Effect that copies props into state, or that runs a handler that a user action should trigger (https://react.dev/learn/you-might-not-need-an-effect).
- A non-idempotent Effect setup with no cleanup. Strict Mode exposes it.
- `'use client'` on a large tree when one leaf is interactive (https://nextjs.org/docs/app/getting-started/server-and-client-components).
- Secrets in a file that a Client Component imports.
- Array index as the `key` of a list that can reorder.
- A `div` with `onClick` where a `button` is the element the source uses.
- Using `params` or `searchParams` without `await` on the version that makes them Promises.
- A test that queries by class name or test id when a role or label exists (https://testing-library.com/docs/guide-which-query).

## Library registry

- Registry: npm, https://www.npmjs.com/. Not verified offline: the package page layout.
- Before adding a package, confirm: latest version, peer dependency on the pinned React, supported Next.js version, license, last publish.
- Pin the version in `package.json` and commit the lockfile the project uses.
- Full procedure: `.claude/skills/migration-conduct/references/library-research.md`.

## Sources

- React: https://react.dev/blog, https://react.dev/reference/react/useEffect, https://react.dev/learn/you-might-not-need-an-effect, https://react.dev/learn/keeping-components-pure, https://react.dev/learn/reusing-logic-with-custom-hooks, https://react.dev/learn/sharing-state-between-components, https://react.dev/learn/rendering-lists
- Next.js: https://nextjs.org/docs/app/getting-started/server-and-client-components, https://nextjs.org/docs/app/getting-started/layouts-and-pages, https://nextjs.org/docs/app/api-reference/file-conventions/proxy, https://nextjs.org/docs/app/getting-started/linking-and-navigating
- Testing Library: https://testing-library.com/docs/guide-which-query, https://testing-library.com/docs/queries/about
- Playwright: https://playwright.dev/docs/best-practices
- Accessibility: https://www.w3.org/TR/WCAG22/
