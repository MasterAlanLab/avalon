import 'package:freezed_annotation/freezed_annotation.dart';

part 'refs.freezed.dart';
part 'refs.g.dart';

enum Builtin { direct, reject }

/// What a selector choice, rule target or chain hop points at
/// (DATA_MODEL §1.3). Identity is by key or id, never by name; a reference
/// whose target disappears stays and is shown as unavailable.
@Freezed(unionKey: 'kind')
sealed class MemberRef with _$MemberRef {
  const MemberRef._();

  /// A node or group of an imported configuration.
  const factory MemberRef.source({
    required String configurationId,
    required String key,
  }) = SourceMember;

  const factory MemberRef.selfNode({required String id}) = SelfNodeRef;

  const factory MemberRef.chain({required String id}) = ChainRef;

  const factory MemberRef.tailnetExit({
    required String tailnet,
    required String nodeStableId,
    required String name,
  }) = TailnetExitRef;

  const factory MemberRef.builtin({required Builtin builtin}) = BuiltinRef;

  factory MemberRef.fromJson(Map<String, dynamic> json) =>
      _$MemberRefFromJson(json);

  /// Kinds allowed as a chain hop. A [SourceMember] hop must also resolve to
  /// a node, not a group; that needs the content and is checked there.
  bool get canBeHop => switch (this) {
    SourceMember() || SelfNodeRef() || TailnetExitRef() => true,
    ChainRef() || BuiltinRef() => false,
  };
}
