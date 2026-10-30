---
name: typescript
description: "TypeScript 7.0+ (7.0.2 checked 2026-10-29) for .ts and .tsx code: tsconfig and strict mode, structural types, narrowing, enums, any and unknown, JSON input, numbers and dates, and the tsc and test gates. Use for TypeScript code, tsconfig.json, typescript in package.json, or migrations to or from TypeScript."
metadata:
  baseline: "TypeScript 7.0 (7.0.2 on npm latest, checked 2026-10-29)"
  verified: "2026-10-29"
---

# typescript (TypeScript 7.0)

Practice for TypeScript code, used when TypeScript is the source or the target of a migration. The baseline is TypeScript 7.0, the current release on 2026-10-29 (7.0.2 on the npm `latest` tag). Facts were checked against the official handbook, release notes and tsconfig reference, the Node.js 22 docs, and by running `tsc` 7.0.2 and Node v22.23.1 on 2026-10-29. Sources are listed at the end.

## 1. Scope and versions

- Target the version the repository declares: the `typescript` entry in `package.json`. If it declares none, use the 7.0 line and say so in the report.
- The official pages checked on 2026-10-29 name 7.0 as current: the homepage says "TypeScript 7.0 is now available, 7.1 is currently in beta." Repositories on 5.9 or 6.0 differ in the defaults of section 2.
- Check the current tags with `npm view typescript dist-tags`. On 2026-10-29: `latest` is 7.0.2 and `beta` is 7.1.0-beta. 7.1 is not the baseline; verify before use.
- TypeScript 7.0 is a native port of the compiler, built in Go. The command is still `tsc`, from the npm package `typescript` (https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/).
- TypeScript 7.0 ships no stable programmatic API. The 7.0 announcement says `@typescript/typescript6` re-exports the 6.0 API for tools such as typescript-eslint. Verify before use which package a tool needs.
- `strict` defaults to true from 6.0 on. Before 6.0 the default was false: a project that relied on it must set `"strict": false` explicitly (https://www.typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html).

## 2. Layout and build

- `package.json` lists `typescript` in `devDependencies` (`npm install -D typescript`). Commit the lockfile of the repository's package manager. `npm ci` needs `package-lock.json` and exits with an error when it is out of sync with `package.json` (https://docs.npmjs.com/cli/v11/commands/npm-ci).
- Set `"strict": true` in `tsconfig.json` explicitly. It is the default in 7.0; the explicit value shows the intent in the file.
- A gate config that compiled a clean file with exit 0 on 2026-10-29:

```json
{
  "compilerOptions": { "strict": true, "noEmit": true, "target": "es2022", "module": "esnext", "moduleResolution": "bundler" },
  "include": ["src"]
}
```

- Paths that moved in 6.0 and 7.0: `rootDir` defaults to the tsconfig folder (`./`). With sources in `src` and no `rootDir`, output lands in `dist/src/index.js`, and tsc 7.0.2 also reports TS5011 ("The common source directory of 'tsconfig.json' is './src'. The 'rootDir' setting must be explicitly set...") and exits 2. With `"rootDir": "./src"`, tsc exits 0 and output lands in `dist/index.js` (verified 2026-10-29; https://www.typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html). `types` defaults to `[]`: list `"node"` when the code uses Node APIs, or `process` is not found (6.0 release notes).
- Set `module` and `target` when the emitted JS must not change. In 7.0, `module` defaults to `esnext`, and `target` to the stable ECMAScript version before esnext (7.0 announcement).
- Removed in 7.0 (announcement): `target: es5`, `downlevelIteration`, `moduleResolution` `node`, `node10` and `classic`, `module` `amd`, `umd`, `systemjs` and `none`, `baseUrl`, `esModuleInterop` and `alwaysStrict` set to false, and `asserts` on imports (use `with`). Replace `baseUrl` with a prefix in each `paths` entry (6.0 release notes).
- `erasableSyntaxOnly` makes `tsc` report constructs with runtime behavior, such as `enum` (TS1294 on 2026-10-29; https://www.typescriptlang.org/tsconfig).
- Node 22.18.0 and later run `.ts` files directly (type stripping is on by default). Types are removed and not checked. Enum declarations, namespaces with runtime code, parameter properties and import aliases fail unless `--experimental-transform-types` is passed; decorators and tsconfig `paths` fail too. `enum E { A }` fails with `ERR_UNSUPPORTED_TYPESCRIPT_SYNTAX` on 2026-10-29 (https://nodejs.org/docs/latest-v22.x/api/typescript.html).
- Generic practice: pure modules for logic, thin adapters for I/O. Tests import the pure modules directly.

## 3. Idioms

- Type untrusted input as `unknown`, and narrow it before use. `unknown` is "the type-safe counterpart of `any`" (https://www.typescriptlang.org/docs/handbook/release-notes/typescript-3-0.html). Runtime checks: references/runtime-validation.md.
- Narrow with `typeof`, `instanceof`, `in`, equality, truthiness, discriminated unions and user-defined guards such as `function isFish(pet: Fish | Bird): pet is Fish` (https://www.typescriptlang.org/docs/handbook/2/narrowing.html). Details: references/type-system.md.
- Switch over a union and assign the default branch to a `never` variable. A new union member then fails to compile (narrowing page).
- `as` removes the type at compile time, with no runtime check: "there is no runtime checking associated with a type assertion" (https://www.typescriptlang.org/docs/handbook/2/everyday-types.html). Verified: `JSON.parse('"s"') as number` compiles, and `v + 1` prints `s1`.
- A fixed set of names with no runtime object: a literal union (`"open" | "closed"`). A non-const `enum` is a runtime object: keep it where the source reads it (references/as-source.md).
- Two interfaces with the same name merge. Two type aliases with the same name fail with TS2300 "Duplicate identifier" (https://www.typescriptlang.org/docs/handbook/declaration-merging.html; verified).

## 4. Errors, resources and exit

- Under `strict`, a `catch` variable is `unknown` (`useUnknownInCatchVariables`). Verified: `e.message` fails with TS18046. Narrow with `instanceof Error` first.
- Throw `Error` objects. `new Error(message, { cause })` needs an ES2022 library: it compiles with `--target es2022` and fails with TS2554 with `--target es2015` (verified).
- A typed error class with a `code`, and a handler that narrows. It compiles under `--strict` with `--target es2022` (verified):

```ts
export class ParseError extends Error {
  readonly code: string;
  constructor(message: string, code: string, options?: ErrorOptions) {
    super(message, options);
    this.name = "ParseError";
    this.code = code;
  }
}

export function describeFailure(e: unknown): string {
  if (e instanceof ParseError) return `${e.code}: ${e.message}`;
  if (e instanceof Error) return e.message;
  return String(e);
}
```

- A function's type does not list what it throws: `function f(): number { throw new Error("x"); }` compiles under `--strict` (verified). Document the throws in the unit doc.
- `tsc` exits 0 with no diagnostics. With `--noEmit` and a TS2322 error it exits 1; without `--noEmit` (emit enabled) the same error exits 2 (local run of tsc 7.0.2 on 2026-10-29; no official exit-code page was read).

## 5. Concurrency

- TypeScript adds no runtime behavior. `async`, `await` and `Promise` run as ECMAScript and Node define them. For the event loop, ordering and unhandled rejections, see the Node.js 22 docs (https://nodejs.org/docs/latest-v22.x/api/).
- `Promise<T>` does not show rejections: `async function later(): Promise<number> { throw new Error("y"); }` compiles under `--strict` (verified).
- A type annotation never orders calls. Keep the source's order in code, and test it.

## 6. Data and numbers (parity traps)

- `number` is the only numeric type; JavaScript has no integer runtime type (https://www.typescriptlang.org/docs/handbook/2/everyday-types.html). `9007199254740993` is stored as `9007199254740992` (verified). For exact integers use `bigint` (`BigInt("9007199254740993")` keeps the digits) or minor units with `Number.isSafeInteger`.
- Rounding belongs to the runtime, not to the type. `(2.5).toFixed(0)` is `"3"`, `(-2.5).toFixed(0)` is `"-3"`, `Math.round(-2.5)` is `-2`, and `(1.005).toFixed(2)` is `"1.00"` (verified, Node v22.23.1). Name the tie rule in every rounding function.
- `JSON.parse` returns `any`: `const x: string = JSON.parse("1")` compiles (verified). Nothing checks the value.
- `JSON.stringify` is typed to return `string`, but `JSON.stringify(undefined)` returns `undefined` (verified). `{ a: undefined }` serializes as `{}`, `NaN` and `Infinity` become `null`, and `JSON.stringify(1n)` throws `TypeError` (verified).
- `"\u{1F600}".length` is 2: strings are UTF-16 code units (verified). From 7.0, template literal types keep code points (announcement).
- Dates: `new Date("2026-01-15")` is UTC midnight. `new Date("2026-01-15T00:00")` is local time: on a machine at UTC-3 it gives `2026-01-15T03:00:00.000Z`, and with `TZ=UTC` it gives `2026-01-15T00:00:00.000Z` (verified). Store UTC instants; format with `Intl.DateTimeFormat` and an explicit `timeZone`.
- `Number("")` is 0, `Number("12px")` is NaN, `parseInt("12px")` is 12 (verified). Pick the parser the source calls.
- Key order: integer-like keys come first, in ascending order. `Object.keys({ b: 1, 2: "x", 1: "y" })` is `["1","2","b"]` (verified).
- Parse input as `unknown` and check it before use: references/runtime-validation.md.

## 7. Testing

- The repository's runner decides. Checked options: `node --test` (default discovery includes `*.test.ts`, `*-test.ts` and `test/**/*.ts`, https://nodejs.org/docs/latest-v22.x/api/test.html; an ES import in a `.ts` test did not need `"type": "module"` on Node v22.23.1, verified 2026-10-29), Vitest (`vitest run`, Node 22.12.0 or later; https://vitest.dev/guide/), and Jest (TypeScript through Babel or ts-jest; https://jestjs.io/docs/getting-started). Details: references/testing-and-tooling.md.
- Test runners do not type-check. Node's type stripping performs no checks, so `tsc --noEmit` stays in the gate.
- Layout: `test/<unit>.test.ts` for rule tests; `test/golden/<unit>/<case>.json` for recorded source outputs, written from the source and never from the target.
- Doubles: depend on an `interface` and inject it. A fake that lacks a method fails to compile: `const fake: Clock = {};` gives TS2741 (verified).
- Golden tests: parse the golden file through a validator, not `as`, then compare with `assert.deepStrictEqual` from `node:assert/strict`.
- Test names carry the rule id when the migration has one.

## 8. Quality gate

Run each command, read the real result, and report it. A gate that did not run is not a pass.

1. `npx tsc --version`: prints `Version 7.0.2` on 2026-10-29. Pass: the version matches the declared range.
2. `npm ci`: exit 0 with a lockfile in sync with `package.json`.
3. `npx tsc --noEmit -p tsconfig.json`: exit 0 and no output. On 2026-10-29 a clean file exits 0; a file with `const n: number = "x";` exits 1 with TS2322 under `--noEmit`.
4. `npm test` (runs the `test` script, for example `"test": "jest"`), or `node --test` for `node:test` suites: exit 0, with `# fail 0` in the summary. Verified with `node --test` and `"type": "module"`: `# pass 1`, `# fail 0`.
5. `npx eslint .`, only when the repository uses ESLint. Setup: `npm install --save-dev eslint @eslint/js typescript typescript-eslint` (https://typescript-eslint.io/getting-started).
6. Coverage, when the plan sets a minimum: the repository's own tool. Verify before use.

## 9. Migrating TO TypeScript

- Parity beats idiom. A type annotation is erased, so each runtime check of the source must be code (a guard or a validator) with a test (references/runtime-validation.md).
- Map each source construct with references/as-target.md. Constructs a unit usually needs: rounding, text, dates, errors, I/O and collections.
- Keep the source's numeric, text and date semantics (section 6). Write a test for each tie, boundary and error path before the code.
- One error model: one class or `code` per source exception, as in the class in section 4, and the source's message text when the source has a stable one.
- Keep the source's runtime objects. A non-const `enum` emits an object; a const enum is inlined and emits none (verified; references/type-system.md).

## 10. Migrating FROM TypeScript

- Read references/as-source.md. Look for type erasure, `as` casts, `any`, `undefined` in JSON, optional properties, enum emit, declaration merging, and the tsconfig settings that change the emitted JS.
- Before reading the code, record the source's `strict`, `target`, `module`, `rootDir`, `types`, `esModuleInterop` and `verbatimModuleSyntax` values, each with its `path:line`. Their defaults changed in 6.0 and 7.0.
- Traps the types do not show: runtime defaults (Node 22.18.0 and later strip types from `.ts` files by default, with no type check), implicit conversions (`Number("")` is 0), ordering (integer-like keys come first; `sort()` changes the array in place), encodings (`.length` counts UTF-16 code units), and time zones (`new Date("2026-01-15T00:00")` is local time). See references/as-source.md and references/as-target.md.

## 11. Anti-patterns

- `any` at a boundary: it turns checks off for the value and for everything derived from it.
- `as` on JSON, environment or network values: no check happens.
- `strict: false` to hide errors, without a `deviation` marker and a reason.
- `enum` in a `.ts` file that Node runs directly.
- `baseUrl` or `target: es5` in a TypeScript 7 project.
- A `JSON.parse` or `JSON.stringify` result used without a check for `any` or `undefined`.
- Money as a `number` float.
- `catch (e)` followed by `e.message` without narrowing.
- A fake object cast to an interface to skip the compiler.

## Library registry

- Registry: https://www.npmjs.com/ (package pages show versions, `engines`, license, maintainers and last publish date). Type packages live under `@types/*` on the same registry.
- Before adding a package, check the standard library and the TypeScript built-ins first. Then search npm, open the package page, and confirm: latest version, `engines.node` and `typescript` peer range compatible with the target, license, last publish, and open issues. Check the `@types/*` package matches the library's major version.
- Read the exact versions with `npm view <package> version engines peerDependencies` and pin them. Commit the lockfile.
- Full procedure and evaluation checks: `.claude/skills/migration-conduct/references/library-research.md`.

## Sources

- TypeScript homepage, current release banner: https://www.typescriptlang.org/
- npm registry: https://www.npmjs.com/
- TypeScript 7.0 announcement: https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/
- TypeScript blog index (7.1 beta, 6.0 and 7.0 posts): https://devblogs.microsoft.com/typescript/
- TypeScript 6.0 release notes: https://www.typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html
- TypeScript 3.0 release notes: https://www.typescriptlang.org/docs/handbook/release-notes/typescript-3-0.html
- TypeScript tsconfig reference: https://www.typescriptlang.org/tsconfig
- TypeScript handbook, narrowing, everyday types, objects, enums, type compatibility, declaration merging: https://www.typescriptlang.org/docs/handbook/2/narrowing.html, https://www.typescriptlang.org/docs/handbook/2/everyday-types.html, https://www.typescriptlang.org/docs/handbook/2/objects.html, https://www.typescriptlang.org/docs/handbook/enums.html, https://www.typescriptlang.org/docs/handbook/type-compatibility.html, https://www.typescriptlang.org/docs/handbook/declaration-merging.html
- Node.js 22 docs, TypeScript and test runner: https://nodejs.org/docs/latest-v22.x/api/typescript.html, https://nodejs.org/docs/latest-v22.x/api/test.html
- npm `ci`: https://docs.npmjs.com/cli/v11/commands/npm-ci
- Vitest guide: https://vitest.dev/guide/
- Jest getting started: https://jestjs.io/docs/getting-started
- typescript-eslint getting started: https://typescript-eslint.io/getting-started

Runtime values in sections 4 and 6 (JSON, Number, Date, string length, key order) were verified by running Node v22.23.1 on 2026-10-29. The ECMAScript text was not read: verify before use in a spec-level claim.
