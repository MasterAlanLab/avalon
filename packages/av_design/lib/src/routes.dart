import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

import 'density.dart';
import 'effects.dart';
import 'theme.dart';
import 'tokens.dart';

/// Edge strip that starts a back swipe (iOS uses 20 pt).
const double _kBackSwipeEdge = 20;

/// Fling speed, in screen widths per second, that decides a released swipe.
const double _kBackSwipeFling = 1;

/// Settle time after a released back swipe. V3 has no gesture, so this keeps
/// the iOS feel with the V3 curve.
const Duration _kBackSwipeSettle = Duration(milliseconds: 350);

/// Page push/pop exactly as V3 draws it: the new page slides in from 100%
/// (`ios-push .5s`), the page underneath moves to -30% and fades to 0.6
/// (`ios-pop .5s`, reversed on push), both on `cubic-bezier(.32,.72,0,1)`.
/// Pops replay the same motion backwards in time, so each direction eases out.
///
/// Keeps the iOS edge swipe: the transition follows the finger linearly and,
/// on release, settles with the V3 curve.
class AvPageRoute<T> extends PageRoute<T> {
  AvPageRoute({
    required this.builder,
    super.settings,
    this.maintainState = true,
  });

  final WidgetBuilder builder;

  @override
  final bool maintainState;

  @override
  Duration get transitionDuration => AvMotion.push;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  /// Moves aside for another [AvPageRoute]; routes that bring their own
  /// delegated transition (the add sheet) take over this page instead.
  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) =>
      nextRoute is AvPageRoute ||
      (nextRoute is ModalRoute && nextRoute.delegatedTransition != null);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: builder(context),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _AvPushTransition(
      primary: animation,
      secondary: secondaryAnimation,
      linear: popGestureInProgress,
      backdrop: context.av.bg,
      child: _AvBackSwipe(route: this, child: child),
    );
  }

  void _swipeStart() => navigator!.didStartUserGesture();

  void _swipeUpdate(double fraction) => controller!.value -= fraction;

  void _swipeEnd(double velocity) {
    final c = controller!;
    final bool stay;
    if (!isCurrent) {
      // Popped programmatically mid-swipe: finish whatever the stack says.
      stay = isActive;
    } else if (velocity.abs() >= _kBackSwipeFling) {
      stay = velocity <= 0;
    } else {
      stay = c.value > 0.5;
    }
    if (stay) {
      c.animateTo(1, duration: _kBackSwipeSettle, curve: AvMotion.ios);
    } else {
      if (isCurrent) navigator!.pop();
      if (c.isAnimating) {
        c.animateBack(0, duration: _kBackSwipeSettle, curve: AvMotion.ios);
      }
    }
    if (c.isAnimating) {
      // Stay linear until settled so the curve does not switch mid-flight.
      late final AnimationStatusListener done;
      done = (_) {
        navigator?.didStopUserGesture();
        c.removeStatusListener(done);
      };
      c.addStatusListener(done);
    } else {
      navigator!.didStopUserGesture();
    }
  }
}

class _AvPushTransition extends StatefulWidget {
  const _AvPushTransition({
    required this.primary,
    required this.secondary,
    required this.linear,
    required this.backdrop,
    required this.child,
  });

  final Animation<double> primary;
  final Animation<double> secondary;
  final bool linear;
  final Color backdrop;
  final Widget child;

  @override
  State<_AvPushTransition> createState() => _AvPushTransitionState();
}

class _AvPushTransitionState extends State<_AvPushTransition> {
  static final _inTween = Tween(begin: const Offset(1, 0), end: Offset.zero);
  static final _asideTween = Tween(
    begin: Offset.zero,
    end: const Offset(-0.3, 0),
  );
  static final _dimTween = Tween<double>(begin: 1, end: 0.6);

  CurvedAnimation? _primary;
  CurvedAnimation? _secondary;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void didUpdateWidget(_AvPushTransition old) {
    super.didUpdateWidget(old);
    if (old.primary != widget.primary ||
        old.secondary != widget.secondary ||
        old.linear != widget.linear) {
      _dispose();
      _setup();
    }
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _setup() {
    final curve = widget.linear ? Curves.linear : AvMotion.ios;
    final reverse = widget.linear ? Curves.linear : AvMotion.ios.flipped;
    _primary = CurvedAnimation(
      parent: widget.primary,
      curve: curve,
      reverseCurve: reverse,
    );
    _secondary = CurvedAnimation(
      parent: widget.secondary,
      curve: curve,
      reverseCurve: reverse,
    );
  }

  void _dispose() {
    _primary?.dispose();
    _secondary?.dispose();
    _primary = _secondary = null;
  }

  @override
  Widget build(BuildContext context) {
    final dir = Directionality.of(context);
    final page = SlideTransition(
      position: _primary!.drive(_inTween),
      textDirection: dir,
      transformHitTests: false,
      child: widget.child,
    );
    if (widget.secondary.isDismissed) return page;
    // The covered page fades toward the screen background, as in V3.
    return ColoredBox(
      color: widget.backdrop,
      child: SlideTransition(
        position: _secondary!.drive(_asideTween),
        textDirection: dir,
        transformHitTests: false,
        child: FadeTransition(
          opacity: _secondary!.drive(_dimTween),
          child: page,
        ),
      ),
    );
  }
}

class _AvBackSwipe extends StatefulWidget {
  const _AvBackSwipe({required this.route, required this.child});

  final AvPageRoute<dynamic> route;
  final Widget child;

  @override
  State<_AvBackSwipe> createState() => _AvBackSwipeState();
}

class _AvBackSwipeState extends State<_AvBackSwipe> {
  late final HorizontalDragGestureRecognizer _drag;
  bool _active = false;

  @override
  void initState() {
    super.initState();
    _drag = HorizontalDragGestureRecognizer(debugOwner: this)
      ..onStart = _start
      ..onUpdate = _update
      ..onEnd = _end
      ..onCancel = _cancel;
  }

  @override
  void dispose() {
    if (_active) widget.route._swipeEnd(0);
    _drag.dispose();
    super.dispose();
  }

  double _forward(double v) =>
      Directionality.of(context) == TextDirection.rtl ? -v : v;

  void _start(DragStartDetails d) {
    _active = true;
    widget.route._swipeStart();
  }

  void _update(DragUpdateDetails d) {
    if (!_active) return;
    widget.route._swipeUpdate(_forward(d.primaryDelta! / context.size!.width));
  }

  void _end(DragEndDetails d) {
    if (!_active) return;
    _active = false;
    widget.route._swipeEnd(
      _forward(d.velocity.pixelsPerSecond.dx / context.size!.width),
    );
  }

  void _cancel() {
    if (!_active) return;
    _active = false;
    widget.route._swipeEnd(0);
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final inset = Directionality.of(context) == TextDirection.rtl
        ? padding.right
        : padding.left;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        PositionedDirectional(
          start: 0,
          top: 0,
          bottom: 0,
          width: math.max(inset, _kBackSwipeEdge),
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (e) {
              if (widget.route.popGestureEnabled) _drag.addPointer(e);
            },
          ),
        ),
      ],
    );
  }
}

/// iOS page sheet with V3 timing: the sheet rises over 550 ms on
/// `cubic-bezier(.32,.72,0,1)` (`ios-sheet .55s`) and the page behind scales
/// back in step. Drag-to-dismiss and scroll hand-off stay native.
///
/// [CupertinoSheetTransition] hard-codes its own curves, so the route feeds it
/// a re-timed animation whose value, once passed through those curves, lands
/// exactly on the V3 curve. While a drag is in progress the raw value is used,
/// as the framework does.
class AvSheetRoute<T> extends CupertinoSheetRoute<T> {
  AvSheetRoute({required super.scrollableBuilder, super.settings});

  Animation<double>? _source;
  Animation<double>? _retimed;

  @override
  Duration get transitionDuration => AvMotion.sheet;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      super.delegatedTransition == null ? null : _delegate;

  // A static tear-off keeps the builder identical across routes, which the
  // navigator relies on to tell a sheet from the page beneath it.
  static Widget? _delegate(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) {
    final linear = Navigator.of(context).userGestureInProgress;
    final page = CupertinoSheetTransition.delegateTransition(
      context,
      animation,
      linear
          ? secondaryAnimation
          : _Retimed(secondaryAnimation, _behindIn, _behindOut),
      allowSnapshotting,
      child,
    );
    if (secondaryAnimation.isDismissed) return page;
    final progress = linear
        ? secondaryAnimation
        : _Retimed(secondaryAnimation, AvMotion.ios, AvMotion.ios.flipped);
    return Stack(
      children: [
        page,
        IgnorePointer(
          child: FadeTransition(
            opacity: progress.drive(
              Tween(begin: 0, end: context.av.isDark ? _dimDark : _dimLight),
            ),
            child: const ColoredBox(
              color: Color(0xFF000000),
              child: SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }

  // The framework dims the page behind by 10%. V3 shows that strip as
  // `var(--cell)` at 45% over black: 115 over the light background #F2F2F7
  // (242 × 0.9 × 0.53) and 13 over the dark #000 (framework 20 × 0.65).
  static const _dimLight = 0.47;
  static const _dimDark = 0.35;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (!identical(_source, animation)) {
      _source = animation;
      _retimed = _Retimed(animation, _sheetIn, _sheetOut);
    }
    return super.buildTransitions(
      context,
      popGestureInProgress ? animation : _retimed!,
      secondaryAnimation,
      child,
    );
  }

  // Framework curves this route compensates for (flutter/cupertino/sheet.dart).
  static final _sheetIn = _Compensate(
    Curves.fastEaseInToSlowEaseOut,
    AvMotion.ios,
  );
  static final _sheetOut = _Compensate(
    Curves.fastEaseInToSlowEaseOut.flipped,
    AvMotion.ios.flipped,
  );
  static final _behindIn = _Compensate(Curves.linearToEaseOut, AvMotion.ios);
  static final _behindOut = _Compensate(
    Curves.easeInToLinear,
    AvMotion.ios.flipped,
  );
}

/// `inner⁻¹ ∘ target`: applying [inner] afterwards yields [target].
class _Compensate extends Curve {
  const _Compensate(this.inner, this.target);

  final Curve inner;
  final Curve target;

  @override
  double transformInternal(double t) {
    final y = target.transform(t);
    var lo = 0.0, hi = 1.0;
    for (var i = 0; i < 24; i++) {
      final mid = (lo + hi) / 2;
      if (inner.transform(mid) < y) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return (lo + hi) / 2;
  }
}

/// Applies [forward] or [reverse] by the parent's current direction, without
/// latching, to match the framework's per-frame `CurvedAnimation`s.
class _Retimed extends Animation<double> with AnimationWithParentMixin<double> {
  _Retimed(this.parent, this.forward, this.reverse);

  @override
  final Animation<double> parent;
  final Curve forward;
  final Curve reverse;

  @override
  double get value {
    final t = parent.value;
    if (t <= 0 || t >= 1) return t.clamp(0.0, 1.0);
    return (parent.status == AnimationStatus.reverse ? reverse : forward)
        .transform(t);
  }
}

/// A declarative page (go_router `pageBuilder`) shown with [AvPageRoute].
/// The child is read from the current page, so an updated page rebuilds the
/// route's content in place.
class AvPage<T> extends Page<T> {
  const AvPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => AvPageRoute<T>(
    settings: this,
    builder: (context) => (ModalRoute.of(context)!.settings as AvPage<T>).child,
  );
}

/// A declarative page shown as an [AvSheetRoute]; [builder] receives the
/// sheet's scroll controller.
class AvSheetPage<T> extends Page<T> {
  const AvSheetPage({
    required this.builder,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final ScrollableWidgetBuilder builder;

  @override
  Route<T> createRoute(BuildContext context) => AvSheetRoute<T>(
    settings: this,
    scrollableBuilder: (context, controller) =>
        (ModalRoute.of(context)!.settings as AvSheetPage<T>).builder(
          context,
          controller,
        ),
  );
}

/// The desktop counterpart of a sheet (V3 3p «添加» dialog): a 580-wide panel
/// that zooms in over a 30% black scrim; clicking the scrim closes it.
class AvDialogRoute<T> extends PopupRoute<T> {
  AvDialogRoute({required this.builder, super.settings});

  final WidgetBuilder builder;

  static const double width = 580;

  @override
  Color get barrierColor => const Color(0x4D000000);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => null;

  @override
  Curve get barrierCurve => Curves.easeOut;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final c = context.av;
    final height = (MediaQuery.sizeOf(context).height - 80).clamp(400.0, 680.0);
    return Center(
      child: AvZoomIn(
        duration: const Duration(milliseconds: 400),
        child: Container(
          width: width,
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: c.bg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), spreadRadius: 0.5),
              BoxShadow(
                color: Color(0x59000000),
                offset: Offset(0, 24),
                blurRadius: 60,
              ),
            ],
          ),
          child: AvDensity.desktop(child: Builder(builder: builder)),
        ),
      ),
    );
  }

  // The panel zooms in by itself; only closing fades with the scrim.
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(opacity: _ClosingOnly(animation), child: child);
}

class _ClosingOnly extends Animation<double>
    with AnimationWithParentMixin<double> {
  _ClosingOnly(this.parent);

  @override
  final Animation<double> parent;

  @override
  double get value =>
      parent.status == AnimationStatus.reverse ? parent.value : 1;
}

/// A declarative page shown as an [AvDialogRoute].
class AvDialogPage<T> extends Page<T> {
  const AvDialogPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => AvDialogRoute<T>(
    settings: this,
    builder: (context) =>
        (ModalRoute.of(context)!.settings as AvDialogPage<T>).child,
  );
}

/// A declarative page that cross-fades in place, without sliding: the
/// content pane of the desktop tools page (V3 3p swaps it in 300 ms).
class AvSwapPage<T> extends Page<T> {
  const AvSwapPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => PageRouteBuilder<T>(
    settings: this,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, _, _) =>
        (ModalRoute.of(context)!.settings as AvSwapPage<T>).child,
    transitionsBuilder: (context, animation, _, child) => FadeTransition(
      opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
      child: child,
    ),
  );
}
