<div align="center">
  <img src="../tool/branding/icon.svg" width="144" height="144" alt="Avalon Gate icon">
  <h1>Avalon</h1>
  <p><strong>Route · Connect · Control</strong></p>
  <p>
    <a href="https://github.com/MasterAlanLab/avalon/releases"><img src="https://img.shields.io/github/v/release/MasterAlanLab/avalon?display_name=tag&amp;style=flat-square&amp;logo=github&amp;logoColor=white&amp;label=Release&amp;color=E3A72F&amp;cacheSeconds=300" alt="Latest release"></a>
    <a href="https://github.com/MasterAlanLab/avalon/actions/workflows/build.yaml"><img src="https://img.shields.io/github/actions/workflow/status/MasterAlanLab/avalon/build.yaml?style=flat-square&amp;logo=githubactions&amp;logoColor=white&amp;label=Build" alt="Build status"></a>
    <a href="../LICENSE"><img src="https://img.shields.io/badge/License-AGPL--3.0-17191D?style=flat-square&amp;logo=gnu&amp;logoColor=white" alt="AGPL-3.0 license"></a>
    <a href="https://github.com/MasterAlanLab/avalon/releases"><img src="https://img.shields.io/badge/Android-arm64%20%7C%20armv7%20%7C%20x86__64-3DDC84?style=flat-square&amp;logo=android&amp;logoColor=white" alt="Android: arm64, armv7, x86_64"></a>
    <a href="https://github.com/MasterAlanLab/avalon/releases"><img src="https://img.shields.io/badge/Windows-x64-0078D4?style=flat-square&amp;logo=windows11&amp;logoColor=white" alt="Windows: x64"></a>
    <a href="https://github.com/MasterAlanLab/avalon/releases"><img src="https://img.shields.io/badge/macOS-ARM64-000000?style=flat-square&amp;logo=apple&amp;logoColor=white" alt="macOS: ARM64"></a>
    <a href="https://github.com/MasterAlanLab/avalon/releases"><img src="https://img.shields.io/badge/Linux-x64-FCC624?style=flat-square&amp;logo=linux&amp;logoColor=17191D" alt="Linux: x64"></a>
  </p>
</div>

[简体中文](../README.md) · [English](README.en.md) · [العربية](README.ar.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

A proxy client for Android, Windows, macOS, and Linux, powered by [mihomo](https://github.com/MetaCubeX/mihomo). Supports standalone nodes, subscription management, and multi-hop proxy chains. Built with Flutter.

> Avalon is based on [FlClash](https://github.com/chen08209/FlClash).

Download the package for your platform from [Releases](https://github.com/MasterAlanLab/avalon/releases).

## Features

- Protocol support: VLESS, VMess, Shadowsocks, Trojan, Hysteria2, TUIC, AnyTLS, SOCKS4/4a/5, HTTP(S), and more.
- Node management: manage individual nodes independently, with options to add, edit, duplicate, and bind them to profiles.
- Subscriptions: import profiles from URLs or local files, with automatic subscription updates.
- Proxy chains: combine nodes, proxy groups, and local proxy endpoints, with support for pre-proxies, multi-hop connections, and path previews.
- Profile generation: create ready-to-use profiles from chains, or add chains to proxy groups in existing profiles.
- Import and export: support for node URIs, QR codes, YAML / JSON, and packaged exports of nodes and chains with their attachments.
- Routing rules: Rule, Global, and Direct modes, with editable routing rules and proxy groups.
- Network diagnostics: node latency tests, live connection monitoring, and runtime logs.
- Data sync: local backup and restore, with WebDAV synchronization.
- Themes: desktop and mobile layouts, dark mode, and custom colors.
- Tailscale: view devices and configure Tailnet routing, remote subnets, and exit nodes.

## Operating Modes

| Mode | Description |
| :--- | :--- |
| Rule | Select outbound routes according to the profile's rules |
| Global | Send all traffic entering the core through the outbound selected in the global proxy group |
| Direct | Connect directly to the destination without a proxy node |

Desktop platforms support system proxy and TUN; Android captures traffic through a VPN service. The system proxy only covers apps that follow proxy settings. TUN/VPN capture follows the configured routes, IPv6 settings, and access controls.

## Core Engine

[mihomo](https://github.com/MetaCubeX/mihomo) handles proxy connections, DNS resolution, rule-based routing, and TUN traffic. In addition to protocol-specific forms, Raw YAML / JSON can be used to configure other mihomo node types.

Subscriptions, the node library, and proxy chains are combined into a single runtime configuration. Chains use `dialer-proxy` to connect each hop in the order “client → pre-proxy → main node → post-proxy → destination,” within a single core instance.

## Development

Run from the repository root. CI uses Flutter 3.44.4 and Go 1.26.4; native components also require Rust and platform toolchains.

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test
```

## Documentation

- [Development and builds (Chinese)](development.md): environment setup, core and app builds, tests, code generation, and CI.
- [Tailscale (Chinese)](tailscale.md): sign-in, routing, exit nodes, identity management, and known issues.
- [Release workflow](../.github/workflows/build.yaml): platform packaging and release configuration.

## Tech Stack

- Languages: Dart, Go, Rust
- UI framework: Flutter / Material Design
- State management: Riverpod
- Database: SQLite / Drift
- Proxy core: mihomo
- Package management: Pub, Go Modules, Cargo

## Recommended Resources

Some links are affiliate links. The author may earn a commission when you register or purchase through them. Service details and prices are listed on the respective websites.

| Category | Project / Service | Description |
| :--- | :--- | :--- |
| Proxy pool | [Free Proxy](https://github.com/MasterAlanLab/free-proxy) | Self-hosted proxy pool for use with the node library or proxy chains |
| VPS | [BandwagonHost](https://cutt.ly/qywJNWzd) · [DMIT](https://cutt.ly/YywJIzY0) | Node and application hosting |
| Virtual credit cards | [International virtual cards](https://cutt.ly/IyrMR4Mg) | Payments for international services |
| Resource search | [Telegram search bot](https://cutt.ly/2yeh3GOE) | Find resources on Telegram |
| Accounts and SIM cards | [International accounts and SIM cards](https://cutt.ly/dywt86NC) | Account and communication services |
| Fingerprint browser | [BitBrowser](https://client.bitbrowser.cn/register?lang=zh&code=Alan123) | Manage isolated browser environments |
| Email hosting | [Emailbox](https://github.com/MasterAlanLab/emailbox) | Bulk email management and proxy grouping |
| CAPTCHA services | [Captcha.run](https://captcha.run/sso?inviter=542f4f4f-31b6-4b70-b485-c4762c45d1e8) · [YesCaptcha](https://cutt.ly/Mywt39r0) | CAPTCHA recognition |
| AI APIs | [CC / GPT relay](https://cutt.ly/JywJG3G5) | Model API services |
| Subscription sharing | [Subscription-sharing platform](https://cutt.ly/5ywt8vb4) | Shared subscriptions |

## License

[AGPL-3.0](../LICENSE). Third-party code retains its respective licenses. See [NOTICE](../NOTICE) for copyright and licensing information.

## Acknowledgments

- [FlClash](https://github.com/chen08209/FlClash)
- [mihomo](https://github.com/MetaCubeX/mihomo)
- [Surfboard](https://github.com/getsurfboard/surfboard)
