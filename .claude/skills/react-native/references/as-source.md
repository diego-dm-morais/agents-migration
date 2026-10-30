Read this when the source you migrate from is React Native. These are the places where the behavior is easy to miss, because it sits in the runtime, the platform, or the library, not in the line you read.

# Reading React Native as the source

## Layout

- `flexDirection` defaults to `column`, not `row`. `alignContent` defaults to `flex-start`, not `stretch`. `flexShrink` defaults to `0`, not `1`. The `flex` prop accepts only a single number (https://reactnative.dev/docs/flexbox). A source that relies on the CSS defaults is a source whose layout a web port would get wrong.
- The `alignItems` default is `stretch` (https://reactnative.dev/docs/flexbox). The page does not compare it with CSS; do not claim that it differs.
- `StyleSheet.create` is "An identity function for creating styles" and gives static type checking, not runtime validation (https://reactnative.dev/docs/stylesheet). A style value that is invalid at run time is not reported by `create`.
- Inline style objects and `StyleSheet` entries are both style values. Record which form the source uses: the flattening behavior of `StyleSheet.flatten` is not verified offline: verify before use.

## Platform branches

- `Platform.OS` is `ios` on iOS and `android` on Android (https://reactnative.dev/docs/platform-specific-code). A source with `Platform.OS === 'web'` or other values is outside this page: verify before use.
- `Platform.select({ ios, android, native, default })` tries the platform key first, then `native`, then `default` (https://reactnative.dev/docs/platform-specific-code). A source that lists keys in another order gets the same result by this rule, and the order of the keys in the object does not decide it.
- A file named `X.ios.js` or `X.android.js` is loaded for the matching platform (same page). The precedence when both a platform file and a `X.native.js` file exist was not stated on the page: verify before use. Look for both files in the source tree.
- `X.native.js` is for a module shared by iOS and Android with no platform differences (same page).

## Touch and press

- `Pressable` "can detect various stages of press interactions on any of its defined children" (https://reactnative.dev/docs/pressable). A source that handles press stages (press in, press out, long press) has behavior that a simple tap handler does not reproduce.
- `hitSlop` is "Sets additional distance outside of element in which a press can be detected" (https://reactnative.dev/docs/pressable). A source with a small visual target and a larger `hitSlop` accepts taps the visual size would not.

## Keyboard

- `KeyboardAvoidingView` takes a `behavior` prop. "Android and iOS both interact with this prop differently. On both iOS and Android, setting `behavior` is recommended" (https://reactnative.dev/docs/keyboardavoidingview). A source without `behavior` has a keyboard result that depends on the platform default: record the source's values and test each platform.
- Android keyboard behavior beyond the quoted sentence was not stated on the page read: not verified offline.

## Safe area

- `SafeAreaView` from React Native core is deprecated: "Use react-native-safe-area-context instead." It "is currently only applicable to iOS devices with iOS version 11 or later" (https://reactnative.dev/docs/safeareaview). A source that uses it has iOS-only inset behavior; a port must not assume it insets Android.

## Runtime

- React Native uses Hermes by default: "Hermes is used by default by React Native and no additional configuration is required to enable it" (https://reactnative.dev/docs/hermes). If Hermes is disabled, JavaScriptCore runs the code. "On iOS, JavaScriptCore does not use JIT due to the absence of writable executable memory in iOS apps" (https://reactnative.dev/docs/javascript-environment).
- "It is best to avoid relying on specifics of any runtime" (https://reactnative.dev/docs/javascript-environment). A source that depends on one engine's specifics is a `known-issue` to record, not to copy silently.
- Chrome debugging runs all JavaScript inside Chrome, which uses V8 (same page). Timing and number output can differ from the device run: test on the device engine.

## Text, numbers and dates

- The JavaScript environment page makes no statement about `Intl` or `Date` support (https://reactnative.dev/docs/javascript-environment). Output that depends on locale or time zone is not verified offline: read the source's formatting and test it on the device engine.
- Numbers are JavaScript doubles. Use the rules of the `javascript` and `nodejs` skills for rounding and string output.

## Navigation and state

- React Navigation is "a navigation library for React Native and Web" (https://reactnavigation.org/docs/getting-started). Navigator packages and their options are not named on that page: verify per navigator.
- The `react-native-screens` and `react-native-safe-area-context` packages are the dependencies "used by most navigators" (same page). A source that relies on native stack behavior depends on them.

## Testing evidence

- React Native's testing overview says the default template ships Jest (https://reactnative.dev/docs/testing-overview). The source's test files show what the author expected: read them, and cite them, but do not treat them as the behavior.
