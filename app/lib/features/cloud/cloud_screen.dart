import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cloud_view.dart';
import 'cloud_view_model.dart';

/// Wires the development email account page to its view model. The router and
/// composition root own the gate; release builds do not expose this page.
class CloudScreen extends ConsumerWidget {
  const CloudScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cloudViewModelProvider);
    final model = ref.read(cloudViewModelProvider.notifier);
    return CloudView(
      state: state,
      onStartEmail: model.sendEmail,
      onVerify: model.verify,
      onChangeEmail: model.changeEmail,
      onReload: model.refreshAccount,
      onLogout: model.logout,
      onRemoveDevice: model.removeDevice,
      onDeleteAccount: model.deleteAccount,
      onRetryRevocations: model.retryRevocations,
      onSync: model.syncNow,
      onRebuildFromDevice: (takeOver) =>
          model.rebuildFromDevice(takeOver: takeOver),
      onCancelRebuild: model.cancelRebuild,
    );
  }
}
