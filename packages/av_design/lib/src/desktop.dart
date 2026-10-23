import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'brand.dart';
import 'effects.dart';
import 'icon.dart';
import 'pressable.dart';
import 'surfaces.dart';
import 'theme.dart';
import 'tokens.dart';

/// Desktop window families drawn in V3 (3p macOS, 3q Windows, 3r Linux).
enum AvDesktopPlatform { mac, windows, linux }

/// Per-platform desktop metrics and copy from V3 `PLAT`.
class AvDesktopSpec {
  const AvDesktopSpec._(
    this.platform,
    this.navHeight,
    this.navRadius,
    this.trayName,
    this.tunNote,
    this.sysNote,
    this.hotkeys,
    this.osName,
  );

  final AvDesktopPlatform platform;
  final double navHeight;
  final double navRadius;
  final String trayName;
  final String tunNote;
  final String sysNote;
  final List<String> hotkeys;
  final String osName;

  static const mac = AvDesktopSpec._(
    AvDesktopPlatform.mac,
    32,
    7,
    '菜单栏',
    'utun · 需要授权网络扩展',
    '设置 macOS 网络代理',
    ['⌥⌘P', '⌥⌘M', '⌥⌘A'],
    'macOS',
  );
  static const windows = AvDesktopSpec._(
    AvDesktopPlatform.windows,
    36,
    5,
    '系统托盘',
    'WinTUN · 需要管理员权限',
    '设置 Windows 系统代理（WinINet）',
    ['Ctrl+Alt+P', 'Ctrl+Alt+M', 'Ctrl+Alt+A'],
    'Windows',
  );
  static const linux = AvDesktopSpec._(
    AvDesktopPlatform.linux,
    38,
    8,
    '系统托盘',
    'tun0 · 需要 CAP_NET_ADMIN',
    '写入 GNOME / KDE 代理设置',
    ['Ctrl+Alt+P', 'Ctrl+Alt+M', 'Ctrl+Alt+A'],
    'Linux',
  );

  static AvDesktopSpec of(AvDesktopPlatform p) => switch (p) {
    AvDesktopPlatform.mac => mac,
    AvDesktopPlatform.windows => windows,
    AvDesktopPlatform.linux => linux,
  };
}

/// Title bar drawn by the app. Windows: 36 high, app mark + name, 46×36
/// caption buttons, close hover `#C42B1C`. Linux (GNOME/libadwaita): 46 high,
/// sidebar toggle, centered bold title, round minimize/close. macOS uses the
/// system traffic lights instead (see [AvTrafficLights]).
class AvWindowTitleBar extends StatelessWidget {
  const AvWindowTitleBar({
    super.key,
    required this.platform,
    this.title = 'Avalon',
  });

  final AvDesktopPlatform platform;
  final String title;

  @override
  Widget build(BuildContext context) => platform == AvDesktopPlatform.mac
      ? const SizedBox.shrink()
      : _bar(context);

  Widget _bar(BuildContext context) {
    final c = context.av;
    switch (platform) {
      case AvDesktopPlatform.mac:
        return const SizedBox.shrink();
      case AvDesktopPlatform.windows:
        Widget caption(
          IconData icon,
          double size,
          VoidCallback onTap, {
          bool close = false,
        }) => GestureDetector(
          onTap: onTap,
          child: AvHover(
            hover: close ? const Color(0xFFC42B1C) : c.fill,
            hoverForeground: close ? const Color(0xFFFFFFFF) : null,
            builder: (fg) => SizedBox(
              width: 46,
              height: 36,
              child: Center(
                child: AvIcon(
                  icon,
                  size: size,
                  fill: 0,
                  weight: 300,
                  color: fg ?? c.l1,
                ),
              ),
            ),
          ),
        );
        return Container(
          height: 36,
          color: c.side,
          child: Row(
            children: [
              Expanded(
                child: AvWindowDragArea(
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      const AvBrandMark.avalon(size: 16),
                      const SizedBox(width: 10),
                      Text(title, style: AvType.caption.copyWith(color: c.l1)),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
              caption(Symbols.remove_rounded, 16, AvWindow.minimize),
              caption(Symbols.crop_square_rounded, 14, AvWindow.maximize),
              caption(Symbols.close_rounded, 16, AvWindow.close, close: true),
            ],
          ),
        );
      case AvDesktopPlatform.linux:
        Widget round(IconData icon, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: c.fill, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: AvIcon(icon, size: 14, weight: 600, color: c.l1),
          ),
        );
        return Container(
          height: 46 + AvBorder.hairline,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: c.side,
            border: Border(bottom: BorderSide(color: c.sep, width: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AvHover(
                    hover: c.fill,
                    radius: 6,
                    builder: (_) => SizedBox(
                      width: 34,
                      height: 30,
                      child: Center(
                        child: AvIcon(
                          Symbols.dock_to_right_rounded,
                          size: 18,
                          color: c.l1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AvWindowDragArea(
                child: Text(
                  title,
                  style: AvType.subheadStrong.copyWith(
                    fontWeight: FontWeight.w700,
                    color: c.l1,
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    round(Symbols.remove_rounded, AvWindow.minimize),
                    const SizedBox(width: 10),
                    round(Symbols.close_rounded, AvWindow.close),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }
}

/// macOS traffic lights as drawn in V3 (12 px, `#FF5F57 #FEBC2E #28C840`,
/// gap 8). In the real app the system draws them; this is for previews.
class AvTrafficLights extends StatelessWidget {
  const AvTrafficLights({super.key});

  @override
  Widget build(BuildContext context) {
    Widget dot(int color) => Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: Color(color), shape: BoxShape.circle),
    );
    return Row(
      children: [
        dot(0xFFFF5F57),
        const SizedBox(width: 8),
        dot(0xFFFEBC2E),
        const SizedBox(width: 8),
        dot(0xFF28C840),
      ],
    );
  }
}

class AvSidebarItem {
  const AvSidebarItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

/// Desktop sidebar (240 wide overall, `--side`). Item styles per platform:
/// macOS 32 high radius 7 with tint fill and white text when selected;
/// Windows 36 high radius 5 with `--fill` and a 3 px tint pill; Linux 38 high
/// radius 8 with `--fill`.
class AvSidebar extends StatelessWidget {
  const AvSidebar({
    super.key,
    required this.spec,
    required this.items,
    required this.index,
    required this.onSelect,
    this.footer,
    this.version,
    this.showTrafficLights = true,
  });

  final AvDesktopSpec spec;
  final List<AvSidebarItem> items;
  final int index;
  final ValueChanged<int> onSelect;

  /// The account row (PRODUCT_SPEC §2); absent until Cloud is available.
  final Widget? footer;

  /// The core's version line under the app name; hidden when unknown.
  final String? version;
  final bool showTrafficLights;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final mac = spec.platform == AvDesktopPlatform.mac;
    return Container(
      // V3 `width:220px;padding:0 10px` plus the border is content-box:
      // 240.5 overall.
      width: 240 + AvBorder.hairline,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: c.side,
        border: Border(right: BorderSide(color: c.sep, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The traffic-light row is title bar on macOS: it moves the window,
          // and the system buttons sit there when the host draws them.
          AvWindowDragArea(
            child: mac && showTrafficLights
                ? const Padding(
                    padding: EdgeInsets.fromLTRB(8, 18, 8, 18),
                    child: AvTrafficLights(),
                  )
                : SizedBox(height: mac ? 48 : 16),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Row(
              children: [
                const AvBrandMark.avalon(),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Avalon',
                      style: AvType.s(
                        15,
                        weight: FontWeight.w700,
                      ).copyWith(color: c.l1),
                    ),
                    if (version != null)
                      Text(version!, style: AvType.s(11).copyWith(color: c.l2)),
                  ],
                ),
              ],
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 2),
            _SidebarButton(
              spec: spec,
              item: items[i],
              selected: i == index,
              onTap: () => onSelect(i),
            ),
          ],
          const Spacer(),
          if (footer != null)
            Padding(padding: const EdgeInsets.only(bottom: 14), child: footer),
        ],
      ),
    );
  }
}

class _SidebarButton extends StatelessWidget {
  const _SidebarButton({
    required this.spec,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AvDesktopSpec spec;
  final AvSidebarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final mac = spec.platform == AvDesktopPlatform.mac;
    final bg = selected ? (mac ? c.tint : c.fill) : c.fill.withValues(alpha: 0);
    final fg = selected && mac ? const Color(0xFFFFFFFF) : c.l1;
    final ic = selected && mac ? const Color(0xFFFFFFFF) : c.tint;
    return AvPressable(
      onTap: onTap,
      scale: 0.97,
      scaleDuration: const Duration(milliseconds: 300),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: spec.navHeight,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(spec.navRadius),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            if (spec.platform == AvDesktopPlatform.windows)
              Positioned(
                left: -10,
                child: Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: selected ? c.tint : c.tint.withValues(alpha: 0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            Row(
              children: [
                AvIcon(
                  item.icon,
                  size: 19,
                  color: ic,
                  fill: selected ? 1 : 0,
                  weight: selected ? 500 : 400,
                ),
                const SizedBox(width: 10),
                Text(item.label, style: AvType.s(14).copyWith(color: fg)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Content toolbar: 56 high, 20/700 title, page actions, then the trailing
/// global controls (mode segment and connection status).
class AvDesktopToolbar extends StatelessWidget {
  const AvDesktopToolbar({
    super.key,
    required this.title,
    this.actions = const [],
    this.trailing = const [],
  });

  final String title;
  final List<Widget> actions;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final all = [...actions, ...trailing];
    // The bar's empty space and title move the window (macOS title bar).
    return Container(
      height: 56 + AvBorder.hairline,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.sep, width: 0.5)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const AvWindowDragArea(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: IgnorePointer(
                    child: Text(
                      title,
                      style: AvType.s(
                        20,
                        weight: FontWeight.w700,
                      ).copyWith(color: c.l1),
                    ),
                  ),
                ),
                for (var i = 0; i < all.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  all[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Desktop button: 30 high, radius 8, 13/600. [filled] = tint background.
class AvDesktopButton extends StatelessWidget {
  const AvDesktopButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.filled = false,
    this.tinted = false,
    this.spin = false,
    this.height = 30,
    this.radius = 8,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool filled;
  final bool tinted;
  final bool spin;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final fg = filled ? const Color(0xFFFFFFFF) : c.tint;
    Widget? glyph = icon == null
        ? null
        : AvIcon(icon!, size: filled ? 18 : 16, color: fg);
    if (glyph != null && spin) glyph = AvSpin(child: glyph);
    return AvPressable(
      onTap: onTap,
      scale: 0.94,
      scaleDuration: const Duration(milliseconds: 300),
      child: Container(
        height: height,
        padding: EdgeInsets.fromLTRB(
          icon == null ? 14 : 10,
          0,
          icon == null ? 14 : (filled ? 14 : 12),
          0,
        ),
        decoration: BoxDecoration(
          color: filled ? c.tint : (tinted ? c.tintBg : c.fill),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (glyph != null) ...[glyph, const SizedBox(width: 4)],
            Text(label, style: AvType.footnoteStrong.copyWith(color: fg)),
          ],
        ),
      ),
    );
  }
}

/// Status cluster on the toolbar: blinking dot, label, small power switch.
class AvConnectionStatus extends StatelessWidget {
  const AvConnectionStatus({
    super.key,
    required this.connected,
    required this.label,
    required this.onToggle,
  });

  final bool connected;
  final String label;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final color = connected ? c.ok : c.l2;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AvBlinkDot(color: color, size: 7, active: connected),
        const SizedBox(width: 8),
        Text(label, style: AvType.footnoteStrong.copyWith(color: color)),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: AvMotion.switchTrack,
            width: 38,
            height: 22,
            decoration: BoxDecoration(
              color: connected ? c.ok : c.fill2,
              borderRadius: BorderRadius.circular(11),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: connected ? 16 : 0),
              duration: const Duration(milliseconds: 350),
              curve: AvMotion.springSoft,
              builder: (context, dx, child) =>
                  Transform.translate(offset: Offset(2 + dx, 2), child: child),
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFFFF),
                    shape: BoxShape.circle,
                    boxShadow: AvShadows.switchThumbSmall,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Hover highlight for pointer devices (`style-hover` in V3).
class AvHover extends StatefulWidget {
  const AvHover({
    super.key,
    required this.hover,
    required this.builder,
    this.hoverForeground,
    this.radius = 0,
  });

  final Color hover;
  final Color? hoverForeground;
  final double radius;
  final Widget Function(Color? foreground) builder;

  @override
  State<AvHover> createState() => AvHoverState();
}

class AvHoverState extends State<AvHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _hover ? widget.hover : widget.hover.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
        child: widget.builder(_hover ? widget.hoverForeground : null),
      ),
    );
  }
}

/// Native window integration provided by the desktop runner (channel
/// `avalon/window`; macOS today, see macos/Runner/MainFlutterWindow.swift).
/// Calls are no-ops where the host has no handler, e.g. the Android preview.
abstract final class AvWindow {
  static const _channel = MethodChannel('avalon/window');

  /// The host draws the window controls (macOS traffic lights) itself.
  static bool get hasNativeControls =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  /// Moves the window with the current mouse drag.
  static Future<void> startDrag() => _call('startDrag');

  /// Title-bar double click: zoom or minimize, per the system setting.
  static Future<void> titleDoubleClick() => _call('titleDoubleClick');

  static Future<void> minimize() => _call('minimize');
  static Future<void> maximize() => _call('maximize');
  static Future<void> close() => _call('close');

  /// Hides the native controls, for previewing the other platforms' frames.
  static Future<void> setNativeControlsVisible(bool visible) =>
      _call('setNativeControlsVisible', visible);

  static Future<void> _call(String method, [Object? arguments]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      // No native window on this host.
    }
  }
}

/// Title-bar behaviour for empty chrome: dragging moves the window and a
/// double click zooms it. Put it behind controls (e.g. as the first child of
/// a [Stack]) so they keep their own clicks.
class AvWindowDragArea extends StatelessWidget {
  const AvWindowDragArea({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => AvWindow.startDrag(),
      onDoubleTap: AvWindow.titleDoubleClick,
      child: child,
    );
  }
}

/// Scrolling content area of a desktop page (V3 `padding:20px 24px`).
class AvDesktopPage extends StatelessWidget {
  const AvDesktopPage({super.key, required this.child, this.maxWidth});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    Widget body = child;
    if (maxWidth != null) {
      body = Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth!),
          child: body,
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: body,
    );
  }
}

/// 1.5 px dashed rounded border (`border:1.5px dashed var(--l3)`).
class AvDashedBorder extends CustomPainter {
  AvDashedBorder({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 9) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(AvDashedBorder old) =>
      old.color != color || old.radius != radius;
}

/// Equal-width grid that keeps each row's cells the same height (CSS grid
/// `align-items:stretch`).
class AvGrid extends StatelessWidget {
  const AvGrid({
    super.key,
    required this.columns,
    required this.gap,
    required this.rows,
    this.stretch = true,
  });

  final int columns;
  final double gap;
  final List<List<(int span, Widget child)>> rows;
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final cell = (box.maxWidth - gap * (columns - 1)) / columns;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              if (r > 0) SizedBox(height: gap),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: stretch
                      ? CrossAxisAlignment.stretch
                      : CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < rows[r].length; i++) ...[
                      if (i > 0) SizedBox(width: gap),
                      SizedBox(
                        width: cell * rows[r][i].$1 + gap * (rows[r][i].$1 - 1),
                        child: rows[r][i].$2,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
