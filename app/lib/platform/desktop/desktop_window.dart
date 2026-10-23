import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

/// The main window as the desktop shell needs it (RUNTIME_HOST §9).
abstract interface class DesktopWindow {
  /// Takes over the close button: [closeRequests] fire instead.
  Future<void> setup();

  Future<void> show();
  Future<void> hide();

  /// The user closed the window (its button, ⌘W).
  Stream<void> get closeRequests;

  /// System/application quit (for example ⌘Q), independently of closing
  /// the window. The shell finishes runtime cleanup before exiting.
  Stream<void> get quitRequests;

  /// Closes the window for good: the app ends.
  Future<void> quit();
}

final class WindowManagerWindow with WindowListener implements DesktopWindow {
  final _closes = StreamController<void>.broadcast();
  final _quits = StreamController<void>.broadcast();
  AppLifecycleListener? _lifecycle;

  @override
  Stream<void> get closeRequests => _closes.stream;

  @override
  Stream<void> get quitRequests => _quits.stream;

  @override
  Future<void> setup() async {
    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);
    windowManager.addListener(this);
    _lifecycle = AppLifecycleListener(
      onExitRequested: () async {
        if (!_quits.hasListener) return AppExitResponse.exit;
        _quits.add(null);
        return AppExitResponse.cancel;
      },
    );
  }

  @override
  void onWindowClose() {
    if (_closes.hasListener) {
      _closes.add(null);
    } else {
      // A startup failure displays a window without creating a shell.
      unawaited(quit());
    }
  }

  @override
  Future<void> show() async {
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  Future<void> hide() => windowManager.hide();

  @override
  Future<void> quit() async {
    _lifecycle?.dispose();
    _lifecycle = null;
    windowManager.removeListener(this);
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }
}
