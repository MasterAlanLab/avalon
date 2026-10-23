import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/background.dart';
import '../app/log.dart';
import '../app/providers.dart';
import '../services/exit_ip.dart';
import 'host_protocol.dart';
import 'runtime_coordinator.dart';
import 'runtime_state.dart';

/// The exit IP the dashboard shows (CONFIG_PIPELINE §9): through the
/// running session's main selector, or the device's own when nothing runs.
/// A result belongs to the session and the exit it was measured on; when
/// either changes it is dropped and measured again. Null while unknown,
/// on failure, and when the build names no probe service.
final exitIpProvider = NotifierProvider<ExitIpProbe, ExitIp?>(ExitIpProbe.new);

final class ExitIpProbe extends Notifier<ExitIp?> {
  final _background = Background();
  var _epoch = 0;
  late RuntimeCoordinator _runtime;

  @override
  ExitIp? build() {
    final service = ref.watch(exitIpServiceProvider);
    if (service.url == null) return null;
    _runtime = ref.read(runtimeProvider.notifier);
    ref.listen(
      runtimeProvider.select(_measuredOn),
      (_, on) => _measure(service, on),
      fireImmediately: true,
    );
    return null;
  }

  /// Completes once a measurement under way is done (tests).
  Future<void> idle() => _background.done();

  /// What a result is tied to: the session and its actual exit while
  /// running, «direct» when stopped, nothing in between.
  String _measuredOn(RuntimeState s) {
    if (s.phase == RuntimePhase.stopped ||
        (s.phase == RuntimePhase.running && !s.proxyConnected)) {
      return 'direct';
    }
    final snapshot = s.snapshot;
    if (s.phase != RuntimePhase.running || snapshot.sessionId.isEmpty) {
      return '';
    }
    // Down through the selectors to the outbound traffic leaves by.
    var exit = _runtime.primaryTag;
    final seen = <String>{};
    for (
      var next = snapshot.selections[exit];
      next != null && seen.add(exit);
      next = snapshot.selections[exit]
    ) {
      exit = next;
    }
    return 'session ${snapshot.sessionId} $exit';
  }

  void _measure(ExitIpService service, String on) {
    final epoch = ++_epoch;
    state = null;
    if (on.isEmpty) return;
    _background.run('exit ip', () async {
      ExitIp? found;
      try {
        found = on == 'direct'
            ? await service.direct()
            : ExitIp.parse(
                await _runtime.fetchText(
                  service.url!,
                  maxBytes: ExitIpService.maxBytes,
                ),
              );
      } on HostException catch (e) {
        Log.info('exit ip: ${e.error.code.name}');
      } on Exception catch (e) {
        Log.info('exit ip: ${e.runtimeType}');
      }
      // A later session or exit has its own measurement.
      if (ref.mounted && epoch == _epoch) state = found;
    });
  }
}
