import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../runtime/runtime_coordinator.dart';
import 'app_services_running.dart';
import 'log.dart';
import 'providers.dart';
import 'rule_set_updates.dart';
import 'services.dart';
import 'subscription_updates.dart';

/// Scheduled updates without the interface (D75): the
/// entry point Android's WorkManager starts. The same services as the
/// app, on the same database (shared between engines): what is due is
/// downloaded, a running session is reloaded when its plan changed, and
/// the proxy is never started. Tells the platform when it is done.
Future<void> runBackgroundUpdates() async {
  WidgetsFlutterBinding.ensureInitialized();
  const platform = MethodChannel('dev.avalon/background');
  try {
    final services = await AppServices.open();
    final container = ProviderContainer(
      overrides: [
        servicesProvider.overrideWithValue(services),
        runtimeConnectAtLaunchProvider.overrideWithValue(false),
      ],
    );
    keepServicesRunning(container);
    try {
      await updateInBackground(container);
    } finally {
      container.dispose();
      await services.close();
    }
  } on Object catch (e) {
    Log.error('background updates failed', e);
  } finally {
    await platform.invokeMethod<void>('done');
  }
}

/// What a background run does on [container] (whose
/// `runtimeConnectAtLaunchProvider` is false).
Future<void> updateInBackground(ProviderContainer container) async {
  final runtime = container.read(runtimeProvider.notifier);
  await runtime.ready;
  // A session that runs is brought in line first, so downloads «经代理»
  // know where to go.
  await runtime.idle();
  // Subscriptions: the updater checks as it starts.
  await container.read(subscriptionUpdaterProvider.notifier).idle();
  final rules = container.read(ruleSetUpdaterProvider.notifier);
  await rules.updateDue();
  await rules.idle();
  // What changed reaches a running session now, not after a debounce.
  await runtime.sync();
  await runtime.idle();
}
