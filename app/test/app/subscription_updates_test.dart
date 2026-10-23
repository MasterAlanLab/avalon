// Subscriptions kept up to date (CONFIG_PIPELINE §2): every 12 hours for
// those with automatic updates, one download per subscription at a time.
import 'package:avalon/app/app_error.dart';
import 'package:avalon/app/subscription_updates.dart';
import 'package:avalon/data/database/database.dart';
import 'package:avalon/services/import_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../features/harness.dart';

const _links = 'trojan://fake-a@a.example.com:443#A\n';

void main() {
  late Harness h;

  setUp(() async {
    h = await Harness.start()
      ..body = _links;
  });
  tearDown(() => h.stop());

  SubscriptionUpdater updater() =>
      h.container.read(subscriptionUpdaterProvider.notifier);

  Future<String> add({bool autoUpdate = true}) async =>
      (await h.services.imports.addSubscription(
        url: '${h.base}/sub',
        defaultName: '订阅',
        autoUpdate: autoUpdate,
      )).configurationId;

  test('due 12 hours after the last success, then again', () async {
    await add();
    final now = DateTime.now();
    final before = h.requests;
    await updater().updateDue(now: now.add(const Duration(hours: 11)));
    expect(h.requests, before);
    await updater().updateDue(
      now: now.add(const Duration(hours: 12, minutes: 1)),
    );
    expect(h.requests, before + 1);
  });

  test('without automatic updates, and files, never', () async {
    await add(autoUpdate: false);
    await h.services.imports.addFile(text: _links, defaultName: '文件');
    final before = h.requests;
    await updater().updateDue(
      now: DateTime.now().add(const Duration(days: 30)),
    );
    expect(h.requests, before);
  });

  test('a failure is tried again at the next check', () async {
    final id = await add();
    h.status = 500;
    final later = DateTime.now().add(const Duration(hours: 13));
    await updater().updateDue(now: later);
    final configuration = await h.services.configurations.get(id);
    expect(configuration!.lastError, isNotNull);
    final before = h.requests;
    await updater().updateDue(now: later.add(const Duration(hours: 1)));
    expect(h.requests, before + 1);
  });

  test('what fell due while the app was closed is updated at launch', () async {
    final id = await add();
    // Last downloaded 13 hours ago.
    final db = h.services.db;
    await (db.update(db.configurations)..where((c) => c.id.equals(id))).write(
      ConfigurationsCompanion(
        lastSuccessAt: Value(
          DateTime.now()
              .subtract(const Duration(hours: 13))
              .millisecondsSinceEpoch,
        ),
      ),
    );
    final before = h.requests;
    // The app opens again.
    h.container.invalidate(subscriptionUpdaterProvider);
    await updater().idle();
    expect(h.requests, before + 1);
  });

  test('asked twice while it runs, one download', () async {
    final id = await add();
    final before = h.requests;
    final first = updater().refresh(id);
    expect(h.container.read(subscriptionUpdaterProvider), contains(id));
    await updater().refresh(id);
    expect(await first, isA<Ok<RefreshOutcome>>());
    expect(h.requests, before + 1);
    expect(h.container.read(subscriptionUpdaterProvider), isEmpty);
  });

  test(
    'a Cloud subscription fetches its first copy with auto-update off',
    () async {
      final id = await add(autoUpdate: false);
      final db = h.services.db;
      await db
          .into(db.syncDocuments)
          .insert(
            SyncDocumentsCompanion.insert(
              documentId: 'initial-cloud',
              recordId: 'remote-record',
              type: 'configuration',
              localId: Value(id),
              localEditedAt: 1,
              localDeleted: false,
            ),
          );
      await db
          .into(db.sourceProvenance)
          .insert(
            SourceProvenanceCompanion.insert(
              documentId: 'initial-cloud',
              origin: 'cloud',
              sourceGeneration: 'remote-generation',
            ),
          );
      await (db.update(db.configurations)..where((c) => c.id.equals(id))).write(
        const ConfigurationsCompanion(
          lastSuccessAt: Value(null),
          lastAttemptAt: Value(null),
        ),
      );
      final before = h.requests;
      await updater().updateDue();
      await updater().idle();
      final failed = (await h.services.configurations.get(id))!;
      expect(failed.lastError, 'fetch.blockedAddress');
      expect(failed.lastAttemptAt, isNotNull);
      expect(h.requests, before); // No private request reached the server.

      await updater().updateDue();
      expect(
        (await h.services.configurations.get(id))!.lastAttemptAt,
        failed.lastAttemptAt,
      );
      await updater().updateDue(
        now: failed.lastAttemptAt!.add(const Duration(minutes: 61)),
      );
      expect(
        (await h.services.configurations.get(id))!.lastAttemptAt,
        isNot(failed.lastAttemptAt),
      );
    },
  );
}
