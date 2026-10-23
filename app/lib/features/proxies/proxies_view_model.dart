import 'package:av_core/av_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_error.dart';
import '../../app/providers.dart';
import '../../app/selected_configuration.dart';
import '../../data/repositories/self_content_repository.dart';
import '../../runtime/actual_selections.dart';
import '../../runtime/latency.dart';
import 'proxies_state.dart';

/// The page state: the selected configuration's groups with self content
/// and saved choices folded in.
final proxiesStateProvider = Provider.autoDispose<ProxiesState>((ref) {
  // Watched first: while the data loads this is the only listener keeping
  // the group asked for (e.g. 「自定义」 after adding a node) alive.
  final shown = ref.watch(proxiesViewModelProvider);
  final SelectionReady ready;
  switch (ref.watch(selectedConfigurationProvider)) {
    case SelectionLoading():
      return const ProxiesState(loading: true);
    case NothingSelected():
      return const ProxiesState(hasConfiguration: false);
    case NotDownloaded():
      return const ProxiesState(downloaded: false);
    case SelectionFailed(:final error):
      return ProxiesState(error: error);
    case final SelectionReady selected:
      ready = selected;
  }
  final SelectionReady(:configuration, :catalog, :selections, :settings) =
      ready;
  final content = catalog.content;
  final latencies = ref.watch(latencyProvider);
  final actual = ref.watch(actualSelectionsProvider);

  ProxyMember member(MemberRef ref) {
    final unavailable = catalog.unavailable(ref);
    final name = catalog.name(ref);
    final latency = latencies[(configuration.id, ref)];
    switch (ref) {
      case SourceMember(:final key):
        final group = content.group(key);
        if (group != null) {
          return ProxyMember(
            ref: ref,
            name: name,
            kind: ProxyMemberKind.group,
            groupType: group.displayType,
            unavailable: unavailable,
            latency: latency,
          );
        }
        return ProxyMember(
          ref: ref,
          name: name,
          kind: ProxyMemberKind.node,
          protocol: catalog.paramsOf(ref)?.protocol,
          unavailable: unavailable,
          latency: latency,
        );
      case SelfNodeRef():
        return ProxyMember(
          ref: ref,
          name: name,
          kind: ProxyMemberKind.node,
          protocol: catalog.paramsOf(ref)?.protocol,
          unavailable: unavailable,
          latency: latency,
        );
      case ChainRef(:final id):
        return ProxyMember(
          ref: ref,
          name: name,
          kind: ProxyMemberKind.chain,
          hops: catalog.chain(id)?.hops.length ?? 0,
          unavailable: unavailable,
          latency: latency,
        );
      case TailnetExitRef():
        return ProxyMember(
          ref: ref,
          name: name,
          kind: ProxyMemberKind.tailnet,
          unavailable: unavailable,
          latency: latency,
        );
      case BuiltinRef(:final builtin):
        return ProxyMember(
          ref: ref,
          name: name,
          kind: builtin == Builtin.direct
              ? ProxyMemberKind.direct
              : ProxyMemberKind.reject,
          latency: latency,
        );
    }
  }

  ProxyGroup group(String key) {
    final def = content.group(key);
    final members = [for (final r in catalog.membersOf(key)) member(r)];
    final selectable = def == null || def.type == GroupType.selector;
    // What the host says it uses while connected; otherwise the rule the
    // compiler applies (MemberCatalog.currentOf).
    final using =
        actual.of(
          MemberRef.source(configurationId: configuration.id, key: key),
        ) ??
        catalog.currentOf(key, selections);
    final index = using == null
        ? -1
        : members.indexWhere((m) => m.ref == using);
    final current = index >= 0 ? index : null;
    return ProxyGroup(
      key: key,
      name: key == ContentKeys.custom ? null : def?.name ?? key,
      displayType: def?.displayType ?? 'Selector',
      selectable: selectable,
      members: members,
      current: current,
    );
  }

  final groups = [for (final key in catalog.groupKeys) group(key)];
  return ProxiesState(
    groups: groups,
    groupKey: groups.any((g) => g.key == shown) ? shown : groups.first.key,
    directMode: settings.mode == OutboundMode.direct,
  );
});

/// The group on show (null: the first), and the page's commands.
final proxiesViewModelProvider =
    NotifierProvider.autoDispose<ProxiesViewModel, String?>(
      ProxiesViewModel.new,
    );

class ProxiesViewModel extends Notifier<String?> {
  @override
  String? build() => null;

  void showGroup(String key) => state = key;

  /// Tests the latency of [members] (the group on show). Null when it ran.
  Future<LatencyRefusal?> test(List<MemberRef> members) =>
      ref.read(latencyProvider.notifier).test(members);

  /// Saves a manual choice for a selector group of the selected
  /// configuration (applied at once while connected, D10).
  Future<Result<void>> select(String groupKey, MemberRef member) => attempt(
    () async {
      final settings = await ref.read(settingsRepositoryProvider).device();
      final id = settings.selectedConfigurationId;
      if (id == null) return;
      await ref.read(selectionRepositoryProvider).select(id, groupKey, member);
    },
  );

  /// Deletes a self node or chain. A node still used by chains stays, and
  /// the result says which (see [ProxiesState.chainName]).
  Future<DeleteResult> delete(MemberRef member) async {
    final repository = ref.read(selfContentRepositoryProvider);
    try {
      switch (member) {
        case SelfNodeRef(:final id):
          await repository.deleteNode(id);
        case ChainRef(:final id):
          await repository.deleteChain(id);
        case SourceMember() || TailnetExitRef() || BuiltinRef():
          break;
      }
      return const Deleted();
    } on NodeInUseException catch (e) {
      return NodeInUse(e.chainIds);
    } on Exception catch (e) {
      return DeleteFailed(AppError.from(e));
    }
  }
}
