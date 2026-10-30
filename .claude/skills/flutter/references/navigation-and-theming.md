Read this when a migrated unit has routes, screens that push or pop, deep links, or theme values (colors, text styles, dark mode).

# Navigation and theming (Flutter 3.47)

## Navigator 1 (imperative)

- `Navigator.push`, `Navigator.pop` and `Navigator.of(context)` manage a stack of routes. The imperative API is the simplest form and the one most older code uses (https://docs.flutter.dev/ui/navigation).
- Parity risk: the back stack after `pushReplacement` or `pushAndRemoveUntil` must match the source. Test the stack depth after each action.
- After `await`, check `context.mounted` before calling `Navigator.of(context)` (see widgets-and-state.md).

## Navigator 2 (declarative, Router API)

- Navigator 2 lets the app describe the route stack as a list of pages built from state. The core types are `Router`, `RouterDelegate` and `RouteInformationParser`. The docs describe it as a way to handle deep links and browser URLs (https://docs.flutter.dev/ui/navigation/deep-linking).
- The exact signatures of `RouterDelegate` and `RouteInformationParser` were not read in this run: verify on https://api.flutter.dev/flutter/widgets/RouterDelegate-class.html before writing code.
- Use Navigator 2 directly only when the plan requires full control of the stack. Otherwise a routing package is the usual choice.

## go_router (package)

- `go_router` is a routing package published by the Flutter team, built on Navigator 2. Routes are declared as a `GoRouter` with a list of `GoRoute` entries (https://pub.dev/packages/go_router; API: https://pub.dev/documentation/go_router/latest/).
- Install and pin the version through the procedure in the Library registry section of SKILL.md. The version and the API were not checked in this run: verify the constructor and the redirect signature on the package page before use.
- Parity risks: a `redirect` callback can change the destination of a route (for example an unauthenticated user); the source must produce the same destination. Path parameters are strings: parse them with `int.tryParse` and handle the null case as the source does.
- Deep links on the web use the URL; on mobile, the platform's link configuration must match the route table. Verify the platform setup in the package docs.

## Choosing between the three

| Need | Choice | Parity risk to test |
|---|---|---|
| Small app, few screens, push and pop only | Navigator 1 | the back stack after replace actions |
| Deep links, URL-driven web, guards | go_router or a Navigator 2 setup | redirects and the destination of each URL |
| Source uses a URL scheme or route names | keep the same names as route paths | the same string returns the same screen |

## Theming (ThemeData)

- `ThemeData` holds the visual defaults for Material widgets: colors, text styles, component themes. Each widget reads it through `Theme.of(context)` (https://api.flutter.dev/flutter/material/ThemeData-class.html).
- `MaterialApp` takes `theme` for light mode and `darkTheme` for dark mode, and `themeMode` to choose between them (https://api.flutter.dev/flutter/material/MaterialApp-class.html).
- `ColorScheme` holds the color roles (primary, surface and others). Build it from a seed with `ColorScheme.fromSeed` or set each role explicitly (https://api.flutter.dev/flutter/material/ColorScheme-class.html).
- Parity risk: a source color given as a hex value must map to the same `Color` value. `Color(0xFFRRGGBB)` takes an ARGB int; check the alpha byte against the source.
- Parity risk: text sizes are in logical pixels. Fonts and `TextStyle` values must match the source's size and weight, not the platform default.
- Do not read colors from `Theme.of(context)` inside pure Dart logic: pass the value in.

```dart
final theme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
);
```

- The seed value above is a placeholder: take the real value from the source.

## Parity checklist for navigation and theming units

- List each source route, its parameters and its redirect rules; write one test per route.
- Check the back stack after each action that replaces or clears it.
- Check the theme value for each color and text style the source uses, in light and dark.
- Check the behavior of an unknown route: the source's fallback must match.
