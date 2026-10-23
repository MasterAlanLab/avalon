// The startup animation and what follows it (UI_DESIGN_SYSTEM §5).
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:av_core/av_core.dart';
import 'package:avalon/app/bootstrap.dart';
import 'package:avalon/app/services.dart';
import 'package:avalon/app/startup_splash.dart';
import 'package:avalon/data/database/database.dart';
import 'package:avalon/data/vault/vault.dart';
import 'package:avalon/platform/launch_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final class _LaunchScreen implements LaunchScreen {
  /// Answers «still visible» this many times.
  int visibleFor = 0;
  int asked = 0;

  @override
  Future<bool> systemSplashVisible() async => asked++ < visibleFor;

  @override
  Future<void> rememberAppearance(Appearance appearance) async {}
}

final class _MissingKeyStore implements MasterKeyStore {
  bool? creationAllowed;

  @override
  Future<Uint8List> readOrCreate({bool allowCreate = true}) async {
    creationAllowed = allowCreate;
    throw const MasterKeyMissingException();
  }
}

void main() {
  test(
    'opening an occupied vault never authorizes replacement of its key',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'avalon-key-open-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/local.sqlite');
      final original = AppDatabase(NativeDatabase(file));
      final nonce = Uint8List.fromList(List.generate(24, (i) => i));
      final ciphertext = Uint8List.fromList(List.generate(32, (i) => i + 32));
      await original
          .into(original.secrets)
          .insert(
            SecretsCompanion.insert(
              id: 'retained-ciphertext',
              nonce: nonce,
              ciphertext: ciphertext,
              createdAt: 1,
            ),
          );
      await original.close();

      final store = _MissingKeyStore();
      await expectLater(
        AppServices.open(
          database: AppDatabase(NativeDatabase(file)),
          keyStore: store,
        ),
        throwsA(isA<MasterKeyMissingException>()),
      );
      expect(store.creationAllowed, isFalse);

      final reopened = AppDatabase(NativeDatabase(file));
      addTearDown(reopened.close);
      final retained = (await reopened.select(reopened.secrets).get()).single;
      expect(retained.id, 'retained-ciphertext');
      expect(retained.nonce, nonce);
      expect(retained.ciphertext, ciphertext);
    },
  );

  testWidgets('a system splash that never leaves holds it 1.5 s at most', (
    tester,
  ) async {
    final launch = _LaunchScreen()..visibleFor = 1 << 30;
    var completed = false;
    await tester.pumpWidget(
      StartupSplash(launchScreen: launch, onComplete: () => completed = true),
    );
    for (var i = 0; i < 200 && !completed; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(completed, isTrue);
  });

  group('the gate', () {
    Widget gate(Future<Startup> startup) => StartupGate(
      startup: startup,
      launchScreen: _LaunchScreen(),
      builder: (startup) => Directionality(
        textDirection: TextDirection.ltr,
        child: Text(switch (startup) {
          Started() => 'app',
          StartFailed(:final databaseTooNew) => 'failed $databaseTooNew',
        }),
      ),
    );

    StartupSplash splash(WidgetTester tester) =>
        tester.widget<StartupSplash>(find.byType(StartupSplash));

    testWidgets('slow data: the last frame stays until it is open', (
      tester,
    ) async {
      final opening = Completer<Startup>();
      await tester.pumpWidget(gate(opening.future));
      await tester.pump();
      expect(splash(tester).brightness, isNull);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(startupSplashDuration * 2);
      expect(find.byType(StartupSplash), findsOneWidget);
      opening.complete(const StartFailed(databaseTooNew: true));
      await tester.pump();
      await tester.pump();
      expect(find.text('failed true'), findsOneWidget);
    });
  });
}
