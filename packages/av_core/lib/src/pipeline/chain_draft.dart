import '../domain/refs.dart';
import '../domain/user_content.dart';

/// Where a hop sits in a chain (PRODUCT_SPEC §3.7).
enum HopRole { entry, relay, exit }

enum ChainDraftError {
  /// Fewer than two hops.
  tooShort,

  /// The same hop twice.
  duplicate,

  /// A chain or a built-in cannot be a hop.
  kind,
}

final class ChainDraftException implements Exception {
  const ChainDraftException(this.error, {this.index});

  final ChainDraftError error;

  /// The offending hop, when there is one.
  final int? index;

  @override
  String toString() => 'ChainDraftException(${error.name}, $index)';
}

/// What the chain form holds: a name, the hops in order and the groups to
/// join.
final class ChainDraft {
  const ChainDraft({this.name = '', this.hops = const [], this.groups});

  final String name;
  final List<MemberRef> hops;

  /// Group keys to join; null until the user touches the list, which then
  /// starts from the default (the main selector).
  final Set<String>? groups;

  /// A chain needs at least two hops.
  bool get canSave => hops.length >= 2;

  HopRole role(int index) => hops.length == 1 || index == hops.length - 1
      ? HopRole.exit
      : (index == 0 ? HopRole.entry : HopRole.relay);

  ChainDraft withName(String name) =>
      ChainDraft(name: name, hops: hops, groups: groups);

  /// Appends a hop; one already in the chain is ignored.
  ChainDraft add(MemberRef hop) => hops.contains(hop)
      ? this
      : ChainDraft(name: name, hops: [...hops, hop], groups: groups);

  ChainDraft removeAt(int index) =>
      ChainDraft(name: name, hops: [...hops]..removeAt(index), groups: groups);

  /// Swaps a hop with its neighbour ([delta] −1 up, +1 down).
  ChainDraft move(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= hops.length) return this;
    final next = [...hops];
    final hop = next[index];
    next[index] = next[target];
    next[target] = hop;
    return ChainDraft(name: name, hops: next, groups: groups);
  }

  /// The groups to join, given the [defaults] that apply while untouched.
  Set<String> groupsOr(Set<String> defaults) => groups ?? defaults;

  ChainDraft toggleGroup(String key, {required Set<String> defaults}) {
    final next = {...groupsOr(defaults)};
    if (!next.remove(key)) next.add(key);
    return ChainDraft(name: name, hops: hops, groups: next);
  }

  /// Static checks only (two hops, hop kinds, no repeats); whether the path
  /// works is found out when it is used. The name stays null when empty so
  /// the chain shows as «A → B».
  Chain build() {
    if (hops.length < 2) {
      throw const ChainDraftException(ChainDraftError.tooShort);
    }
    for (final (i, hop) in hops.indexed) {
      if (!hop.canBeHop) {
        throw ChainDraftException(ChainDraftError.kind, index: i);
      }
      if (hops.indexOf(hop) != i) {
        throw ChainDraftException(ChainDraftError.duplicate, index: i);
      }
    }
    final trimmed = name.trim();
    return Chain(id: '', name: trimmed.isEmpty ? null : trimmed, hops: hops);
  }
}
