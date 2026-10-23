import 'package:flutter/widgets.dart';

import 'theme.dart';
import 'tokens.dart';

/// Two expanding rings behind the power button:
/// `ios-pulse 2.4s cubic-bezier(.2,.6,.4,1) infinite`, second ring delayed
/// 1.2 s; scale 1 → 1.7, opacity .45 → 0.
class AvPulseRings extends StatefulWidget {
  const AvPulseRings({super.key, required this.size, required this.active});

  final double size;
  final bool active;

  @override
  State<AvPulseRings> createState() => _AvPulseRingsState();
}

class _AvPulseRingsState extends State<AvPulseRings>
    with SingleTickerProviderStateMixin {
  // Created with the state, not on first use: a ring that was never
  // active would otherwise make its controller while being disposed.
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: AvMotion.pulsePeriod);
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(AvPulseRings old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.active) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return SizedBox.square(dimension: widget.size);
    // Painted on a layer of its own, straight from the animation: each
    // frame repaints only the rings, without rebuilding or laying out.
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _RingsPainter(_c, context.av.tint),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.animation, this.tint) : super(repaint: animation);

  final Animation<double> animation;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (final phase in const [0.0, 0.5]) {
      final t = AvMotion.pulse.transform((animation.value + phase) % 1.0);
      canvas.drawCircle(
        center,
        size.width / 2 * (1 + 0.7 * t),
        Paint()..color = tint.withValues(alpha: 0.45 * (1 - t)),
      );
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) =>
      old.animation != animation || old.tint != tint;
}

/// Status dot that breathes (`ios-blink 2s ease-in-out infinite`, opacity
/// 1 → .35 → 1).
class AvBlinkDot extends StatefulWidget {
  const AvBlinkDot({
    super.key,
    required this.color,
    this.size = 8,
    this.active = true,
  });

  final Color color;
  final double size;
  final bool active;

  @override
  State<AvBlinkDot> createState() => _AvBlinkDotState();
}

class _AvBlinkDotState extends State<AvBlinkDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AvMotion.blink,
  );

  // 0→50%: 1→.35, 50→100%: .35→1, each half ease-in-out; 1 at rest.
  late final Animation<double> _opacity = _c.drive(
    TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.35,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.35,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
    ]),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(AvBlinkDot old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.active) {
      _c
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A layer of its own: each frame changes only its opacity.
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(widget.size / 2),
          ),
        ),
      ),
    );
  }
}

/// Enter animation for rows and expanding panels
/// (`ios-drop`: translateY(-8px), opacity 0 → none, 350 ms
/// `cubic-bezier(.32,.72,0,1)`). Plays once when first built.
class AvDropIn extends StatefulWidget {
  const AvDropIn({
    super.key,
    required this.child,
    this.duration = AvMotion.drop,
  });

  final Widget child;
  final Duration duration;

  @override
  State<AvDropIn> createState() => _AvDropInState();
}

class _AvDropInState extends State<AvDropIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();
  late final CurvedAnimation _t = CurvedAnimation(
    parent: _c,
    curve: AvMotion.ios,
  );

  @override
  void dispose() {
    _t.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, -8 * (1 - _t.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Popover/dialog enter (`ios-zoom`: scale .92 + opacity 0 → none).
class AvZoomIn extends StatefulWidget {
  const AvZoomIn({
    super.key,
    required this.child,
    this.alignment = Alignment.center,
    this.duration = AvMotion.zoom,
  });

  final Widget child;
  final Alignment alignment;
  final Duration duration;

  @override
  State<AvZoomIn> createState() => _AvZoomInState();
}

class _AvZoomInState extends State<AvZoomIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();
  late final CurvedAnimation _t = CurvedAnimation(
    parent: _c,
    curve: AvMotion.ios,
  );

  @override
  void dispose() {
    _t.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) => Opacity(
        opacity: _t.value.clamp(0, 1),
        child: Transform.scale(
          scale: 0.92 + 0.08 * _t.value,
          alignment: widget.alignment,
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Fade + slight zoom used for tab switches (`ios-fade .32s ease-out`) and
/// sheet segment swaps (`.25s`). Replays whenever [token] changes.
class AvFadeSwap extends StatefulWidget {
  const AvFadeSwap({
    super.key,
    required this.token,
    required this.child,
    this.duration = AvMotion.tabFade,
    this.cacheDuringTransition = false,
  });

  final Object token;
  final Widget child;
  final Duration duration;

  /// Cache the page input while scaling, then return to unfiltered painting.
  /// Content changes still repaint; this does not freeze a page snapshot.
  /// Keep this option fixed while mounted to preserve the child's element path.
  final bool cacheDuringTransition;

  @override
  State<AvFadeSwap> createState() => _AvFadeSwapState();
}

class _AvFadeSwapState extends State<AvFadeSwap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  );
  late final CurvedAnimation _t = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOut,
  );

  @override
  void didUpdateWidget(AvFadeSwap old) {
    super.didUpdateWidget(old);
    if (old.token != widget.token) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _t.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.scale(
          scale: 0.985 + 0.015 * _t.value,
          filterQuality: widget.cacheDuringTransition && _t.value < 1
              ? FilterQuality.low
              : null,
          child: child,
        ),
      ),
      child: widget.cacheDuringTransition
          ? RepaintBoundary(child: widget.child)
          : widget.child,
    );
  }
}
