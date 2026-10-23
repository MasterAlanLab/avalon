import 'package:flutter/widgets.dart';

/// Material Symbols Rounded glyph with V3 defaults: `.ms` sets
/// `'FILL' 1, 'wght' 500`, and browsers apply optical sizing automatically
/// (the loaded font's `opsz` axis spans 20–48).
class AvIcon extends StatelessWidget {
  const AvIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
    this.fill = 1,
    this.weight = 500,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final double fill;
  final double weight;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color,
      fill: fill,
      weight: weight,
      opticalSize: size.clamp(20, 48).toDouble(),
    );
  }
}
