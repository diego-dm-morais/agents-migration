# Semantics and coercion (JavaScript)

Read this when a migration touches comparisons, NaN, -0, number conversion, rounding, or number formatting. Outputs marked (probe) were run on Node.js 22.23.1 on 2026-10-29; other facts cite ECMAScript clauses (living draft at tc39.es, clause numbers to be verified against the 17th edition) or MDN.

## Loose equality (==)

- `==` follows the abstract equality algorithm (MDN Operators/Equality). Operands of the same type compare by value. `null` and `undefined` equal only each other. An object is converted to a primitive when the other operand is a primitive. The rest is decided case by case.
- Probe results:

| Expression | Result | Reason in one line |
|---|---|---|
| `[] == false` | `true` | the boolean and the array both reduce to `0` |
| `"" == 0` | `true` | the string converts to the number `0` |
| `"0" == false` | `true` | the boolean and the string both reduce to `0` |
| `[1] == 1` | `true` | the array converts to the string `"1"`, then to the number `1` |
| `null == 0` | `false` | `null` equals only `null` and `undefined` under `==` |
| `null >= 0` | `true` | relational operators convert `null` to `0` |
| `null == undefined` | `true` | the one special pair |

- Rule for migration: where the source compares values of one type, use `===`. Where it compares mixed types, write the conversion out and test each pair of types.

## NaN

- `NaN === NaN` is `false`. `Object.is(NaN, NaN)` is `true` (probe). MDN NaN: NaN is the only value that compares unequal to itself.
- `isNaN("hello world")` is `true`, but `Number.isNaN("hello world")` is `false` (MDN NaN). The global `isNaN` converts its argument first.
- Map and Set treat NaN as one key: `new Set([NaN, NaN]).size` is `1`, and `new Map([[NaN, "n"]]).get(NaN)` is `"n"` (probe).
- Rule: test NaN with `Number.isNaN`. A numeric parse must state what it returns for `"hello"` and for `""` (both paths to test in the source and in the target).

## Zero and -0

- `0 === -0` is `true`. `Object.is(0, -0)` is `false` (probe).
- `1 / -0` is `-Infinity` (probe).
- `String(-0)` is `"0"`, and `JSON.stringify(-0)` is `"0"` (probe). Text output drops the sign.
- `Math.round(-0.4)` returns `-0`: `Object.is(Math.round(-0.4), -0)` is `true` (probe; MDN Math/round says `Math.round` returns -0 for -0.5 <= x < 0).
- Map and Set treat -0 and +0 as one key: `new Map([[-0, "x"]]).get(0)` is `"x"`, `new Set([0, -0]).size` is `1`, and `[-0].includes(0)` is `true` (probe).
- Rule: if the source output can show a sign on zero, format it explicitly and test it. Otherwise test the value with `Object.is` where the sign matters.

## Doubles and integers

- A Number is an IEEE-754 binary64 value (ECMAScript 4.4.23, verify before use).
- `Number.MAX_SAFE_INTEGER` is `9007199254740991`. `2 ** 53 + 1 === 2 ** 53` is `true` (probe).
- `0.1 + 0.2` is `0.30000000000000004` (probe). Do not compare money or rates with `===`.
- `JSON.parse` and `Number(text)` both round `"9007199254740993"` to `9007199254740992` (probe).
- Rule: an exact integer above 2^53 travels as a string or a `BigInt`. Test the largest source value and the first value that does not fit.

## toFixed

ECMAScript 21.1.3.3 (verify before use), in order:

1. `d` must be an integer from 0 to 100, or the call throws RangeError (MDN toFixed).
2. The sign is removed from the number, and `-` is put back in front of the result.
3. The integer closest to the exact binary value of `x * 10^d` is chosen. On a tie the larger integer is chosen.

Probe results:

| Expression | Result | Why |
|---|---|---|
| `(2.5).toFixed(0)` | `"3"` | tie, larger integer |
| `(-2.5).toFixed(0)` | `"-3"` | sign removed first, then tie to larger |
| `(0.5).toFixed(0)` | `"1"` | tie, larger integer |
| `(1.005).toFixed(2)` | `"1.00"` | the binary value is below 1.005 |
| `(1.45).toFixed(1)` | `"1.4"` | the binary value is below 1.45 |

MDN examples with the same rule: `(2.35).toFixed(1)` is `"2.4"`, `(2.55).toFixed(1)` is `"2.5"`, `(-2.34).toFixed(1)` is `"-2.3"`.

## Math.round

ECMAScript 21.3.2.29 (verify before use): the result is the integral value closest to `x`; on a tie it is the one closer to +infinity.

| Expression | Result |
|---|---|
| `Math.round(2.5)` | `3` |
| `Math.round(-2.5)` | `-2` |
| `Math.round(-3.5)` | `-3` |
| `Math.round(3.5)` | `4` |
| `Math.round(0.49999999999999994)` | `0` (probe) |

The spec notes that `Math.round(x)` is not always `Math.floor(x + 0.5)`: the addition can round, and -0 differs.

## Half-even rounding

- Half-even (banker's) rounding is not built into `Math.round` or `toFixed`.
- `Uint8ClampedArray` uses half-even (ECMAScript 7.1.12, ToUint8Clamp, 17th edition): `new Uint8ClampedArray([0.5, 1.5, 2.5, 3.5])` gives `0,2,2,4` (probe). This is a conversion, not a rounding function a migration should copy blindly.
- Rule: implement half-even on integers or decimal strings, and test both tie directions (`2.5` and `3.5`).

## Typed-array truncation and bitwise conversion

- Bitwise operators convert their operands to 32-bit integers, and integer typed arrays truncate the fractional part before taking the low bits (MDN Number; verify before use).
- `new Int8Array([257, -257])` is `[1, -1]`, and `new Uint8Array([257, -257])` is `[1, 255]` (MDN Number; verify before use).
