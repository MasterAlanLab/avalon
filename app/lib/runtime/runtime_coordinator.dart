import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:av_core/av_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/background.dart';
import '../app/log.dart';
import '../app/providers.dart';
import '../app/rule_set_updates.dart' show cloudRuleSetUrls;
import '../app/selected_configuration.dart';
import '../services/plan_service.dart';
import '../services/resource_service.dart';
import 'host_protocol.dart';
import 'runtime_host.dart';
import 'runtime_state.dart';

/// The host of this device; null where it is not built yet.
final runtimeHostProvider = Provider<RuntimeHost?>(
  (ref) => ref.watch(servicesProvider).runtimeHost,
);

/// Whether «启动后自动连接» applies: the interface opening, not the
/// background updates (D75), which never start the proxy.
final runtimeConnectAtLaunchProvider = Provider<bool>((ref) => true);

/// How often the host is asked for its state while a session runs and the
/// app is in view (RUNTIME_HOST §6).
final runtimePollIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 1),
);

/// How long changes to what the plan is made from are gathered before the
/// running session is reloaded (D10): a subscription refresh writes more
/// than once.
final runtimeDebounceProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 1),
);

final runtimeProvider = NotifierProvider<RuntimeCoordinator, RuntimeState>(
  RuntimeCoordinator.new,
);

/// Seconds of download speed kept for the chart.
const runtimeSpeedSamples = 30;

/// Holds what the user wants (the proxy on or off), turns it into commands
/// for the host one at a time, and follows the host's state (RUNTIME_HOST
/// §4). While a session runs it also keeps it in line with what the user
/// changes (§5): a choice of member or mode is switched in place, anything
/// else that alters the plan reloads it. Pages read its state and call
/// [connect], [disconnect] or [toggle]; nothing else talks to the host.
final class RuntimeCoordinator extends Notifier<RuntimeState> {
  RuntimeHost? _host;

  /// The user's intent; a start still waiting for the system's consent is
  /// dropped when this turned false meanwhile.
  bool _wanted = false;
  bool _proxyIntentTouched = false;
  Future<void> _queue = Future.value();
  Timer? _poll;
  bool _visible = true;
  Future<bool>? _refreshing;
  var _refreshingEpoch = 0;
  String _sessionId = '';

  /// Hash of the plan the session runs; a compiled plan with another hash
  /// needs a reload (CONFIG_PIPELINE §7).
  String _planHash = '';

  /// The main selector of the running plan: downloads «经代理» go there.
  String _primaryTag = '';

  /// The choices in the plan file the host restarts from.
  PlanChoices? _keptChoices;
  final _watching = <ProviderSubscription<Object?>>[];
  Timer? _debounce;
  final _background = Background();

  /// The mode and members the session should run with: its plan's, as our
  /// own commands switched them since. Null until known (a session adopted
  /// at start-up, before the first sync).
  PlanChoices? _expected;

  /// Changes to the two dashboard switches are rendered optimistically while
  /// the running plan is reloaded. A newer edit keeps the optimistic value
  /// alive when an older reload finishes.
  var _runtimePreferenceEpoch = 0;

  /// Counts commands of ours starting and ending, so that a snapshot that
  /// overlapped one is not mistaken for someone else's change.
  var _commandEpoch = 0;
  var _commanding = false;

  @override
  RuntimeState build() {
    _host = ref.watch(runtimeHostProvider);
    ref.onDispose(() {
      _poll?.cancel();
      _debounce?.cancel();
    });
    final host = _host;
    if (host == null) return const RuntimeState(available: false);
    // The host keeps what it acts on by itself (RUNTIME_HOST §8).
    ref.listen(
      deviceSettingsProvider.select((s) => s.whenData(HostOptions.of).value),
      (_, options) {
        if (options == null) return;
        _background.run(
          'runtime: host options',
          () => host.system.configure(options),
        );
      },
      fireImmediately: true,
    );
    // A host may already run a session (the app was closed, not the proxy).
    ready = Future.microtask(attach);
    return const RuntimeState();
  }

  /// Completes once the host's state has been read for the first time.
  Future<void> ready = Future.value();

  /// One command at a time, in the order asked.
  Future<void> _enqueue(Future<void> Function() command) {
    final next = _queue.then((_) async {
      _commanding = true;
      _commandEpoch++;
      try {
        await command();
      } finally {
        _commanding = false;
        _commandEpoch++;
      }
    });
    _queue = next.catchError((Object error) {
      Log.error('runtime: a command failed', error);
    });
    return next;
  }

  /// Reads the host's state and adopts a session it already runs.
  Future<void> attach() => _enqueue(() async {
    final host = _host;
    if (host == null) return;
    try {
      final capabilities = await host.gateway.capabilities();
      final snapshot = await host.gateway.snapshot();
      state = state.copyWith(coreVersion: capabilities.coreVersion);
      if (!_proxyIntentTouched) {
        _wanted = snapshot.proxyActive ?? snapshot.state == HostState.running;
      }
      _adopt(snapshot);
      if (snapshot.state == HostState.running) {
        // What the plan is made from may have changed while the app was
        // closed.
        _scheduleSync(debounced: false);
      } else {
        await host.system.release();
        // «启动后自动连接»: once, as the app opens (PRODUCT_SPEC §4).
        final settings = await ref.read(settingsRepositoryProvider).device();
        if ((settings.autoConnect || settings.tailnet.enabled) &&
            ref.mounted &&
            ref.read(runtimeConnectAtLaunchProvider)) {
          _background.run(
            'runtime: connecting at launch',
            settings.autoConnect ? connect : _connectTailnet,
          );
        }
      }
    } on HostException catch (e) {
      Log.error('runtime: the host did not answer', e);
    }
  });

  Future<void> toggle() =>
      state.proxyConnected || (state.phase == RuntimePhase.starting && _wanted)
      ? disconnect()
      : connect();

  /// Starts the proxy with the selected configuration.
  Future<void> connect() {
    _proxyIntentTouched = true;
    _wanted = true;
    return _enqueue(_startOrSync);
  }

  Future<void> _connectTailnet() => _enqueue(_startOrSync);

  Future<void> setTunPreference(bool enabled) async {
    final epoch = ++_runtimePreferenceEpoch;
    if (state.proxyConnected) {
      state = state.copyWith(pendingTun: () => enabled);
    }
    try {
      await ref
          .read(settingsRepositoryProvider)
          .updateDevice((s) => s.copyWith(tunEnabled: enabled));
      if (state.proxyConnected) _scheduleSync(debounced: false);
    } catch (_) {
      if (epoch == _runtimePreferenceEpoch) {
        state = state.copyWith(pendingTun: () => null);
      }
      rethrow;
    }
  }

  Future<void> setSystemProxyPreference(bool enabled) async {
    final epoch = ++_runtimePreferenceEpoch;
    if (state.proxyConnected) {
      state = state.copyWith(pendingSystemProxy: () => enabled);
    }
    try {
      await ref
          .read(settingsRepositoryProvider)
          .updateDevice((s) => s.copyWith(systemProxy: enabled));
      if (state.proxyConnected) _scheduleSync(debounced: false);
    } catch (_) {
      if (epoch == _runtimePreferenceEpoch) {
        state = state.copyWith(pendingSystemProxy: () => null);
      }
      rethrow;
    }
  }

  /// Keeps the independently saved Tailnet intent in the one native
  /// session. Turning either feature off preserves the other feature.
  Future<void> setTailnetEnabled(bool enabled) async {
    await ref
        .read(settingsRepositoryProvider)
        .updateDevice(
          (s) => s.copyWith(tailnet: s.tailnet.copyWith(enabled: enabled)),
        );
    await _enqueue(() async {
      if (enabled || _wanted) {
        await _startOrSync();
      } else {
        await _stopSession();
      }
    });
  }

  Future<void> _startOrSync() async {
    final host = _host;
    if (host == null) return;
    if (state.connected) {
      await _sync();
      return;
    }
    final intent = await ref.read(settingsRepositoryProvider).device();
    if (!_wanted && !intent.tailnet.enabled) return;
    state = state.copyWith(phase: RuntimePhase.starting, failure: () => null);
    try {
      final settings = await ref.read(settingsRepositoryProvider).device();
      if (!await host.system.prepare(
        tun: settings.tailnet.enabled || (_wanted && settings.tunEnabled),
      )) {
        _stopped(const PermissionRefused());
        return;
      }
      // Stop was pressed while the system asked: do not start after all.
      final latest = await ref.read(settingsRepositoryProvider).device();
      if (!_wanted && !latest.tailnet.enabled) {
        _stopped(null);
        return;
      }
      final plan = await _compile();
      if (await _noListedAppInstalled(plan)) {
        _stopped(const NoListedAppInstalled());
        return;
      }
      final file = await _writePlan(host, plan);
      final session = await host.gateway.start(
        planPath: file.path,
        planHash: plan.planHash,
        utcOffset: DateTime.now().timeZoneOffset,
      );
      await _keepPlan(file, plan);
      _sessionId = session.sessionId;
      _planHash = plan.planHash;
      _primaryTag = plan.primaryTag;
      _expected = plan.choices;
      state = state.copyWith(
        phase: RuntimePhase.running,
        speeds: const [],
        tags: plan.tags,
        activeMixedPort: () => _mixedPort(plan),
        activeProxyTun: () => _proxyTun(plan),
      );
      await refresh();
      _schedule();
      _background.run('runtime: pruning rule sets', _prune);
    } on PlanUnavailableException catch (e) {
      _stopped(NothingToRun(e.reason));
    } on CompileException catch (e) {
      _stopped(PlanFailed(e));
    } on HostException catch (e) {
      _stopped(HostFailed(e.error));
    }
  }

  /// Stops the proxy.
  Future<void> disconnect() {
    _proxyIntentTouched = true;
    _wanted = false;
    return _enqueue(() async {
      final settings = await ref.read(settingsRepositoryProvider).device();
      if (settings.tailnet.enabled) {
        await _sync();
        return;
      }
      await _stopSession();
    });
  }

  /// Application exit stops both features while retaining saved options.
  Future<void> stopAll() {
    _proxyIntentTouched = true;
    _wanted = false;
    return _enqueue(_stopSession);
  }

  Future<void> _stopSession() async {
    final host = _host;
    if (host == null || state.phase == RuntimePhase.stopped) return;
    state = state.copyWith(phase: RuntimePhase.stopping);
    try {
      await host.gateway.stop();
      _stopped(null);
      await refresh();
      await host.system.release();
    } on HostException catch (e) {
      // Not assumed stopped: the next snapshot says what the host does.
      state = state.copyWith(failure: () => HostFailed(e.error));
      await refresh();
    }
  }

  /// The app came into view or left it: the host is only asked while
  /// someone can see the answer.
  void setVisible(bool visible) {
    _visible = visible;
    if (visible) _background.run('runtime: refresh', refresh);
    _schedule();
  }

  /// Asks the host for its state now. Concurrent callers share the query;
  /// false means no fresh snapshot could be confirmed, so actions must
  /// not mistake the last known state for a current answer.
  Future<bool> refresh() {
    final host = _host;
    if (host == null) return Future.value(false);
    final epoch = _commandEpoch;
    final pending = _refreshing;
    if (pending != null) {
      if (_refreshingEpoch == epoch) return pending;
      // A command's follow-up cannot reuse a query sent before that
      // command. Wait for it, then query once more for the current epoch.
      return pending.then((_) => epoch == _commandEpoch ? refresh() : false);
    }
    _refreshingEpoch = epoch;
    return _refreshing = _refresh(
      host,
      epoch,
    ).whenComplete(() => _refreshing = null);
  }

  Future<bool> _refresh(RuntimeHost host, int epoch) async {
    try {
      final snapshot = await host.gateway.snapshot();
      // A lifecycle command may have changed the session while this
      // query was in flight. Its own follow-up snapshot confirms the
      // result; an older poll must not undo it or authorize an action.
      if (epoch != _commandEpoch) return false;
      if (!_adopt(snapshot)) return false;
      // Only a snapshot that no command of ours overlapped can show
      // someone else's change.
      if (!_commanding && epoch == _commandEpoch) {
        await _writeBackExternal(snapshot);
      }
      // Persisting an external change can yield while our own command
      // starts. Only a stable, idle epoch confirms an action's snapshot.
      return epoch == _commandEpoch && !_commanding;
    } on HostException catch (e) {
      Log.error('runtime: the host did not answer', e);
      return false;
    }
  }

  /// Follows what the host reports. The host can stop by itself (the user
  /// turned the VPN off in the system): the intent then follows it, and
  /// nothing is reconnected (RUNTIME_HOST §4).
  bool _adopt(HostSnapshot snapshot) {
    final previous = state.snapshot;
    // Revisions count up within a host process; a lower one from the same
    // session arrived late.
    if (snapshot.sessionId == previous.sessionId &&
        snapshot.revision < previous.revision) {
      return false;
    }
    switch (snapshot.state) {
      case HostState.running:
        _sessionId = snapshot.sessionId;
        // A queued lifecycle change already records the user's latest
        // proxy intent. Its confirmation must not revive the old intent.
        if (!_commanding) {
          _wanted = snapshot.proxyActive ?? true;
        }
        if (_planHash.isEmpty) _planHash = snapshot.planHash;
        final sameSession = snapshot.sessionId == previous.sessionId;
        final speeds = [if (sameSession) ...state.speeds, snapshot.downBps];
        state = state.copyWith(
          phase: state.phase == RuntimePhase.reloading
              ? RuntimePhase.reloading
              : RuntimePhase.running,
          snapshot: snapshot,
          activeMixedPort:
              !_commanding && snapshot.planHash != previous.planHash
              ? () => null
              : null,
          activeProxyTun: !_commanding && snapshot.planHash != previous.planHash
              ? () => null
              : null,
          speeds: speeds.length > runtimeSpeedSamples
              ? speeds.sublist(speeds.length - runtimeSpeedSamples)
              : speeds,
        );
        _schedule();
      case HostState.stopped || HostState.failed:
        final wasUp = state.connected;
        final error = snapshot.error;
        state = state.copyWith(
          // A command of ours under way decides the phase itself.
          phase: state.busy ? state.phase : RuntimePhase.stopped,
          snapshot: snapshot,
          failure: wasUp && error != null ? () => HostFailed(error) : null,
          speeds: const [],
          activeMixedPort: () => null,
          activeProxyTun: () => null,
          pendingTun: () => null,
          pendingSystemProxy: () => null,
        );
        if (wasUp) {
          if (!_commanding) {
            _wanted = false;
          }
          _sessionId = '';
          _planHash = '';
          _expected = null;
        }
        _schedule();
      case HostState.starting || HostState.reloading || HostState.stopping:
        state = state.copyWith(snapshot: snapshot);
    }
    return true;
  }

  void _stopped(RuntimeFailure? failure) {
    _sessionId = '';
    _planHash = '';
    _expected = null;
    state = state.copyWith(
      phase: RuntimePhase.stopped,
      failure: () => failure,
      speeds: const [],
      tags: const {},
      activeMixedPort: () => null,
      activeProxyTun: () => null,
      pendingTun: () => null,
      pendingSystemProxy: () => null,
    );
    _schedule();
  }

  /// Polls while a session runs and the app is in view; follows the
  /// plan's inputs while a session runs at all.
  void _schedule() {
    if (state.connected && _host != null) {
      _watch();
    } else {
      _unwatch();
    }
    final wanted = _visible && state.connected && _host != null;
    if (!wanted) {
      _poll?.cancel();
      _poll = null;
      return;
    }
    _poll ??= Timer.periodic(
      ref.read(runtimePollIntervalProvider),
      (_) => _background.run('runtime: refresh', refresh),
    );
  }

  /// The plan goes to the host as a file in its own directory: it can be
  /// megabytes, more than a call to another process carries, and it is
  /// what the host restarts from (RUNTIME_HOST §8). It holds the nodes'
  /// secrets, so it stays where only the app can read. Written beside the
  /// running plan first: a plan the host refuses must not replace it.
  Future<File> _writePlan(RuntimeHost host, CompiledPlan plan) async {
    final facts = await host.system.facts();
    final file = File('${facts.stateDir}/plan.next.json');
    await file.writeAsString(jsonEncode(plan.toJson()), flush: true);
    return file;
  }

  /// The host runs [next]: it is now the plan to restart from.
  Future<void> _keepPlan(File next, CompiledPlan plan) async {
    await next.rename('${next.parent.path}/plan.json');
    _keptChoices = plan.choices;
  }

  // ------------------------------------------------- keeping it in line

  void _watch() {
    if (_watching.isNotEmpty) return;
    _watching
      ..add(
        ref.listen(selectedConfigurationProvider, (previous, next) {
          // A member or the mode is switched at once; the rest waits for
          // the writes to settle.
          final choice =
              previous is SelectionReady &&
              next is SelectionReady &&
              (!mapEquals(previous.selections, next.selections) ||
                  previous.settings.mode != next.settings.mode);
          _scheduleSync(debounced: !choice);
        }),
      )
      ..add(
        ref.listen(policyProvider, (_, _) => _scheduleSync(debounced: true)),
      );
  }

  void _unwatch() {
    for (final subscription in _watching) {
      subscription.close();
    }
    _watching.clear();
    _debounce?.cancel();
    _debounce = null;
  }

  void _scheduleSync({required bool debounced}) {
    if (!debounced) {
      _debounce?.cancel();
      _debounce = null;
      _background.run('runtime: sync', sync);
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(
      ref.read(runtimeDebounceProvider),
      () => _background.run('runtime: sync', sync),
    );
  }

  /// Brings the running session in line with what is selected and set
  /// now (RUNTIME_HOST §5): reloads when the plan changed, switches the
  /// mode and members when only those did, and does nothing otherwise.
  Future<void> sync() => _enqueue(_sync);

  Future<void> _sync() async {
    final preferenceEpoch = _runtimePreferenceEpoch;
    try {
      await _syncPlan();
    } finally {
      if (preferenceEpoch == _runtimePreferenceEpoch) {
        state = state.copyWith(
          pendingTun: () => null,
          pendingSystemProxy: () => null,
        );
      }
    }
  }

  Future<void> _syncPlan() async {
    final host = _host;
    if (host == null || state.phase != RuntimePhase.running) return;
    if (host.preparesEveryReload) {
      try {
        final settings = await ref.read(settingsRepositoryProvider).device();
        if (!await host.system.prepare(
          tun: settings.tailnet.enabled || (_wanted && settings.tunEnabled),
        )) {
          state = state.copyWith(failure: () => const PermissionRefused());
          return;
        }
      } on HostException catch (error) {
        state = state.copyWith(failure: () => HostFailed(error.error));
        return;
      }
    }
    final CompiledPlan plan;
    try {
      plan = await _compile();
    } on PlanUnavailableException catch (e) {
      // The session goes on with the plan it has; the page says why the
      // change did not take.
      state = state.copyWith(failure: () => NothingToRun(e.reason));
      return;
    } on CompileException catch (e) {
      state = state.copyWith(failure: () => PlanFailed(e));
      return;
    } on HostException catch (e) {
      state = state.copyWith(failure: () => HostFailed(e.error));
      return;
    }
    // The session goes on with the plan it has (see connect).
    if (plan.planHash != _planHash && await _noListedAppInstalled(plan)) {
      state = state.copyWith(failure: () => const NoListedAppInstalled());
      return;
    }
    try {
      if (plan.planHash != _planHash) {
        final inbounds = plan.toJson()['inbounds'] as List? ?? const [];
        final needsTun = inbounds.any((i) => i is Map && i['type'] == 'tun');
        if (!host.preparesEveryReload &&
            needsTun &&
            state.snapshot.tunActive != true &&
            !await host.system.prepare(tun: true)) {
          state = state.copyWith(failure: () => const PermissionRefused());
          return;
        }
        state = state.copyWith(phase: RuntimePhase.reloading);
        final file = await _writePlan(host, plan);
        final session = await host.gateway.reload(
          sessionId: _sessionId,
          planPath: file.path,
          planHash: plan.planHash,
          utcOffset: DateTime.now().timeZoneOffset,
        );
        await _keepPlan(file, plan);
        _sessionId = session.sessionId;
        _planHash = plan.planHash;
        _primaryTag = plan.primaryTag;
        _expected = plan.choices;
        state = state.copyWith(
          phase: RuntimePhase.running,
          failure: () => null,
          speeds: const [],
          tags: plan.tags,
          activeMixedPort: () => _mixedPort(plan),
          activeProxyTun: () => _proxyTun(plan),
        );
        _background.run('runtime: pruning rule sets', _prune);
      } else {
        await _applyChoices(host, plan.choices);
        // A restart (at boot, or by the system) runs what was chosen since.
        if (!_sameChoices(_keptChoices, plan.choices)) {
          await _keepPlan(await _writePlan(host, plan), plan);
        }
        _primaryTag = plan.primaryTag;
        state = state.copyWith(
          failure: () => null,
          tags: plan.tags,
          activeMixedPort: () => _mixedPort(plan),
          activeProxyTun: () => _proxyTun(plan),
        );
      }
      await refresh();
    } on HostException catch (e) {
      // A plan the core would not load left the session running; any other
      // failure may have cost it. The host says which.
      state = state.copyWith(
        phase: RuntimePhase.running,
        failure: () => HostFailed(e.error),
      );
      await refresh();
    }
  }

  /// A mode or member the host runs that neither the plan nor our own
  /// commands chose came from outside, from a panel on the Clash API: it
  /// becomes the user's choice (D30), and is synced like any other
  /// (D12). The plan compiled from it then matches what runs, so nothing
  /// is sent back.
  Future<void> _writeBackExternal(HostSnapshot snapshot) async {
    final expected = _expected;
    final tags = state.tags;
    if (expected == null ||
        tags.isEmpty ||
        state.phase != RuntimePhase.running) {
      return;
    }
    final expectedMode = expected.mode;
    final mode = OutboundMode.values
        .where((m) => m.name == snapshot.mode.toLowerCase())
        .firstOrNull;
    final changedMode =
        expectedMode != null &&
        mode != null &&
        mode.name != expectedMode.toLowerCase();
    final changedMembers = <SourceMember, MemberRef>{};
    for (final MapEntry(key: group, value: member)
        in expected.selections.entries) {
      final actual = snapshot.selections[group];
      if (actual == null || actual == member) continue;
      final groupRef = tags[group]?.ref;
      final memberRef = tags[actual]?.ref;
      if (groupRef is SourceMember && memberRef != null) {
        changedMembers[groupRef] = memberRef;
      }
    }
    if (!changedMode && changedMembers.isEmpty) return;
    // What runs is now what is expected, whatever the writes below do.
    _expected = PlanChoices(
      mode: changedMode ? mode.name : expectedMode,
      selections: {
        ...expected.selections,
        for (final MapEntry(key: group, value: _) in changedMembers.entries)
          for (final tag in tags.keys)
            if (tags[tag]!.ref == group) tag: snapshot.selections[tag]!,
      },
    );
    Log.info(
      'runtime: kept a change made outside the app '
      '(${changedMode ? 'mode ' : ''}${changedMembers.length} member(s))',
    );
    if (changedMode) {
      await ref
          .read(settingsRepositoryProvider)
          .updateDevice((s) => s.copyWith(mode: mode));
    }
    final selections = ref.read(selectionRepositoryProvider);
    for (final MapEntry(key: group, value: member) in changedMembers.entries) {
      await selections.select(group.configurationId, group.key, member);
    }
  }

  static bool _proxyTun(CompiledPlan plan) =>
      (plan.tree['inbounds'] as List? ?? const []).any(
        (inbound) =>
            inbound is Map &&
            inbound['type'] == 'tun' &&
            // The compiler restricts a Tailnet-only TUN to its own CIDRs.
            inbound['route_address'] == null,
      );

  static int? _mixedPort(CompiledPlan plan) {
    for (final inbound in plan.toJson()['inbounds'] as List? ?? const []) {
      if (inbound is Map && inbound['type'] == 'mixed') {
        return (inbound['listen_port'] as num?)?.toInt();
      }
    }
    return null;
  }

  /// Switches the mode and the members that differ from the plan's.
  static bool _sameChoices(PlanChoices? a, PlanChoices b) =>
      a != null && a.mode == b.mode && mapEquals(a.selections, b.selections);

  Future<void> _applyChoices(RuntimeHost host, PlanChoices choices) async {
    _expected = choices;
    final snapshot = await host.gateway.snapshot();
    final mode = choices.mode;
    if (mode != null && mode.toLowerCase() != snapshot.mode.toLowerCase()) {
      await host.gateway.setMode(_sessionId, mode);
    }
    for (final MapEntry(key: group, value: member)
        in choices.selections.entries) {
      final current = snapshot.selections[group];
      if (current != null && current != member) {
        await host.gateway.select(_sessionId, group, member);
      }
    }
  }

  /// Measures how long the outbounds [tags] of [plan] take to answer the
  /// test address: in the session when one runs, otherwise through a
  /// probe that takes over nothing (CONFIG_PIPELINE §9).
  ///
  /// Throws [HostException]; with `unsupported` where there is no host.
  Future<Map<String, HostLatency>> urlTest(
    CompiledPlan plan,
    List<String> tags,
  ) async {
    final host = _host;
    if (host == null) {
      throw const HostException(
        HostError(HostErrorCode.unsupported, 'this platform has no host yet'),
      );
    }
    final settings = await ref.read(settingsRepositoryProvider).device();
    final timeout = Duration(milliseconds: settings.testTimeoutMs);
    if (state.connected && _sessionId.isNotEmpty) {
      return host.gateway.urlTest(
        sessionId: _sessionId,
        tags: tags,
        url: settings.testUrl,
        timeout: timeout,
      );
    }
    final facts = await host.system.facts();
    final probe = File('${facts.stateDir}/probe.json');
    await probe.writeAsString(jsonEncode(plan.toJson()), flush: true);
    try {
      return await host.gateway.urlTest(
        planPath: probe.path,
        tags: tags,
        url: settings.testUrl,
        timeout: timeout,
      );
    } finally {
      if (probe.existsSync()) await probe.delete();
      if (state.phase == RuntimePhase.stopped) await host.system.release();
    }
  }

  /// The host's log lines after [afterSeq]. Empty where there is no host.
  /// Reading wakes a host that is not running; [rest] lets it go again.
  Future<HostLogPage> readLogs({required int afterSeq, int limit = 500}) async {
    final host = _host;
    if (host == null) return const HostLogPage();
    return host.gateway.logs(afterSeq: afterSeq, limit: limit);
  }

  /// The running session's connections; empty when nothing runs.
  Future<List<HostConnection>> connections() async {
    final host = _host;
    if (host == null || !state.connected || _sessionId.isEmpty) return const [];
    return host.gateway.connections(_sessionId);
  }

  /// Closes one connection, or all of them without [id].
  Future<void> closeConnections({String? id}) async {
    final host = _host;
    if (host == null || !state.connected || _sessionId.isEmpty) return;
    if (id == null) {
      await host.gateway.closeAllConnections(_sessionId);
    } else {
      await host.gateway.closeConnection(_sessionId, id);
    }
  }

  /// Lets go of a host that runs nothing (after a page read from it).
  Future<void> rest() async {
    final host = _host;
    if (!ref.mounted) return;
    if (host != null && state.phase == RuntimePhase.stopped) {
      await host.system.release();
    }
  }

  /// Compiles the selected configuration. Clash rule providers must be
  /// converted before the core can read them: when one is missing it is
  /// downloaded now, directly, as the subscription naming it was (D86).
  Future<CompiledPlan> _compile() async {
    final plans = ref.read(planServiceProvider);
    try {
      return await plans.compileSelected(proxy: _wanted);
    } on CompileException catch (e) {
      if (e.code != CompileErrorCode.ruleSetMissing) rethrow;
      final services = ref.read(servicesProvider);
      final id = (await services.settings.device()).selectedConfigurationId;
      final content = id == null
          ? null
          : (await services.configurations.content(id))?.content;
      if (content == null) rethrow;
      final resources = ref.read(resourceServiceProvider);
      for (final rule in await resources.missing(
        RuleSetCatalog.usedBy(content),
      )) {
        if (!rule.format.isSingBox) {
          final cloudUrls = await cloudRuleSetUrls(services);
          await resources.update(
            rule,
            cloudSource: cloudUrls.contains(rule.url),
          );
        }
      }
      // Still missing: the error says which.
      return plans.compileSelected(proxy: _wanted);
    }
  }

  /// Per-app proxy on Android names the apps the tunnel takes
  /// (`include_package`). With none of them installed the system would take
  /// every app instead, the opposite of what the list asks; the host
  /// refuses too, this says why first (PRODUCT_SPEC §3.11).
  Future<bool> _noListedAppInstalled(CompiledPlan plan) async {
    final allowed = <Object?>{
      for (final inbound in (plan.toJson()['inbounds'] as List? ?? const []))
        if (inbound is Map && inbound['type'] == 'tun')
          ...(inbound['include_package'] as List? ?? const []),
    };
    if (allowed.isEmpty) return false;
    try {
      final installed = await ref.read(installedAppsProvider).list();
      // The device's apps cannot be listed: the host decides.
      if (installed.isEmpty) return false;
      return !installed.any((app) => allowed.contains(app.id));
    } on Object {
      return false;
    }
  }

  /// After a start or reload: the files the core read before are no longer
  /// needed (CONFIG_PIPELINE §8). The rule sets the core had to download
  /// itself are kept by the updater, which follows the session.
  Future<void> _prune() async {
    if (!ref.mounted) return;
    await ref.read(resourceServiceProvider).prune();
  }

  /// Completes once work started in the background is done (tests wait
  /// for it before closing the database).
  Future<void> idle() => _background.done();

  /// Downloads through the running session's main selector; null when
  /// nothing runs (RUNTIME_HOST §2 `fetch`).
  ProxyDownload? get proxyDownload {
    final host = _host;
    if (host == null || !state.proxyConnected || _sessionId.isEmpty) {
      return null;
    }
    final session = _sessionId;
    final outbound = _primaryTag;
    return (url, destPath, maxBytes, {publicOnly = false}) async {
      final answer = await host.gateway.fetch(
        sessionId: session,
        outboundTag: outbound,
        url: url.toString(),
        maxBytes: maxBytes,
        destPath: destPath,
        publicOnly: publicOnly,
      );
      if (answer.status != 200) {
        throw HostException(
          HostError(HostErrorCode.coreFailed, 'HTTP ${answer.status}'),
        );
      }
    };
  }

  /// Fetches a small answer from [url] through the running session's main
  /// selector, as the exit IP probe does (CONFIG_PIPELINE §9).
  ///
  /// Throws [HostException]; with `sessionMismatch` when nothing runs.
  Future<String> fetchText(Uri url, {required int maxBytes}) async {
    final host = _host;
    if (host == null || !state.proxyConnected || _sessionId.isEmpty) {
      throw const HostException(
        HostError(HostErrorCode.sessionMismatch, 'nothing runs'),
      );
    }
    final answer = await host.gateway.fetch(
      sessionId: _sessionId,
      outboundTag: _primaryTag,
      url: url.toString(),
      maxBytes: maxBytes,
      timeout: const Duration(seconds: 15),
    );
    if (answer.status != 200 || answer.body == null) {
      throw HostException(
        HostError(HostErrorCode.coreFailed, 'HTTP ${answer.status}'),
      );
    }
    return answer.body!;
  }

  /// The running session, for commands that name it.
  String get sessionId => _sessionId;

  /// The running plan's main selector.
  String get primaryTag => _primaryTag;
}
