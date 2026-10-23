import 'package:av_core/av_core.dart';
import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_error.dart';
import '../../app/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../runtime/latency.dart';
import 'proxies_state.dart';
import 'proxies_view.dart';
import 'proxies_view_model.dart';

/// Tests the latency of the group on show, and says why when it cannot.
Future<void> testShownGroup(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final state = ref.read(proxiesStateProvider);
  final group = state.groups.where((g) => g.key == state.groupKey).firstOrNull;
  if (group == null || group.testing) return;
  final refusal = await ref.read(proxiesViewModelProvider.notifier).test([
    for (final member in group.members) member.ref,
  ]);
  if (!context.mounted) return;
  switch (refusal) {
    case null:
      break;
    case LatencyRefusal.noHost:
      await showAvNotice(
        context,
        title: l.coreNotConnected,
        message: l.coreNotConnectedNote,
        ok: l.ok,
      );
    case LatencyRefusal.noPlan:
      showAvToast(context, l.runtimePlanFailed);
    case LatencyRefusal.hostFailed:
      showAvToast(context, l.runtimeHostUnreachable);
  }
}

class ProxiesScreen extends ConsumerStatefulWidget {
  const ProxiesScreen({super.key, this.group});

  /// The group to show on arrival (`Routes.proxiesGroup`), e.g. 「自定义」
  /// after adding a node.
  final String? group;

  @override
  ConsumerState<ProxiesScreen> createState() => _ProxiesScreenState();
}

class _ProxiesScreenState extends ConsumerState<ProxiesScreen> {
  @override
  void initState() {
    super.initState();
    _showRequested();
  }

  @override
  void didUpdateWidget(ProxiesScreen old) {
    super.didUpdateWidget(old);
    if (widget.group != old.group) _showRequested();
  }

  void _showRequested() {
    final group = widget.group;
    if (group == null) return;
    // Providers may not change while the tree builds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(proxiesViewModelProvider.notifier).showGroup(group);
    });
  }

  Future<void> _select(ProxyGroup group, ProxyMember member) async {
    final l = AppLocalizations.of(context);
    if (!group.selectable) {
      showAvToast(context, l.autoGroupNote);
      return;
    }
    final result = await ref
        .read(proxiesViewModelProvider.notifier)
        .select(group.key, member.ref);
    if (result case Err(:final error) when mounted) {
      showAvToast(context, error.message(l));
    }
  }

  /// 「编辑」「删除」 for a self node or chain.
  Future<void> _menu(ProxyMember member, Offset? position) async {
    final l = AppLocalizations.of(context);
    final (kind, id) = switch (member.ref) {
      SelfNodeRef(:final id) => (EditKind.node, id),
      ChainRef(:final id) => (EditKind.chain, id),
      _ => (null, ''),
    };
    if (kind == null) return;
    final choice = await showAvItemMenu(
      context,
      position: position,
      title: member.name,
      actions: [AvAction(l.edit), AvAction(l.delete, destructive: true)],
      cancel: l.cancel,
    );
    if (!mounted) return;
    if (choice == 0) {
      await context.push<AddResult>(Routes.edit(kind, id));
      return;
    }
    if (choice != 1) return;
    final confirmed = await showAvConfirm(
      context,
      title: l.deleteItemTitle(member.name),
      message: kind == EditKind.node ? l.deleteNodeBody : l.deleteChainBody,
      confirm: l.delete,
      cancel: l.cancel,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    // Chain names as the page shows them, read before anything changes.
    final shown = ref.read(proxiesStateProvider);
    final result = await ref
        .read(proxiesViewModelProvider.notifier)
        .delete(member.ref);
    if (!mounted) return;
    switch (result) {
      case Deleted():
        break;
      case NodeInUse(:final chainIds):
        await showAvNotice(
          context,
          title: l.nodeInUseTitle,
          message: l.nodeInUseBody(
            member.name,
            chainIds.map(shown.chainName).join('、'),
          ),
          ok: l.ok,
        );
      case DeleteFailed(:final error):
        await showAvNotice(context, title: error.message(l), ok: l.ok);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(proxiesStateProvider);
    final model = ref.read(proxiesViewModelProvider.notifier);
    return ProxiesView(
      state: state,
      onGroup: (group) => model.showGroup(group.key),
      onMember: _select,
      onMemberMenu: _menu,
      onTest: () => testShownGroup(context, ref),
      onOpenConfigurations: () => context.go(Routes.configurations),
    );
  }
}
