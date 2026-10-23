// MemberCatalog: what the proxies page lists must be what the compiler
// builds (PRODUCT_SPEC §3.2).
import 'dart:typed_data';

import 'package:av_core/av_core.dart';
import 'package:test/test.dart';

const _id = 'cfg-0001';

const _self = SelfNode(
  id: 'n1',
  name: '自建 VPS',
  server: 'vps.example.com',
  port: 443,
  params: NodeParams.trojan(
    password: Secret('fake-self'),
    tls: Tls(serverName: 'vps.example.com'),
  ),
);
const _good = Chain(
  id: 'c1',
  hops: [
    MemberRef.source(configurationId: _id, key: 'link:0'),
    MemberRef.selfNode(id: 'n1'),
  ],
);
const _broken = Chain(
  id: 'c2',
  name: '坏链',
  hops: [
    MemberRef.source(configurationId: _id, key: 'gone'),
    MemberRef.selfNode(id: 'n1'),
  ],
);

NodeDef _node(
  String key, {
  String? name,
  NodeParams? params,
  String? detourKey,
}) => NodeDef(
  key: key,
  name: name ?? key,
  server: 'node.example.com',
  port: 443,
  params: params ?? _self.params,
  detourKey: detourKey,
);

void main() {
  final content = parseContent(
    'trojan://fake@a.example.com:443#A\n'
    'trojan://fake@b.example.com:443#B\n',
  ).content;
  final nodeKeys = [for (final n in content.nodes) n.key];
  final select = content.groups.firstWhere(
    (g) => g.name == LinkListGroups.select,
  );

  MemberCatalog catalog({
    List<Chain> chains = const [_good, _broken],
    List<Membership> memberships = const [],
  }) => MemberCatalog(
    configurationId: _id,
    content: content,
    selfNodes: const [_self],
    chains: [
      // The fixture's real first node key stands in for `link:0`.
      for (final c in chains)
        c.copyWith(
          hops: [
            for (final h in c.hops)
              h == const MemberRef.source(configurationId: _id, key: 'link:0')
                  ? MemberRef.source(configurationId: _id, key: nodeKeys[0])
                  : h,
          ],
        ),
    ],
    memberships: memberships,
  );

  test('members: own first, then joined self nodes and chains', () {
    final c = catalog(
      memberships: [
        Membership(
          ownerKind: MemberOwner.node,
          ownerId: 'n1',
          configurationId: _id,
          groupKey: select.key,
        ),
        Membership(
          ownerKind: MemberOwner.chain,
          ownerId: 'c1',
          configurationId: _id,
          groupKey: select.key,
        ),
        const Membership(
          ownerKind: MemberOwner.node,
          ownerId: 'n1',
          configurationId: 'another',
          groupKey: 'x',
        ),
      ],
    );
    final members = c.membersOf(select.key);
    expect(members.length, select.members.length + 2);
    expect(members[members.length - 2], const MemberRef.selfNode(id: 'n1'));
    expect(members.last, const MemberRef.chain(id: 'c1'));
    expect(c.membersOf(ContentKeys.custom), const [
      MemberRef.selfNode(id: 'n1'),
      MemberRef.chain(id: 'c1'),
      MemberRef.chain(id: 'c2'),
    ]);
  });

  test('current member and the actual exit', () {
    final c = catalog();
    final auto = content.groups.firstWhere(
      (g) => g.name == LinkListGroups.auto,
    );
    // 节点选择 lists 自动选择 first: with no choice that group is the exit,
    // and it picks by latency, so its own pick is unknown.
    expect(c.primaryKey, select.key);
    expect(
      c.currentOf(select.key, const {}),
      MemberRef.source(configurationId: _id, key: auto.key),
    );
    expect(c.currentOf(auto.key, const {}), isNull);
    expect(
      c.exit(const {}),
      MemberRef.source(configurationId: _id, key: auto.key),
    );

    // A saved node is followed.
    final b = MemberRef.source(configurationId: _id, key: nodeKeys[1]);
    expect(c.exit({select.key: b}), b);
    // A choice that left the group falls back to the first usable member.
    expect(
      c.currentOf(select.key, {
        select.key: const MemberRef.source(configurationId: _id, key: 'gone'),
      }),
      MemberRef.source(configurationId: _id, key: auto.key),
    );

    // 「自建节点」 exits through 「自定义」.
    final self = MemberCatalog(
      configurationId: SelfSource.id,
      content: const ConfigContent(finalTarget: ContentKeys.custom),
      selfNodes: const [_self],
    );
    expect(self.primaryKey, ContentKeys.custom);
    expect(self.exit(const {}), const MemberRef.selfNode(id: 'n1'));
    final empty = MemberCatalog(
      configurationId: SelfSource.id,
      content: const ConfigContent(finalTarget: ContentKeys.custom),
    );
    expect(empty.exit(const {}), isNull);
  });

  test('availability matches what the compiler can build', () {
    final c = catalog();
    expect(c.unavailable(const MemberRef.chain(id: 'c1')), isNull);
    expect(c.unavailable(const MemberRef.chain(id: 'c2')), 'hop-missing');
    expect(c.unavailable(const MemberRef.chain(id: 'nope')), 'missing');
    expect(c.unavailable(const MemberRef.selfNode(id: 'nope')), 'missing');
    expect(
      c.unavailable(const MemberRef.source(configurationId: _id, key: 'gone')),
      'missing',
    );
    expect(
      c.unavailable(
        const MemberRef.tailnetExit(tailnet: 't', nodeStableId: 'x', name: 'x'),
      ),
      'tailnet-exit',
    );

    final plan = compile(
      CompileInput(
        source: ImportedSource(id: _id, content: content),
        settings: const DeviceSettings(clashApiSecret: Secret('fake-api')),
        host: const HostInfo(
          platform: HostPlatform.macos,
          stateDir: '/state',
          deviceName: 'mac',
        ),
        hashKey: Uint8List.fromList(List.filled(32, 7)),
        selfNodes: c.selfNodes,
        chains: c.chains,
      ),
    );
    final built = {for (final t in plan.tags.values) t.ref};
    for (final key in c.groupKeys) {
      for (final ref in c.membersOf(key)) {
        if (ref is BuiltinRef) continue;
        expect(
          built.contains(ref),
          c.unavailable(ref) == null,
          reason: '${c.name(ref)} in ${c.displayName(key)}',
        );
      }
    }
  });

  test('duplicate keys keep the first node, group, self node and chain', () {
    const unsupported = NodeParams.socks5(tls: Tls());
    const group = GroupDef(
      key: 'group',
      name: 'First group',
      type: GroupType.selector,
      displayType: 'Selector',
      members: ['same'],
    );
    final firstChain = _good.copyWith(
      name: 'First chain',
      hops: [
        const MemberRef.source(configurationId: _id, key: 'same'),
        const MemberRef.selfNode(id: 'n1'),
      ],
    );
    final c = MemberCatalog(
      configurationId: _id,
      content: ConfigContent(
        finalTarget: group.key,
        nodes: [
          _node('same', name: 'First node'),
          _node('same', name: 'Last node', params: unsupported),
        ],
        groups: [
          group,
          group.copyWith(type: GroupType.urltest, members: ['missing']),
        ],
      ),
      selfNodes: [
        _self,
        _self.copyWith(params: unsupported),
      ],
      chains: [
        firstChain,
        _broken.copyWith(id: firstChain.id),
      ],
    );
    const ref = MemberRef.source(configurationId: _id, key: 'same');
    expect(c.name(ref), 'First node');
    expect(c.paramsOf(ref), _self.params);
    expect(c.unavailable(ref), isNull);
    expect(c.displayName(group.key), group.name);
    expect(c.membersOf(group.key), [ref]);
    expect(c.currentOf(group.key, const {}), ref);
    expect(c.selfNode(_self.id), _self);
    expect(c.unavailable(const MemberRef.selfNode(id: 'n1')), isNull);
    expect(c.chain(firstChain.id), firstChain);
    expect(c.unavailable(const MemberRef.chain(id: 'c1')), isNull);
  });

  test('same content keys remain scoped to their configuration', () {
    const other = 'other';
    const local = MemberRef.source(configurationId: _id, key: 'same');
    const remote = MemberRef.source(configurationId: other, key: 'same');
    final remoteContent = ConfigContent(
      finalTarget: ContentKeys.direct,
      nodes: [
        _node('same', name: 'Remote node'),
        _node('same', params: const NodeParams.socks5(tls: Tls())),
      ],
      groups: const [
        GroupDef(
          key: 'group',
          name: 'Remote group',
          type: GroupType.selector,
          displayType: 'Selector',
        ),
      ],
    );
    final c = MemberCatalog(
      configurationId: _id,
      content: ConfigContent(
        finalTarget: ContentKeys.direct,
        nodes: [
          _node(
            'same',
            name: 'Local node',
            params: const NodeParams.socks5(tls: Tls()),
          ),
        ],
      ),
      // An entry for the current id must not shadow the current content.
      otherContents: {_id: remoteContent, other: remoteContent},
      selfNodes: const [_self],
      chains: [
        _good.copyWith(
          hops: [
            remote,
            const MemberRef.selfNode(id: 'n1'),
          ],
        ),
        _broken.copyWith(
          hops: [
            const MemberRef.source(configurationId: other, key: 'group'),
            const MemberRef.selfNode(id: 'n1'),
          ],
        ),
      ],
    );
    expect(c.name(local), 'Local node');
    expect(c.paramsOf(local), isA<Socks5Params>());
    expect(c.unavailable(local), 'socks-tls');
    expect(c.name(remote), 'Remote node');
    expect(c.paramsOf(remote), _self.params);
    expect(c.unavailable(remote), 'other-configuration');
    expect(c.unavailable(const MemberRef.chain(id: 'c1')), isNull);
    expect(c.unavailable(const MemberRef.chain(id: 'c2')), 'hop-group');
  });

  test('root availability does not replace detour or chain-hop validation', () {
    const routed = MemberRef.source(configurationId: _id, key: 'routed');
    const unsupported = MemberRef.source(configurationId: _id, key: 'bad');
    const wrapper = MemberRef.source(configurationId: _id, key: 'wrapper');
    const cycle = MemberRef.source(configurationId: _id, key: 'cycle');
    const chain = MemberRef.chain(id: 'c1');
    final content = ConfigContent(
      finalTarget: ContentKeys.direct,
      nodes: [
        _node('routed', detourKey: 'gone'),
        _node('bad', params: const NodeParams.socks5(tls: Tls())),
        _node('wrapper', detourKey: 'bad'),
        _node('cycle', detourKey: 'cycle'),
      ],
    );
    for (final chainFirst in [false, true]) {
      final c = MemberCatalog(
        configurationId: _id,
        content: content,
        selfNodes: const [_self],
        chains: [
          // Explicit chain hops replace an imported node's detour.
          _good.copyWith(hops: [routed, cycle]),
        ],
      );
      if (chainFirst) expect(c.unavailable(chain), isNull);
      expect(c.unavailable(routed), 'detour');
      expect(c.unavailable(wrapper), 'detour');
      expect(c.unavailable(unsupported), 'socks-tls');
      expect(c.unavailable(cycle), 'detour');
      expect(c.unavailable(chain), isNull);
      expect(c.unavailable(routed), 'detour');
    }
    final replaced = MemberCatalog(
      configurationId: _id,
      content: ConfigContent(
        finalTarget: ContentKeys.direct,
        nodes: [_node('routed')],
      ),
    );
    expect(replaced.unavailable(routed), isNull);
  });
}
