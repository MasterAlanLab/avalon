import 'package:flutter/widgets.dart';

import 'theme.dart';
import 'tokens.dart';

/// V3 press feedback. CSS `:active` + `transition` applies the same curve in
/// both directions, so a press both settles and releases with overshoot.
///
/// * [scale]: `transform:scale(x)` with `cubic-bezier(.34,1.56,.64,1)`.
/// * [pressedOpacity]: `opacity:x` with a 200 ms `ease`.
/// * [highlight]: list-row background jumps to `--hl` on press
///   (`transition:none`) and fades back over 250 ms on release.
///
/// Tap-down is reported after `kPressTimeout` inside scrollables, which gives
/// the iOS delayed highlight for free.
class AvPressable extends StatefulWidget {
  const AvPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale,
    this.scaleDuration = AvMotion.press,
    this.pressedOpacity,
    this.highlight = false,
    this.highlightOut = AvMotion.highlightOut,
    this.borderRadius = BorderRadius.zero,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? scale;
  final Duration scaleDuration;
  final double? pressedOpacity;
  final bool highlight;
  final Duration highlightOut;
  final BorderRadius borderRadius;

  @override
  State<AvPressable> createState() => _AvPressableState();
}

class _AvPressableState extends State<AvPressable>
    with TickerProviderStateMixin {
  AnimationController? _scaleController;
  AnimationController? _opacityController;
  AnimationController? _highlightController;

  // Unbounded so the overshooting curve can carry the value past its target.
  AnimationController get _scale =>
      _scaleController ??= AnimationController.unbounded(vsync: this);
  AnimationController get _opacity =>
      _opacityController ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      );
  AnimationController get _highlight =>
      _highlightController ??= AnimationController(vsync: this, value: 0);

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  void _down(TapDownDetails _) {
    if (!_enabled) return;
    if (widget.scale != null) {
      _scale.animateTo(
        1,
        duration: widget.scaleDuration,
        curve: AvMotion.spring,
      );
    }
    if (widget.pressedOpacity != null) {
      _opacity.animateTo(1, curve: AvMotion.ease);
    }
    if (widget.highlight) _highlight.value = 1;
  }

  void _up() {
    if (widget.scale != null) {
      _scale.animateTo(
        0,
        duration: widget.scaleDuration,
        curve: AvMotion.spring,
      );
    }
    if (widget.pressedOpacity != null) {
      _opacity.animateTo(0, curve: AvMotion.ease);
    }
    if (widget.highlight) {
      _highlight.animateTo(
        0,
        duration: widget.highlightOut,
        curve: AvMotion.ease,
      );
    }
  }

  @override
  void dispose() {
    _scaleController?.dispose();
    _opacityController?.dispose();
    _highlightController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.child;

    if (widget.highlight) {
      final hl = context.av.hl;
      child = AnimatedBuilder(
        animation: _highlight,
        builder: (context, child) => DecoratedBox(
          decoration: BoxDecoration(
            color: hl.withValues(alpha: hl.a * _highlight.value),
            borderRadius: widget.borderRadius,
          ),
          child: child,
        ),
        child: child,
      );
    }
    if (widget.pressedOpacity != null) {
      final target = widget.pressedOpacity!;
      child = AnimatedBuilder(
        animation: _opacity,
        builder: (context, child) =>
            Opacity(opacity: 1 - (1 - target) * _opacity.value, child: child),
        child: child,
      );
    }
    if (widget.scale != null) {
      final target = widget.scale!;
      child = AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: 1 - (1 - target) * _scale.value,
          child: child,
        ),
        child: child,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _down,
      onTapUp: (_) => _up(),
      onTapCancel: _up,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: child,
    );
  }
}
