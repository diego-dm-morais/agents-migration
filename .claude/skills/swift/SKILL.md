---
name: swift
description: "Swift with SwiftUI and UIKit for iOS and macOS UI: value vs reference semantics, optionals, Codable, @State, @Binding, @Observable, @Environment, NavigationStack, UIViewController lifecycle, Auto Layout basics, XCTest and XCUITest, and the build and test gate. Use for Swift code, Package.swift, Xcode projects, SwiftUI or UIKit views, or migrations to or from Swift and iOS/macOS UI."
metadata:
  baseline: "Swift 6 language mode and current Xcode, to be verified on the project's toolchain"
  verified: "2026-10-30"
---

# swift (Swift with SwiftUI and UIKit, iOS and macOS)

Practice for Swift code and Apple platform UI, used when Swift or Apple UI is the source or the target of a migration. Facts were checked against the official Apple and swift.org pages on 2026-10-30. Most Apple documentation pages are JavaScript-driven: the fetch returned only the page title, so the body text of those pages was NOT verified in this run. Every such claim is marked "not verified offline" and must be checked on the project's toolchain before it is relied on. No Swift toolchain or Xcode is installed on the machine where this skill was written, so no gate command was run. Sources are listed at the end.

## 1. Scope and versions

- Record the Swift version (`swift --version`), the Xcode version (`xcodebuild -version`) and the deployment target (iOS or macOS minimum) that the project actually uses. The current stable Swift version is listed at https://www.swift.org/install/ (checked 2026-10-30: "Install (6.4.2)"); the project's own toolchain is what counts.
- Read the language mode from `Package.swift` (`swift-tools-version`) or from the Xcode build settings (`SWIFT_VERSION`). Do not assume Swift 6 strict concurrency unless the project enables it.
- SwiftUI and UIKit have per-OS availability. Check each API's availability line on its documentation page, and guard newer APIs with `if #available(...)` where the deployment target is older.
- If the project declares none of the above, use this baseline and say so in the report.

## 2. Layout and build

- Swift Package Manager: `Package.swift` declares targets and dependencies (https://www.swift.org/documentation/package-manager/). Xcode projects declare targets in the `.xcodeproj` or `.xcworkspace`. Keep the project's own layout; do not reorganize it in a migration.
- Commit `Package.resolved` when the project does (Xcode and SwiftPM both write it).
- Split by responsibility: pure Swift logic in types that import only `Foundation` (no `SwiftUI` or `UIKit`) and read no clock; adapters for files, network and platform; views that only show state. Tests import the pure types.
- Do not invent module or target names. Use the names the project already has.

## 3. Idioms

- Structs are value types: assignment and passing copy them. Classes are reference types: assignment shares one instance. Choose the kind the source's semantics need (references/as-source.md, section "Value and reference").
- Optionals: a value of type `T?` is either a `T` or `nil`. Unwrap with `if let`, `guard let`, or `??` where the source default is known. Force unwrap `!` only where the source guarantees the value and a crash is the source's behavior.

```swift
guard let count = Int(text) else {
    // the source's rejection path goes here, with the source's message
    return
}
```

- `Int(_:)` on a `String` returns `nil` when the text is not a number (https://developer.apple.com/documentation/swift/int/init(_:)-4bnaf; not verified offline: exact accepted forms).
- Codable: a type conforms to `Codable` to encode to and decode from an external format such as JSON, with `JSONEncoder` and `JSONDecoder` (https://developer.apple.com/documentation/foundation/encoding-and-decoding-custom-types). Keep the source's key names with `CodingKeys` when they differ from the property names.
- Views and state: see references/swiftui-uikit-basics.md for the property wrappers, `@Observable`, `@Environment` and `NavigationStack`, and for the UIKit controller lifecycle and Auto Layout.
- Business logic lives in plain Swift types that the view calls. The view holds only the state it shows.

## 4. Errors, resources and exit

- Errors are values of a type that conforms to `Error`. Throwing functions are marked `throws` and called with `try`. Handle with `do` / `catch`, or propagate with `try` (https://docs.swift.org/swift-book/documentation/the-swift-programming-language/errorhandling/).
- Map each source exception to one error type with a stable name. Keep the source message when the source emits it.
- `defer` runs a block when the scope exits, whether or not an error is thrown (https://docs.swift.org/swift-book/documentation/the-swift-programming-language/statements/). Use it to close files and resources.
- Process exit: `exit(_:)` from Glibc or Foundation ends the process at once. Not verified offline: whether it runs `defer` blocks of the calling scope (it does not run them for the frames above it). Verify before use.
- In UI apps the process is not exited by library code. Do not add exit calls to view or model code.

## 5. Concurrency

- Swift Concurrency uses `async` and `await` (https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/).
- `@MainActor` marks code that must run on the main thread. UI state and UIKit calls run on the main actor. Not verified offline: the exact diagnostics of strict concurrency checking in each language mode.
- `Task { }` starts asynchronous work from synchronous code; `Task.cancel()` requests cancellation, and the work checks it (not verified offline: exact semantics). Verify before use.
- After an `await`, the code may resume on another point of the program. A value read before an `await` can be stale: re-read it, or keep the section free of awaits.

## 6. Data and numbers (parity traps)

- `Int` is 64-bit on 64-bit Apple platforms. Not verified offline: the exact width on each target. Check `Int.bitWidth` on each target before relying on it (https://developer.apple.com/documentation/swift/int).
- Arithmetic on `Int` traps on overflow in Swift. The `&+` operators wrap instead (https://docs.swift.org/swift-book/documentation/the-swift-programming-language/basicoperators/). Use the operator the source uses.
- `Double` is a 64-bit IEEE 754 type (https://developer.apple.com/documentation/swift/double).
- `Double.rounded()` with no argument uses `.toNearestOrAwayFromZero`; a tie rule is set with `rounded(_:)` and a `FloatingPointRoundingRule` (https://developer.apple.com/documentation/swift/floatingpointroundingrule). Test each tie on the target.
- `String.count` counts extended grapheme clusters, not UTF-16 code units. `String.utf16.count` counts UTF-16 code units (https://developer.apple.com/documentation/swift/string). A source that counts code units differs: test with a surrogate pair and with a combined emoji.
- Formatting a double: `String(format:)` uses C printf rules (not verified offline: exact tie behavior). Verify before relying on it.
- `Date` is an instant with no time zone. Formatting with `DateFormatter` or `Date.FormatStyle` applies a time zone and locale (not verified offline: exact default time zone). Store instants as `Date` and set the zone explicitly when formatting.

## 7. Testing

- Unit tests use XCTest (https://developer.apple.com/documentation/xctest). Test classes subclass `XCTestCase`, and test methods start with `test`.
- UI tests use XCUITest, which drives the app through `XCUIApplication` (https://developer.apple.com/documentation/xctest/xcuiapplication). Not verified offline: the exact element query API of the current Xcode. Verify before use.
- Name each test with its rule id when there is one, and keep one behavior per test:

```swift
func testBR_ROUND_002_roundsTiesAwayFromZero() {
    XCTAssertEqual((3.5).rounded(), 4)
    XCTAssertEqual((-3.5).rounded(), -4)
}
```

- Doubles: hand-written fakes first. Put each external dependency behind a protocol that the unit receives as a parameter.
- Test layout, commands and gate: references/testing-and-tooling.md.

## 8. Quality gate

Run each command in the project root and report its real output. A gate that did not run is not a pass. No toolchain was installed in this run, so none of these commands was run here.

1. Format: `swift-format lint --recursive --strict Sources Tests` (the tool ships with the Swift toolchain on recent versions; not verified offline: presence and flags on the project's toolchain). Verify before use.
2. Build: `swift build` for a Swift package, or `xcodebuild -scheme <scheme> -destination '<destination>' build` for an Xcode project. The destination string is project-specific.
3. Test: `swift test` for a package, or `xcodebuild -scheme <scheme> -destination '<destination>' test` for an Xcode project (https://developer.apple.com/documentation/xcode/building-and-testing-software).

- Run all three, even when the first one fails, and report each command, its exit code, and the line that decides the result.

## 9. Migrating TO Swift / SwiftUI / UIKit

- Parity beats idiom. Choose an idiom only when inputs, outputs and errors stay the same. Otherwise keep the source behavior, and mark the difference `deviation` with its reason and source.
- Map each source construct with references/as-target.md: numbers, text, dates, errors, I/O and collections.
- Write a test for each tie, boundary and error path before writing the code.
- Record the expected output from the source, not from the Swift target, and compare against it.
- For UI, keep the source's state transitions and map them to the property wrappers or the view controller lifecycle that the target uses (references/swiftui-uikit-basics.md).

## 10. Migrating FROM Swift / SwiftUI / UIKit

- Read references/as-source.md for the places where Swift behavior hides: value versus reference copies, optionals, `Int` overflow, grapheme counts, `Date` time zones, async resumption and main-actor rules.
- Read references/swiftui-uikit-basics.md for the state and lifecycle facts behind each trap.
- Cite the source with `path:line` for each rule, and check each Swift behavior it depends on against the official pages listed in the references.

## 11. Anti-patterns

- Force unwrap `!` on a value the source may leave empty.
- A class where the source expects a copy, or a struct where the source expects shared mutation.
- `Int` arithmetic that overflows where the source wraps, or the reverse.
- Counting characters with `String.count` where the source counts code units.
- Updating UI state off the main actor.
- Reading a value before an `await` and using it after, when another task may have changed it.
- Calling `DateFormatter` with the implicit time zone where the source fixes one.
- Keeping business logic inside a view body, where tests cannot reach it.

## Sources

- Apple documentation (body text not verified offline; titles only): https://developer.apple.com/documentation/swiftui/state, https://developer.apple.com/documentation/observation/observable(), https://developer.apple.com/documentation/swiftui/navigationstack, https://developer.apple.com/documentation/uikit/uiviewcontroller, https://developer.apple.com/documentation/xctest, https://developer.apple.com/documentation/xctest/xcuiapplication, https://developer.apple.com/documentation/swift/codable
- Apple, other: https://developer.apple.com/documentation/swift/double, https://developer.apple.com/documentation/swift/string, https://developer.apple.com/documentation/swift/int, https://developer.apple.com/documentation/swift/floatingpointroundingrule, https://developer.apple.com/documentation/foundation/encoding-and-decoding-custom-types, https://developer.apple.com/documentation/xcode/building-and-testing-software
- Swift book (swift.org): https://docs.swift.org/swift-book/documentation/the-swift-programming-language/classesandstructures/, https://docs.swift.org/swift-book/documentation/the-swift-programming-language/optionalchaining/, https://docs.swift.org/swift-book/documentation/the-swift-programming-language/errorhandling/, https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/, https://docs.swift.org/swift-book/documentation/the-swift-programming-language/basicoperators/, https://docs.swift.org/swift-book/documentation/the-swift-programming-language/statements/
- Swift Package Manager: https://www.swift.org/documentation/package-manager/
- Reference files: references/as-source.md, references/as-target.md, references/swiftui-uikit-basics.md, references/testing-and-tooling.md
