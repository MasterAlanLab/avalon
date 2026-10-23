import 'dart:async';

import 'package:av_core/av_core.dart';
import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_error.dart';
import '../../app/routes.dart';
import '../../l10n/app_localizations.dart';
import 'configurations_state.dart';
import 'configurations_view.dart';
import 'configurations_view_model.dart';
import 'self_content_management_screen.dart';

/// Opens the add form, then shows what an import skipped, or goes to
/// 「自定义」 where a new node or chain appears.
Future<void> openAddConfiguration(BuildContext context, WidgetRef ref) async {
  final result = await context.push<AddResult>(Routes.add);
  if (!context.mounted) return;
  switch (result) {
    case ConfigurationAdded(:final warnings) when warnings.isNotEmpty:
      ref.read(configurationsViewModelProvider.notifier).showWarnings(warnings);
    case SelfContentAdded():
      context.go(Routes.proxiesCustom);
    case ConfigurationAdded() || null:
      break;
  }
}

class ConfigurationsScreen extends ConsumerStatefulWidget {
  const ConfigurationsScreen({super.key});

  @override
  ConsumerState<ConfigurationsScreen> createState() =>
      _ConfigurationsScreenState();
}

class _ConfigurationsScreenState extends ConsumerState<ConfigurationsScreen> {
  // Keeps «5 分钟前» moving while the page stays open.
  late final Timer _clock = Timer.periodic(
    const Duration(seconds: 30),
    (_) => setState(() {}),
  );

  @override
  void initState() {
    super.initState();
    _clock;
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  Future<void> _menu(ConfigurationCard card, Offset? position) async {
    final l = AppLocalizations.of(context);
    final choice = await showAvItemMenu(
      context,
      position: position,
      title: card.name,
      actions: [AvAction(l.edit), AvAction(l.delete, destructive: true)],
      cancel: l.cancel,
    );
    if (!mounted) return;
    if (choice == 0) {
      await context.push<AddResult>(
        Routes.edit(EditKind.configuration, card.id),
      );
      return;
    }
    if (choice != 1) return;
    final confirmed = await showAvConfirm(
      context,
      title: l.deleteConfigurationTitle(card.name),
      message: l.deleteConfigurationBody,
      confirm: l.delete,
      cancel: l.cancel,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final result = await ref
        .read(configurationsViewModelProvider.notifier)
        .delete(card.id);
    if (result case Err(:final error) when mounted) {
      await showAvNotice(context, title: error.message(l), ok: l.ok);
    }
  }

  Future<void> _manageSelfContent() async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final member = await navigator.push<MemberRef>(
      AvDensity.isDesktop(context)
          ? AvDialogRoute<MemberRef>(
              builder: (_) => const SelfContentManagementScreen(),
            )
          : AvSheetRoute<MemberRef>(
              scrollableBuilder: (_, controller) =>
                  SelfContentManagementScreen(scrollController: controller),
            ),
    );
    if (!mounted) return;
    final target = switch (member) {
      SelfNodeRef(:final id) => EditTarget(EditKind.node, id),
      ChainRef(:final id) => EditTarget(EditKind.chain, id),
      _ => null,
    };
    if (target != null) {
      await context.push<AddResult>(Routes.edit(target.kind, target.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(configurationsStateProvider);
    final model = ref.read(configurationsViewModelProvider.notifier);
    return ConfigurationsView(
      state: state,
      now: DateTime.now(),
      onSelect: (card) => model.select(card.id),
      onRefresh: (card) => model.refresh(card.id),
      onRefreshAll: model.refreshAll,
      onAdd: () => openAddConfiguration(context, ref),
      onManageSelfContent: _manageSelfContent,
      onMenu: _menu,
      onDismissWarnings: model.dismissWarnings,
    );
  }
}
