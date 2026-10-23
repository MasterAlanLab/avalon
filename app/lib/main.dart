import 'app/background_updates.dart';
import 'app/bootstrap.dart';

void main() => bootstrap();

/// Started by Android's WorkManager without the interface (D75).
@pragma('vm:entry-point')
Future<void> backgroundMain() => runBackgroundUpdates();
