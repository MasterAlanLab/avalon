import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Speed sparkline: SVG `viewBox 0 0 326 72`, `preserveAspectRatio:none`,
/// 2.2 px round-joined tint stroke over a `--tintbg` area, scaled to
/// 110% of the window maximum.
class AvSpeedChart extends StatelessWidget {
  const AvSpeedChart({
    super.key,
    required this.samples,
    this.active = true,
    this.strokeWidth = 2.2,
  });

  final List<double> samples;
  final bool active;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    return CustomPaint(
      painter: _ChartPainter(samples, active, c.tint, c.tintBg, strokeWidth),
      size: Size.infinite,
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(
    this.samples,
    this.active,
    this.line,
    this.area,
    this.strokeWidth,
  );

  final List<double> samples;
  final bool active;
  final Color line;
  final Color area;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) return;
    final maxV = samples.reduce(math.max) * 1.1;
    final n = samples.length - 1;
    // V3 maps into a 72-unit-high box with a 6-unit top inset.
    double y(double v) => active && maxV > 0
        ? size.height - v / maxV * (size.height * (66 / 72))
        : size.height - 1;
    final path = Path()..moveTo(0, y(samples[0]));
    for (var i = 1; i <= n; i++) {
      path.lineTo(size.width * i / n, y(samples[i]));
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = area);
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.samples != samples ||
      old.active != active ||
      old.line != line ||
      old.area != area;
}
