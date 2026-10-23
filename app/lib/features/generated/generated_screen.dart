import 'dart:convert';
import 'dart:isolate';

import 'package:av_core/av_core.dart';
import 'package:av_design/av_design.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_error.dart';
import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../services/plan_service.dart';
import 'generated_view.dart';

/// The selected configuration compiled as it would run, secrets masked.
final generatedConfigProvider = FutureProvider.autoDispose<String>((ref) async {
  final plan = await ref.watch(planServiceProvider).compileSelected();
  final masked = plan.redacted();
  return Isolate.run(() => const JsonEncoder.withIndent('  ').convert(masked));
});

/// Why the configuration could not be shown.
String generatedErrorText(AppLocalizations l, Object error) => switch (error) {
  PlanUnavailableException(:final reason) => switch (reason) {
    PlanUnavailable.nothingSelected => l.compileNothingSelected,
    PlanUnavailable.notDownloaded => l.contentNotDownloaded,
  },
  CompileException() => compileErrorText(l, error),
  _ => AppError.from(error).message(l),
};

class GeneratedScreen extends ConsumerWidget {
  const GeneratedScreen({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final config = ref.watch(generatedConfigProvider);
    final text = config.value;
    return GeneratedView(
      text: text,
      message: config.hasError ? generatedErrorText(l, config.error!) : null,
      scrollController: scrollController,
      onDone: () => context.pop(),
      onCopy: () async {
        if (text == null) return;
        await Clipboard.setData(ClipboardData(text: text));
        if (context.mounted) showAvToast(context, l.copied);
      },
    );
  }
}
