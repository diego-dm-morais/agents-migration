# Reading JavaScript as the source

Read this when the source you migrate from is JavaScript. These are the places where behavior is easy to miss, because the language does it without a line of code. Outputs marked (probe) were run on Node.js 22.23.1 on 2026-10-29. Other outputs cite the specification or MDN.

## Equality and coercion

- `==` converts operands before comparing. `[] == false` is `true`; `"" == 0` is `true`; `"0" == false` is `true`; `[1] == 1` is `true` (probe). Find each `==` and state the operand types.
- `null == 0` is `false`, but `null >= 0` is `true` (probe). Relational operators convert `null` to `0`. Equality does not.
- `NaN` is the only value that is not equal to itself: `NaN === NaN` is `false` (MDN NaN, Operators/Equality).
- `0 === -0` is `true`, but `Object.is(0, -0)` is `false` (probe).

Details: references/semantics-and-coercion.md.

## Numbers

- Every number is an IEEE-754 double (ECMAScript 4.4.23, verify before use). `0.1 + 0.2` is `0.30000000000000004` (probe). Look for money, counters and identifiers above `9007199254740991`.
- `2 ** 53 + 1 === 2 ** 53` is `true` (probe). A source that adds identifiers or counts past 2^53 loses digits silently.
- `Number("9007199254740993")` and `JSON.parse("9007199254740993")` both give `9007199254740992` (probe).
- `toFixed(d)` rounds ties to the larger integer, after removing the sign: `(2.5).toFixed(0)` is `"3"`, `(-2.5).toFixed(0)` is `"-3"` (ECMAScript 21.1.3.3, verify before use). It uses the exact binary value: `(1.005).toFixed(2)` is `"1.00"` and `(1.45).toFixed(1)` is `"1.4"` (probe). Copy the source output exactly; do not fix it in the target.
- `Math.round` rounds ties toward +infinity: `Math.round(-2.5)` is `-2`, `Math.round(2.5)` is `3` (ECMAScript 21.3.2.29, verify before use). `Math.round(0.49999999999999994)` is `0` (probe).
- Bitwise operators convert to 32-bit integers, and typed arrays truncate: `new Int8Array([257, -257])` is `[1, -1]` (MDN Number; verify before use).

## Strings and text

- `.length` counts UTF-16 code units: `"\u{1F600}".length` is `2`, and `[..."\u{1F600}"].length` is `1` (probe; MDN String/length).
- Sorting strings with the default comparator uses UTF-16 code unit order: `["b", "B", "a"].sort()` is `["B", "a", "b"]` (probe; MDN Array/sort). A `localeCompare` call would order them differently.
- `String.prototype.normalize()` is not applied unless the code calls it. `"\u00e9" === "e\u0301"` is `false` (probe).

## Dates and time

- Months are zero-based (MDN Date): `new Date(Date.UTC(2026, 0, 31))` is January 31.
- Out-of-range parts carry over: `Date.UTC(2026, 1, 31)` is `2026-03-03T00:00:00.000Z` and `Date.UTC(2026, 12, 1)` is `2027-01-01T00:00:00.000Z` (probe; MDN Date describes the carry).
- Formatting without a `timeZone` option depends on the environment (verify before use: no explicit MDN statement found). Look for `toString`, `toLocaleString` and `getHours` calls, and check which zone the source relies on.
- `Intl.DateTimeFormat` with `timeZone: "UTC"` formats `Date.UTC(2026, 0, 31, 23, 30)` as `1/31/2026` (probe; MDN Intl/DateTimeFormat).

## Sorting

- `sort()` with no comparator converts each element to a string and compares code units: `[10, 9, 1, 80].sort()` is `[1, 10, 80, 9]` (probe; MDN Array/sort).
- `sort()` changes the array in place and returns the same reference (MDN Array/sort). A source that keeps the original array must copy it first.
- `undefined` elements sort to the end, without a call to the comparator (MDN Array/sort).
- A comparator that returns `NaN` counts as equal (MDN Array/sort).

## Serialization

- `JSON.stringify({ a: undefined, b: 1 })` is `{"b":1}`: undefined object fields are dropped (probe).
- `JSON.stringify([undefined, 1])` is `[null,1]`: undefined array items become `null` (probe).
- `JSON.stringify(NaN)` and `JSON.stringify(Infinity)` are `null` (probe).
- `JSON.stringify(new Date(0))` is `"1970-01-01T00:00:00.000Z"`, because `Date` has a `toJSON` method (probe).
- `JSON.stringify({ big: 1n })` throws `TypeError: Do not know how to serialize a BigInt` (probe).
- `String(-0)` and `JSON.stringify(-0)` are both `"0"` (probe): the sign of -0 disappears in text output.
- Key order: integer-like keys come first in ascending order, then string keys in insertion order (probe: `Object.keys({ b: 1, 2: 1, a: 1, 1: 1 })` is `["1","2","b","a"]`).

## Errors and exceptions

- `throw` accepts any value: `throw "plain string"` is legal, and the catch receives a string (probe). Check what the source catches and how it reports a non-Error value.
- `new Error("outer", { cause })` keeps the inner error reachable through `cause` (MDN Error/cause).
- An error's `message` is part of the output only when the source returns it. `stack` is not a stable output.

## Ordering and asynchronous behavior

- Promise callbacks run as jobs in first-in, first-out order. A `.then` on an already resolved promise queues one job, and an `await` resumes as a later job (probe; references/async-and-ordering.md).
- Resolving a promise with another promise adds two jobs before its reactions run (probe).
- `Promise.all` rejects with the first rejection (MDN Promise/all). `Promise.allSettled` keeps each outcome in input order (probe).

## Built-ins and module state

- A module-level variable lives as long as the module is loaded and is shared by all callers. Look for caches, counters and singletons in the source.
- Code that assigns to a built-in prototype or global changes behavior for every module in the same realm. Find those assignments with a search over the snapshot.
