import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:av_core/av_core.dart';
import 'package:crypto/crypto.dart';

import '../data/repositories/plan_snapshot_repository.dart';

/// Why there is nothing to compile.
enum PlanUnavailable {
  /// No configuration is selected.
  nothingSelected,

  /// The selected subscription has no content on this device yet.
  notDownloaded,
}

final class PlanUnavailableException implements Exception {
  const PlanUnavailableException(this.reason);

  final PlanUnavailable reason;

  @override
  String toString() => 'PlanUnavailableException(${reason.name})';
}

/// Compiles the selected configuration into a sing-box plan from one
/// consistent snapshot (CONFIG_PIPELINE §1, §6). The pages that show or
/// check a plan use it now; the runtime coordinator will start the proxy
/// from the same call (L2).
final class PlanService {
  PlanService(
    this._snapshots, {
    required this.host,
    required this.hashKey,
    Future<Map<String, String>> Function()? ruleSets,
  }) : _ruleSets = ruleSets ?? (() async => const {});

  final PlanSnapshotRepository _snapshots;

  /// Facts about the host the plan is for.
  final Future<HostInfo> Function() host;

  /// Per-installation key for the plan hash (CONFIG_PIPELINE §7).
  final Future<Uint8List> Function() hashKey;

  /// Downloaded rule-set files by `ruleSetKey` (ResourceService): the plan
  /// reads those instead of downloading at start.
  final Future<Map<String, String>> Function() _ruleSets;

  /// The plan of the selected configuration. With [override] the saved
  /// JSON override is replaced by that text, to check it before saving.
  ///
  /// Throws [PlanUnavailableException] when there is nothing to compile and
  /// `CompileException` when the plan cannot be built.
  Future<CompiledPlan> compileSelected({
    String? override,
    bool proxy = true,
  }) async {
    final snapshot = await _snapshots.read();
    final configuration = snapshot.configuration;
    if (proxy && configuration == null) {
      throw const PlanUnavailableException(PlanUnavailable.nothingSelected);
    }
    final content = snapshot.content;
    final CompileSource source;
    if (!proxy || configuration?.kind == ConfigurationKind.self) {
      source = const SelfSource();
    } else if (content == null) {
      throw const PlanUnavailableException(PlanUnavailable.notDownloaded);
    } else {
      source = ImportedSource(id: configuration!.id, content: content);
    }
    final input = CompileInput(
      source: source,
      settings: snapshot.settings,
      policy: override == null
          ? snapshot.policy
          : snapshot.policy.copyWith(
              jsonOverride: override.trim().isEmpty ? null : Secret(override),
            ),
      host: await host(),
      hashKey: await hashKey(),
      selfNodes: snapshot.selfNodes,
      chains: snapshot.chains,
      memberships: snapshot.memberships,
      selections: snapshot.selections,
      otherContents: snapshot.otherContents,
      ruleSetCache: await _ruleSets(),
      tailnet: snapshot.settings.tailnet.enabled,
      proxy: proxy,
    );
    final plan = await Isolate.run(() => compile(input));
    return _guardCloudNativeResources(snapshot, input.policy, plan);
  }

  /// The host validates and pins cloud endpoint addresses before every
  /// instance start. Automatic core probes, remote rule downloads and raw
  /// DNS overrides remain refused until their own callbacks are guarded.
  static CompiledPlan _guardCloudNativeResources(
    PlanSnapshot snapshot,
    Policy policy,
    CompiledPlan plan,
  ) {
    Never blocked(String reason) => throw CompileException(
      CompileErrorCode.invalidSetting,
      subject: 'cloud.networkGuard',
      detail: reason,
    );

    if (snapshot.configuration?.kind != ConfigurationKind.self &&
        snapshot.cloudPolicy &&
        (policy.jsonOverride?.value.trim().isNotEmpty ?? false)) {
      blocked('cloudOverrideNativeGuardRequired');
    }
    bool cloudMember(MemberRef member) => switch (member) {
      SourceMember(:final configurationId) =>
        snapshot.cloudConfigurationIds.contains(configurationId),
      SelfNodeRef(:final id) => snapshot.cloudNodeIds.contains(id),
      ChainRef(:final id) => snapshot.cloudChainIds.contains(id),
      _ => false,
    };
    final endpoints = <String>{};
    for (final MapEntry(key: tag, value: info) in plan.tags.entries) {
      if (cloudMember(info.ref)) endpoints.add(tag);
      if (info.ref case ChainRef(:final id)) {
        for (final chain in snapshot.chains) {
          if (chain.id == id &&
              (snapshot.cloudChainIds.contains(id) ||
                  chain.hops.any(cloudMember))) {
            // The last hop's PlanTag names the chain, not its underlying
            // node. Include all concrete hops, including locally authored
            // ones selected by a remote-authored chain.
            endpoints.addAll(
              plan.tags.keys.where((t) => t.startsWith('c:$id:')),
            );
          }
        }
      }
    }

    // A Cloud configuration may contain only DIRECT/REJECT, so no node tag
    // above identifies it. Its native remote rule downloads still need to
    // go through the guarded Dart downloader first.
    if (snapshot.cloudConfigurationIds.contains(snapshot.configuration?.id)) {
      final route = plan.tree['route'];
      if (route is Map) {
        final sets = route['rule_set'];
        if (sets is List &&
            sets.any((s) => s is Map && s['type'] == 'remote')) {
          blocked('cloudRuleSetNativeGuardRequired');
        }
      }
      final outbounds = plan.tree['outbounds'];
      if (outbounds is List &&
          outbounds.any((o) => o is Map && o['type'] == 'urltest')) {
        blocked('cloudUrlTestNativeGuardRequired');
      }
    }
    if (endpoints.isEmpty) return plan;
    final tags = endpoints.toList()..sort();
    final tree = <String, Object?>{
      ...plan.tree,
      '_avalon_public_network': {'version': 1, 'endpointTags': tags},
    };
    // A provenance change must reload an otherwise identical local plan;
    // its endpoint restrictions are part of its runtime identity.
    final hash = sha256.convert(
      utf8.encode(jsonEncode([plan.planHash, 'public-network-v1', tags])),
    );
    return CompiledPlan(
      tree: tree,
      planHash: hash.toString(),
      tags: plan.tags,
      primaryTag: plan.primaryTag,
    );
  }

  /// Checks an override before it is saved (CONFIG_PIPELINE §5): syntax,
  /// allowed keys and types always; the names it refers to against the
  /// selected configuration when there is one it applies to (D19).
  ///
  /// Throws `CompileException` with an override error code.
  Future<void> checkOverride(String text) async {
    parseOverride(text);
    try {
      await compileSelected(override: text);
    } on PlanUnavailableException {
      // Nothing to resolve names against.
    } on CompileException catch (e) {
      // Only what the override itself causes concerns the editor.
      const own = {
        CompileErrorCode.overrideInvalid,
        CompileErrorCode.overrideReference,
        CompileErrorCode.overrideConflict,
      };
      if (own.contains(e.code)) rethrow;
    }
  }
}
