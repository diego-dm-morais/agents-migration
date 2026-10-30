Read this when the source you migrate from is TypeScript. These are the places where the behavior is easy to miss, because it sits in the types, the compiler settings or the Node.js runtime, not in the code you read.

# Reading TypeScript as the source

Each trap gives the input, the output the language gives (verified on 2026-10-29 with `tsc` 7.0.2 or Node v22.23.1, unless marked), and the rule to follow. Copy the source output exactly; do not fix it in the target.

## Types are erased

- Annotations, `interface`, `type`, generics and `as` casts compile to nothing. A check written only as a type is not a check at runtime. Look for the runtime checks in the code.
- `as` is not a check: `JSON.parse('"s"') as number` gives `s1` for `v + 1` (verified). Do not add a check the source lacks, and do not remove one it has.
- `any` turns checks off for the value and for what it produces. Find each `any`, and the code that reads its result.

## Numbers

- `number` is the only numeric type and is a double (https://www.typescriptlang.org/docs/handbook/2/everyday-types.html). `9007199254740993` prints `9007199254740992` (verified).
- `0.1 + 0.2` is `0.30000000000000004` (verified). Money computed with `number` drifts.
- `(2.5).toFixed(0)` is `"3"`, `(-2.5).toFixed(0)` is `"-3"`, `Math.round(-2.5)` is `-2`, and `(1.005).toFixed(2)` is `"1.00"` (verified). The tie rules differ; copy the output.

## Text

- `.length` counts UTF-16 code units: `"\u{1F600}".length` is 2 (verified).
- From 7.0, template literal types keep code points (7.0 announcement). A type-level string utility written for code units behaves differently in 7.0.

## JSON and serialization

- `JSON.stringify({ a: undefined })` is `{}` (verified). `JSON.stringify([undefined])` is `[null]` (verified).
- `JSON.stringify(undefined)` returns `undefined`, although its type is `string` (verified).
- `JSON.stringify({ n: NaN, i: Infinity })` is `{"n":null,"i":null}` (verified).
- `JSON.stringify(1n)` throws `TypeError` (verified).
- `JSON.parse` returns `any`. A large integer in the input loses digits: `9007199254740993` becomes `9007199254740992` (verified).

## Optional properties

- With `exactOptionalPropertyTypes` off, `{ a: undefined }` is accepted for `a?: number` (verified). With it on, the same object is rejected (verified, TS2375). Read the source's tsconfig before deciding which one applies.
- The key can exist with the value `undefined`: `"a" in { a: undefined }` is true (verified). Output that lists keys shows it; JSON does not.

## Enums

- A non-const `enum` is a runtime object. A source that reads `Color` at runtime needs that object (verified: the emitted JS starts with `var Color;`).
- A const enum is inlined at each use and emits no object: `const sz = 0 /* Size.S */;` (verified). The source reads the number, not the name.
- Under `isolatedModules`, an ambient const enum in a `.d.ts` file cannot be used (https://www.typescriptlang.org/docs/handbook/enums.html).

## Structural typing and excess properties

- A literal with an extra member is an error at compile time (TS2353, verified). Such code cannot be in a source that compiles.
- A variable with an extra member compiles. Its JSON keeps the member. The literal `const q: { x: number } = { x: 1, y: 2 };` does not compile: TS2353, "Object literal may only specify known properties, and 'y' does not exist in type '{ x: number; }'" (tsc 7.0.2, exit 1). It compiles through a variable: `const o = { x: 1, y: 2 }; const q: { x: number } = o;` (exit 0). `JSON.stringify(q)` gives `{"x":1,"y":2}` (verified in Node v22.23.1; https://www.typescriptlang.org/docs/handbook/type-compatibility.html). Input from outside the program can carry extra members, so check each input.

## Declaration merging

- Two `interface` declarations with the same name merge (https://www.typescriptlang.org/docs/handbook/declaration-merging.html). Find all declarations of a name, across files, before you read one.
- Two type aliases with the same name fail (TS2300, verified). Two classes with the same name fail (TS2300, verified).
- A namespace merges only with a declaration that comes before it (declaration-merging page).

## Compiler settings that change behavior

- `strict` is true by default in 6.0 and 7.0 (6.0 release notes; 7.0 announcement). A source compiled with the 5.9 default (false) can contain implicit `any`. Read the source's tsconfig before you read its code: with no `strict` key, 7.0 reports TS7006 (verified).
- `target` and `module` decide the emitted JS. In 7.0, `module` defaults to `esnext` and `target` to the stable ECMAScript version before esnext (7.0 announcement). Record the source's values.
- `rootDir` defaults to the tsconfig folder in 6.0 and 7.0. Output paths move when sources sit in a subfolder: `./dist/src/index.js` instead of `./dist/index.js` (6.0 release notes).
- `types` defaults to `[]` in 6.0 and 7.0. Global names such as `process` are missing without `"node"`: "Cannot find name 'process'" (6.0 release notes).
- `esModuleInterop` and `alwaysStrict` cannot be false in 7.0 (7.0 announcement).
- `erasableSyntaxOnly` makes the source use only erasable syntax (tsconfig page; verify before use). `verbatimModuleSyntax` turns `isolatedModules` on by default (tsconfig page; verify before use).

## Runtime: Node.js type stripping

- Node 22.18.0 and later run `.ts` files by removing types, with no type check (https://nodejs.org/docs/latest-v22.x/api/typescript.html).
- Enum declarations, namespaces with runtime code, parameter properties, import aliases, decorators and tsconfig `paths` fail under type stripping (nodejs doc). `enum E { A }` fails with `ERR_UNSUPPORTED_TYPESCRIPT_SYNTAX` (verified).
- Check whether the source runs `.ts` files directly (type stripping) or runs compiled `.js` output. The two behave differently when the source uses a construct that type stripping rejects.
