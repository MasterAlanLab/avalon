import 'package:av_core/av_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../services/plan_service.dart';
import 'host_protocol.dart';
import 'runtime_coordinator.dart';

enum LatencyStatus { testing, measured, timedOut, failed }

/// What is known about how fast a member answers (PRODUCT_SPEC §3.2).
@immutable
final class Latency {
  const Latency(this.status, {this.ms, this.stale = false});

  final LatencyStatus status;

  /// Milliseconds, when [status] is `measured`.
  final int? ms;

  /// Measured in a session that has ended since, or against another test
  /// address: still shown, greyed.
  final bool stale;

  Latency get asStale => status == LatencyStatus.testing
      ? this
      : Latency(status, ms: ms, stale: true);
}

/// A member of a configuration. The same member answers alike in every
/// group it appears in, so the group is not part of the key; the test
/// address is not either: changing it makes the results stale instead.
typedef LatencyKey = (String configurationId, MemberRef member);

/// Why a test did not run.
enum LatencyRefusal {
  /// This platform has no host yet.
  noHost,

  /// No configuration to test, or it cannot be compiled.
  noPlan,

  /// The host could not be reached or refused.
  hostFailed,
}

final latencyProvider =
    NotifierProvider<LatencyController, Map<LatencyKey, Latency>>(
      LatencyController.new,
    );

/// Latency results, kept in memory (CONFIG_PIPELINE §9). They belong to
/// the session they were measured in: when it changes they turn stale.
final class LatencyController extends Notifier<Map<LatencyKey, Latency>> {
  var _run = 0;

  /// The newest test of each key; an older one arriving late is dropped.
  final _newest = <LatencyKey, int>{};

  @override
  Map<LatencyKey, Latency> build() {
    // Measured in another session, or against another address: still
    // shown, but no longer current.
    void stale() => state = {
      for (final entry in state.entries) entry.key: entry.value.asStale,
    };
    ref
      ..listen(runtimeProvider.select((s) => s.snapshot.sessionId), (_, _) {
        stale();
      })
      ..listen(deviceSettingsProvider.select((s) => s.value?.testUrl), (
        previous,
        next,
      ) {
        if (previous != null && previous != next) stale();
      });
    return const {};
  }

  /// Tests [members] of the selected configuration. Null when it ran;
  /// members the plan has no outbound for are left as they were.
  Future<LatencyRefusal?> test(List<MemberRef> members) async {
    if (!ref.read(runtimeProvider).available) return LatencyRefusal.noHost;
    final settings = await ref.read(settingsRepositoryProvider).device();
    final configurationId = settings.selectedConfigurationId;
    if (configurationId == null) return LatencyRefusal.noPlan;
    final CompiledPlan plan;
    try {
      plan = await ref.read(planServiceProvider).compileSelected();
    } on PlanUnavailableException {
      return LatencyRefusal.noPlan;
    } on CompileException {
      return LatencyRefusal.noPlan;
    }

    final run = ++_run;
    final tags = <String, LatencyKey>{};
    for (final member in members) {
      // REJECT answers nothing by design.
      if (member == const MemberRef.builtin(builtin: Builtin.reject)) continue;
      final tag = plan.tagOf(member);
      if (tag == null) continue;
      final key = (configurationId, member);
      tags[tag] = key;
      _newest[key] = run;
    }
    if (tags.isEmpty) return null;
    state = {
      ...state,
      for (final key in tags.values) key: const Latency(LatencyStatus.testing),
    };

    Map<String, HostLatency> results;
    LatencyRefusal? refusal;
    try {
      results = await ref
          .read(runtimeProvider.notifier)
          .urlTest(plan, tags.keys.toList());
    } on HostException {
      results = const {};
      refusal = LatencyRefusal.hostFailed;
    }
    state = {
      ...state,
      for (final MapEntry(key: tag, value: key) in tags.entries)
        if (_newest[key] == run) key: _latency(results[tag]),
    };
    return refusal;
  }

  static Latency _latency(HostLatency? result) {
    final ms = result?.delayMs;
    if (ms != null && ms > 0) return Latency(LatencyStatus.measured, ms: ms);
    return Latency(
      result?.timedOut ?? false ? LatencyStatus.timedOut : LatencyStatus.failed,
    );
  }
}
