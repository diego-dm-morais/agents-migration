Read this when you map a source UI construct to React Native code. The left column is the concept; the middle column is the React Native idiom; the right column is the risk to test.

# Writing React Native as the target

| Concept | Idiom in this platform | Parity risk to test |
|---|---|---|
| Vertical stack | `View` with the default `flexDirection: 'column'` | the default is `column` here, not `row` as in CSS (https://reactnative.dev/docs/flexbox) |
| Horizontal row | `View` with `flexDirection: 'row'` set explicitly | a missing `row` lays children vertically |
| Wrapping lines | `flexWrap: 'wrap'` with `alignContent` | the default `alignContent` is `flex-start` (https://reactnative.dev/docs/flexbox) |
| Shrinking children | `flexShrink` set explicitly | the default is `0`, so children do not shrink unless set |
| Flex sizing | a single number in `flex` | the `flex` prop takes one number only (https://reactnative.dev/docs/flexbox) |
| Style values | `StyleSheet.create` with the source's values | `create` is type checking only, not runtime validation (https://reactnative.dev/docs/stylesheet) |
| Tap | `Pressable` with `onPress` | press stages and `hitSlop` change which touches count (https://reactnative.dev/docs/pressable) |
| Long press and press states | `Pressable` `onPressIn`, `onPressOut`, `onLongPress` | the source's order of press events, as recorded in its tests |
| Scrollable list | `FlatList` or `ScrollView` | list keys and `keyExtractor`; a list rendered with `ScrollView` does not virtualize |
| Text input | `TextInput` | the source's keyboard type, return key and submit behavior, as recorded |
| Keyboard avoidance | `KeyboardAvoidingView` with `behavior` set | "On both iOS and Android, setting `behavior` is recommended" (https://reactnative.dev/docs/keyboardavoidingview) |
| Safe area | `react-native-safe-area-context` | core `SafeAreaView` is deprecated and iOS only (https://reactnative.dev/docs/safeareaview) |
| Platform branch | `Platform.OS` or `Platform.select` | `select` falls back to `native`, then `default` (https://reactnative.dev/docs/platform-specific-code) |
| Platform files | `X.ios.tsx` / `X.android.tsx` / `X.native.tsx` | a platform file is loaded for its platform; precedence when two exist: verify before use |
| Navigation | React Navigation, one navigator per source flow | back behavior, the header, and the tab state; a port must keep the source's transitions (https://reactnavigation.org/docs/getting-started) |
| Local widget state | `useState` or `useReducer` | state is lost on unmount; the source's state transitions, one test each |
| Shared state | the project's chosen store, verified in its docs | the store's update order; not verified offline for any specific library |
| Side effects | `useEffect` with a cleanup return | the cleanup runs on unmount; a listener without cleanup leaks |
| Async action after leaving a screen | check whether the component is still mounted in the cleanup, or ignore the result | the source's observable output when the user leaves during a request |
| Text | `Text` around every string | a string outside `Text` is not verified offline: check the Text page |
| Locale and date output | the source's formatter, tested on the device engine | `Intl` and `Date` support is not stated on the environment page (https://reactnative.dev/docs/javascript-environment) |
| Numbers | JavaScript number rules from the `javascript` skill | IEEE-754 doubles; rounding ties |
| Errors | one error class per source error, with the source message | an unhandled promise rejection is not a source behavior unless the source has one |
| Exit | none in the app; record the source's behavior | a CLI exit code has no direct mobile equivalent: record as `deviation` |
| Tests | Jest, with React Native Testing Library for components | user-visible behavior, not internal state (https://callstack.github.io/react-native-testing-library/docs/start/intro) |
