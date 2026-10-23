import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/layout.dart';
import '../../app/providers.dart';
import 'logs_view.dart';
import 'logs_view_model.dart';

class LogsScreen extends ConsumerWidget {
  const LogsScreen({super.key});

  /// Phones share through the system; desktops save a file.
  Future<void> _share(WidgetRef ref) async {
    final platform = AppPlatform.host;
    final file = ref
        .read(logsViewModelProvider.notifier)
        .export(platform: platform.name);
    if (platform.isDesktop) {
      await ref
          .read(fileDialogsProvider)
          .save(name: file.name, bytes: file.bytes);
    } else {
      await ref
          .read(shareSheetProvider)
          .shareFile(name: file.name, bytes: file.bytes);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(logsViewModelProvider);
    final model = ref.read(logsViewModelProvider.notifier);
    return LogsView(
      state: state,
      onFilter: model.setFilter,
      onShare: () => _share(ref),
    );
  }
}
