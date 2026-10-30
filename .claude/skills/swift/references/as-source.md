Read this when the source you migrate from is Swift or an Apple UI. These are the places where the behavior is easy to miss, because it sits in the runtime, the compiler or the framework, not in the line you read. Apple documentation body text was mostly not verified offline; each such item says so.

# Reading Swift and Apple UI as the source

## Value and reference

- A struct is copied on assignment and when passed to a function. A class instance is shared: two names refer to one object (https://docs.swift.org/swift-book/documentation/the-swift-programming-language/classesandstructures/). A source that mutates a shared object through one name differs from a copy.
- Copy-on-write: standard collections such as `Array` and `Dictionary` copy their storage only when a shared copy is mutated. Not verified offline: exact storage rules. Do not rely on them for performance claims.

## Numbers

- `Int` arithmetic traps on overflow. `&+`, `&-` and `&*` wrap (https://docs.swift.org/swift-book/documentation/the-swift-programming-language/basicoperators/). A source that wraps and a Swift port that traps differ on overflow: test the boundary.
- Integer division `/` on `Int` truncates toward zero. Not verified offline: quote from the book page before citing. Verify before use.
- `Double.rounded()` rounds to the nearest integer and ties away from zero by default. Other rules are set with `rounded(_:)` and a `FloatingPointRoundingRule` (https://developer.apple.com/documentation/swift/floatingpointroundingrule). A source that rounds half to even needs the explicit rule.
- Floating-point text: `String(format:)` uses printf-style formatting. Not verified offline: exact tie rule of the format. Record the output on exact ties such as `2.5` at 0 digits and `0.125` at 2 digits, and copy the source's output.
- `Double` is an IEEE 754 type (https://developer.apple.com/documentation/swift/double). Equality of computed doubles is not guaranteed across operation orders.
- `Int` width: 64-bit on 64-bit Apple platforms. Not verified offline for every target: check `Int.bitWidth`.

## Text

- `String.count` counts extended grapheme clusters. A combined emoji or a flag counts as one. `String.utf16.count` counts UTF-16 code units (https://developer.apple.com/documentation/swift/string). A source that counts code units or bytes differs.
- Byte length: `String.utf8.count` counts UTF-8 bytes. Not verified offline: exact method name on the target SDK. Verify before use.
- String comparison with `==` uses Unicode canonical equivalence. A source that compares code units differs for composed and decomposed forms. Not verified offline: exact rule text. Verify before use.

## Optionals and forced unwrap

- A force unwrap `!` on `nil` traps at run time. A source that catches the missing value in a branch differs. Keep the source's branch.
- `Int(_:)` on a `String` returns `nil` when the text is not a number. Not verified offline: exact set of accepted forms (sign, whitespace, leading zeros, a `+` prefix). Test each form the source accepts.

## Dates and time

- `Date` is an instant with no time zone (https://developer.apple.com/documentation/foundation/date). Output that formats a `Date` depends on the formatter's time zone and locale. Not verified offline: default time zone of `DateFormatter`. Verify before use.
- A source that keeps a clock string without the zone differs from one that stores an instant.

## Async and actors

- After an `await`, the code may resume later, and other tasks may have changed shared state (https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/). A source that reads a value before an await and uses it after may differ.
- `@MainActor` code runs on the main thread. A source that updates UI from a background task differs in timing.
- Not verified offline: the exact runtime errors of strict concurrency in each language mode.

## Errors

- Errors are values that conform to `Error`. A `throws` function returns normally or throws (https://docs.swift.org/swift-book/documentation/the-swift-programming-language/errorhandling/). A source that uses an optional return instead of a throw differs in the error it gives.
- `defer` runs when the scope exits, including on a throw. Not verified offline: the exact order of several `defer` blocks, which runs in reverse declaration order per the book. Verify before use.

## Codable

- A `Codable` type decodes missing keys as errors unless the property is optional. Not verified offline: exact error type thrown by `JSONDecoder` for a missing key. Verify before use.
- Key names: `CodingKeys` maps property names to JSON keys. A source with different key names differs if the mapping is missed (https://developer.apple.com/documentation/foundation/encoding-and-decoding-custom-types).
- Date and number strategies of `JSONEncoder` and `JSONDecoder` are set per coder. Not verified offline: default date strategy. Verify before use.

## SwiftUI and UIKit state

- `@State` storage is owned by the view and is preserved while the view identity stays the same (https://developer.apple.com/documentation/swiftui/state). Not verified offline: the exact identity rules. Verify before use.
- `UIViewController` lifecycle order: `viewDidLoad` runs once per controller instance when its view is loaded, then `viewWillAppear` and `viewDidAppear` run each time it appears (https://developer.apple.com/documentation/uikit/uiviewcontroller). The page body was not verified offline: check the exact order on the target SDK before relying on it.
- Auto Layout: a view with ambiguous constraints gets a layout that the system picks, and the console logs the ambiguity. Not verified offline: exact wording of the log. Verify before use.
