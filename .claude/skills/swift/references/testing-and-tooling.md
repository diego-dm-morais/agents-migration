Read this when you write tests, set up the quality gate, or choose a Swift or Apple tool. Commands were checked against the official pages where the pages loaded. None was run on the machine that wrote this file.

# Testing and tooling (Swift, Xcode, XCTest)

## Test layout

- Unit tests: XCTest. A test class subclasses `XCTestCase` and its test methods start with `test` (https://developer.apple.com/documentation/xctest). Not verified offline: exact page body.
- One test file per unit: `Tests/<Module>Tests/<Unit>Tests.swift` for a package, or the test target's folder in an Xcode project. Name each test with its rule id when there is one.
- UI tests: XCUITest, a separate UI test target. `XCUIApplication` launches and drives the app (https://developer.apple.com/documentation/xctest/xcuiapplication). Not verified offline: its element query API. Verify before use.

## Unit test with XCTest

```swift
import XCTest

final class RoundingTests: XCTestCase {
    func testBR_ROUND_002_roundsTiesAwayFromZero() {
        XCTAssertEqual((3.5).rounded(), 4)
        XCTAssertEqual((-3.5).rounded(), -4)
    }
}
```

- `XCTAssertEqual` compares two values. Not verified offline: the exact page body.

## UI test with XCUITest

```swift
import XCTest

final class CheckoutUITests: XCTestCase {
    func testBR_UI_001_showsInitialTotal() {
        let app = XCUIApplication()
        app.launch()
        // query elements from app and assert on what is shown
    }
}
```

- Not verified offline: exact element query methods and their waiting behavior. Verify before use.

## Commands

| Command | What it does | What passes |
|---|---|---|
| `swift build` | builds a Swift package | exit code 0 |
| `swift test` | runs the package tests | exit code 0, every test passes |
| `swift test --filter <name>` | runs the tests whose name matches | as above. Not verified offline: exact filter syntax. Verify before use. |
| `xcodebuild -scheme <scheme> -destination '<destination>' build` | builds an Xcode project | exit code 0 |
| `xcodebuild -scheme <scheme> -destination '<destination>' test` | runs the tests of an Xcode scheme | exit code 0, every test passes |
| `xcodebuild -list` | lists schemes and targets | not a pass or fail; shows names for the commands above |

- The destination string names a simulator or a device, for example `platform=iOS Simulator,name=<device name>`. Not verified offline: exact string format on the project's Xcode. Verify before use.
- Source: https://developer.apple.com/documentation/xcode/building-and-testing-software (page body not verified offline).

## Format and lint

- `swift-format` ships with the Swift toolchain on recent versions. `swift-format lint --recursive --strict Sources Tests` reports style issues. Not verified offline: presence and flag set on the project's toolchain. Verify before use.
- Use the project's existing formatter and config. Do not add a new formatter in a migration unless the plan names it.

## Doubles and fakes

- Put each external dependency behind a protocol that the unit receives as a parameter. Write a hand-made fake for it. This is the default.
- Time: pass a clock as a value. Call `Date()` only at the edge of the program.
- Randomness: pass the source as a parameter. Not verified offline: the random API. Verify before use.

## Gate

| Gate | Command | What passes | Verified in this run |
|---|---|---|---|
| Format | `swift-format lint --recursive --strict Sources Tests` | no issue reported; exit code 0 | not verified offline: presence and exit code |
| Build | `swift build` or `xcodebuild ... build` | exit code 0 | not run; command shape from Apple docs page list only |
| Test | `swift test` or `xcodebuild ... test` | exit code 0, every test passes | not run |

- Report each gate with its command, its exit code and the line that decides the result.
- Coverage: Xcode reports coverage when the scheme enables it. Not verified offline: the command-line flag. Verify before use.
