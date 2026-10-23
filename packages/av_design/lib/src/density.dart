import 'package:flutter/widgets.dart';

enum AvDensityMode { touch, desktop }

/// Touch (V3 mobile frames) or desktop (V3 3p/3q/3r) density. Components
/// read it to pick V3's desktop metrics: 14 px rows at 40–42 high, 12 px
/// captions, 38×22 switches, 28 high segments, no row chevrons.
class AvDensity extends InheritedWidget {
  const AvDensity({super.key, required this.mode, required super.child});

  const AvDensity.desktop({super.key, required super.child})
    : mode = AvDensityMode.desktop;

  final AvDensityMode mode;

  static AvDensityMode of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AvDensity>()?.mode ??
      AvDensityMode.touch;

  static bool isDesktop(BuildContext context) =>
      of(context) == AvDensityMode.desktop;

  @override
  bool updateShouldNotify(AvDensity oldWidget) => oldWidget.mode != mode;
}
