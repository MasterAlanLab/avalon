import 'package:av_design/av_design.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Window width from which the desktop layout applies (V3 3p–3r).
const double desktopBreakpoint = 900;

bool isWideLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= desktopBreakpoint;

/// The window frame family of the host.
AvDesktopPlatform hostDesktopPlatform() => switch (defaultTargetPlatform) {
  TargetPlatform.windows => AvDesktopPlatform.windows,
  TargetPlatform.linux => AvDesktopPlatform.linux,
  _ => AvDesktopPlatform.mac,
};

/// The platform families whose settings and pages differ (PRODUCT_SPEC §6).
enum AppPlatform {
  android,
  ios,
  mac,
  windows,
  linux;

  bool get isDesktop =>
      this == AppPlatform.mac ||
      this == AppPlatform.windows ||
      this == AppPlatform.linux;

  /// The host this build runs on.
  static AppPlatform get host => switch (defaultTargetPlatform) {
    TargetPlatform.android => AppPlatform.android,
    TargetPlatform.iOS => AppPlatform.ios,
    TargetPlatform.windows => AppPlatform.windows,
    TargetPlatform.linux => AppPlatform.linux,
    _ => AppPlatform.mac,
  };
}

/// Global shortcuts as each platform writes them (PRODUCT_SPEC §7): start or
/// stop the proxy, switch the outbound mode, show the main window.
List<String> hotkeysOf(AppPlatform platform) => platform == AppPlatform.mac
    ? const ['⌥⌘P', '⌥⌘M', '⌥⌘A']
    : const ['Ctrl+Alt+P', 'Ctrl+Alt+M', 'Ctrl+Alt+A'];
