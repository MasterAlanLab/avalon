import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'icon.dart';
import 'list.dart';
import 'pressable.dart';
import 'theme.dart';
import 'tokens.dart';

/// Rounded surface (`background:--cell`). When [selected] is set, the 2 px
/// tint ring (`box-shadow:0 0 0 2px var(--tint)`) fades in over 300 ms.
class AvCard extends StatelessWidget {
  const AvCard({
    super.key,
    required this.child,
    this.radius = 16,
    this.padding = const EdgeInsets.all(14),
    this.selected,
    this.onTap,
    this.onLongPress,
    this.pressScale = 0.97,
    this.color,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final bool? selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressScale;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: AvMotion.ease,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.cell,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: selected == null
            ? null
            : AvShadows.ring(selected! ? c.tint : c.tint.withValues(alpha: 0)),
      ),
      child: child,
    );
    if (onTap == null && onLongPress == null) return card;
    return AvPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      scale: pressScale,
      child: card,
    );
  }
}

/// Full-width filled button: 50 high, radius 14, 17/600, press scale .97 +
/// opacity .85.
class AvPrimaryButton extends StatelessWidget {
  const AvPrimaryButton(
    this.label, {
    super.key,
    this.onTap,
    this.background,
    this.foreground,
    this.leading,
  });

  final String label;
  final VoidCallback? onTap;
  final Color? background;
  final Color? foreground;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    return AvPressable(
      onTap: onTap,
      scale: 0.97,
      pressedOpacity: 0.85,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: background ?? c.tint,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 8)],
            Text(
              label,
              style: AvType.bodyStrong.copyWith(
                color: foreground ?? const Color(0xFFFFFFFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Capsule action (`height:34px; border-radius:17px; background:--fill;
/// color:--tint; 15/600`) such as 测速.
class AvPillButton extends StatelessWidget {
  const AvPillButton({
    super.key,
    required this.label,
    this.icon,
    this.iconSpin = false,
    this.onTap,
    this.height = 34,
    this.filled = false,
    this.tinted = false,
    this.pressScale = 0.9,
  });

  final String label;
  final IconData? icon;
  final bool iconSpin;
  final VoidCallback? onTap;
  final double height;

  /// Solid tint background with white text (GEO 全部更新).
  final bool filled;

  /// `--tintbg` background (解析).
  final bool tinted;
  final double pressScale;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final bg = filled ? c.tint : (tinted ? c.tintBg : c.fill);
    final fg = filled ? const Color(0xFFFFFFFF) : c.tint;
    Widget? glyph = icon == null ? null : AvIcon(icon!, size: 18, color: fg);
    if (glyph != null && iconSpin) glyph = AvSpin(child: glyph);
    return AvPressable(
      onTap: onTap,
      scale: pressScale,
      scaleDuration: const Duration(milliseconds: 300),
      child: Container(
        height: height,
        padding: EdgeInsets.fromLTRB(icon == null ? 14 : 10, 0, 14, 0),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (glyph != null) ...[glyph, const SizedBox(width: 4)],
            Text(label, style: AvType.calloutStrong.copyWith(color: fg)),
          ],
        ),
      ),
    );
  }
}

/// Circular icon button (34 or 32). [primary] uses the tint fill.
class AvCircleButton extends StatelessWidget {
  const AvCircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 34,
    this.iconSize = 20,
    this.primary = false,
    this.iconWeight = 500,
    this.pressScale = 0.88,
    this.spin = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final bool primary;
  final double iconWeight;
  final double pressScale;
  final bool spin;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    Widget glyph = AvIcon(
      icon,
      size: iconSize,
      weight: iconWeight,
      color: primary ? const Color(0xFFFFFFFF) : c.tint,
    );
    if (spin) glyph = AvSpin(child: glyph);
    return AvPressable(
      onTap: onTap,
      scale: pressScale,
      scaleDuration: const Duration(milliseconds: 300),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: primary ? c.tint : c.fill,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: glyph,
      ),
    );
  }
}

/// Text action used in navigation bars (取消 / 保存 / 全部关闭): opacity .4 on
/// press.
class AvTextAction extends StatelessWidget {
  const AvTextAction(
    this.label, {
    super.key,
    this.onTap,
    this.strong = false,
    this.color,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool strong;
  final Color? color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.35,
      duration: const Duration(milliseconds: 200),
      child: AvPressable(
        onTap: enabled ? onTap : null,
        pressedOpacity: 0.4,
        child: Text(
          label,
          style: (strong ? AvType.bodyStrong : AvType.body).copyWith(
            color: color ?? context.av.tint,
          ),
        ),
      ),
    );
  }
}

/// Root-page large title row (`padding:4px 16px 10px`, 34/700, +.01em).
class AvLargeTitle extends StatelessWidget {
  const AvLargeTitle(
    this.title, {
    super.key,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 10),
  });

  final String title;
  final List<Widget> actions;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              title,
              style: AvType.largeTitle.copyWith(color: context.av.l1),
            ),
          ),
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: actions[i],
            ),
          ],
        ],
      ),
    );
  }
}

/// Pushed-page navigation bar: 44 high, `chevron_left` 32 + parent title,
/// centered 17/600 title, trailing actions.
class AvNavBar extends StatelessWidget {
  const AvNavBar({
    super.key,
    required this.title,
    required this.backLabel,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String backLabel;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: AvPressable(
                  onTap: onBack ?? () => Navigator.of(context).maybePop(),
                  pressedOpacity: 0.4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, 0),
                        child: AvIcon(
                          Symbols.chevron_left_rounded,
                          size: 32,
                          color: c.tint,
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(-4, 0),
                        child: Text(
                          backLabel,
                          style: AvType.body.copyWith(color: c.tint),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Text(title, style: AvType.bodyStrong.copyWith(color: c.l1)),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: trailing ?? const SizedBox(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Spinning glyph (`ios-spin .9s linear infinite`).
class AvSpin extends StatefulWidget {
  const AvSpin({super.key, required this.child});

  final Widget child;

  @override
  State<AvSpin> createState() => _AvSpinState();
}

class _AvSpinState extends State<AvSpin> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AvMotion.spin,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RotationTransition(turns: _c, child: widget.child);
}

/// The card at the top of the GEO and Tailscale pages (V3 3t, 3u:
/// `padding:14px 16px; gap:14px`, 46 px tile of radius 11): what the page
/// is about, its status, and its main action.
class AvHeaderCard extends StatelessWidget {
  const AvHeaderCard({
    super.key,
    required this.icon,
    required this.hue,
    required this.title,
    required this.subtitle,
    this.subtitleColor,
    this.trailing,
  });

  final IconData icon;
  final Color hue;
  final String title;
  final String subtitle;
  final Color? subtitleColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: c.cell,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          AvIconTile(icon, hue, size: 46, radius: 11, iconSize: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AvType.bodyStrong.copyWith(color: c.l1)),
                Text(
                  subtitle,
                  style: AvType.footnote.copyWith(color: subtitleColor ?? c.l2),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 14), trailing!],
        ],
      ),
    );
  }
}

/// An inline notice at the top of a page or form (PRODUCT_SPEC §8): what
/// happened, optional detail lines, and a close button when dismissible.
class AvBanner extends StatelessWidget {
  const AvBanner({
    super.key,
    required this.title,
    this.lines = const [],
    this.icon = Symbols.info_rounded,
    this.color,
    this.onClose,
    this.action,
    this.onAction,
  });

  final String title;
  final List<String> lines;
  final IconData icon;

  /// Icon colour; the accent by default.
  final Color? color;
  final VoidCallback? onClose;

  /// What the reader can do about it, as a text button under the lines.
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: c.cell,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvIcon(icon, size: 20, color: color ?? c.tint, fill: 1),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AvType.footnoteStrong.copyWith(color: c.l1)),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      line,
                      style: AvType.footnote.copyWith(color: c.l2),
                    ),
                  ),
                if (action != null)
                  AvPressable(
                    onTap: onAction,
                    pressedOpacity: 0.4,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        action!,
                        style: AvType.footnoteStrong.copyWith(color: c.tint),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (onClose != null)
            AvPressable(
              onTap: onClose,
              pressedOpacity: 0.4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 1, 4, 1),
                child: AvIcon(Symbols.close_rounded, size: 18, color: c.l3),
              ),
            ),
        ],
      ),
    );
  }
}
