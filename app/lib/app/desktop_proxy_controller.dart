import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../platform/desktop/system_proxy.dart';
import '../runtime/runtime_coordinator.dart';
import 'providers.dart';

final desktopSystemProxyProvider = Provider<DesktopSystemProxy?>((ref) {
  final DesktopProxyBackend backend;
  if (Platform.isWindows) {
    backend = const WindowsProxyBackend();
  } else if (Platform.isLinux) {
    backend = GnomeProxyBackend();
  } else {
    return null;
  }
  final secrets = ref.watch(servicesProvider).secrets;
  return DesktopSystemProxy(
    backend: backend,
    readRecovery: secrets.systemProxyRecovery,
    saveRecovery: secrets.saveSystemProxyRecovery,
  );
});

final class DesktopProxyState {
  const DesktopProxyState({
    this.managed = false,
    this.active = false,
    this.failed = false,
    this.known = false,
  });
  final bool managed;
  final bool active;
  final bool failed;
  final bool known;
}

final desktopProxyProvider =
    NotifierProvider<DesktopProxyController, DesktopProxyState>(
      DesktopProxyController.new,
    );

final desktopProxyPollIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 10),
);

/// OS proxy settings belong to the desktop session, independently of the
/// helper. This service remains alive when no page is watching it (D88).
final class DesktopProxyController extends Notifier<DesktopProxyState> {
  Future<void> _queue = Future.value();
  (bool, int?)? _last;
  Timer? _timer;
  bool _exiting = false;

  @override
  DesktopProxyState build() {
    final manager = ref.read(desktopSystemProxyProvider);
    if (manager == null) return const DesktopProxyState();
    ref.listen(deviceSettingsProvider, (_, _) => unawaited(reconcile()));
    ref.listen(
      runtimeProvider.select(
        (r) => (r.phase, r.proxyConnected, r.activeMixedPort),
      ),
      (_, _) => unawaited(reconcile()),
    );
    _timer = Timer.periodic(
      ref.read(desktopProxyPollIntervalProvider),
      (_) => unawaited(_inspect()),
    );
    ref.onDispose(() => _timer?.cancel());
    unawaited(Future.microtask(reconcile));
    return const DesktopProxyState(managed: true);
  }

  Future<void> reconcile({bool force = false}) {
    if (!ref.mounted) return Future.value();
    final manager = ref.read(desktopSystemProxyProvider);
    if (manager == null) return Future.value();
    _queue = _queue
        .then((_) async {
          await ref.read(runtimeProvider.notifier).ready;
          if (!ref.mounted || _exiting) return;
          final settings = await ref.read(settingsRepositoryProvider).device();
          if (!ref.mounted || _exiting) return;
          final runtime = ref.read(runtimeProvider);
          if (runtime.busy) return;
          final wanted = runtime.proxyConnected && settings.systemProxy;
          final port = runtime.activeMixedPort;
          // A saved preference cannot prove which port an adopted or
          // unsuccessfully reloaded session actually listens on.
          if (wanted && port == null) {
            state = const DesktopProxyState(managed: true);
            _last = null;
            return;
          }
          final intent = (wanted, wanted ? port : null);
          if (!force && _last == intent) return;
          try {
            if (wanted) {
              await manager.apply(port!);
            } else {
              await manager.restore();
            }
            _last = intent;
            if (ref.mounted) {
              state = DesktopProxyState(
                managed: true,
                active: wanted,
                known: true,
              );
            }
          } on Object {
            if (ref.mounted) {
              state = const DesktopProxyState(managed: true, failed: true);
            }
          }
        })
        .catchError((Object _) {
          if (ref.mounted) {
            state = const DesktopProxyState(managed: true, failed: true);
          }
        });
    return _queue;
  }

  Future<void> _inspect() async {
    if (!ref.mounted) return;
    final manager = ref.read(desktopSystemProxyProvider);
    if (manager == null || _exiting) return;
    // Retry a failed cleanup after disconnect. A failed enable or a user's
    // subsequent OS change must never be overwritten by a periodic retry.
    try {
      if (state.failed) {
        final settings = await ref.read(settingsRepositoryProvider).device();
        if (!ref.mounted || _exiting) return;
        if (!ref.read(runtimeProvider).proxyConnected ||
            !settings.systemProxy) {
          await reconcile(force: true);
        }
        return;
      }
      if (!state.active) return;
      final observed = state;
      final port = ref.read(runtimeProvider).activeMixedPort;
      if (port == null) {
        state = const DesktopProxyState(managed: true);
        _last = null;
        return;
      }
      final active = await manager.active(port);
      if (ref.mounted && identical(state, observed)) {
        state = DesktopProxyState(managed: true, active: active, known: true);
      }
    } on Object {
      if (ref.mounted) {
        state = const DesktopProxyState(managed: true, failed: true);
      }
    }
  }

  /// Quit never recomputes "wanted" from a core which failed to stop.
  Future<bool> restoreForExit() async {
    _exiting = true;
    await _queue;
    final manager = ref.read(desktopSystemProxyProvider);
    if (manager == null) return true;
    try {
      await manager.restore();
      if (ref.mounted) {
        state = const DesktopProxyState(managed: true, known: true);
      }
      return true;
    } on Object {
      _exiting = false;
      if (ref.mounted) {
        state = const DesktopProxyState(managed: true, failed: true);
      }
      return false;
    }
  }
}
