import 'package:av_core/av_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'runtime_coordinator.dart';

/// What each group of the running plan uses right now, as members rather
/// than tags: the host's snapshot read through the plan's tag map
/// (CONFIG_PIPELINE §7). It is the truth for groups that pick by latency,
/// and for selectors it shows what a failed switch left in place.
@immutable
final class ActualSelections {
  const ActualSelections(this._byGroup);

  static const none = ActualSelections({});

  final Map<MemberRef, MemberRef> _byGroup;

  /// The member [group] uses now; null when unknown (nothing runs, or the
  /// plan is not known yet).
  MemberRef? of(MemberRef group) => _byGroup[group];

  /// Follows [from] through groups to what traffic actually leaves by.
  MemberRef resolve(MemberRef from) {
    var member = from;
    for (var depth = 0; depth < 16; depth++) {
      final next = _byGroup[member];
      if (next == null) break;
      member = next;
    }
    return member;
  }

  // By value: the host reports every second, and pages should rebuild only
  // when a choice really changed.
  @override
  bool operator ==(Object other) =>
      other is ActualSelections && mapEquals(other._byGroup, _byGroup);

  @override
  int get hashCode => Object.hashAllUnordered(
    _byGroup.entries.map((e) => Object.hash(e.key, e.value)),
  );
}

final actualSelectionsProvider = Provider<ActualSelections>((ref) {
  final runtime = ref.watch(runtimeProvider);
  if (!runtime.proxyConnected || runtime.tags.isEmpty) {
    return ActualSelections.none;
  }
  final tags = runtime.tags;
  final byGroup = <MemberRef, MemberRef>{};
  for (final MapEntry(key: group, value: member)
      in runtime.snapshot.selections.entries) {
    final groupRef = tags[group]?.ref;
    final memberRef = tags[member]?.ref;
    if (groupRef != null && memberRef != null) byGroup[groupRef] = memberRef;
  }
  return ActualSelections(byGroup);
});
