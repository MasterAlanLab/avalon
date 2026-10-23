import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/app_localizations.dart';
import 'configurations_screen.dart';
import 'configurations_view_model.dart';

/// Desktop toolbar «全部更新» (PRODUCT_SPEC §2).
class RefreshAllConfigurationsButton extends ConsumerWidget {
  const RefreshAllConfigurationsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(
      configurationsStateProvider.select((s) => s.refreshingAll),
    );
    return AvDesktopButton(
      label: AppLocalizations.of(context).refreshAll,
      icon: busy ? Symbols.progress_activity_rounded : Symbols.refresh_rounded,
      spin: busy,
      onTap: () =>
          ref.read(configurationsViewModelProvider.notifier).refreshAll(),
    );
  }
}

/// Desktop toolbar «添加».
class AddConfigurationButton extends ConsumerWidget {
  const AddConfigurationButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AvDesktopButton(
    label: AppLocalizations.of(context).add,
    icon: Symbols.add_rounded,
    filled: true,
    onTap: () => openAddConfiguration(context, ref),
  );
}
