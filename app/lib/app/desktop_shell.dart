import 'dart:async';
import 'dart:io';

import 'package:av_core/av_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../platform/desktop/desktop_window.dart';
import '../platform/desktop/global_hotkeys.dart';
import '../platform/desktop/login_item.dart';
import '../platform/desktop/system_tray.dart';
import '../runtime/runtime_coordinator.dart';
import '../runtime/runtime_state.dart';
import 'avalon_app.dart';
import 'desktop_proxy_controller.dart';
import 'log.dart';
import 'providers.dart';

/// How each global shortcut fared (the basic settings say «已被占用» or
/// «暂不支持», PRODUCT_SPEC §7); empty until the shell has tried.
final hotkeyResultsProvider =
    NotifierProvider<HotkeyResults, Map<HotkeyAction, HotkeyResult>>(
      HotkeyResults.new,
    );

final class HotkeyResults extends Notifier<Map<HotkeyAction, HotkeyResult>> {
  @override
  Map<HotkeyAction, HotkeyResult> build() => const {};

  void set(Map<HotkeyAction, HotkeyResult> results) => state = results;
}

enum LoginItemProblem { failed, approvalRequired }

final loginItemProblemProvider =
    NotifierProvider<LoginItemProblemState, LoginItemProblem?>(
      LoginItemProblemState.new,
    );

final class LoginItemProblemState extends Notifier<LoginItemProblem?> {
  @override
  LoginItemProblem? build() => null;

  void set(LoginItemProblem? problem) => state = problem;
}

/// The desktop shell (PRODUCT_SPEC §7, RUNTIME_HOST §9): the tray or menu
/// bar icon and its menu, the global shortcuts, the login item, and what
/// closing the window does. It follows the runtime and the settings on
/// [container] for as long as the app runs.
final class DesktopShell {
  DesktopShell({
    required this.container,
    required this.window,
    required this.tray,
    required this.hotkeys,
    required this.loginItem,
    required this.icons,
    this.quitApp,
    this.touchLoginItem = !kDebugMode,
  });

  final ProviderContainer container;
  final DesktopWindow window;
  final SystemTray tray;
  final GlobalHotkeys hotkeys;
  final LoginItem loginItem;

  /// The tray icons: idle and connected.
  final ({String idle, String running}) icons;

  /// Ends the process once the shell has let go (tests replace it).
  final Future<void> Function()? quitApp;

  /// Debug builds leave the login item alone: registering would make the
  /// development build start with the developer's session.
  final bool touchLoginItem;

  bool _trayShown = false;
  bool _quitting = false;
  Future<void> _loginItemQueue = Future.value();
  final _subscriptions = <StreamSubscription<Object?>>[];
  final _listeners = <ProviderSubscription<Object?>>[];

  /// Without a tray the window could not be found again once hidden, so
  /// closing it quits (PRODUCT_SPEC §7).
  bool get trayShown => _trayShown;

  RuntimeCoordinator get _runtime => container.read(runtimeProvider.notifier);

  /// Sets everything up; the window is shown unless [silent].
  Future<void> start({required bool silent}) async {
    await window.setup();
    _trayShown = await tray.show(icons.idle);
    // «静默启动» needs somewhere to come back from.
    if (!silent || !_trayShown) await window.show();
    _subscriptions
      ..add(window.closeRequests.listen((_) => unawaited(_closed())))
      ..add(window.quitRequests.listen((_) => unawaited(quit())))
      ..add(tray.choices.listen((key) => unawaited(_chosen(key))));
    _listeners
      ..add(
        container.listen(
          runtimeProvider.select(
            (s) => (s.proxyConnected, s.available, s.busy),
          ),
          (_, _) => unawaited(_refreshTray()),
        ),
      )
      ..add(
        container.listen(
          deviceSettingsProvider.select(
            (s) => (s.value?.mode, s.value?.locale),
          ),
          (_, _) => unawaited(_refreshTray()),
        ),
      )
      ..add(
        container.listen<bool?>(
          deviceSettingsProvider.select((s) => s.value?.launchAtStartup),
          (_, enabled) {
            if (enabled != null) unawaited(_setLoginItem(enabled));
          },
          fireImmediately: true,
        ),
      );
    await _refreshTray();
    await _registerHotkeys();
  }

  Future<void> _closed() async {
    final settings = await container.read(settingsRepositoryProvider).device();
    if (settings.keepOnClose && _trayShown) {
      await window.hide();
    } else {
      await quit();
    }
  }

  Future<void> _chosen(String key) async {
    switch (key) {
      case 'show':
        await window.show();
      case 'toggle':
        await _runtime.toggle();
      case 'quit':
        await quit();
      default:
        final mode = OutboundMode.values
            .where((m) => key == 'mode:${m.name}')
            .firstOrNull;
        if (mode != null) await _setMode(mode);
    }
  }

  Future<void> _setMode(OutboundMode mode) => container
      .read(settingsRepositoryProvider)
      .updateDevice((s) => s.copyWith(mode: mode));

  Future<void> _cycleMode() async {
    final current =
        (await container.read(settingsRepositoryProvider).device()).mode;
    const order = OutboundMode.values;
    await _setMode(order[(order.indexOf(current) + 1) % order.length]);
  }

  /// The menu of D31, in the app's language, and the icon of the state.
  Future<void> _refreshTray() async {
    if (!_trayShown || _quitting) return;
    final runtime = container.read(runtimeProvider);
    final settings = container.read(deviceSettingsProvider).value;
    final l = lookupAppLocalizations(appLocale(settings?.locale));
    final mode = settings?.mode ?? OutboundMode.rule;
    await tray.setIcon(runtime.proxyConnected ? icons.running : icons.idle);
    await tray.setMenu([
      TrayItem('show', l.hotkeyShow),
      const TrayItem.separator(),
      TrayItem(
        'toggle',
        runtime.proxyConnected ? l.trayStop : l.trayStart,
        // Where the platform has no host yet, nothing can start.
        enabled: runtime.available && !runtime.busy,
      ),
      TrayItem(
        'mode',
        l.trayMode,
        children: [
          for (final m in OutboundMode.values)
            TrayItem('mode:${m.name}', switch (m) {
              OutboundMode.rule => l.modeRuleFull,
              OutboundMode.global => l.modeGlobalFull,
              OutboundMode.direct => l.modeDirectFull,
            }, checked: m == mode),
        ],
      ),
      const TrayItem.separator(),
      TrayItem('quit', l.trayQuit),
    ]);
  }

  Future<void> _registerHotkeys() async {
    final results = <HotkeyAction, HotkeyResult>{};
    for (final action in HotkeyAction.values) {
      results[action] = await hotkeys.register(action, () {
        switch (action) {
          case HotkeyAction.toggle:
            unawaited(_runtime.toggle());
          case HotkeyAction.mode:
            unawaited(_cycleMode());
          case HotkeyAction.show:
            unawaited(window.show());
        }
      });
    }
    container.read(hotkeyResultsProvider.notifier).set(results);
  }

  Future<void> _setLoginItem(bool enabled) {
    // A slow system request must finish before the next preference takes
    // effect, including an enable immediately followed by a disable.
    _loginItemQueue = _loginItemQueue.then((_) => _applyLoginItem(enabled));
    return _loginItemQueue;
  }

  Future<void> _applyLoginItem(bool enabled) async {
    if (!touchLoginItem) {
      Log.info('desktop: login item left alone in a debug build ($enabled)');
      return;
    }
    try {
      await loginItem.set(enabled: enabled);
      container.read(loginItemProblemProvider.notifier).set(null);
    } on Object catch (e) {
      Log.warn('desktop: the login item could not be set: $e');
      container
          .read(loginItemProblemProvider.notifier)
          .set(
            e is PlatformException && e.code == 'approvalRequired'
                ? LoginItemProblem.approvalRequired
                : LoginItemProblem.failed,
          );
    }
  }

  /// Quits (the tray's entry, or closing with nothing to keep): the proxy
  /// stops first (RUNTIME_HOST §7).
  Future<void> quit() async {
    if (_quitting) return;
    _quitting = true;
    try {
      await _runtime.ready;
      // This also cancels a connection waiting for system permission and
      // joins the command queue before deciding whether exit is safe.
      await _runtime.stopAll();
    } on Object catch (e) {
      Log.warn('desktop: stopping before quitting failed: $e');
      _quitting = false;
      await _refreshTray();
      await window.show();
      return;
    }
    if (container.read(runtimeProvider).phase != RuntimePhase.stopped) {
      _quitting = false;
      await _refreshTray();
      await window.show();
      return;
    }
    if (!await container.read(desktopProxyProvider.notifier).restoreForExit()) {
      _quitting = false;
      await _refreshTray();
      await window.show();
      return;
    }
    for (final s in _subscriptions) {
      await s.cancel();
    }
    for (final l in _listeners) {
      l.close();
    }
    await hotkeys.unregisterAll();
    await window.quit();
    await (quitApp ?? _exit)();
  }

  static Future<void> _exit() async => exit(0);
}
