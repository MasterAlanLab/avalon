// DEVELOPMENT ONLY: lets tool/fidelity/ios.sh drive the gallery or the app
// (gallery/app_main.dart) on the iOS simulator, which offers screenshots and
// video but no input injection.
//
// Dart sees no process environment on iOS, so the remote is switched on by a
// marker: ios.sh creates an empty av_remote.in in the app's temporary
// directory before launching. The host then appends commands to that file and
// waits for the count in av_remote.out:
//
//   tap X Y                   touch at logical point (X, Y)
//   drag X1 Y1 X2 Y2 MS       touch, move for MS milliseconds, release
//   hold X Y MS               touch and keep still for MS milliseconds
//   rclick X Y                right mouse click (desktop context menus)
//   hover X Y                 move the mouse there without pressing
//   type TEXT                 replace the focused field's text
//
// plus the commands the entry point registers (the gallery: `dark 0|1`,
// `account paid|free|loggedOut`).
//
// Touches are synthesized as framework pointer events, so they go through the
// same hit testing and gesture arena as real ones.
import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

typedef DevCommand = FutureOr<void> Function(List<String> args);

class DevRemote {
  DevRemote._(this._commands, this._in, this._out);

  final Map<String, DevCommand> _commands;
  final File _in;
  final File _out;
  int _done = 0;
  bool _busy = false;
  int _pointer = 9000;
  final _clock = Stopwatch()..start();

  static DevRemote? maybeStart({Map<String, DevCommand> commands = const {}}) {
    final dir = Directory.systemTemp.path;
    final file = File('$dir/av_remote.in');
    if (!file.existsSync()) return null;
    final remote = DevRemote._(commands, file, File('$dir/av_remote.out'));
    remote._out.writeAsStringSync('');
    Timer.periodic(const Duration(milliseconds: 50), (_) => remote._poll());
    return remote;
  }

  Future<void> _poll() async {
    if (_busy || !_in.existsSync()) return;
    final lines = _in.readAsLinesSync();
    if (lines.length <= _done) return;
    _busy = true;
    try {
      while (_done < lines.length) {
        await _run(lines[_done].trim().split(RegExp(r'\s+')));
        _done++;
        _out.writeAsStringSync('$_done\n');
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _run(List<String> a) async {
    double n(int i) => double.parse(a[i]);
    switch (a.first) {
      case 'tap':
        await _drag(Offset(n(1), n(2)), Offset(n(1), n(2)), 60);
      case 'drag':
        await _drag(Offset(n(1), n(2)), Offset(n(3), n(4)), n(5));
      case 'rclick':
        await _mouse(Offset(n(1), n(2)), kSecondaryMouseButton);
      case 'hover':
        await _mouse(Offset(n(1), n(2)), null);
      case 'hold':
        await _drag(Offset(n(1), n(2)), Offset(n(1), n(2)), n(3));
      case 'type':
        _type(a.skip(1).join(' '));
        await SchedulerBinding.instance.endOfFrame;
      default:
        await _commands[a.first]?.call(a);
    }
  }

  /// A mouse at [at]: pressed and released with [buttons], or only moved
  /// there when null.
  Future<void> _mouse(Offset at, int? buttons) async {
    final view = WidgetsBinding.instance.platformDispatcher.implicitView!;
    final pointer = ++_pointer;
    Duration now() => Duration(microseconds: _clock.elapsedMicroseconds);
    void send(PointerEvent e) => GestureBinding.instance.handlePointerEvent(e);
    send(
      PointerHoverEvent(
        viewId: view.viewId,
        kind: PointerDeviceKind.mouse,
        device: pointer,
        position: at,
        timeStamp: now(),
      ),
    );
    if (buttons != null) {
      send(
        PointerDownEvent(
          viewId: view.viewId,
          kind: PointerDeviceKind.mouse,
          pointer: pointer,
          device: pointer,
          buttons: buttons,
          position: at,
          timeStamp: now(),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));
      send(
        PointerUpEvent(
          viewId: view.viewId,
          kind: PointerDeviceKind.mouse,
          pointer: pointer,
          device: pointer,
          position: at,
          timeStamp: now(),
        ),
      );
    }
    await SchedulerBinding.instance.endOfFrame;
  }

  /// Replaces the text of the focused field, as the keyboard would.
  void _type(String text) {
    final editable = FocusManager.instance.primaryFocus?.context
        ?.findAncestorStateOfType<EditableTextState>();
    editable?.userUpdateTextEditingValue(
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
      SelectionChangedCause.keyboard,
    );
  }

  /// Down at [from], moves to [to] over [ms] at 120 Hz, then up.
  Future<void> _drag(Offset from, Offset to, double ms) async {
    final view = WidgetsBinding.instance.platformDispatcher.implicitView!;
    final pointer = ++_pointer;
    Duration now() => Duration(microseconds: _clock.elapsedMicroseconds);
    void send(PointerEvent e) => GestureBinding.instance.handlePointerEvent(e);

    send(
      PointerDownEvent(
        viewId: view.viewId,
        pointer: pointer,
        position: from,
        timeStamp: now(),
      ),
    );
    var last = from;
    final steps = (ms / 8).ceil();
    for (var i = 1; i <= steps; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 8));
      final p = Offset.lerp(from, to, i / steps)!;
      if (p != last) {
        send(
          PointerMoveEvent(
            viewId: view.viewId,
            pointer: pointer,
            position: p,
            delta: p - last,
            timeStamp: now(),
          ),
        );
        last = p;
      }
    }
    send(
      PointerUpEvent(
        viewId: view.viewId,
        pointer: pointer,
        position: to,
        timeStamp: now(),
      ),
    );
    await SchedulerBinding.instance.endOfFrame;
  }
}
