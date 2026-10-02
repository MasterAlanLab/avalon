import 'dart:async';
import 'package:avalon/core/controller.dart';
import 'package:avalon/core/event.dart';
import 'package:avalon/core/method.dart';
import 'package:avalon/enum/enum.dart';
import 'package:avalon/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'model.dart';

typedef TailscaleRequest =
    Future<Map<String, dynamic>> Function(
      CoreMethod method, [
      Object? arguments,
    ]);

final tailscaleRequestProvider = Provider<TailscaleRequest>((ref) {
  return (method, [arguments]) async {
    // Starting the management core never starts the main service or asks for
    // TUN permission. Keep this production concern out of the state controller.
    if ((method == CoreMethod.tailscaleSnapshot ||
            method == CoreMethod.tailscaleLogin) &&
        ref.read(coreStatusProvider) == CoreStatus.disconnected) {
      await ref.read(coreActionProvider.notifier).startCore();
      if (!ref.mounted) return <String, dynamic>{};
    }
    return coreController.tailscale(method, arguments);
  };
});
final tailscaleProvider =
    NotifierProvider<TailscaleController, TailscaleViewState>(
      TailscaleController.new,
    );

class TailscaleController extends Notifier<TailscaleViewState>
    with CoreEventListener {
  @override
  TailscaleViewState build() {
    coreEventManager.addListener(this);
    ref.onDispose(() => coreEventManager.removeListener(this));
    ref.listen(coreStatusProvider, (_, next) {
      if (next == CoreStatus.connected) {
        unawaited(refresh());
      }
      if (next == CoreStatus.disconnected) {
        onCrash('');
      }
    });
    Future.microtask(refresh);
    return TailscaleViewState();
  }

  @override
  void onTailscale(Map<String, dynamic> data) =>
      accept(TailscaleSnapshot(data));
  void accept(TailscaleSnapshot incoming) {
    if (!ref.mounted || !incoming.isNewerThan(state.snapshot)) return;
    state = state.copy(snapshot: incoming, loading: false);
  }

  @override
  void onCrash(String message) {
    if (ref.mounted)
      state = state.copy(
        snapshot: state.snapshot.disconnected(),
        error: 'backend_disconnected',
        loading: false,
      );
  }

  Future<void> refresh() async {
    try {
      final data = await ref.read(tailscaleRequestProvider)(
        CoreMethod.tailscaleSnapshot,
      );
      if (ref.mounted) {
        accept(TailscaleSnapshot(data));
        state = state.copy(loading: false);
      }
    } catch (error) {
      if (ref.mounted) state = state.copy(error: _code(error), loading: false);
    }
  }

  String _code(Object error) =>
      error is CoreMethodException ? error.code : 'backend_error';
  Future<void> command(CoreMethod method, [Object? arguments]) async {
    if (state.busy) return;
    state = state.copy(busy: true);
    try {
      final data = await ref.read(tailscaleRequestProvider)(method, arguments);
      accept(TailscaleSnapshot(data));
      if (ref.mounted) state = state.copy(busy: false, loading: false);
    } catch (error) {
      if (ref.mounted)
        state = state.copy(busy: false, loading: false, error: _code(error));
    }
  }

  Future<void> preferences(Map<String, dynamic> changes) => command(
    CoreMethod.tailscalePreferences,
    {...state.snapshot.prefs, ...changes},
  );
  Future<void> probe(List<String> ids) =>
      command(CoreMethod.tailscaleProbe, {'ids': ids});
  Future<void> cancelProbes() => command(CoreMethod.tailscaleCancelProbes);
}
