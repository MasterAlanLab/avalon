import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/app_localizations.dart';
import 'proxies_screen.dart';
import 'proxies_view_model.dart';

/// Desktop toolbar «测速» (PRODUCT_SPEC §2): tests the group on show.
class TestLatencyButton extends ConsumerWidget {
  const TestLatencyButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(proxiesStateProvider);
    final testing = state.groups.any(
      (g) => g.key == state.groupKey && g.testing,
    );
    return AvDesktopButton(
      label: AppLocalizations.of(context).testLatency,
      icon: testing ? Symbols.progress_activity_rounded : Symbols.bolt_rounded,
      spin: testing,
      onTap: testing ? null : () => testShownGroup(context, ref),
    );
  }
}
