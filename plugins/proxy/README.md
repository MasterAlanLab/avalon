# proxy

Avalon's desktop system-proxy integration.

- Windows uses a Flutter method channel and WinINet settings.
- macOS uses `/usr/sbin/networksetup` for each active network service.
- Linux uses GNOME/MATE `gsettings` or KDE `kwriteconfig` based on the active
  desktop environment.

The public `Proxy` API validates the port, applies HTTP, HTTPS, and SOCKS
settings to `127.0.0.1`, and returns `false` when the selected platform backend
is unavailable or a command fails.

Use `Proxy().startProxy(port, bypassDomains)` to enable the proxy and
`Proxy().stopProxy()` to disable it. This changes desktop proxy settings, not
Avalon's core lifecycle or TUN routes; applications may ignore system settings.
Android uses the application's VPN service rather than this plugin.

## Development

From this directory:

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test --reporter expanded
```

Native Windows behavior also requires a Windows application build. Shared
build instructions and licensing are in [development.md](../../docs/development.md)
and [NOTICE](../../NOTICE).
