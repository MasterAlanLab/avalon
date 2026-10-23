import '../domain/content.dart';
import '../domain/node.dart';
import '../domain/refs.dart';
import '../domain/user_content.dart';
import 'compiler/compile_input.dart';
import 'compiler/outbound.dart';

/// Who is in which group of one configuration, what each member is called
/// and whether it can be used (PRODUCT_SPEC §3.2). The compiler and the
/// proxies page both read it, so what the page lists is what runs.
final class MemberCatalog {
  MemberCatalog({
    required this.configurationId,
    required this.content,
    this.otherContents = const {},
    this.selfNodes = const [],
    this.chains = const [],
    this.memberships = const [],
    this.tailnetExit,
  });

  /// Name of the 「自定义」 group in plans and logs; pages show their own
  /// translation.
  static const customName = '自定义';

  final String configurationId;
  final ConfigContent content;

  /// Contents of other configurations, for chain hops that point into them.
  final Map<String, ConfigContent> otherContents;
  final List<SelfNode> selfNodes;
  final List<Chain> chains;
  final List<Membership> memberships;

  /// The chosen exit node while Tailscale is on.
  final TailnetExitRef? tailnetExit;

  // Inputs stay unchanged for this catalog's lifetime. Keep indexes and
  // validation results with that snapshot rather than across configurations.
  late final _nodesByKey = _firstBy(content.nodes, (n) => n.key);
  late final _groupsByKey = _firstBy(content.groups, (g) => g.key);
  late final _selfNodesById = _firstBy(selfNodes, (n) => n.id);
  late final _chainsById = _firstBy(chains, (c) => c.id);
  final _otherNodesByConfiguration = <String, Map<String, NodeDef>>{};
  final _otherGroupsByConfiguration = <String, Map<String, GroupDef>>{};
  final _unavailableRoots = <MemberRef, String?>{};

  static Map<String, T> _firstBy<T>(
    Iterable<T> values,
    String Function(T) key,
  ) {
    final index = <String, T>{};
    for (final value in values) {
      index.putIfAbsent(key(value), () => value);
    }
    return index;
  }

  SelfNode? selfNode(String id) => _selfNodesById[id];

  Chain? chain(String id) => _chainsById[id];

  NodeDef? _sourceNode(String id, String key) {
    if (id == configurationId) return _nodesByKey[key];
    final other = otherContents[id];
    if (other == null) return null;
    return _otherNodesByConfiguration.putIfAbsent(
      id,
      () => _firstBy(other.nodes, (n) => n.key),
    )[key];
  }

  GroupDef? _sourceGroup(String id, String key) {
    if (id == configurationId) return _groupsByKey[key];
    final other = otherContents[id];
    if (other == null) return null;
    return _otherGroupsByConfiguration.putIfAbsent(
      id,
      () => _firstBy(other.groups, (g) => g.key),
    )[key];
  }

  /// Name of a content key: a node, a group or a built-in.
  String displayName(String key) {
    if (key == ContentKeys.direct) return 'DIRECT';
    if (key == ContentKeys.reject) return 'REJECT';
    if (key == ContentKeys.custom) return customName;
    return _nodesByKey[key]?.name ?? _groupsByKey[key]?.name ?? key;
  }

  /// A chain's own name, or its hops joined with arrows.
  String? chainName(Chain? c) {
    if (c == null) return null;
    return c.name ?? c.hops.map(name).join(' → ');
  }

  String name(MemberRef ref) => switch (ref) {
    SourceMember(configurationId: final id, :final key) =>
      id == configurationId
          ? displayName(key)
          : _sourceNode(id, key)?.name ?? key,
    SelfNodeRef(:final id) => selfNode(id)?.name ?? id,
    ChainRef(:final id) => chainName(chain(id)) ?? id,
    TailnetExitRef(:final name) => 'Tailscale · $name',
    BuiltinRef(:final builtin) =>
      builtin == Builtin.direct ? 'DIRECT' : 'REJECT',
  };

  /// Group keys in page order: imported order with 「自定义」 second
  /// (PRODUCT_SPEC §3.2).
  List<String> get groupKeys {
    final keys = [
      for (final g in content.groups)
        if (g.key != ContentKeys.custom) g.key,
    ];
    keys.insert(keys.isEmpty ? 0 : 1, ContentKeys.custom);
    return keys;
  }

  /// Members of a group in order: its own, then the self nodes and chains
  /// that joined it. 「自定义」 holds every self node and chain and the
  /// tailnet exit.
  List<MemberRef> membersOf(String groupKey) {
    if (groupKey == ContentKeys.custom) {
      return [
        for (final n in selfNodes) MemberRef.selfNode(id: n.id),
        for (final c in chains) MemberRef.chain(id: c.id),
        ?tailnetExit,
      ];
    }
    final group = _groupsByKey[groupKey];
    if (group == null) return const [];
    return [
      for (final m in group.members)
        if (m == ContentKeys.direct)
          const MemberRef.builtin(builtin: Builtin.direct)
        else if (m == ContentKeys.reject)
          const MemberRef.builtin(builtin: Builtin.reject)
        else
          MemberRef.source(configurationId: configurationId, key: m),
      for (final ms in memberships)
        if (ms.configurationId == configurationId && ms.groupKey == groupKey)
          ms.ownerKind == MemberOwner.node
              ? MemberRef.selfNode(id: ms.ownerId)
              : MemberRef.chain(id: ms.ownerId),
    ];
  }

  /// The group (or node) the plan's main exit is (CONFIG_PIPELINE §4):
  /// 「自定义」 for 「自建节点」, else the main selector, else the final
  /// target. The compiler's primary tag is built from the same key.
  String get primaryKey => configurationId == SelfSource.id
      ? ContentKeys.custom
      : content.primaryGroup?.key ?? content.finalTarget;

  bool _isSelector(String groupKey) =>
      groupKey == ContentKeys.custom ||
      _groupsByKey[groupKey]?.type == GroupType.selector;

  /// The member a selector group uses: the saved choice while it is still a
  /// member (even when it cannot be used: the plan then fails rather than
  /// switch silently), else the first member that can be used. Null for a
  /// group that picks by latency (the core decides) and for one with
  /// nothing usable.
  MemberRef? currentOf(String groupKey, Map<String, MemberRef> selections) {
    if (!_isSelector(groupKey)) return null;
    final members = membersOf(groupKey);
    final saved = selections[groupKey];
    if (saved != null && members.contains(saved)) return saved;
    for (final m in members) {
      if (unavailable(m) == null) return m;
    }
    return null;
  }

  /// What traffic of the main exit actually leaves through: [primaryKey]
  /// followed through the choices of nested selector groups. Stops at a
  /// group that picks by latency (returned as that group) and returns null
  /// when a selector has nothing to use.
  MemberRef? exit(Map<String, MemberRef> selections) {
    MemberRef ref = switch (primaryKey) {
      ContentKeys.direct => const MemberRef.builtin(builtin: Builtin.direct),
      ContentKeys.reject => const MemberRef.builtin(builtin: Builtin.reject),
      final key => MemberRef.source(configurationId: configurationId, key: key),
    };
    final seen = <String>{};
    while (true) {
      final key = switch (ref) {
        SourceMember(configurationId: final id, :final key)
            when id == configurationId &&
                (key == ContentKeys.custom || _groupsByKey[key] != null) =>
          key,
        _ => null,
      };
      if (key == null || !_isSelector(key) || !seen.add(key)) return ref;
      final next = currentOf(key, selections);
      if (next == null) return null;
      ref = next;
    }
  }

  /// The node behind a member, when it is one.
  NodeParams? paramsOf(MemberRef ref) => switch (ref) {
    SourceMember(configurationId: final id, :final key) => _sourceNode(
      id,
      key,
    )?.params,
    SelfNodeRef(:final id) => selfNode(id)?.params,
    ChainRef() || TailnetExitRef() || BuiltinRef() => null,
  };

  /// Why a group member cannot be used, or null when it can. Mirrors the
  /// compiler's reasons: `missing`, `detour`, `hops`, `hop-missing`,
  /// `hop-group`, `hop-kind`, `tailnet-hop`, `tailnet-exit`,
  /// `other-configuration`, or what the node itself cannot express.
  String? unavailable(MemberRef ref) {
    if (_unavailableRoots.containsKey(ref)) return _unavailableRoots[ref];
    // A recursive visit carries its own detour context. Cache only the
    // complete root result, including null for a usable member.
    return _unavailableRoots[ref] = _unavailable(ref, <String>{});
  }

  String? _unavailable(MemberRef ref, Set<String> visiting) {
    switch (ref) {
      case SourceMember(configurationId: final id, :final key):
        if (id != configurationId) return 'other-configuration';
        if (key == ContentKeys.direct || key == ContentKeys.reject) return null;
        final node = _nodesByKey[key];
        if (node != null) {
          if (!visiting.add(key)) return 'detour';
          final detour = node.detourKey;
          if (detour != null &&
              _unavailable(
                    MemberRef.source(configurationId: id, key: detour),
                    visiting,
                  ) !=
                  null) {
            return 'detour';
          }
          return _unsupported(node.server, node.port, node.params);
        }
        if (key == ContentKeys.custom || _groupsByKey[key] != null) {
          return null;
        }
        return 'missing';
      case SelfNodeRef(:final id):
        final node = selfNode(id);
        if (node == null) return 'missing';
        return _unsupported(node.server, node.port, node.params);
      case ChainRef(:final id):
        final c = chain(id);
        if (c == null) return 'missing';
        if (c.hops.length < 2) return 'hops';
        for (final hop in c.hops) {
          final reason = _hopUnavailable(hop);
          if (reason != null) return reason;
        }
        return null;
      case TailnetExitRef():
        return ref == tailnetExit ? null : 'tailnet-exit';
      case BuiltinRef():
        return null;
    }
  }

  String? _hopUnavailable(MemberRef hop) {
    switch (hop) {
      case SourceMember(configurationId: final id, :final key):
        final node = _sourceNode(id, key);
        if (node == null) {
          return _sourceGroup(id, key) != null ? 'hop-group' : 'hop-missing';
        }
        return _unsupported(node.server, node.port, node.params);
      case SelfNodeRef(:final id):
        final node = selfNode(id);
        if (node == null) return 'hop-missing';
        return _unsupported(node.server, node.port, node.params);
      case TailnetExitRef():
        // Whether an exit node can be a hop is decided by S3.
        return 'tailnet-hop';
      case ChainRef() || BuiltinRef():
        return 'hop-kind';
    }
  }

  static String? _unsupported(String server, int port, NodeParams params) {
    try {
      nodeOutbound(tag: '', server: server, port: port, params: params);
      return null;
    } on UnsupportedNode catch (e) {
      return e.reason;
    }
  }
}
