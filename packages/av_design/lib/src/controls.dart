import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'density.dart';
import 'icon.dart';
import 'theme.dart';
import 'tokens.dart';

/// V3 switch. Regular 51×31 (thumb 27, travel 20), small 38×22 (thumb 18,
/// travel 16). Track color eases over 300 ms; the thumb slides with
/// `cubic-bezier(.34,1.4,.64,1)`.
class AvSwitch extends StatelessWidget {
  const AvSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.small,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// 38×22 when true; defaults to the desktop density.
  final bool? small;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final small = this.small ?? AvDensity.isDesktop(context);
    final w = small ? 38.0 : 51.0;
    final h = small ? 22.0 : 31.0;
    final d = small ? 18.0 : 27.0;
    final travel = small ? 16.0 : 20.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onChanged!(!value);
            },
      child: AnimatedContainer(
        duration: AvMotion.switchTrack,
        curve: AvMotion.ease,
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: value ? c.ok : c.fill2,
          borderRadius: BorderRadius.circular(h / 2),
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value ? travel : 0),
          duration: small
              ? const Duration(milliseconds: 350)
              : AvMotion.switchThumb,
          curve: AvMotion.springSoft,
          builder: (context, dx, child) =>
              Transform.translate(offset: Offset(2 + dx, 2), child: child),
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: d,
              height: d,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                shape: BoxShape.circle,
                boxShadow: small
                    ? AvShadows.switchThumbSmall
                    : AvShadows.switchThumb,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum AvSegmentStyle {
  /// Stand-alone control: 36 high (V3 `height:32px;padding:2px`,
  /// content-box), radius 9/7, two-layer thumb shadow.
  primary,

  /// Inside a list row: 30–32 high, radius 8/6, single soft shadow.
  inline,

  /// Desktop density: 28 high (border-box rows; pass 32 for the toolbar,
  /// log filter and transport rows, which are content-box), radius 8/6,
  /// 12 px labels.
  desktop,
}

/// V3 sliding segmented control. The thumb glides 400 ms on
/// `cubic-bezier(.32,.72,0,1)`; labels switch weight 500 → 600 instantly.
class AvSegmented<T> extends StatelessWidget {
  const AvSegmented({
    super.key,
    required this.values,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
    this.style = AvSegmentStyle.primary,
    this.width,
    this.height,
    this.fontSize,
  });

  final List<T> values;
  final String Function(T) labelOf;
  final T selected;
  final ValueChanged<T> onChanged;
  final AvSegmentStyle style;
  final double? width;
  final double? height;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    // Desktop density always uses V3's desktop segment metrics.
    final style = AvDensity.isDesktop(context)
        ? AvSegmentStyle.desktop
        : this.style;
    final h =
        height ??
        switch (style) {
          // V3 `height:32px;padding:2px` is content-box: 36 overall.
          AvSegmentStyle.primary => 36.0,
          AvSegmentStyle.inline => 30.0,
          AvSegmentStyle.desktop => 28.0,
        };
    final outer = style == AvSegmentStyle.primary ? 9.0 : 8.0;
    final inner = style == AvSegmentStyle.primary ? 7.0 : 6.0;
    final shadow = style == AvSegmentStyle.primary
        ? AvShadows.segmentThumb
        : AvShadows.segmentThumbInline;
    final size = fontSize ?? (style == AvSegmentStyle.desktop ? 12.0 : 13.0);
    final index = values.indexOf(selected).clamp(0, values.length - 1);

    return Container(
      width: width,
      height: h,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.fill,
        borderRadius: BorderRadius.circular(outer),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final segW = box.maxWidth / values.length;
          return Stack(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: index * segW),
                duration: AvMotion.segment,
                curve: AvMotion.ios,
                builder: (context, x, child) => Positioned(
                  left: x,
                  top: 0,
                  bottom: 0,
                  width: segW,
                  child: child!,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.thumb,
                    borderRadius: BorderRadius.circular(inner),
                    boxShadow: shadow,
                  ),
                ),
              ),
              Row(
                children: [
                  for (final v in values)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (v == selected) return;
                          HapticFeedback.selectionClick();
                          onChanged(v);
                        },
                        child: Center(
                          child: Text(
                            labelOf(v),
                            maxLines: 1,
                            style: AvType.s(
                              size,
                              weight: v == selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ).copyWith(color: c.l1),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Checkmark that pops in from scale 0 with overshoot (`transform .4s
/// cubic-bezier(.34,1.56,.64,1)`).
class AvPopIcon extends StatelessWidget {
  const AvPopIcon(
    this.icon, {
    super.key,
    required this.visible,
    this.size = 22,
    this.color,
  });

  final IconData icon;
  final bool visible;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: visible ? 1 : 0,
      duration: AvMotion.check,
      curve: AvMotion.spring,
      child: AvIcon(icon, size: size, color: color ?? context.av.tint),
    );
  }
}
