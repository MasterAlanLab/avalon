import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/log.dart';
import '../../runtime/host_protocol.dart';
import '../../runtime/runtime_coordinator.dart';

/// The running session's connections, read every second while the page
/// is open and the proxy runs (RUNTIME_HOST §6).
final connectionsViewModelProvider =
    NotifierProvider.autoDispose<ConnectionsViewModel, List<HostConnection>>(
      ConnectionsViewModel.new,
    );

final class ConnectionsViewModel extends Notifier<List<HostConnection>> {
  Timer? _poll;
  var _reading = false;

  @override
  List<HostConnection> build() {
    void schedule(bool connected) {
      _poll?.cancel();
      _poll = connected
          ? Timer.periodic(
              ref.read(runtimePollIntervalProvider),
              (_) => unawaited(read()),
            )
          : null;
      if (!connected) state = const [];
    }

    ref
      ..listen(runtimeProvider.select((s) => s.connected), (_, connected) {
        schedule(connected);
        if (connected) unawaited(read());
      })
      ..onDispose(() => _poll?.cancel());
    final connected = ref.read(runtimeProvider).connected;
    if (connected) {
      _poll = Timer.periodic(
        ref.read(runtimePollIntervalProvider),
        (_) => unawaited(read()),
      );
      unawaited(Future.microtask(read));
    }
    return const [];
  }

  Future<void> read() async {
    if (_reading || !ref.mounted) return;
    _reading = true;
    try {
      final list = await ref.read(runtimeProvider.notifier).connections();
      if (ref.mounted) state = list;
    } on HostException catch (e) {
      Log.warn('connections: the host did not answer: ${e.error.message}');
    } finally {
      _reading = false;
    }
  }

  /// Closes one connection; it leaves the list at once.
  Future<void> close(String id) async {
    state = [
      for (final c in state)
        if (c.id != id) c,
    ];
    await _quietly(
      () => ref.read(runtimeProvider.notifier).closeConnections(id: id),
    );
  }

  Future<void> closeAll() async {
    state = const [];
    await _quietly(() => ref.read(runtimeProvider.notifier).closeConnections());
  }

  /// A connection that could not be closed shows up again on the next read.
  Future<void> _quietly(Future<void> Function() command) async {
    try {
      await command();
    } on HostException catch (e) {
      Log.warn('connections: closing failed: ${e.error.message}');
    }
    await read();
  }
}
