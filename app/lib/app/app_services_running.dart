import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/cloud/cloud_view_model.dart';
import '../runtime/runtime_coordinator.dart';
import 'desktop_proxy_controller.dart';
import 'providers.dart';
import 'rule_set_updates.dart';
import 'subscription_updates.dart';

/// Keeps the application-level services working for as long as the app
/// runs, whatever page is shown. A provider that is
/// only read has its own listeners paused, so each is listened to here,
/// on the container rather than from a widget that may leave the screen.
void keepServicesRunning(ProviderContainer container, {bool cloud = false}) {
  container
    ..listen(runtimeProvider, (_, _) {})
    ..listen(desktopProxyProvider, (_, _) {})
    ..listen(ruleSetUpdaterProvider, (_, _) {})
    ..listen(subscriptionUpdaterProvider, (_, _) {});
  // Only the UI entry restores Cloud. Headless subscription updates neither
  // open the account page nor send authentication requests.
  if (cloud && container.read(cloudAuthServiceProvider) != null) {
    container.read(cloudSyncEngineProvider)?.start();
    container.listen(cloudViewModelProvider, (_, _) {});
  }
}
