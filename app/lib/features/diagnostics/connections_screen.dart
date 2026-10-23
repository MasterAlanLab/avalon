import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connections_state.dart';
import 'connections_view.dart';
import 'connections_view_model.dart';

class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectionsStateProvider);
    final model = ref.read(connectionsViewModelProvider.notifier);
    return ConnectionsView(
      state: state,
      onClose: (row) => model.close(row.id),
      onCloseAll: model.closeAll,
    );
  }
}
