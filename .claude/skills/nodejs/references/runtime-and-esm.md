# Runtime, modules and environment (Node.js 22)

Read this when you decide the module system, load JSON or environment, or use a flag that is not stable.

## Module system

- ESM is the default for new code. Mark the package with `"type": "module"`, or use `.mjs`. A `.js` file without that marker is CommonJS.
- `require()` can load an ES module whose graph is fully synchronous (no top-level `await`). This is on by default since v22.12; the warning is off since v22.13. Use it only when the consumer is CommonJS and the module is synchronous.
- CommonJS files cannot use top-level `await`. Use `await import()` inside an async function.
- ESM has no `__dirname`, `__filename` or `require`. Use `import.meta.dirname` and `import.meta.filename` (since v21.2 and v20.11; not experimental since v22.16). These exist only for `file:` modules.
- `import.meta.resolve(specifier)` returns the resolved URL synchronously; it may touch the file system.

## JSON and attributes

- `import config from './config.json' with { type: 'json' }` is required. The default export is the only export.
- Dynamic form: `const { default: config } = await import('./config.json', { with: { type: 'json' } })`.
- Node 22 supports only the `type` attribute.

## Environment

- `--env-file=<path>` loads a file into `process.env`. Repeat it to layer files; a later file overrides an earlier one. The value already in the environment wins over the file. A missing file is an error; `--env-file-if-exists=<path>` ignores a missing file (both are stable in 22.21 and later).
- The format is `KEY=value`, one per line, with `#` comments. Quotes are stripped. Multi-line values are supported.
- Read the environment in one module. Validate types and required keys at start, and fail with a message that names the key, never its value.

## Permission model

- `--permission` turns on the permission model (stable since v22.13). It restricts file system, child processes, worker threads, WASI and native addons.
- Allow only what the process needs: `--allow-fs-read=<path>`, `--allow-fs-write=<path>`. The entry module is readable implicitly.
- Use it for tools and tests that must not write outside a directory; it is not a sandbox against hostile code.

## Process lifecycle

- `process.exitCode = 1` lets the event loop drain. `process.exit(1)` stops at once and can drop buffered output.
- Handle `SIGINT` and `SIGTERM` for a clean shutdown when the source does: stop accepting work, wait for in-flight tasks with a deadline, close resources, then set the exit code.
- An unhandled promise rejection exits the process with an error by default (since v15). Keep that default unless the source behavior is different, and then say so.

## Stability of flags

Check each flag in the docs of the Node version you target. Facts checked on 2026-10-29 for Node 22:

| Flag or feature | Status in Node 22 |
|---|---|
| `--env-file` | stable since v22.21 |
| `--env-file-if-exists` | stable since v22.21 |
| `--permission`, `--allow-fs-read`, `--allow-fs-write` | stable since v22.13 |
| `require(esm)` | on by default since v22.12 |
| JSON modules | stable since v22.12 |
| `import.meta.dirname` | stable since v22.16 |
| `--test-coverage-lines` and related threshold flags | experimental (stability 1, since v22.8) |

Source: https://nodejs.org/docs/latest-v22.x/api/cli.html and https://nodejs.org/docs/latest-v22.x/api/esm.html
