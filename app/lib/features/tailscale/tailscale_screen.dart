import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tailscale_view.dart';
import 'tailscale_view_model.dart';

class TailscaleScreen extends ConsumerWidget {
  const TailscaleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tailscaleViewModelProvider);
    final model = ref.read(tailscaleViewModelProvider.notifier);
    return TailscaleView(
      state: state,
      onEnabled: model.setEnabled,
      onLogin: model.login,
      onLogout: model.logout,
      onExit: model.selectExit,
      onAcceptRoutes: model.setAcceptRoutes,
      onMagicDns: model.setMagicDns,
      onAdvertiseExit: model.setAdvertiseExit,
    );
  }
}
