// DEVELOPMENT ONLY: the real app with the dev remote switched on, so
// tool/fidelity/ios.sh can drive it on the iOS simulator
// (`flutter build ios --simulator --debug -t gallery/app_main.dart`).
// Outside lib/, so release builds of lib/main.dart never include it.
import 'package:avalon/app/bootstrap.dart';

import 'dev_remote.dart';

Future<void> main() async {
  await bootstrap();
  DevRemote.maybeStart();
}
