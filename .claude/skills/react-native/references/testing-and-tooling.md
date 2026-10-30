Read this when you write tests, set up the quality gate, or choose a React Native test tool. Facts were checked against the official pages on 2026-10-30. None of the commands was run on the machine that wrote this file.

# Testing and tooling (React Native, Jest, RNTL)

## Test layout

- Jest is the test runner. The React Native template ships it with a preset: "The default template of React Native ships with Jest testing framework. It includes a preset that's tailored to this environment" (https://reactnative.dev/docs/testing-overview).
- One test file per unit: `__tests__/<unit>.test.tsx` or `<unit>.test.tsx` beside the unit. The project's `jest` config decides the match pattern: read it from `package.json` or `jest.config.*`.
- Name each test with its rule id when there is one, for example `BR-NAV-002 returns to the list on back`.

## Test types

- Unit: "Unit tests cover the smallest parts of code, like individual functions or classes" (https://reactnative.dev/docs/testing-overview).
- Integration: "real individual units are combined (same as in your app) and tested together" (same page).
- End-to-end: "you verify your app is working as expected on a device (or a simulator / emulator) from the user perspective" (same page). The page names Detox, Appium and Maestro as E2E options: "Detox is a popular framework because it's tailored for React Native apps" (same page). Choose one only when the project already has it; the choice is not verified here beyond that sentence.

## Component tests with React Native Testing Library

- RNTL "builds on top of React's test renderer and adds `fireEvent` and `query` APIs" (https://reactnative.dev/docs/testing-overview). Its guiding principle: "The more your tests resemble how your software is used, the more confidence they can give you" (https://callstack.github.io/react-native-testing-library/docs/start/intro, read from its redirect target).
- The `screen` object "contains all available query methods bound to the most recently rendered UI" (http://oss.callstack.com/react-native-testing-library/docs/api/queries).
- `getByText` "Returns a `TestInstance` with matching text" (same page). `getByRole` "Returns a `TestInstance` with matching `role` or `accessibilityRole` prop" (same page).
- The `*ByTestId` queries are a last resort: "use this only when other queries don't work for your use case" (same page).
- The page read does not define a query priority: verify before writing a rule about the order.
- `react-test-renderer` is deprecated: "[Deprecated] React's Test Renderer" (https://reactnative.dev/docs/testing-overview). The RNTL version and its peer requirements for the pinned React version were not verified offline: check the install page of the pinned RNTL before use.

```tsx
import { render, screen, fireEvent } from '@testing-library/react-native';

test('BR-UI-001 shows the count after a press', () => {
  render(<Counter />);
  fireEvent.press(screen.getByText('Add'));
  expect(screen.getByText('1')).toBeTruthy();
});
```

- The example above is an illustration. The `fireEvent.press` and `toBeTruthy` names are not verified offline on the RNTL API page read: check them against the pinned RNTL version before use.

## Doubles and fakes

- Put each device or network dependency behind an interface the unit receives as a parameter. Write a hand-made fake for it. This is the default.
- Jest mocking "from function level all the way to module level" (https://reactnative.dev/docs/testing-overview). Module mocks for native modules: the exact `jest.mock` setup for native modules was not verified offline; read the React Native mocking section before writing one.
- Time: pass a clock as a value. Use Jest fake timers only where the source test controls time; the fake timer API was not read: verify before use.

## Quality gate

Run each command in the project root and report its real output. A gate that did not run is not a pass. Read the project's scripts from `package.json` first.

| Gate | Command | What passes | Verified in this run |
|---|---|---|---|
| Lint | the project's lint script, for example `npm run lint` | the script exits 0 | the script name: read from `package.json`; exit code semantics not verified offline |
| Type check | `npx tsc --noEmit` when the project uses TypeScript | exit code 0 | the flag `--noEmit` is a TypeScript compiler flag: verify with `tsc --help` in the project |
| Test | the project's test script, for example `npm test`, which runs Jest | the Jest run passes | the Jest CLI exit code for a pass: not verified offline (https://jestjs.io/docs/cli) |

- Report each gate with its command, its exit code and the line that decides the result.
- Coverage: the Jest coverage flag was not verified offline: check the Jest CLI docs before use.

## Tool choice

- Use what the project already has. Add a package only when the plan names it and the gate needs it.
- Jest and React Native Testing Library are the tools this skill names. Other test libraries: not verified offline.
- Read the flags of any command with its `--help` output and record the version you ran.
