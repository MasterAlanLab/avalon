import 'package:freezed_annotation/freezed_annotation.dart';

import 'node.dart';
import 'refs.dart';

part 'user_content.freezed.dart';
part 'user_content.g.dart';

/// A node the user added (PRODUCT_SPEC §3.6). Lives in the built-in
/// 「自建节点」 configuration's 「自定义」 group and in any group it joins.
@freezed
abstract class SelfNode with _$SelfNode {
  const factory SelfNode({
    required String id,
    required String name,
    required String server,
    required int port,
    required NodeParams params,
  }) = _SelfNode;

  factory SelfNode.fromJson(Map<String, dynamic> json) =>
      _$SelfNodeFromJson(json);
}

/// A proxy chain of at least two hops (PRODUCT_SPEC §3.7).
@freezed
abstract class Chain with _$Chain {
  const Chain._();

  const factory Chain({
    required String id,

    /// Null shows the hop names joined (PRODUCT_SPEC §3.7).
    String? name,
    required List<MemberRef> hops,
  }) = _Chain;

  factory Chain.fromJson(Map<String, dynamic> json) => _$ChainFromJson(json);
}

enum MemberOwner { node, chain }

/// A self node or chain added to a group of an imported configuration.
@freezed
abstract class Membership with _$Membership {
  const factory Membership({
    required MemberOwner ownerKind,
    required String ownerId,
    required String configurationId,
    required String groupKey,
  }) = _Membership;

  factory Membership.fromJson(Map<String, dynamic> json) =>
      _$MembershipFromJson(json);
}
