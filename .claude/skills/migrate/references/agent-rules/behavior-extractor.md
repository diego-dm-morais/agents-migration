# behavior-extractor: rules, UI units and architecture mode

Read by `behavior-extractor` before its first step (its prompt points here). Each section applies when its heading says so.

## UI units (platform web or mobile)

Read `unit_platform` and `unit_kind` from the unit's frontmatter in `docs/migration/MIGRATION.md`. For `backend`, ignore this block.

- Survey mode: list candidates from routes (router config, `app/` or `pages/` trees, navigators), screen and page components (`*Screen`, `*Page`, `*_screen.dart`, `*_page.dart`) and feature folders. Each candidate gets its kind (`screen` or `feature`), its route or screen name, and its entry point as `path:line @sha7`.
- Trace, in order, for the unit's entry point: route entry and params (names, types, defaults, how they are read); lifecycle (mount, init, dispose, focus or resume hooks); state management (stores, reducers, providers, signals, local state, what persists); events (taps, submits, changes, gestures) and their handlers; validation (field rules, messages); API calls (route, method, when fired, what happens on each result); navigation in and out (targets, params passed, back behavior); loading, empty and error states, each as its own rule; permissions (camera, location, auth guards, role checks); i18n strings (keys and literal text, cited); platform branches (`Platform`, `kIsWeb`, `isIOS`, media queries, `process.env` build flags).
- A UI state, event or navigation target is a `BR-` like any other: it needs a `path:line @sha7` citation and an evidence line. A visual value (color, spacing, font) is recorded as a token with its citation, not as a rule.
- Layout you cannot trace to code is a gap. Do not describe pixels from memory.

## Rules

- The implemented code is the only source of behavior. Document it as it is, bugs included. Never reinterpret it to look like a best practice.
- Framework, library or runtime behavior: first the dependency source at the pinned version (lockfile, vendored or cached code), then the official documentation (WebFetch or WebSearch, with the URL). If neither settles it, it is an open item in Gaps, never a remembered fact.
- A rule the code does not show is a gap. Never state it as a rule.
- Before any `NEEDS: user`, check the implemented code, the dependency source and the official docs. Ask only what none of them settles, and list what you checked.
- Keep source bugs as they are. Mark each one `known-issue` in Gaps, with its citation.
- Legacy fidelity (conduct rule 10): check the legacy code before any question. List each intentional decision that contradicts best practice as a `DEC-NNN` line under `## Legacy decisions contrary to best practice` in extraction.md (conduct section 13), or write `none found` with the search you ran. Never change the behavior you extract.
- Never copy a secret value. Write `<redacted>` and cite where it is.
- Never write inside the snapshot. Write only under `docs/migration/<unit>/`. Run source code only from a copy outside the snapshot, or with flags that stop cache writes into it (for example `PYTHONDONTWRITEBYTECODE=1`).
- Write labels in `artifact_language`. Keep identifiers, paths and literals untranslated.
