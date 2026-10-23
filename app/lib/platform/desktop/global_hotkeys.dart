import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The three global shortcuts (PRODUCT_SPEC §7).
enum HotkeyAction { toggle, mode, show }

/// What registering a shortcut came to.
enum HotkeyResult {
  registered,

  /// Another app holds it (shown as «已被占用»).
  taken,

  /// Not on this platform yet.
  unsupported,
}

abstract interface class GlobalHotkeys {
  Future<HotkeyResult> register(HotkeyAction action, void Function() onPressed);

  Future<void> unregisterAll();

  static GlobalHotkeys host() => switch (defaultTargetPlatform) {
    TargetPlatform.macOS => MacHotkeys(),
    TargetPlatform.windows || TargetPlatform.linux => NativeHotkeys(),
    _ => const NoHotkeys(),
  };
}

/// Hosts without a global shortcut API.
final class NoHotkeys implements GlobalHotkeys {
  const NoHotkeys();

  @override
  Future<HotkeyResult> register(
    HotkeyAction action,
    void Function() onPressed,
  ) async => HotkeyResult.unsupported;

  @override
  Future<void> unregisterAll() async {}
}

/// Win32 RegisterHotKey and Linux X11 grabs. Unsupported environments (such
/// as Wayland without a global-shortcuts portal) report the actual result.
final class NativeHotkeys implements GlobalHotkeys {
  NativeHotkeys() {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'pressed') return;
      final action = HotkeyAction.values
          .where((a) => a.name == call.arguments)
          .firstOrNull;
      if (action != null) _handlers[action]?.call();
    });
  }

  static const _channel = MethodChannel('avalon/hotkeys');
  final _handlers = <HotkeyAction, void Function()>{};

  @override
  Future<HotkeyResult> register(
    HotkeyAction action,
    void Function() onPressed,
  ) async {
    final result = await _channel.invokeMethod<String>('register', action.name);
    final status = HotkeyResult.values
        .where((value) => value.name == result)
        .firstOrNull;
    if (status == null) throw const FormatException('invalid hotkey result');
    if (status == HotkeyResult.registered) _handlers[action] = onPressed;
    return status;
  }

  @override
  Future<void> unregisterAll() async {
    await _channel.invokeMethod<void>('unregisterAll');
    _handlers.clear();
  }
}

/// ⌥⌘P, ⌥⌘M, ⌥⌘A through Carbon's hotkeys, in the window's Swift code.
final class MacHotkeys implements GlobalHotkeys {
  MacHotkeys() {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'pressed') return;
      final action = HotkeyAction.values
          .where((a) => a.name == call.arguments)
          .firstOrNull;
      if (action != null) _handlers[action]?.call();
    });
  }

  static const _channel = MethodChannel('avalon/hotkeys');
  final _handlers = <HotkeyAction, void Function()>{};

  @override
  Future<HotkeyResult> register(
    HotkeyAction action,
    void Function() onPressed,
  ) async {
    _handlers[action] = onPressed;
    final ok = await _channel.invokeMethod<bool>('register', action.name);
    return ok ?? false ? HotkeyResult.registered : HotkeyResult.taken;
  }

  @override
  Future<void> unregisterAll() async {
    _handlers.clear();
    await _channel.invokeMethod<void>('unregisterAll');
  }
}
