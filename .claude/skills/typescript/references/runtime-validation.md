Read this when input comes from outside the program (JSON, environment, files, network) and the target must accept and reject the same values as the source.

# Runtime validation (TypeScript 7.0)

Types are erased. No annotation, generic or cast checks a value at runtime. The facts below were verified with `tsc` 7.0.2 and Node v22.23.1 on 2026-10-29, or cited from the official handbook.

## Pattern: parse as unknown, then check

```ts
interface Invoice { id: string; amountCents: number }

export function isInvoice(value: unknown): value is Invoice {
  if (typeof value !== "object" || value === null) return false;
  const v = value as Record<string, unknown>;
  return typeof v.id === "string" && typeof v.amountCents === "number" && Number.isSafeInteger(v.amountCents);
}

export function readInvoice(text: string): Invoice | undefined {
  const parsed: unknown = JSON.parse(text);
  return isInvoice(parsed) ? parsed : undefined;
}
```

- This file compiles under `--strict` with exit 0 (verified). The field names and checks are an example. Take the real ones from the source, with `path:line`.
- The cast after `typeof` is safe only because the `typeof` check runs first. Each property is then checked with `typeof` before it is used.

## Traps

- `JSON.parse` returns `any`: `const x: string = JSON.parse("1");` compiles (verified). A parsed value is never checked by its type.
- A cast skips the check: `JSON.parse('"s"') as number` compiles and `v + 1` gives `s1` (verified). Replace the cast with a guard.
- Extra keys survive. A value typed `{ x: number }` that holds `y` serializes `y`: `JSON.stringify({ x: 1, y: 2 })` gives `{"x":1,"y":2}` (verified). Decide per source whether to keep, drop or reject extra keys, and test one input with an extra key.
- Absent and `undefined` differ from `null`. `{ a: undefined }` serializes without `a` (verified). A source field that is absent, `null` or `undefined` are different inputs: test each one the source distinguishes.
- Big integers lose digits: `JSON.parse('{"v":9007199254740993}').v` is `9007199254740992` (verified). Parse such fields as strings and convert with `BigInt`: `BigInt("9007199254740993")` keeps the digits (verified).
- Coercion: `Number("")` is 0, `Number(" 12 ")` is 12, `Number("12px")` is NaN, and `parseInt("12px")` is 12 (verified). A guard built on `Number(x)` accepts the empty string. Use the parser the source calls, and test its rejects.
- Dates: `new Date("2026-01-15")` is UTC midnight and `new Date("2026-01-15T00:00")` is local time (verified: the results differ with `TZ=UTC`). Non-ISO text is implementation-defined: `new Date("2026-1-15")` is valid in Node v22.23.1 (verified). Accept only the formats the source accepts, and test the rejects.
- `JSON.stringify(undefined)` returns `undefined`, though its type is `string` (verified). A value that may be `undefined` needs a check before it is written as text.
- Non-finite numbers: `JSON.stringify({ n: NaN, i: Infinity })` gives `{"n":null,"i":null}` (verified).
- BigInt in JSON: `JSON.stringify(1n)` throws `TypeError: Do not know how to serialize a BigInt` (verified).
- Strings: `"\u{1F600}".length` is 2, so a length check counts code units, not characters (verified).

## Parity rules for validators

- The source decides what is accepted, rejected, defaulted and normalized. Cite each rule at `path:line` in the source. Do not infer a rule from a type.
- One test per rule and per rejected input, named with the rule id when the migration has one.
- Error output: keep the source's error code, and its message text when the source returns one.
- Defaults: apply the source's default values, where the source applies them.
- Never use `as` to skip a check that the source makes.
- Test the boundary values the source checks: empty strings, zero, negative numbers, values above 2^53 - 1, and the largest and smallest accepted dates.

## Checks in the source versus types in the target

- `tsc` checks types only. A runtime check in the source (a comparison, a parse, a range check, a required key) becomes code in the target, with a test.
- A schema library can generate such checks. It is a third-party dependency: name it in the plan and cite its official documentation. Verify before use.
- Keep the guard next to the type it guards, so a reader sees the rule and the type together.

## Sources

- TypeScript handbook, narrowing and everyday types: https://www.typescriptlang.org/docs/handbook/2/narrowing.html and https://www.typescriptlang.org/docs/handbook/2/everyday-types.html
- TypeScript tsconfig reference: https://www.typescriptlang.org/tsconfig
- Runtime values (JSON, Number, Date, string length): verified by running Node v22.23.1 on 2026-10-29. The ECMAScript text was not read: verify before use in a spec-level claim.
