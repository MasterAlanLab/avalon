import 'package:av_core/av_core.dart';

import '../../app/app_error.dart';
import '../../runtime/latency.dart';

enum ProxyMemberKind { node, group, chain, direct, reject, tailnet }

/// One row of a group (PRODUCT_SPEC §3.2).
final class ProxyMember {
  const ProxyMember({
    required this.ref,
    required this.name,
    required this.kind,
    this.protocol,
    this.groupType,
    this.hops = 0,
    this.unavailable,
    this.latency,
  });

  final MemberRef ref;
  final String name;
  final ProxyMemberKind kind;

  /// [ProxyMemberKind.node] only.
  final Protocol? protocol;

  /// [ProxyMemberKind.group] only: Selector, URLTest, Fallback…
  final String? groupType;

  /// [ProxyMemberKind.chain] only.
  final int hops;

  /// Why it cannot be used (`MemberCatalog.unavailable`); null when it can.
  final String? unavailable;

  /// The last latency test of it; null when never tested.
  final Latency? latency;

  /// A self node or a chain: it can be edited and deleted from 「自定义」.
  bool get isSelfContent => ref is SelfNodeRef || ref is ChainRef;
}

/// What became of a delete from 「自定义」 (PRODUCT_SPEC §3.4).
sealed class DeleteResult {
  const DeleteResult();
}

final class Deleted extends DeleteResult {
  const Deleted();
}

/// A node that chains still pass through is kept.
final class NodeInUse extends DeleteResult {
  const NodeInUse(this.chainIds);

  final List<String> chainIds;
}

final class DeleteFailed extends DeleteResult {
  const DeleteFailed(this.error);

  final AppError error;
}

final class ProxyGroup {
  const ProxyGroup({
    required this.key,
    required this.name,
    required this.displayType,
    required this.selectable,
    required this.members,
    this.current,
  });

  final String key;

  /// Null for 「自定义」, which the page names in its own language.
  final String? name;

  /// Selector, URLTest, Fallback or LoadBalance, as imported.
  final String displayType;

  /// False for groups that choose by latency (D28).
  final bool selectable;
  final List<ProxyMember> members;

  /// Index of the member in use. While connected it is what the host
  /// reports (for groups that pick by latency, their pick); otherwise the
  /// saved choice while it is still a member, else the first usable one,
  /// and null for automatic groups.
  final int? current;

  /// A latency test of this group's members is under way.
  bool get testing =>
      members.any((m) => m.latency?.status == LatencyStatus.testing);

  bool get isCustom => key == ContentKeys.custom;
}

final class ProxiesState {
  const ProxiesState({
    this.loading = false,
    this.hasConfiguration = true,
    this.downloaded = true,
    this.groups = const [],
    this.groupKey,
    this.directMode = false,
    this.error,
  });

  /// True until the first read from the database arrives.
  final bool loading;

  /// False when no configuration is selected.
  final bool hasConfiguration;

  /// False for a subscription whose content is not on this device yet.
  final bool downloaded;
  final List<ProxyGroup> groups;

  /// The group on show.
  final String? groupKey;
  final bool directMode;

  /// The content could not be read (e.g. the secure storage was reset).
  final AppError? error;

  /// A chain's name as 「自定义」 shows it.
  String chainName(String id) {
    for (final g in groups) {
      if (!g.isCustom) continue;
      for (final m in g.members) {
        if (m.ref == MemberRef.chain(id: id)) return m.name;
      }
    }
    return id;
  }

  ProxyGroup? get group {
    for (final g in groups) {
      if (g.key == groupKey) return g;
    }
    return groups.isEmpty ? null : groups.first;
  }
}
