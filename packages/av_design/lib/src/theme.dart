import 'package:flutter/widgets.dart';

import 'tokens.dart';

/// Provides [AvColors] to the subtree. Read with `context.av`.
class AvTheme extends InheritedWidget {
  const AvTheme({super.key, required this.colors, required super.child});

  final AvColors colors;

  static AvColors of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AvTheme>()?.colors ??
      AvColors.light;

  @override
  bool updateShouldNotify(AvTheme oldWidget) => oldWidget.colors != colors;
}

extension AvThemeContext on BuildContext {
  AvColors get av => AvTheme.of(this);
}
