Read this when you map a source construct to Swift, SwiftUI or UIKit code. The left column is the concept; the middle column is the Swift idiom; the right column is the risk to test.

# Writing Swift and Apple UI as the target

| Concept | Idiom in this language | Parity risk to test |
|---|---|---|
| Integer arithmetic | `Int` with an explicit range check, or a sized type where the source fixes a width | overflow traps in Swift; `&+` wraps; test the boundary |
| Decimal money | `Int` in minor units with a fixed scale; not `Double` | every tie; the output scale; negative values |
| Integer division | `/` on `Int` | truncation toward zero for negatives: verify before use |
| Rounding to an integer | `.rounded()` (ties away from zero) or `.rounded(.toNearestOrEven)` | the rule must match the source; test both tie directions |
| Fixed decimal text | `String(format:)` with an explicit format | the tie rule of the format: test `2.5` at 0 digits and `0.125` at 2 digits |
| Text length | `String.count` counts graphemes; `utf16.count` counts code units | the source's unit; a surrogate pair; a combined emoji |
| Absent value | optional `T?`; `if let`, `guard let`, `??` | a nil the source omits, or emits as an empty string |
| Instant in time | `Date`; set the time zone and locale explicitly at format time | local time leaking into output |
| Current time | inject a clock as a parameter; call `Date()` only at the edge | the test must control the value |
| Ordered collection | `Array`; `sort` is not guaranteed stable (not verified offline: check the sort docs) | equal elements may reorder if the source keeps input order |
| Keyed collection | `Dictionary`; iteration order is not defined | key order in output and in JSON: sort explicitly |
| Error model | an `enum` conforming to `Error` with one case per source exception | one case and one message per source exception |
| JSON out | `Codable` with `JSONEncoder`; set key and date strategies explicitly | key order (`outputFormatting`), null against omitted field |
| JSON in | `Codable` with `JSONDecoder`; typed fields | missing keys, extra keys, number types after decode |
| Parallel calls | `async let` or a task group; collect results in input order | completion order against input order |
| CPU-bound work | a detached task or a background actor; results cross actors as `Sendable` | a closure that captures more state than the source |
| UI state | `@State` for view-owned values; `@Observable` for shared models | the source's state transitions, one for one |
| Shared model | `@Observable` class (SwiftUI) or an `ObservableObject` with `@Published` for older targets | a copy where the source shares, or the reverse |
| Navigation | `NavigationStack` with a path or `NavigationLink` | the back stack after a pop, against the source's screen order |
| Legacy UI | `UIViewController` with `viewDidLoad` and `viewWillAppear` | the lifecycle order; work repeated on each appearance |
| Layout | Auto Layout constraints, or SwiftUI layout modifiers | ambiguous constraints; the layout at each size class |

- Parity beats idiom: when the idiom changes an output, keep the source behavior and record a `deviation`.
- A Swift type that the source expects to share state must be a class (or an `@Observable` class). A struct gives a copy.
