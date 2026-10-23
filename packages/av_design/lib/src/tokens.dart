import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Semantic colors, taken verbatim from the V3 `.dv-turn` CSS custom
/// properties (light) and `[data-theme="dark"]` overrides.
@immutable
class AvColors {
  const AvColors({
    required this.brightness,
    required this.bg,
    required this.cell,
    required this.l1,
    required this.l2,
    required this.l3,
    required this.sep,
    required this.fill,
    required this.fill2,
    required this.hl,
    required this.ok,
    required this.warn,
    required this.bad,
    required this.tbar,
    required this.side,
    required this.thumb,
    required this.tint,
    required this.tintBg,
  });

  final Brightness brightness;

  /// Grouped page background (`--bg`).
  final Color bg;

  /// Cell / card surface (`--cell`).
  final Color cell;

  /// Primary, secondary and tertiary labels (`--l1`..`--l3`).
  final Color l1;
  final Color l2;
  final Color l3;

  /// Hairline separators (`--sep`).
  final Color sep;

  /// Translucent control fill (`--fill`) and opaque fill (`--fill2`).
  final Color fill;
  final Color fill2;

  /// Pressed-row highlight (`--hl`).
  final Color hl;

  final Color ok;
  final Color warn;
  final Color bad;

  /// Tab bar material before blur (`--tbar`).
  final Color tbar;

  /// Desktop sidebar (`--side`).
  final Color side;

  /// Segmented control thumb (`--thumb`).
  final Color thumb;

  /// Accent (`--tint`) and its 12–20% wash (`--tintbg`).
  final Color tint;
  final Color tintBg;

  bool get isDark => brightness == Brightness.dark;

  static const light = AvColors(
    brightness: Brightness.light,
    bg: Color(0xFFF2F2F7),
    cell: Color(0xFFFFFFFF),
    l1: Color(0xFF000000),
    l2: Color(0x993C3C43), // rgba(60,60,67,.6)
    l3: Color(0x4D3C3C43), // rgba(60,60,67,.3)
    sep: Color(0x4A3C3C43), // rgba(60,60,67,.29)
    fill: Color(0x1F767680), // rgba(118,118,128,.12)
    fill2: Color(0xFFE9E9EB),
    hl: Color(0xFFD1D1D6),
    ok: Color(0xFF34C759),
    warn: Color(0xFFFF9500),
    bad: Color(0xFFFF3B30),
    tbar: Color(0xDBF9F9F9), // rgba(249,249,249,.86)
    side: Color(0xFFE8E8ED),
    thumb: Color(0xFFFFFFFF),
    tint: Color(0xFF007AFF),
    tintBg: Color(0x1F007AFF), // rgba(0,122,255,.12)
  );

  static const dark = AvColors(
    brightness: Brightness.dark,
    bg: Color(0xFF000000),
    cell: Color(0xFF1C1C1E),
    l1: Color(0xFFFFFFFF),
    l2: Color(0x99EBEBF5), // rgba(235,235,245,.6)
    l3: Color(0x4DEBEBF5), // rgba(235,235,245,.3)
    sep: Color(0xA6545458), // rgba(84,84,88,.65)
    fill: Color(0x3D767680), // rgba(118,118,128,.24)
    fill2: Color(0xFF39393D),
    hl: Color(0xFF3A3A3C),
    ok: Color(0xFF30D158),
    warn: Color(0xFFFF9F0A),
    bad: Color(0xFFFF453A),
    tbar: Color(0xDB161616), // rgba(22,22,22,.86)
    side: Color(0xFF2A2A2C),
    thumb: Color(0xFF636366),
    tint: Color(0xFF0A84FF),
    tintBg: Color(0x330A84FF), // rgba(10,132,255,.2)
  );
}

/// Fixed hues used for icon tiles and card labels; identical in both themes,
/// exactly as hard-coded in V3.
abstract final class AvHues {
  static const green = Color(0xFF34C759);
  static const gray = Color(0xFF8E8E93);
  static const blue = Color(0xFF007AFF);
  static const indigo = Color(0xFF5856D6);
  static const teal = Color(0xFF30B0C7);
  static const graphite = Color(0xFF242424);
  static const cyan = Color(0xFF5AC8FA);
  static const orange = Color(0xFFFF9500);
  static const purple = Color(0xFFAF52DE);
  static const pink = Color(0xFFFF2D55);
  static const tabInactive = Color(0xFF999999);
}

/// Type scale. V3 sets `letter-spacing:-0.01em` on the body; large titles
/// override it with `+.01em`.
abstract final class AvType {
  static TextStyle s(
    double size, {
    FontWeight weight = FontWeight.w400,
    double? height,
    double tracking = -0.01,
    bool tabular = false,
    String? family,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: size * tracking,
      leadingDistribution: TextLeadingDistribution.even,
      fontFamily: family,
      fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
    );
  }

  /// V3 leaves `line-height: normal`, which the browser resolved to a 50 pt
  /// line for the CJK titles (measured on the deck); fixed here so every
  /// platform's fallback font lays out the same.
  static final largeTitle = s(
    34,
    weight: FontWeight.w700,
    tracking: 0.01,
    height: 50 / 34,
  );
  static final title1 = s(28, weight: FontWeight.w700);
  static final title2 = s(22, weight: FontWeight.w700);
  static final title3 = s(20, weight: FontWeight.w600);
  static final body = s(17);
  static final bodyStrong = s(17, weight: FontWeight.w600);
  static final input = s(16);
  static final callout = s(15);
  static final calloutStrong = s(15, weight: FontWeight.w600);
  static final subheadStrong = s(14, weight: FontWeight.w600);
  static final footnote = s(13);
  static final footnoteStrong = s(13, weight: FontWeight.w600);
  static final caption = s(12);
  static final tab = s(10, weight: FontWeight.w500, height: 1.2);

  /// V3 `ui-rounded` numerals (timer, speeds, latency, prices). Avalon
  /// follows the system default font on every platform (D62), so this is the
  /// default face with tabular figures.
  static TextStyle numeric(
    double size, {
    FontWeight weight = FontWeight.w600,
    double tracking = -0.01,
  }) => s(size, weight: weight, tracking: tracking, tabular: true);

  /// The platform's system monospace family (D62).
  static String get monoFamily => switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.macOS => 'Menlo',
    TargetPlatform.windows => 'Consolas',
    _ => 'monospace',
  };
  static TextStyle mono(double size, {double? height}) =>
      s(size, height: height, family: monoFamily);

  /// CSS `word-break:break-all`: allow a line break between any two
  /// characters (display only; never for text the user copies).
  static String breakAll(String text) => text.characters.join('\u200B');
}

/// Shadows from V3 `box-shadow` declarations (Flutter blurRadius matches the
/// CSS blur length).
/// V3 sizes boxes content-box: a `0.5px` separator sits outside the CSS
/// `height`/`min-height`, so a 44 px row with a bottom hairline is 44.5 tall
/// (rows marked `box-sizing:border-box` in V3 stay at their size).
abstract final class AvBorder {
  static const double hairline = 0.5;
}

abstract final class AvShadows {
  static const switchThumb = [
    BoxShadow(color: Color(0x26000000), offset: Offset(0, 3), blurRadius: 8),
    BoxShadow(color: Color(0x0F000000), offset: Offset(0, 3), blurRadius: 1),
  ];
  static const switchThumbSmall = [
    BoxShadow(color: Color(0x40000000), offset: Offset(0, 1), blurRadius: 3),
  ];
  static const segmentThumb = [
    BoxShadow(color: Color(0x1F000000), offset: Offset(0, 3), blurRadius: 8),
    BoxShadow(color: Color(0x0A000000), offset: Offset(0, 3), blurRadius: 1),
  ];
  static const segmentThumbInline = [
    BoxShadow(color: Color(0x26000000), offset: Offset(0, 1), blurRadius: 3),
  ];
  static List<BoxShadow> menu(AvColors c) => [
    BoxShadow(color: c.sep, spreadRadius: 0.5),
    const BoxShadow(
      color: Color(0x38000000),
      offset: Offset(0, 12),
      blurRadius: 40,
    ),
  ];
  static List<BoxShadow> glow(AvColors c, {double y = 8}) => [
    BoxShadow(color: c.tintBg, offset: Offset(0, y), blurRadius: 24),
  ];

  /// Under the app icon (About): neutral, as the dark tile would make a
  /// tinted glow read as a coloured band.
  static const appIcon = [
    BoxShadow(color: Color(0x2E000000), offset: Offset(0, 8), blurRadius: 20),
  ];
  static List<BoxShadow> ring(Color color) => [
    BoxShadow(color: color, spreadRadius: 2),
  ];
}

/// Motion: every V3 easing and duration.
abstract final class AvMotion {
  /// `cubic-bezier(.32,.72,0,1)`: push/pop, sheets, segment thumb, drops, zooms.
  static const ios = Cubic(0.32, 0.72, 0.0, 1.0);

  /// `cubic-bezier(.34,1.56,.64,1)`: press bounce, check pops.
  static const spring = Cubic(0.34, 1.56, 0.64, 1.0);

  /// `cubic-bezier(.34,1.4,.64,1)`: switch thumb.
  static const springSoft = Cubic(0.34, 1.4, 0.64, 1.0);

  /// `cubic-bezier(.34,1.8,.64,1)`: tab bar icon scale.
  static const springStrong = Cubic(0.34, 1.8, 0.64, 1.0);

  /// `cubic-bezier(.2,.6,.4,1)`: power button pulse rings.
  static const pulse = Cubic(0.2, 0.6, 0.4, 1.0);

  /// CSS `ease`.
  static const ease = Cubic(0.25, 0.1, 0.25, 1.0);

  static const push = Duration(milliseconds: 500);
  static const sheet = Duration(milliseconds: 550);
  static const tabFade = Duration(milliseconds: 320);
  static const swap = Duration(milliseconds: 250);
  static const segment = Duration(milliseconds: 400);
  static const switchThumb = Duration(milliseconds: 400);
  static const switchTrack = Duration(milliseconds: 300);
  static const press = Duration(milliseconds: 350);
  static const check = Duration(milliseconds: 400);
  static const drop = Duration(milliseconds: 350);
  static const zoom = Duration(milliseconds: 320);
  static const highlightOut = Duration(milliseconds: 250);
  static const spin = Duration(milliseconds: 900);
  static const blink = Duration(seconds: 2);
  static const pulsePeriod = Duration(milliseconds: 2400);
}
