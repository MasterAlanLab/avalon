import 'package:av_core/av_core.dart';
import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/rule_set_updates.dart';
import '../../l10n/app_localizations.dart';
import 'rules_state.dart';
import 'rules_view.dart';
import 'rules_view_model.dart';

class RulesScreen extends ConsumerWidget {
  const RulesScreen({super.key});

  Future<void> _update(
    BuildContext context,
    WidgetRef ref,
    List<RuleSetRef> refs,
  ) async {
    final refusal = await ref.read(rulesViewModelProvider).update(refs);
    if (refusal == null || !context.mounted) return;
    final l = AppLocalizations.of(context);
    switch (refusal) {
      case RulesUpdateRefusal.needsProxy:
        showAvToast(context, l.rulesNeedProxy);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rulesStateProvider);
    final model = ref.read(rulesViewModelProvider);
    return RulesView(
      state: state,
      now: DateTime.now(),
      onUpdateAll: () =>
          _update(context, ref, [for (final item in state.items) item.ref]),
      onUpdate: (item) => _update(context, ref, [item.ref]),
      onAutoUpdate: model.setAutoUpdate,
      onInterval: model.setInterval,
      onVia: model.setVia,
    );
  }
}
