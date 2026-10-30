Read this when the source you migrate from is React or Next.js. These are the places where the behavior is easy to miss, because it sits in the runtime, the framework or the rendering model, not in the line you read.

# Reading React and Next.js as the source

## Rendering and Effects

- Effects run after commit, not during render. A value read in an Effect is the one from the render that scheduled it (https://react.dev/reference/react/useEffect).
- In development with Strict Mode, Effects run setup, cleanup, setup once more before the first real setup. A source that works only because the setup runs once is a finding: record it as `known-issue` if it is the source's bug (same page).
- An Effect that depends on a value it does not list is a stale-value source. Check the dependency list against the code (https://react.dev/reference/react/useEffect).
- Effects are not run on the server. A source that reads `window` in render breaks on the server in Next.js (https://nextjs.org/docs/app/getting-started/server-and-client-components).

## Server and Client boundary

- A file with `'use client'` puts its imports and the components it renders directly into the client bundle. Components passed as `children` are not in that module graph (https://nextjs.org/docs/app/getting-started/server-and-client-components).
- Props from a Server Component to a Client Component must be serializable. A source that passes a function or a class instance as a prop differs.
- In Next.js, only `NEXT_PUBLIC_` variables reach the client bundle. Other variables are replaced with an empty string in client code (same page). A source that reads a secret in the browser has a behavior to record.

## Routing

- `params` and `searchParams` are Promises in the current App Router docs. A source that reads them synchronously follows a different API (https://nextjs.org/docs/app/getting-started/layouts-and-pages).
- A page that reads `searchParams` is dynamically rendered (same page).
- Layouts keep state across navigation between their child pages (same page).
- `proxy` runs on every route unless a matcher excludes it. A source that relies on a matcher to skip checks has a behavior to record (https://nextjs.org/docs/app/api-reference/file-conventions/proxy).
- Server Functions are POST requests to the route where they are used. A proxy matcher that excludes that route also skips them (same page).

## State and keys

- A list without a stable key keeps the state of the item that now sits at its index. Test a reorder with state in each row. Not verified offline: exact wording in the React docs.
- `setState` with the same value as the current one may skip a re-render. Not verified offline: exact React docs wording.

## Errors and timing

- A promise rejected in an Effect is not caught by an error boundary. Not verified offline: check https://react.dev/reference/react/Component#catching-rendering-errors-with-an-error-boundary before stating it as fact.
- `setTimeout` and listeners that an Effect creates must be removed in its cleanup. A source that does not remove them has a leak behavior to record.

## Accessibility and text

- A `div` with `onClick` is not focusable or announced as a button. A source that uses it has a behavior to keep or record (https://testing-library.com/docs/guide-which-query).
- Text inside `aria-label` and `alt` is read by assistive tech and found by `getByRole` and `getByLabelText`. A source that changes that text changes what a test finds.

## Forms and input

- Not verified offline: exact behavior of controlled and uncontrolled inputs in the current React docs. Read https://react.dev/reference/react-dom/components/input before stating a rule.

## Library behavior that the source may depend on

- Date formatting: the output depends on the runtime locale and time zone. Not verified offline: exact `Intl` behavior; cite MDN before stating it.
- A third-party component may need `'use client'` to work in the App Router (https://nextjs.org/docs/app/getting-started/server-and-client-components).
