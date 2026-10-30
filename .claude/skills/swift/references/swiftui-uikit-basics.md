Read this when you write or read SwiftUI or UIKit UI code, or map UI state between a legacy screen and a Swift screen. Apple documentation pages are JavaScript-driven: in this run only the page titles loaded, so each body claim below is marked "not verified offline" unless noted. Verify each against the project's SDK before relying on it.

# SwiftUI and UIKit basics

## SwiftUI: views and state

- A SwiftUI view is a type that conforms to `View` and returns its body (https://developer.apple.com/documentation/swiftui/view). Not verified offline: the exact body text of the page.
- `@State`: a property wrapper for a value owned by the view, stored by SwiftUI (https://developer.apple.com/documentation/swiftui/state). Declare it `private` by convention; not verified offline whether the compiler requires it. Use it for simple value types the view owns.
- `@Binding`: a two-way reference to a value owned elsewhere, passed to a child view. Not verified offline: exact page text (https://developer.apple.com/documentation/swiftui/binding).
- `@Observable`: a macro that makes a class's stored properties observable by SwiftUI (https://developer.apple.com/documentation/observation/observable()). Not verified offline: the minimum OS version. Check the availability line on the page for the deployment target.
- `ObservableObject` with `@Published` and `@StateObject` / `@ObservedObject`: the older model that some deployment targets still require. Not verified offline: current status in the SDK. Verify before use.
- `@Environment`: reads a value that an ancestor provides (for example `colorScheme`). Not verified offline: exact page text. Verify before use.
- Rule of thumb: state the view owns is `@State`; state it shares is an observable model passed in; a value the view edits in a child is `@Binding`.

## SwiftUI: navigation

- `NavigationStack` is the container for a stack of views driven by a path or by `NavigationLink` (https://developer.apple.com/documentation/swiftui/navigationstack). Not verified offline: availability line and page text. Check the minimum OS on the page.
- The older `NavigationView` is deprecated in current SDKs. Not verified offline: exact deprecation status. Verify before use.

## SwiftUI: value and identity

- A view's identity decides whether its `@State` survives. A view that changes identity loses its state. Not verified offline: exact rule. Verify before use.

## UIKit: view controller lifecycle

- `UIViewController` runs these methods in order on first presentation: `loadView` (if the view is not loaded), `viewDidLoad`, `viewWillAppear`, `viewWillLayoutSubviews`, `viewDidLayoutSubviews`, `viewDidAppear` (https://developer.apple.com/documentation/uikit/uiviewcontroller). Not verified offline: the exact order and the page body. Check on the target SDK.
- `viewDidLoad` runs once per controller instance. `viewWillAppear` and `viewDidAppear` run each time the view appears. Not verified offline: exact page text. Verify before use.
- `viewDidLayoutSubviews` may run more than once. Do not add views there. Not verified offline. Verify before use.

## UIKit: navigation

- `UINavigationController` manages a stack of view controllers (https://developer.apple.com/documentation/uikit/uinavigationcontroller). Not verified offline: exact page text. Verify before use.
- `pushViewController` and `popViewController` change the stack. Not verified offline: animated defaults. Verify before use.

## Auto Layout basics

- Auto Layout describes a view's position and size with constraints (`NSLayoutConstraint`), which the layout engine solves (https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/AutolayoutPG/). This page is an archive page; not verified offline: its current status.
- Use `translatesAutoresizingMaskIntoConstraints = false` on a view that you lay out with code constraints. Not verified offline: exact text. Verify before use.
- Constraints must be unambiguous: each view needs enough constraints to fix its position and size. Ambiguous layouts are reported at run time. Not verified offline: exact message text.

## Checks before using a fact from this file

- Open the page at the URL, and read the availability line and the body text. If the page does not load, mark the claim "not verified offline" in the target file, as this file does.
