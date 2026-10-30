Read this when a migrated unit has screens, components, navigation, state, platform branches, or touch and keyboard behavior. Facts were checked against the official React Native and React Navigation pages on 2026-10-30.

# Components, navigation and state (React Native)

## Core components

- Build with the core components: `View`, `Text`, `Pressable`, `ScrollView`, `FlatList`, `TextInput`, `Image` (https://reactnative.dev/docs/components-and-apis). The components-and-apis page was not read in full on 2026-10-30: verify each component's props before use.
- `Pressable` "is a Core Component wrapper that can detect various stages of press interactions on any of its defined children" (https://reactnative.dev/docs/pressable).
- `hitSlop` "Sets additional distance outside of element in which a press can be detected" and takes a `Rect` or a number (same page).
- The page read does not compare `Pressable` with `TouchableOpacity`: do not claim a preference without a source. Keep the source's component and its press behavior.

## Styles and layout

- `StyleSheet.create` is "An identity function for creating styles" (https://reactnative.dev/docs/stylesheet). Use it for static type checking.
- Flexbox defaults: `flexDirection` is `column`, `alignItems` is `stretch`, `alignContent` is `flex-start`, `flexShrink` is `0`. The page says the first, third and fourth differ from CSS on the web, and that `flex` takes only a single number (https://reactnative.dev/docs/flexbox).
- `alignContent` is `stretch` "when using Yoga on the web" (same page). React Native's layout engine is Yoga; this is stated on the page.

## Platform differences

- `Platform.OS` is `ios` on iOS and `android` on Android (https://reactnative.dev/docs/platform-specific-code).
- `Platform.select` takes keys `ios`, `android`, `native` or `default`. It picks "the most fitting value for the platform you are currently running on", trying the platform key, then `native`, then `default` (same page).
- Platform files: "React Native will detect when a file has a `.ios.` or `.android.` extension and load the relevant platform file when required from other components" (same page). Example: `BigButton.ios.js` and `BigButton.android.js` are both imported as `./BigButton` (same page).
- `.native.js` is for modules shared by iOS and Android with no platform difference (same page). The precedence of a `.ios.` file against a `.native.` file is not stated on that page: verify before use.
- Safe area: core `SafeAreaView` is deprecated and iOS only (https://reactnative.dev/docs/safeareaview). Use `react-native-safe-area-context`, which the same page names as the replacement.

## Keyboard

- `KeyboardAvoidingView` has a `behavior` prop: "Specify how to react to the presence of the keyboard." "On both iOS and Android, setting `behavior` is recommended" (https://reactnative.dev/docs/keyboardavoidingview).
- The value to use per platform is not stated on the page read: record the source's value and test on both platforms.

## Navigation

- React Navigation: "React Navigation is a navigation library for React Native and Web" (https://reactnavigation.org/docs/getting-started).
- Install `@react-navigation/native`. "The `@react-navigation/native` package contains the core functionality of React Navigation" (same page). Install `react-native-screens` and `react-native-safe-area-context` for most navigators (same page).
- Navigator packages (stack, tabs, drawer) are not named on the getting-started page: verify each in its own docs before use.
- A source's back behavior, header, and tab state are the behavior. Write one test per transition.

## State

- Local state: `useState` or `useReducer` in the component. Shared logic: a plain function or a reducer that the component calls, so a test can run it without rendering.
- A store library is a project choice. Verify its docs and the pinned version before use. None is named as the default here.
- Parity risk: state reset on unmount. Test what the source keeps when the user leaves a screen and comes back.

## Async results and leaving a screen

- A request that finishes after the user leaves the screen is a case the source may handle one way, and the port must match it. Record the source's behavior with a test: the source may apply the result, drop it, or show an error.
- The mechanism (cleanup flag, abort, or ignore) is an implementation choice. The React Native pages read do not define it: verify against the pinned React docs before use.

## Parity checklist for UI units

- List each source screen transition and each platform branch, and write one test per item.
- Check the flexbox defaults on each layout: set `flexDirection`, `flexShrink` and `alignContent` explicitly where the source relies on them.
- Check the press behavior: `Pressable` press stages and `hitSlop`.
- Check the keyboard `behavior` value on both platforms.
- Check the safe-area handling: the source's inset behavior on Android, where core `SafeAreaView` does not apply.
- Check the back behavior and the header in each navigator.
