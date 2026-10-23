import 'dart:async';

import 'package:av_core/av_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../runtime/host_protocol.dart';
import '../../runtime/runtime_coordinator.dart';
import 'tailscale_state.dart';

final tailscaleViewModelProvider =
    NotifierProvider.autoDispose<TailscaleViewModel, TailscaleState>(
      TailscaleViewModel.new,
    );

/// Only native status reaches the page. Authorization URLs live in memory
/// while the page is open; identity state stays in the native private dir.
final class TailscaleViewModel extends Notifier<TailscaleState> {
  Timer? _timer;
  bool _reading = false;
  bool _openNextLogin = false;
  bool _actionFailed = false;

  @override
  TailscaleState build() {
    final host = ref.read(runtimeHostProvider);
    ref.listen(deviceSettingsProvider, (_, next) {
      if (next.value case final settings?) {
        state = state.copyWith(settings: settings.tailnet);
      }
    });
    ref.onDispose(() => _timer?.cancel());
    if (host != null) {
      _timer = Timer.periodic(
        ref.read(runtimePollIntervalProvider),
        (_) => unawaited(refresh()),
      );
      unawaited(Future.microtask(refresh));
    }
    return TailscaleState(
      available: host != null,
      settings:
          ref.read(deviceSettingsProvider).value?.tailnet ??
          const TailnetSettings(),
    );
  }

  Future<void> refresh() async {
    if (_reading || !ref.mounted) return;
    final host = ref.read(runtimeHostProvider);
    if (host == null) return;
    _reading = true;
    try {
      final status = await host.gateway.tailnetStatus();
      if (!ref.mounted) return;
      state = state.copyWith(
        status: status,
        error: _actionFailed ? null : () => null,
      );
      final url = status.loginUrl;
      if (_openNextLogin && state.settings.enabled && url != null) {
        _openNextLogin = false;
        await _openBrowser(url);
      }
    } on HostException catch (error) {
      if (ref.mounted) state = state.copyWith(error: () => error.error.message);
    } finally {
      _reading = false;
    }
  }

  Future<void> _openBrowser(String value) async {
    final url = Uri.tryParse(value);
    if (url == null ||
        url.scheme != 'https' ||
        url.host != 'login.tailscale.com' ||
        url.userInfo.isNotEmpty ||
        url.fragment.isNotEmpty ||
        (url.hasPort && url.port != 443)) {
      if (ref.mounted) state = state.copyWith(browserFailed: true);
      return;
    }
    var opened = false;
    try {
      opened = await ref.read(browserProvider).open(url);
    } on Exception {
      /* fixed user-facing failure */
    }
    if (ref.mounted) state = state.copyWith(browserFailed: !opened);
  }

  Future<void> _run(Future<void> Function() action) async {
    if (state.busy || !state.available) return;
    _actionFailed = false;
    state = state.copyWith(
      busy: true,
      error: () => null,
      runtimeFailure: () => null,
      browserFailed: false,
    );
    try {
      await action();
    } on HostException catch (error) {
      _actionFailed = true;
      if (ref.mounted) state = state.copyWith(error: () => error.error.message);
    } on Exception {
      _actionFailed = true;
      if (ref.mounted) state = state.copyWith(error: () => 'CORE_FAILED');
    } finally {
      if (ref.mounted) {
        state = state.copyWith(busy: false);
        await refresh();
      }
    }
  }

  Future<void> setEnabled(bool value) => _run(() async {
    _openNextLogin = value;
    final runtime = ref.read(runtimeProvider.notifier);
    await runtime.ready;
    if (!ref.mounted) return;
    await runtime.setTailnetEnabled(value);
    if (!ref.mounted) return;
    final saved = await ref.read(settingsRepositoryProvider).device();
    if (!ref.mounted) return;
    state = state.copyWith(
      settings: saved.tailnet,
      runtimeFailure: () => ref.read(runtimeProvider).failure,
    );
  });

  Future<void> login() => _run(() async {
    _openNextLogin = true;
    await ref.read(runtimeHostProvider)!.gateway.tailnetLogin();
  });

  Future<void> logout() => _run(() async {
    _openNextLogin = false;
    await ref.read(runtimeHostProvider)!.gateway.tailnetLogout();
    await _save((s) => s.copyWith(exit: null));
  });

  Future<void> _save(TailnetSettings Function(TailnetSettings) edit) async {
    final saved = await ref
        .read(settingsRepositoryProvider)
        .updateDevice((s) => s.copyWith(tailnet: edit(s.tailnet)));
    if (!ref.mounted) return;
    state = state.copyWith(settings: saved.tailnet);
    final runtime = ref.read(runtimeProvider.notifier);
    await runtime.ready;
    if (!ref.mounted) return;
    if (saved.tailnet.enabled && !ref.read(runtimeProvider).connected) {
      // Clearing an old unsupported exit restores the explicitly enabled
      // Tailnet intent; an ordinary settings refresh never reconnects it.
      await runtime.setTailnetEnabled(true);
    } else {
      await runtime.sync();
    }
    if (ref.mounted) {
      state = state.copyWith(
        runtimeFailure: () => ref.read(runtimeProvider).failure,
      );
    }
  }

  Future<void> selectExit(HostTailnetPeer? peer) => _run(() async {
    if (peer != null) {
      throw const HostException(
        HostError(
          HostErrorCode.unsupported,
          'Tailscale exit routing has not been verified',
        ),
      );
    } else {
      await _save((s) => s.copyWith(exit: null));
    }
  });

  Future<void> setAcceptRoutes(bool value) =>
      _run(() => _save((s) => s.copyWith(acceptRoutes: value)));
  Future<void> setMagicDns(bool value) =>
      _run(() => _save((s) => s.copyWith(magicDns: value)));
  Future<void> setAdvertiseExit(bool value) => _run(() async {
    if (value) {
      throw const HostException(
        HostError(
          HostErrorCode.unsupported,
          'Tailscale exit routing has not been verified',
        ),
      );
    }
    await _save((s) => s.copyWith(advertiseExit: value));
  });
}
