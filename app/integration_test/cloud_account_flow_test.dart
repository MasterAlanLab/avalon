// Opt-in native acceptance of the actual application/Screen/Router against
// real Go/PostgreSQL. Dedicated encrypted local DB; no personal app data.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:av_core/av_core.dart';
import 'package:avalon/app/app_services_running.dart';
import 'package:avalon/app/avalon_app.dart';
import 'package:avalon/app/providers.dart';
import 'package:avalon/app/routes.dart';
import 'package:avalon/app/services.dart';
import 'package:avalon/cloud/api_client.dart';
import 'package:avalon/cloud/cloud_development_config.dart';
import 'package:avalon/cloud/cloud_models.dart';
import 'package:avalon/data/database/database.dart';
import 'package:avalon/data/repositories/cloud_session_repository.dart';
import 'package:avalon/data/vault/vault.dart';
import 'package:avalon/features/cloud/cloud_state.dart';
import 'package:avalon/features/cloud/cloud_view_model.dart';
import 'package:avalon/runtime/runtime_coordinator.dart';
import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const base = String.fromEnvironment('AVALON_CLOUD_BASE_URL');
  const mailbox = String.fromEnvironment('AVALON_CLOUD_MAILBOX_URL');
  testWidgets(
    'native app email account: restart, offline logout isolation, devices and delete',
    (tester) async {
      final baseUri = _loopback(base);
      final mailUri = _loopback(mailbox);
      final dir = await Directory.systemTemp.createTemp(
        'avalon-cloud-acceptance-',
      );
      final key = MemoryKeyStore();
      final gate = _NetworkGate();
      final cleanups = <_Cleanup>[];
      _Application? app;
      final all = <_Application>[];

      Future<_Application> open({bool secondary = false}) async {
        final services = await AppServices.open(
          database: AppDatabase(
            NativeDatabase(
              File('${dir.path}/${secondary ? 'secondary' : 'primary'}.sqlite'),
            ),
          ),
          keyStore: key,
          exitIpUrl: '',
          cloudConfig: CloudDevelopmentConfig(baseUri: baseUri),
          cloudTransport: _GatedTransport(gate),
        );
        final container = ProviderContainer(
          overrides: [
            servicesProvider.overrideWithValue(services),
            runtimeHostProvider.overrideWithValue(null),
          ],
        );
        keepServicesRunning(container, cloud: true);
        final result = _Application(services, container);
        all.add(result);
        return result;
      }

      Future<void> mount(_Application target) async {
        app = target;
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: target.container,
            child: AvalonApp(
              initialSettings: await target.services.settings.device(),
              initialLocation: Routes.tool(Tool.cloud),
            ),
          ),
        );
        await _until(
          tester,
          () => target.state.initialized && !target.state.initializing,
        );
      }

      Future<StoredCloudSession> login(_Cleanup account) async {
        final current = app!;
        await tester.enterText(_input('cloud-email'), account.email);
        await tester.pump();
        await _tap(tester, 'cloud-send');
        await _until(
          tester,
          () => current.state.challengeId != null && !current.state.busy,
        );
        final code = await _mailCode(mailUri, current.state.challengeId!);
        await tester.enterText(_input('cloud-code'), code);
        await tester.pump();
        account.verifying = true;
        await _tap(tester, 'cloud-verify');
        await _until(
          tester,
          () =>
              current.state.signedIn &&
              current.state.account != null &&
              !current.state.busy,
        );
        final session = await current.services.cloudSessions.read();
        expect(session != null, isTrue);
        account.sessions.add(session!);
        return session;
      }

      try {
        final firstApp = await open();
        await mount(firstApp);
        final accountA = _Cleanup(_email());
        final accountB = _Cleanup(_email());
        cleanups.addAll([accountA, accountB]);
        final original = await login(accountA);
        expect(firstApp.state.account?.entitlement == null, isTrue);
        expect(firstApp.state.account?.syncActiveDeviceCount, 0);

        // Force only the dedicated local access deadline, then use the real
        // UI account action to exercise refresh without waiting 15 minutes.
        await firstApp.services.cloudSessions.save(
          original.copyWith(
            accessExpiresAt: DateTime.now().toUtc().subtract(
              const Duration(seconds: 1),
            ),
          ),
        );
        await _tap(tester, 'cloud-reload');
        await _until(
          tester,
          () => !firstApp.state.busy && firstApp.state.account != null,
        );
        final rotated = await firstApp.services.cloudSessions.read();
        expect(rotated?.refreshToken != original.refreshToken, isTrue);
        expect(rotated?.sessionId == original.sessionId, isTrue);
        accountA.sessions.add(rotated!);

        final localId = await firstApp.services.configurations.add(
          kind: ConfigurationKind.subscription,
          name: 'Acceptance local content',
          parsed: parseContent(
            'trojan://acceptance-password@proxy.example.invalid:443#Local',
          ),
          digest: 'acceptance-local-content',
          source: const SubscriptionSource(
            url: Secret(
              'https://subscription.example.invalid/?token=acceptance-local',
            ),
          ),
        );

        // Recreate application services and read the same encrypted database.
        await tester.pumpWidget(const SizedBox.shrink());
        await firstApp.close();
        final restored = await open();
        await mount(restored);
        expect(restored.state.signedIn, isTrue);
        expect(
          (await restored.services.cloudSessions.read())?.sessionId ==
              original.sessionId,
          isTrue,
        );
        expect(
          await restored.services.configurations.get(localId) != null,
          isTrue,
        );

        // Another real installation signs into A; removal happens through UI.
        final secondary = await open(secondary: true);
        final challenge = await secondary.services.cloudAuth!.startEmail(
          accountA.email,
        );
        final other = await secondary.services.cloudAuth!.verifyEmail(
          challengeId: challenge.challengeId,
          code: await _mailCode(mailUri, challenge.challengeId),
        );
        accountA.sessions.add(other);
        await _tap(tester, 'cloud-reload');
        await _until(
          tester,
          () =>
              restored.state.account?.devices.length == 2 &&
              !restored.state.busy,
        );
        expect(
          find
              .byKey(ValueKey('cloud-remove-${original.deviceId}'))
              .evaluate()
              .isEmpty,
          isTrue,
        );
        final otherRow = find.byKey(ValueKey('cloud-device-${other.deviceId}'));
        await tester.ensureVisible(otherRow);
        await tester.longPress(otherRow);
        await _until(
          tester,
          () => find.byType(CupertinoActionSheetAction).evaluate().length == 2,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(CupertinoActionSheetAction).first);
        await tester.pump();
        await _confirm(tester);
        await _until(
          tester,
          () =>
              restored.state.account?.devices.length == 1 &&
              !restored.state.busy,
        );

        gate.offline = true;
        await _tap(tester, 'cloud-logout');
        await _confirm(tester);
        await _until(
          tester,
          () => !restored.state.signedIn && !restored.state.busy,
        );
        expect(
          (await restored.services.cloudSessions.pendingRevocations()).length,
          1,
        );
        expect(
          await restored.services.configurations.get(localId) != null,
          isTrue,
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await restored.close();
        // Restore connectivity for a new login but hold old proof delivery;
        // the actual request succeeds when foreground polling later recovers.
        gate.offline = false;
        gate.holdLogout = true;
        final restarted = await open();
        await mount(restarted);
        expect(restarted.state.signedIn, isFalse);
        expect(
          (await restarted.services.cloudSessions.pendingRevocations()).length,
          1,
        );
        final newer = await login(accountB);
        gate.holdLogout = false;
        await _until(
          tester,
          () => restarted.state.pendingRevocationCount == 0,
          limit: const Duration(seconds: 25),
        );
        expect(
          (await restarted.services.cloudSessions.read())?.sessionId ==
              newer.sessionId,
          isTrue,
        );
        expect(
          (await restarted.services.cloudAuth!.account()).account.id ==
              newer.accountId,
          isTrue,
        );
        expect(gate.oldProofWithBearer, isFalse);

        final api = ApiClient(baseUri: baseUri, allowLoopbackHttp: true);
        try {
          var revoked = false;
          try {
            await api.getAccount(accessToken: original.accessToken);
          } on CloudApiException catch (e) {
            revoked = e.httpStatus == 401;
          }
          expect(revoked, isTrue);
        } finally {
          api.close();
        }

        await _tap(tester, 'cloud-delete');
        await _confirm(tester);
        await _confirm(tester);
        await _until(
          tester,
          () => restarted.state.accountDeleted && !restarted.state.busy,
        );
        accountB.deleted = true;
        expect(await restarted.services.cloudSessions.read() == null, isTrue);
        expect(
          await restarted.services.configurations.get(localId) != null,
          isTrue,
        );
        expect(
          (await restarted.services.configurations.source(
                localId,
              ))?.url.value ==
              'https://subscription.example.invalid/?token=acceptance-local',
          isTrue,
        );
      } finally {
        gate.offline = false;
        gate.holdLogout = false;
        await tester.pumpWidget(const SizedBox.shrink());
        // Cleanup with real API; no emails/codes/tokens in failure output.
        final api = ApiClient(baseUri: baseUri, allowLoopbackHttp: true);
        var cleanupFailed = false;
        for (final account in cleanups) {
          if (account.deleted || !account.verifying) continue;
          try {
            await account.delete(api, mailUri);
          } on Object {
            cleanupFailed = true;
          }
        }
        api.close();
        for (final local in all.reversed) {
          await local.close();
        }
        await dir.delete(recursive: true);
        if (cleanupFailed) {
          throw StateError('Temporary account cleanup failed.');
        }
      }
    },
    skip: base.isEmpty && mailbox.isEmpty,
    timeout: const Timeout(Duration(minutes: 4)),
  );
}

Future<void> _tap(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pump();
}

Future<void> _confirm(WidgetTester tester) async {
  await _until(
    tester,
    () => find.byType(CupertinoAlertDialog).evaluate().isNotEmpty,
  );
  await tester.pumpAndSettle();
  final action = find.byWidgetPredicate(
    (w) =>
        w is CupertinoDialogAction &&
        (w.isDestructiveAction || w.isDefaultAction),
  );
  await tester.tap(action);
  await tester.pump();
}

Future<void> _until(
  WidgetTester tester,
  bool Function() ready, {
  Duration limit = const Duration(seconds: 20),
}) async {
  final watch = Stopwatch()..start();
  while (!ready()) {
    if (watch.elapsed > limit) {
      throw StateError('Application state did not settle within its deadline.');
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump();
}

Uri _loopback(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.scheme != 'http' ||
      !['localhost', '127.0.0.1', '::1'].contains(uri.host) ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      (uri.path.isNotEmpty && uri.path != '/')) {
    throw StateError(
      'Native acceptance requires explicit loopback sandbox URLs.',
    );
  }
  return uri;
}

Future<String> _mailCode(Uri base, String challenge) async {
  if (!RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(challenge)) {
    throw StateError('Invalid sandbox challenge identifier.');
  }
  final http = HttpClient();
  try {
    final response = await (await http.getUrl(
      base.replace(path: '/$challenge'),
    )).close();
    if (response.statusCode != 200) {
      throw StateError('Sandbox mail was unavailable.');
    }
    final bytes = <int>[];
    await for (final chunk in response) {
      bytes.addAll(chunk);
      if (bytes.length > 65536) {
        throw StateError('Sandbox mail response exceeds its limit.');
      }
    }
    final data = jsonDecode(utf8.decode(bytes));
    final code = data is Map ? data['code'] : null;
    if (code is! String || !RegExp(r'^\d{6}$').hasMatch(code)) {
      throw StateError('Sandbox mail code format is invalid.');
    }
    return code;
  } on Object {
    throw StateError('Sandbox mailbox bridge did not return a valid code.');
  } finally {
    http.close(force: true);
  }
}

String _email() =>
    'avalon-native-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 30)}@sandbox.invalid';

Finder _input(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(CupertinoTextField),
);

String _installation() {
  final random = Random.secure();
  final hex = List.generate(
    32,
    (_) => random.nextInt(16).toRadixString(16),
  ).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-4${hex.substring(13, 16)}-8${hex.substring(17, 20)}-${hex.substring(20)}';
}

class _NetworkGate {
  bool offline = false;
  bool holdLogout = false;
  bool oldProofWithBearer = false;
}

class _GatedTransport implements CloudTransport {
  _GatedTransport(this.gate);
  final _NetworkGate gate;
  final real = HttpClientCloudTransport();
  @override
  Future<CloudResponse> send(CloudRequest request) {
    final logout = request.uri.path.endsWith('/logout');
    if (logout &&
        request.headers.containsKey(HttpHeaders.authorizationHeader)) {
      gate.oldProofWithBearer = true;
    }
    if (gate.offline || (logout && gate.holdLogout)) {
      throw const CloudNetworkException();
    }
    return real.send(request);
  }

  @override
  void close() => real.close();
}

class _Application {
  _Application(this.services, this.container);
  final AppServices services;
  final ProviderContainer container;
  bool closed = false;
  CloudState get state => container.read(cloudViewModelProvider);
  Future<void> close() async {
    if (closed) return;
    closed = true;
    container.dispose();
    await services.close();
  }
}

class _Cleanup {
  _Cleanup(this.email);
  final String email;
  bool verifying = false;
  bool deleted = false;
  final sessions = <StoredCloudSession>[];
  Future<void> delete(ApiClient api, Uri mailbox) async {
    for (final session in sessions.reversed) {
      try {
        await api.deleteAccount(accessToken: session.accessToken);
        deleted = true;
        return;
      } on CloudApiException catch (e) {
        if (e.httpStatus != 401) rethrow;
      }
    }
    final challenge = await api.emailStart(email: email);
    final tokens = await api.emailVerify(
      challengeId: challenge.challengeId,
      code: await _mailCode(mailbox, challenge.challengeId),
      device: DeviceInput(
        installationId: _installation(),
        name: 'Acceptance cleanup',
        os: DeviceOs.macos,
      ),
    );
    await api.deleteAccount(accessToken: tokens.accessToken);
    deleted = true;
  }
}
