import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/layout.dart';
import 'apps_state.dart';
import 'apps_view.dart';
import 'apps_view_model.dart';

class AppsScreen extends ConsumerWidget {
  const AppsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appsStateProvider);
    final model = ref.read(appsViewModelProvider.notifier);
    return AppsView(
      state: state,
      platform: AppPlatform.host,
      onMode: model.setMode,
      onToggle: (id, on) => model.toggle(id, on: on),
      onAdd: model.addProgram,
      onEnableFindProcess: model.enableFindProcess,
    );
  }
}
