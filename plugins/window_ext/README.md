# window_ext

Avalon's small Windows/macOS window integration, using the `window_ext` Flutter method channel.

| Platform | Behavior |
| :--- | :--- |
| Windows | Emits `taskbarCreated` after Explorer recreates the taskbar; applies the window corner preference through DWM |
| macOS | Forwards the application's termination request as `shouldTerminate` |

## Dart API

Import [lib/window_ext.dart](lib/window_ext.dart), then register a `WindowExtListener` with `windowExtManager.addListener(...)`. Remove the same listener during teardown.

- `onTaskbarCreated()` lets Avalon restore its tray integration on Windows.
- `onShouldTerminate()` lets Avalon handle macOS termination through its existing application lifecycle.
- `setWindowCornerPreference(round: ...)` is Windows-only; its visible effect depends on OS support for DWM corner preferences.

Other platforms are not registered by this plugin. It supplements Avalon's window manager rather than owning the window or proxy service.

## Development

From this directory:

```bash
flutter pub get
flutter analyze --no-fatal-infos
```

Native compilation and event behavior are checked through the corresponding host application build. Sources are [windows/window_ext_plugin.cpp](windows/window_ext_plugin.cpp) and [macOS WindowExtPlugin.swift](macos/window_ext/Sources/window_ext/WindowExtPlugin.swift). Shared build instructions and licensing are in [development.md](../../docs/development.md) and [NOTICE](../../NOTICE).
