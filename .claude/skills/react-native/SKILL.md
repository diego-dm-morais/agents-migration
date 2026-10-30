---
name: react-native
description: "React Native (core components, StyleSheet, Flexbox defaults that differ from web), React Navigation, state, platform differences (Platform.OS, platform file extensions, touch, keyboard, safe areas), Hermes, and Jest with React Native Testing Library for React Native code. Use for React Native components, screens, navigation, mobile UI code, or migrations of a mobile UI to or from React Native."
metadata:
  baseline: "React Native (current release; exact version not verified offline: read it from package.json of the project)"
  verified: "2026-10-30"
---

# react-native (React Native, React Navigation, Jest with RNTL)

Practice for React Native code, used when React Native is the source or the target of a migration of a mobile UI. Facts were checked against the official React Native, React Navigation, React Native Testing Library and Jest pages on 2026-10-30. No React Native toolchain was installed where this skill was written, so no gate command was run. Each library claim cites its official page; the sources are listed at the end. A claim that could not be verified is marked "not verified offline".

## 1. Scope and versions

- The baseline is the React Native release the project pins in `package.json` (`react-native` dependency) and its lockfile. Record the version in the report. The newest release number was not verified offline.
- React Native runs JavaScript on Hermes by default: "Hermes is used by default by React Native and no additional configuration is required to enable it" (https://reactnative.dev/docs/hermes). Hermes is "an open-source JavaScript engine optimized for React Native" (same page). If Hermes is disabled, React Native uses JavaScriptCore (https://reactnative.dev/docs/javascript-environment).
- Do not rely on runtime specifics: "It is best to avoid relying on specifics of any runtime" (https://reactnative.dev/docs/javascript-environment).
- Expo: not verified. The Expo docs page checked returned HTTP 404 on 2026-10-30. Do not add Expo steps or claims unless the project uses Expo and the Expo docs for the pinned version are read in the run.
- Target the React Navigation version the project declares. Install the core and the navigator packages it uses (https://reactnavigation.org/docs/getting-started).

## 2. Layout and build

- `package.json` declares `react-native`, `react`, the navigation packages and the test packages. Keep the project's package name and folder layout in the plan. Do not invent a package name.
- Split by responsibility: pure TypeScript or JavaScript logic in files that import no React Native module and read no clock; thin adapters for storage, network and device APIs; components that only render state.
- Platform-specific code goes in `Name.ios.js` / `Name.android.js` files, or in `Name.native.js` when iOS and Android share a module (https://reactnative.dev/docs/platform-specific-code). See references/components-navigation-state.md.
- Tests live beside the code or in a `__tests__` folder, run with Jest (https://reactnative.dev/docs/testing-overview). See references/testing-and-tooling.md.

## 3. Idioms

- Build the UI from core components: `View`, `Text`, `Pressable`, `ScrollView`, `FlatList`, `TextInput`, `Image`. Text rendering rule: "you must wrap all the text nodes inside of a `<Text>` component. You cannot have a text node directly under a `<View>`" (https://reactnative.dev/docs/text).
- Styles: `StyleSheet.create` returns the styles object. It is "An identity function for creating styles" and gives static type checking, not runtime validation (https://reactnative.dev/docs/stylesheet). Keep the source's style values; do not replace them with values from a design system.
- Flexbox: React Native's defaults differ from CSS on the web. `flexDirection` defaults to `column`, `alignContent` to `flex-start`, `flexShrink` to `0`, and the `flex` prop accepts only a single number (https://reactnative.dev/docs/flexbox). Set `flexDirection: 'row'` explicitly wherever the source lays out a row.
- Handle presses with `Pressable`, which "can detect various stages of press interactions on any of its defined children" (https://reactnative.dev/docs/pressable).
- Platform branches: `Platform.OS` is `ios` or `android`; `Platform.select` picks a value and tries the platform key, then `native`, then `default` (https://reactnative.dev/docs/platform-specific-code). See references/components-navigation-state.md.
- Keep the source's text, number and date formatting. Read references/as-source.md before choosing a formatter.

```tsx
const styles = StyleSheet.create({
  row: { flexDirection: 'row' }, // explicit: the default is 'column'
});
```

## 4. Navigation and state

- Navigation uses React Navigation: "React Navigation is a navigation library for React Native and Web" (https://reactnavigation.org/docs/getting-started). Install `@react-navigation/native` plus the navigator package the project uses. The navigator packages are not named on the getting-started page: verify the package for each navigator in its own docs.
- Install `react-native-screens` and `react-native-safe-area-context`, which the getting-started page calls "the dependencies used by most navigators" (same page).
- Local state: `useState` and `useReducer` in the component. Shared logic: plain functions or a reducer that the component calls. The state library, if any, is chosen by the project: verify its docs before use.
- Keep each source screen transition as one test. See references/components-navigation-state.md.

## 5. Errors, resources and exit

- Map each source error to one error class with a stable name. Keep the source message when the source emits it.
- Async calls return promises. Handle rejections in the component or in the adapter; an unhandled rejection is not a source behavior unless the source has one.
- Clean up listeners and timers in the effect cleanup function (`useEffect` return). The React Native docs for each API must be read for its unsubscribe method: verify before use.
- React Native has no `exit` that the app should call. Do not add a native exit call to match a CLI exit code; record the source's behavior instead (`deviation`).

## 6. Concurrency

- JavaScript runs on one thread for the JS side. `await` lets other work run; a value read before an `await` and used after it can be stale. Re-read it or keep the section free of awaits. The official sentence on this was not read: verify before use.
- Animations and gestures have their own rules and are not covered by this skill: not verified offline.

## 7. Data and numbers (parity traps)

- JavaScript numbers are IEEE-754 doubles. Use the rounding and string rules from the `nodejs` or `javascript` skill, not new ones.
- Date and locale output depends on the runtime. The React Native JavaScript environment page makes no statement about `Intl` or `Date` support: not verified offline. Read the source's formatting and test it on the device engine before relying on it.
- Record the source's expected output and compare it with a test. See references/as-source.md.

## 8. Testing

- Runner: Jest. The React Native template ships Jest with a preset: "The default template of React Native ships with Jest testing framework" (https://reactnative.dev/docs/testing-overview).
- Component tests: React Native Testing Library (RNTL). It "builds on top of React's test renderer and adds `fireEvent` and `query` APIs" (https://reactnative.dev/docs/testing-overview).
- Name each test with its rule id when there is one, and keep one behavior per test.
- Layout, commands and tool choice: references/testing-and-tooling.md.

## 9. Quality gate

Run each command in the project root and report its real output. A gate that did not run is not a pass. No React Native toolchain was installed in this run, so none of these commands was run here. The commands below are the project's own scripts; read them from `package.json` before running. Typical names are `lint`, `typecheck`, `test`.

1. Lint: the project's lint script (for example `npm run lint`). Exit code and the deciding line.
2. Type check: the project's TypeScript check (for example `npx tsc --noEmit`) if the project uses TypeScript.
3. Tests: the project's test script, which runs Jest (for example `npm test`). The exit code Jest returns for a pass was not verified offline: read the Jest CLI docs (https://jestjs.io/docs/cli) before relying on it.

- Run all three, even when the first one fails, and report each command, its exit code, and the line that decides the result.

## 10. Migrating TO React Native

- Parity beats idiom. Choose an idiom only when inputs, outputs and errors stay the same. Otherwise keep the source behavior, and mark the difference `deviation` with its reason and source.
- Map each source construct with references/as-target.md: layout, styles, touch, keyboard, safe area, navigation, state, and text.
- Write a test for each state transition and each platform branch before writing the code.
- Record the expected output from the source, not from the React Native target, and compare against it.

## 11. Migrating FROM React Native

- Read references/as-source.md for the places where React Native behavior hides: Flexbox defaults, `Platform` branches, `SafeAreaView` (iOS only and deprecated), keyboard handling, touch targets, and Hermes versus JavaScriptCore.
- Read references/components-navigation-state.md for the facts behind each trap.
- Cite the source with `path:line` for each rule, and check each React Native behavior it depends on against the official pages listed in the references.

## 12. Anti-patterns

- Relying on the CSS default for `flexDirection` or `flexShrink` in a React Native layout.
- Text placed outside a `Text` component: React Native raises an exception for a text node directly under a `<View>` (https://reactnative.dev/docs/text).
- `SafeAreaView` from React Native core for new safe-area handling: it is deprecated and iOS only; use `react-native-safe-area-context` (https://reactnative.dev/docs/safeareaview).
- `TouchableOpacity` where the source uses `Pressable` semantics, or the reverse, without a parity test on press states.
- `KeyboardAvoidingView` without a `behavior` value. "On both iOS and Android, setting `behavior` is recommended" (https://reactnative.dev/docs/keyboardavoidingview).
- Relying on a runtime-specific behavior (Hermes or JavaScriptCore) that the source does not specify.
- Testing internal state instead of what the user sees: RNTL is built around user-visible behavior ("The more your tests resemble how your software is used, the more confidence they can give you") (https://callstack.github.io/react-native-testing-library/docs/start/intro).

## Library registry

- Registry: npm, https://www.npmjs.com/. Before adding a package, check the React Native version first. Then open the package page and its official docs, and confirm: latest version, compatibility with the pinned React Native version, supported platforms, license, and last publish.
- Pin the version in `package.json` and commit the lockfile.
- Full procedure and evaluation checks: `.claude/skills/migration-conduct/references/library-research.md`.

## Sources

- React Native: https://reactnative.dev/docs/flexbox, https://reactnative.dev/docs/stylesheet, https://reactnative.dev/docs/platform-specific-code, https://reactnative.dev/docs/safeareaview, https://reactnative.dev/docs/keyboardavoidingview, https://reactnative.dev/docs/pressable, https://reactnative.dev/docs/hermes, https://reactnative.dev/docs/javascript-environment, https://reactnative.dev/docs/testing-overview
- React Navigation: https://reactnavigation.org/docs/getting-started
- React Native Testing Library: https://callstack.github.io/react-native-testing-library/docs/start/intro (the page redirects to http://oss.callstack.com/react-native-testing-library/docs/start/intro; the content was read from the redirect target)
- Jest: https://jestjs.io/docs/getting-started
