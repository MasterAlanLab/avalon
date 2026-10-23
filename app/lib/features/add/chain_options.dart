import 'package:av_core/av_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../runtime/latency.dart';

/// A node that can be a hop.
final class HopOption {
  const HopOption({
    required this.ref,
    required this.name,
    this.protocol,
    this.latency,
  });

  final MemberRef ref;
  final String name;

  /// Null for a Tailscale exit.
  final Protocol? protocol;

  /// The selected configuration's most recent individual-hop test.
  final Latency? latency;
}

/// What the chain form can choose from (PRODUCT_SPEC §3.7): the selected
/// configuration's nodes, the self nodes and the Tailscale exit as hops;
/// the selected configuration's selector groups to join.
final class ChainOptions {
  const ChainOptions({
    this.hops = const [],
    this.others = const [],
    this.groups = const [],
    this.mainGroupKey,
  });

  /// What «添加一跳» offers.
  final List<HopOption> hops;

  /// Hops of existing chains that are not on offer here (nodes of another
  /// configuration), so an edited chain can still name them.
  final List<HopOption> others;

  /// Selector groups of the selected imported configuration, without
  /// 「自定义」 (a chain is always there). Empty hides the section.
  final List<({String key, String name})> groups;
  final String? mainGroupKey;

  /// Ticked until the user changes the list: the main selector.
  Set<String> get defaultGroups => {?mainGroupKey};

  HopOption? hop(MemberRef ref) {
    for (final h in hops) {
      if (h.ref == ref) return h;
    }
    for (final h in others) {
      if (h.ref == ref) return h;
    }
    return null;
  }

  /// An estimate from individual tests, never a measurement of the chain.
  /// A timeout is still reported when another hop is unknown; otherwise
  /// every hop must have answered before an estimate can be shown.
  Latency? estimate(List<MemberRef> members) {
    if (members.isEmpty) return null;
    final results = [for (final member in members) hop(member)?.latency];
    final stale = results.any((result) => result?.stale ?? false);
    if (results.any((result) => result?.status == LatencyStatus.timedOut)) {
      return Latency(LatencyStatus.timedOut, stale: stale);
    }
    if (results.any((result) => result?.status == LatencyStatus.failed)) {
      return Latency(LatencyStatus.failed, stale: stale);
    }
    if (results.any(
      (result) =>
          result?.status != LatencyStatus.measured ||
          result?.ms == null ||
          result!.ms! <= 0,
    )) {
      return null;
    }
    return Latency(
      LatencyStatus.measured,
      ms: results.fold<int>(0, (sum, result) => sum + result!.ms!),
      stale: stale,
    );
  }
}

final chainOptionsProvider = Provider.autoDispose<ChainOptions>((ref) {
  final settings = ref.watch(deviceSettingsProvider).value;
  final nodes = ref.watch(selfNodesProvider).value ?? const [];
  final selected = settings?.selectedConfigurationId;
  final latencies = ref.watch(latencyProvider);
  Latency? latencyOf(MemberRef member) =>
      selected == null ? null : latencies[(selected, member)];
  final content = selected == null || selected == SelfSource.id
      ? null
      : ref.watch(contentProvider(selected)).value?.content;
  final exit = settings != null && settings.tailnet.enabled
      ? settings.tailnet.exit
      : null;
  final hops = [
    if (content != null)
      for (final n in content.nodes)
        HopOption(
          ref: MemberRef.source(configurationId: selected!, key: n.key),
          name: n.name,
          protocol: n.params.protocol,
          latency: latencyOf(
            MemberRef.source(configurationId: selected, key: n.key),
          ),
        ),
    for (final n in nodes)
      HopOption(
        ref: MemberRef.selfNode(id: n.id),
        name: n.name,
        protocol: n.params.protocol,
        latency: latencyOf(MemberRef.selfNode(id: n.id)),
      ),
    if (exit != null)
      HopOption(
        ref: exit,
        name: 'Tailscale · ${exit.name}',
        latency: latencyOf(exit),
      ),
  ];
  // Nodes of other configurations that existing chains pass through.
  final offered = {for (final h in hops) h.ref};
  final others = <HopOption>[];
  for (final chain in ref.watch(chainsProvider).value ?? const <Chain>[]) {
    for (final hop in chain.hops) {
      if (hop case SourceMember(
        :final configurationId,
        :final key,
      ) when offered.add(hop)) {
        final node = ref
            .watch(contentProvider(configurationId))
            .value
            ?.content
            .node(key);
        if (node != null) {
          others.add(
            HopOption(
              ref: hop,
              name: node.name,
              protocol: node.params.protocol,
              latency: latencyOf(hop),
            ),
          );
        }
      }
    }
  }
  return ChainOptions(
    hops: hops,
    others: others,
    groups: [
      if (content != null)
        for (final g in content.groups)
          if (g.type == GroupType.selector && g.key != ContentKeys.custom)
            (key: g.key, name: g.name),
    ],
    mainGroupKey: content?.primaryGroup?.key,
  );
});
