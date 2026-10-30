Read this when a source or target uses types: strict flags, structural compatibility, narrowing, any and unknown, optional properties, enums or declaration merging.

# Type system (TypeScript 7.0)

Types are erased at compile time. Every statement here was checked with `tsc` 7.0.2 on 2026-10-29, or cited from the official handbook and tsconfig reference.

## Strict flags

| Flag | Default in 7.0 | What it changes |
|---|---|---|
| `strict` | `true` | Umbrella for the strict family. Members can be turned off one by one (https://www.typescriptlang.org/tsconfig). |
| `noImplicitAny` | on (in `strict`) | A parameter with no type is an error: `function untyped(x)` gives TS7006 (verified). |
| `strictNullChecks` | on (in `strict`) | "when a value is `null` or `undefined`, you will need to test for those values before using methods or properties on that value" (everyday-types page). |
| `useUnknownInCatchVariables` | on (in `strict`) | A `catch` variable is `unknown`: `e.message` gives TS18046 (verified). |
| `strictFunctionTypes`, `strictBindCallApply`, `strictPropertyInitialization`, `noImplicitThis` | on (in `strict`) | Members of the strict family (tsconfig page). |
| `alwaysStrict` | on; cannot be false in 7.0 | Emits `"use strict"` (7.0 announcement). |
| `exactOptionalPropertyTypes` | off; not in `strict` | An optional property rejects an explicit `undefined`: TS2375 with the flag, accepted without it (verified). |
| `noUncheckedIndexedAccess` | off; not in `strict` | An index read adds `undefined`: `arr[5]` gives TS2322 with the flag, accepted without it (verified). |
| `erasableSyntaxOnly` | off (verified) | Reports constructs with runtime behavior: `enum` gives TS1294 with the flag (verified; tsconfig page). |
| `isolatedModules` | on if `verbatimModuleSyntax`, off otherwise (verify before use) | Warns on code a single-file transpiler cannot handle (tsconfig page). |

## Structural typing and excess properties

- Compatibility is by members, not by declared name (https://www.typescriptlang.org/docs/handbook/type-compatibility.html; verify before use).
- A variable holding an object with extra members is accepted: `let dog = { name: "Lassie", owner: "Rudd" }; pet = dog;` where `Pet` has only `name`.
- An object literal with an extra member is rejected: `const r: Point = { x: 1, y: 2 };` gives TS2353 (verified).
- Trap: the variable keeps the extra member at runtime. `q` has type `{ x: number }`, but the object has `y`: `JSON.stringify(q)` gives `{"x":1,"y":2}` (verified in Node v22.23.1 with the same object).
- Classes: private and protected members are compared. A class with a private member is compatible only with a source that has that member from the same class (type-compatibility page; verify before use).

## Narrowing

| Check | Narrows to |
|---|---|
| `typeof x === "number"` | `number` (handbook: `typeof` type guard) |
| `x instanceof Date` | `Date` |
| `"swim" in animal` | the members that declare `swim`; optional members exist on both sides |
| `x === y` | the type both can share (`string` in the handbook example) |
| `if (strs && typeof strs === "object")` | truthiness removes `null` and `undefined` |
| `switch (shape.kind)` | the union member with that literal `kind` |
| `function isFish(pet: Fish \| Bird): pet is Fish` | user-defined guard: a `true` result means `pet is Fish` |
| `default: const _exhaustiveCheck: never = shape;` | exhaustiveness: a new union member fails to compile here |

Discriminated union with exhaustive check, as in the handbook (https://www.typescriptlang.org/docs/handbook/2/narrowing.html):

```ts
interface Circle { kind: "circle"; radius: number }
interface Square { kind: "square"; sideLength: number }
type Shape = Circle | Square;

function getArea(shape: Shape) {
  switch (shape.kind) {
    case "circle":
      return Math.PI * shape.radius ** 2;
    case "square":
      return shape.sideLength ** 2;
    default:
      const _exhaustiveCheck: never = shape;
      return _exhaustiveCheck;
  }
}
```

- A guard narrows to what its check proves. A weaker check than the declared type is a runtime lie the compiler cannot see.

## any, unknown and assertions

- `any` disables checking for the value and everything derived from it. `let a: any = 1; a.foo.bar();` compiles (verified). The failure appears only at runtime.
- `unknown` is "the type-safe counterpart of `any`" (3.0 release notes). It must be narrowed before use (verified: `e.message` on `unknown` gives TS18046).
- `as` removes the type at compile time. "there is no runtime checking associated with a type assertion" (everyday-types page). Verified: `JSON.parse('"s"') as number` compiles, and `v + 1` prints `s1`.

## Optional properties and undefined

- `a?: number` reads as `number | undefined` under `strictNullChecks` (https://www.typescriptlang.org/docs/handbook/2/objects.html).
- Without `exactOptionalPropertyTypes`, `{ a: undefined }` is accepted for `a?: number` (verified). With the flag it gives TS2375.
- The runtime keeps the key: `"a" in { a: undefined }` is true and `Object.keys({ a: undefined })` is `["a"]` (verified).
- JSON drops it: `JSON.stringify({ a: undefined })` is `{}` (verified).

## Enums

- A non-const enum is a runtime object with forward and reverse mappings (https://www.typescriptlang.org/docs/handbook/enums.html). The emitted JS starts with `var Color;` (verified). String members get no reverse mapping.
- A const enum is inlined and emits no object: `const sz = 0 /* Size.S */;` (verified with `const enum Size { S, M }`).
- Ambient const enums in `.d.ts` files cannot be used with `isolatedModules` (enums page).
- A member with a computed value, such as `G = "123".length`, is computed, not constant (enums page).
- `enum` fails under `erasableSyntaxOnly` (verified) and under Node type stripping (verified).

## Declaration merging

- Two interfaces with the same name merge their members (https://www.typescriptlang.org/docs/handbook/declaration-merging.html). Verified: `interface Box { w: number }` and `interface Box { h: number }` give a box with both.
- A non-function member declared twice with different types fails: `n: number` and `n: string` give TS2717 (verified; the page says "they must be of the same type").
- Function members with the same name are overloads (declaration-merging page).
- Two classes with the same name fail with TS2300 (verified). The page says "classes can not merge with other classes or with variables."
- Two type aliases with the same name fail with TS2300 (verified). The page does not state this rule.
- Namespaces merge with a declaration only when they come after it (declaration-merging page).
