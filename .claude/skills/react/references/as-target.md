Read this when you map a source construct to React or Next.js code. The left column is the concept; the middle column is the React or Next.js idiom; the right column is the risk to test.

# Writing React and Next.js as the target

| Concept | Idiom in this stack | Parity risk to test |
|---|---|---|
| Screen | a route folder with `page.tsx` under `app/` (https://nextjs.org/docs/app/getting-started/layouts-and-pages) | the URL and the segment names; the source's route table |
| Shared shell | a `layout.tsx`; the root layout has `html` and `body` | state kept across navigation; the source's shell markup |
| Static read | a Server Component with `await` on fetch (https://nextjs.org/docs/app/getting-started/server-and-client-components) | the source's error on a failed read; the timing of the read |
| Interaction | a Client Component with `'use client'` and `useState` (https://react.dev/reference/react/useState) | each state transition; the source's event order |
| Side effect that syncs with the outside | `useEffect` with a cleanup (https://react.dev/reference/react/useEffect) | Strict Mode double run; the cleanup removes what setup added |
| Derived value | compute during render, no state, no Effect (https://react.dev/learn/you-might-not-need-an-effect) | a stale copy; the value updates when its input changes |
| User action side effect | an event handler, not an Effect | a handler that runs twice or not at all |
| Shared state across a subtree | context in a Client Component that takes `children` (https://nextjs.org/docs/app/getting-started/server-and-client-components) | a provider that wraps too much; a Server Component that reads context |
| Reusable stateful logic | a custom hook named `useX` (https://react.dev/learn/reusing-logic-with-custom-hooks) | the hook called conditionally; the hook's returned identity |
| List | `map` with a stable `key` from the data (https://react.dev/learn/rendering-lists) | reorder keeps the state of each row; index keys break it |
| Link between routes | `<Link href>` from `next/link` (https://nextjs.org/docs/app/getting-started/linking-and-navigating) | prefetch side effects; a plain `<a>` where the source does a full reload |
| URL params | `await params` in a page (https://nextjs.org/docs/app/getting-started/layouts-and-pages) | the Promise shape; a missing segment |
| Search params | `await searchParams` in a page, or `useSearchParams` in a Client Component | dynamic rendering when the prop is read; the source's default for a missing param |
| Request guard | `proxy` with a `matcher` (https://nextjs.org/docs/app/api-reference/file-conventions/proxy) and a check inside each Server Function | a path the matcher skips; a Server Function without its own check |
| Secret | read in a Server Component or a route handler only | a `NEXT_PUBLIC_` prefix that exposes it |
| Form control | a native `input` with a `label` | the label text the test queries; the source's validation message |
| Clickable element | a native `button`; a link is an `a` | keyboard activation; the role the source exposes |
| Text and i18n | the source's message keys; `Intl` for dates and numbers | locale and time zone of the output; key names kept |
| Styling | the project's existing CSS approach; record any visual change as `deviation` | breakpoints and spacing; the source's visual state |
| Error display | the nearest `error` file for route errors (https://nextjs.org/docs/app/getting-started/error-handling) | the source's message text; the status code |

- Each row is a default, not a rule. Choose the idiom only when inputs, outputs and errors stay the same.
- A React idiom that changes a visible behavior is a `deviation`, with the source citation and the reason.
