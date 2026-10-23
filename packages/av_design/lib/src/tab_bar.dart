import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'icon.dart';
import 'theme.dart';
import 'tokens.dart';

class AvTabItem {
  const AvTabItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

/// CSS `saturate(s)` as a color matrix.
List<double> _saturate(double s) => [
  0.213 + 0.787 * s,
  0.715 - 0.715 * s,
  0.072 - 0.072 * s,
  0,
  0,
  0.213 - 0.213 * s,
  0.715 + 0.285 * s,
  0.072 - 0.072 * s,
  0,
  0,
  0.213 - 0.213 * s,
  0.715 - 0.715 * s,
  0.072 + 0.928 * s,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];

/// Translucent material: `backdrop-filter: blur(20px) saturate(180%)` over a
/// semi-opaque fill. Filters apply left to right, so blur is the inner filter.
final ui.ImageFilter avBarMaterial = ui.ImageFilter.compose(
  outer: ui.ColorFilter.matrix(_saturate(1.8)),
  inner: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20, tileMode: TileMode.clamp),
);

/// Bottom tab bar: 49 + home-indicator inset, frosted, hairline top border.
/// Active item: tint, filled glyph (`FILL 1, wght 500`), scale 1; inactive:
/// `#999`, outline glyph (`FILL 0, wght 400`), scale .92. Scale animates
/// 450 ms on `cubic-bezier(.34,1.8,.64,1)`, color 250 ms; press dims to .5.
class AvTabBar extends StatelessWidget {
  const AvTabBar({
    super.key,
    required this.items,
    required this.index,
    required this.onTap,
  });

  final List<AvTabItem> items;
  final int index;
  final ValueChanged<int> onTap;

  static const double barHeight = 49;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: avBarMaterial,
        child: Container(
          // V3 `height:83px;border-top:0.5px`: the border sits on top.
          height: barHeight + bottom + AvBorder.hairline,
          padding: EdgeInsets.only(bottom: bottom),
          decoration: BoxDecoration(
            color: c.tbar,
            border: Border(top: BorderSide(color: c.sep, width: 0.5)),
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _TabButton(
                    item: items[i],
                    active: i == index,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatefulWidget {
  const _TabButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final AvTabItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final color = widget.active ? c.tint : AvHues.tabInactive;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: Opacity(
        opacity: _down ? 0.5 : 1,
        child: Padding(
          padding: const EdgeInsets.only(top: 7),
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: color),
            duration: const Duration(milliseconds: 250),
            builder: (context, col, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: widget.active ? 1 : 0.92,
                  duration: const Duration(milliseconds: 450),
                  curve: AvMotion.springStrong,
                  child: AvIcon(
                    widget.item.icon,
                    size: 27,
                    color: col,
                    fill: widget.active ? 1 : 0,
                    weight: widget.active ? 500 : 400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(widget.item.label, style: AvType.tab.copyWith(color: col)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
