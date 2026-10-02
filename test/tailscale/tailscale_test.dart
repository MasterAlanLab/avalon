import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:avalon/common/common.dart';
import 'package:avalon/common/theme.dart';
import 'package:avalon/core/event.dart';
import 'package:avalon/core/method.dart';
import 'package:avalon/features/tailscale/model.dart';
import 'package:avalon/features/tailscale/provider.dart';
import 'package:avalon/l10n/l10n.dart';
import 'package:avalon/state.dart';
import 'package:avalon/views/tailscale.dart';
import 'package:avalon/views/dashboard/widgets/tailscale.dart';
import 'package:avalon/widgets/widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> fixture({
  int generation = 7,
  int revision = 2,
  int sequence = 1,
  String session = 'running',
  bool supported = true,
}) => {
  'supported': supported,
  'generation': generation,
  'revision': revision,
  'sequence': sequence,
  'session': session,
  'service': true,
  'capture': 'tun',
  'ipv6': true,
  'split': 'active',
  'exitState': 'off',
  'profileId': '1',
  'control': 'healthy',
  'prefs': {
    'autoRoute': true,
    'acceptRoutes': false,
    'exitId': '',
    'exitScope': 'groups',
    'failurePolicy': 'stop',
    'bindings': {},
    'routeChoices': {},
  },
  'devices': [
    {
      'id': 'stable-node',
      'name': 'A long device name on a private tailnet',
      'dnsName': 'nas.custom.head.example.',
      'os': 'linux',
      'ips': ['100.70.1.1', 'fd7a:115c:a1e0::1234'],
      'online': true,
      'exitNodeOption': true,
      'routes': [],
    },
  ],
  'routes': [],
  'probes': {},
  'groups': ['Current profile group'],
  'reasons': [],
};

class FakeBackend {
  Map<String, dynamic> snapshot;
  FakeBackend(this.snapshot);
  final calls = <CoreMethod>[];
  Object? arguments;
  Completer<Map<String, dynamic>>? pending;
  String? error;
  Future<Map<String, dynamic>> request(
    CoreMethod method, [
    Object? arguments,
  ]) async {
    calls.add(method);
    this.arguments = arguments is Map ? Map.of(arguments) : arguments;
    if (error != null)
      throw CoreMethodException(code: error!, message: 'categorical error');
    return pending?.future ?? snapshot;
  }
}

class TestApp extends StatelessWidget {
  final Widget child;
  final double scale;
  final Locale locale;
  const TestApp({
    super.key,
    required this.child,
    this.scale = 1,
    this.locale = const Locale('en'),
  });
  @override
  Widget build(BuildContext context) => MaterialApp(
    locale: locale,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
    ),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.delegate.supportedLocales,
    builder: (context, child) {
      globalState.measure = Measure.of(context, 1);
      globalState.theme = CommonTheme.of(context, 1);
      return MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      );
    },
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('snapshot orders generation revision and sequence; data is copied', () {
    final raw = fixture();
    final current = TailscaleSnapshot(raw);
    raw['session'] = 'paused';
    (raw['prefs'] as Map)['autoRoute'] = false;
    (raw['devices'] as List).first['ips'][0] = '100.99.9.9';
    expect(current.session, 'running');
    expect(current.prefs['autoRoute'], true);
    expect(current.devices.single.ips.first, '100.70.1.1');
    expect(
      TailscaleSnapshot(
        fixture(generation: 6, sequence: 99),
      ).isNewerThan(current),
      false,
    );
    expect(
      TailscaleSnapshot(
        fixture(revision: 1, sequence: 99),
      ).isNewerThan(current),
      false,
    );
    expect(TailscaleSnapshot(fixture()).isNewerThan(current), false);
    expect(TailscaleSnapshot(fixture(sequence: 2)).isNewerThan(current), true);
    expect(
      TailscaleSnapshot(
        fixture(generation: 8, revision: 0, sequence: 0),
      ).isNewerThan(current),
      true,
    );
  });
  test('core events update shared state and reject stale snapshots', () async {
    final f = FakeBackend(fixture());
    final container = ProviderContainer(
      overrides: [tailscaleRequestProvider.overrideWithValue(f.request)],
    );
    addTearDown(container.dispose);
    final c = container.read(tailscaleProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    final contract = jsonDecode(
      File('test/fixtures/core_protocol.json').readAsStringSync(),
    );
    final event = coreEventsFromData(contract['tailscaleEvent']).single;
    coreEventManager.sendEvent(event);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(tailscaleProvider).snapshot.session, 'paused');
    expect(
      container.read(tailscaleProvider).snapshot.devices.single.id,
      'stable-node',
    );
    c.accept(TailscaleSnapshot(fixture(sequence: 1)));
    expect(container.read(tailscaleProvider).snapshot.session, 'paused');
    c.accept(
      TailscaleSnapshot(
        fixture(sequence: 7, session: 'authorizing')
          ..['authUrl'] = 'https://HOST/register/TOKEN',
      ),
    );
    c.onCrash('not forwarded to UI');
    final disconnected = container.read(tailscaleProvider).snapshot;
    expect(disconnected.authUrl, isEmpty);
    expect(disconnected.json['service'], false);
    expect(disconnected.cached, true);
    expect(disconnected.split, 'inactive');
    expect(disconnected.devices.single.id, 'stable-node');
  });
  test(
    'duplicate commands are coalesced and older response cannot resurrect logout',
    () async {
      final f = FakeBackend(fixture());
      final container = ProviderContainer(
        overrides: [tailscaleRequestProvider.overrideWithValue(f.request)],
      );
      addTearDown(container.dispose);
      final c = container.read(tailscaleProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      f.pending = Completer();
      final first = c.command(CoreMethod.tailscalePause);
      await c.command(CoreMethod.tailscalePause);
      c.accept(
        TailscaleSnapshot(
          fixture(generation: 8, sequence: 4, session: 'loggedOut'),
        ),
      );
      f.pending!.complete(fixture(sequence: 2));
      await first;
      expect(
        f.calls.where((m) => m == CoreMethod.tailscalePause),
        hasLength(1),
      );
      expect(container.read(tailscaleProvider).snapshot.session, 'loggedOut');
      expect(container.read(tailscaleProvider).busy, false);
    },
  );
  for (final (size, scale, locale) in [
    (const Size(360, 800), 2.0, const Locale('zh', 'CN')),
    (const Size(768, 900), 1.0, const Locale('en')),
    (const Size(1280, 900), 2.0, const Locale('zh', 'CN')),
  ]) {
    testWidgets('native page at $size and text scale $scale with long IPv6', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final f = FakeBackend(
        fixture()
          ..['user'] = 'fixture@example.test'
          ..['self'] = {
            'id': 'self-node',
            'name': 'Avalon embedded node',
            'dnsName': 'avalon.tail.example.',
            'ips': ['100.71.1.2', 'fd7a:115c:a1e0::ab'],
            'os': 'android',
            'keyExpiry': '2027-03-31T04:23:41Z',
          }
          ..['probes'] = {
            'stable-node': {
              'state': 'success',
              'latencyMs': 12.5,
              'path': 'direct',
            },
          }
          ..['service'] = false
          ..['profileId'] = '0'
          ..['split'] = 'inactive'
          ..['error'] = 'config_apply_failed'
          ..['reasons'] = ['service_stopped', 'no_profile'],
      );
      final container = ProviderContainer(
        overrides: [tailscaleRequestProvider.overrideWithValue(f.request)],
      );
      addTearDown(container.dispose);
      globalState.container = container;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: TestApp(
            scale: scale,
            locale: locale,
            child: const TailscalePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l = AppLocalizations.current;
      final chinese = locale.languageCode == 'zh';
      expect(find.text(l.tsDevices), findsOneWidget);
      final header = find.byKey(const ValueKey('tailscale-session-header'));
      expect(tester.getSize(header).height, lessThan(120));
      expect(
        tester
            .widgetList<Text>(
              find.descendant(of: header, matching: find.byType(Text)),
            )
            .map((w) => w.data),
        [l.tsLoggedIn],
      );
      expect(find.text(l.tsThisDevice), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tailscale-self')));
      await tester.pumpAndSettle();
      expect(find.text('fixture@example.test'), findsOneWidget);
      expect(find.text('fd7a:115c:a1e0::ab'), findsOneWidget);
      final expiry = MaterialLocalizations.of(
        tester.element(find.byType(Dialog)),
      ).formatCompactDate(DateTime(2027, 3, 31));
      expect(find.text('${l.tsKeyExpiry}: $expiry'), findsOneWidget);
      expect(find.text(l.tsEmbeddedNote), findsOneWidget);
      expect(find.text(l.tsTest), findsNothing);
      Navigator.of(tester.element(find.byType(Dialog))).pop();
      await tester.pumpAndSettle();
      if (find
          .text('A long device name on a private tailnet')
          .evaluate()
          .isEmpty) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -450));
        await tester.pumpAndSettle();
      }
      expect(
        find.text('A long device name on a private tailnet'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          '${l.tsProbeSuccess} · 12.5 ms · ${l.tsDirectPath}',
        ),
        findsOneWidget,
      );
      if (size.width >= 1000) {
        await tester.tap(find.text('A long device name on a private tailnet'));
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsNothing);
        expect(find.text('nas.custom.head.example.'), findsOneWidget);
        expect(find.text('用于检测设备连通性'), findsOneWidget);
      }
      expect(tester.takeException(), null);
      await tester.ensureVisible(find.widgetWithText(Tab, l.tsRouting));
      await tester.tap(find.widgetWithText(Tab, l.tsRouting));
      await tester.pumpAndSettle();
      expect(find.text(l.tsAutoRoute), findsOneWidget);
      expect(
        find.text(
          chinese
              ? '规则模式下访问 Tailscale 设备'
              : 'Access Tailscale devices in Rule mode',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          chinese ? '通过 TUN 访问共享子网' : 'Access shared subnets through TUN',
        ),
        findsOneWidget,
      );
      final routingStatus = '${l.tsSplit}: ${l.tsInactive}';
      expect(find.text(routingStatus), findsOneWidget);
      expect(find.text(l.tsServiceStopped), findsNothing);
      expect(find.text(l.tsNoProfile), findsNothing);
      await tester.tap(find.text(routingStatus));
      await tester.pumpAndSettle();
      expect(find.text(l.tsServiceStopped), findsOneWidget);
      expect(find.text(l.tsNoProfile), findsOneWidget);
      expect(tester.takeException(), null);
      await tester.ensureVisible(find.widgetWithText(Tab, l.tsExit));
      await tester.tap(find.widgetWithText(Tab, l.tsExit));
      await tester.pumpAndSettle();
      final exitStatus = find.widgetWithText(
        ListTile,
        '${l.tsExit}: ${l.tsOff}',
      );
      expect(
        find.descendant(
          of: exitStatus,
          matching: find.text(
            chinese ? '通过出口节点访问公网' : 'Access the Internet through an exit node',
          ),
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text(l.tsSelectedGroups),
        150,
        scrollable: find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text(l.tsSelectedGroups), findsOneWidget);
      expect(
        find.text(
          chinese
              ? '仅对规则直接匹配的组生效'
              : 'Applies to groups matched directly by rules',
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text(l.tsReturnOriginal),
        150,
        scrollable: find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      final fallback = tester.widget<RadioListTile<String>>(
        find.byWidgetPredicate(
          (w) => w is RadioListTile<String> && w.value == 'fallback',
        ),
      );
      expect(
        (fallback.subtitle! as Text).data,
        chinese ? '切换时断开相关连接' : 'Closes related connections when switching',
      );
      await tester.pumpAndSettle();
      if (size.width == 768) {
        // Layout varies by size; the preference command itself does not.
        await tester.tap(find.text(l.tsReturnOriginal));
        await tester.pumpAndSettle();
        expect(f.calls, contains(CoreMethod.tailscalePreferences));
        expect(f.arguments, containsPair('failurePolicy', 'fallback'));
        container
            .read(tailscaleProvider.notifier)
            .accept(
              TailscaleSnapshot(
                fixture(sequence: 2)..['prefs']['exitScope'] = 'all',
              ),
            );
        await tester.pumpAndSettle();
        expect(find.text(l.tsGroupSemantics), findsNothing);
        expect(find.text('All Internet traffic'), findsOneWidget);
      }
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(f.calls, contains(CoreMethod.tailscaleCancelProbes));
    });
  }
  testWidgets(
    'login keeps keys private and QR encodes the backend authorization URL',
    (tester) async {
      final f = FakeBackend(
        fixture(session: 'loggedOut')
          ..['service'] = false
          ..['profileId'] = '0'
          ..['reasons'] = ['service_stopped', 'no_profile'],
      );
      final container = ProviderContainer(
        overrides: [tailscaleRequestProvider.overrideWithValue(f.request)],
      );
      addTearDown(container.dispose);
      globalState.container = container;
      for (final locale in [
        const Locale('en'),
        const Locale('zh', 'CN'),
        const Locale('ja'),
        const Locale('ru'),
      ]) {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: TestApp(locale: locale, child: const TailscalePage()),
          ),
        );
        await tester.pumpAndSettle();
        final l = AppLocalizations.current;
        expect(
          find.text(switch (locale.languageCode) {
            'zh' => '连接 Tailscale 网络',
            'ja' => 'Tailscale ネットワークに接続',
            'ru' => 'Подключение к сети Tailscale',
            _ => 'Connect to your Tailscale network',
          }),
          findsOneWidget,
        );
        expect(find.text(l.tsServiceStopped), findsNothing);
        expect(find.text(l.tsNoProfile), findsNothing);
        expect(find.text(l.tsRetry), findsNothing);
        final fields = tester.widgetList<TextField>(find.byType(TextField));
        expect(fields.where((w) => w.obscureText), hasLength(1));
        final key = find.byWidgetPredicate(
          (w) => w is TextField && w.obscureText,
        );
        await tester.ensureVisible(key);
        if (locale.languageCode == 'en') {
          await tester.enterText(key, 'headscale-fixture-key');
          await tester.ensureVisible(find.text(l.tsKeyLogin));
          await tester.tap(find.text(l.tsKeyLogin));
          await tester.pump();
          expect(f.calls, contains(CoreMethod.tailscaleLogin));
          expect(f.arguments, {
            'kind': 'key',
            'control': '',
            'authKey': 'headscale-fixture-key',
          });
          expect((tester.widget<TextField>(key).controller!).text, isEmpty);
          const authUrl = 'https://HOST/custom-register/TOKEN';
          f.snapshot = fixture(sequence: 2, session: 'authorizing')
            ..['authUrl'] = authUrl;
          await container.read(tailscaleProvider.notifier).refresh();
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text(l.tsQRCode));
          await tester.tap(find.text(l.tsQRCode));
          await tester.pumpAndSettle();
          expect(find.byType(QrImageView), findsOneWidget);
          final actual = tester
              .widgetList<CustomPaint>(find.byType(CustomPaint))
              .map((w) => w.painter)
              .whereType<QrPainter>()
              .single;
          final expected = QrPainter(
            data: authUrl,
            version: QrVersions.auto,
            gapless: true,
          );
          await tester.runAsync(() async {
            expect(
              (await actual.toImageData(200))!.buffer.asUint8List(),
              (await expected.toImageData(200))!.buffer.asUint8List(),
            );
          });
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    },
  );
  testWidgets(
    'optional card shares events and opens a full native route with back navigation',
    (tester) async {
      final self = {
        'id': 'self-node',
        'ips': ['100.71.1.2', 'fd7a:115c:a1e0::ab'],
      };
      final f = FakeBackend(fixture()..['self'] = self)
        ..pending = Completer<Map<String, dynamic>>();
      final container = ProviderContainer(
        overrides: [tailscaleRequestProvider.overrideWithValue(f.request)],
      );
      addTearDown(container.dispose);
      globalState.container = container;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const TestApp(
            child: Scaffold(body: SizedBox(width: 180, child: TailscaleCard())),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CommonCircleLoading), findsOneWidget);
      f.pending!.complete(f.snapshot);
      f.pending = null;
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<Text>(
              find.descendant(
                of: find.byType(TailscaleCard),
                matching: find.byType(Text),
              ),
            )
            .map((text) => text.data),
        ['Tailscale', '100.71.1.2'],
      );
      final value = tester.widget<Text>(find.text('100.71.1.2'));
      expect(
        value.style,
        Theme.of(
          tester.element(find.byType(TailscaleCard)),
        ).textTheme.bodyMedium?.toLight.adjustSize(1),
      );
      expect(tester.takeException(), null);
      await tester.tap(find.text('Tailscale'));
      await tester.pumpAndSettle();
      expect(find.byType(TailscalePage), findsOneWidget);
      container
          .read(tailscaleProvider.notifier)
          .accept(
            TailscaleSnapshot(
              fixture(sequence: 2, session: 'paused')
                ..['self'] = self
                ..['cached'] = true,
            ),
          );
      await tester.pumpAndSettle();
      expect(find.textContaining('Paused'), findsWidgets);
      expect(find.text('Showing cached information'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tailscale-session-actions')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(f.calls, isNot(contains(CoreMethod.tailscaleLogout)));
      await tester.tap(find.byKey(const ValueKey('tailscale-session-actions')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();
      expect(f.calls, contains(CoreMethod.tailscaleResume));
      Navigator.of(tester.element(find.byType(TailscalePage))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(TailscalePage), findsNothing);
      expect(find.text('Paused'), findsOneWidget);
      expect(find.text('100.71.1.2'), findsNothing);
      const ipv6 = 'fd7a:115c:a1e0:1234:5678:90ab:cdef:1234';
      container
          .read(tailscaleProvider.notifier)
          .accept(
            TailscaleSnapshot(
              fixture(sequence: 3)
                ..['self'] = {
                  'id': 'self-node',
                  'ips': [ipv6],
                },
            ),
          );
      await tester.pumpAndSettle();
      final longAddress = tester.widget<Text>(find.text(ipv6));
      expect(longAddress.maxLines, 1);
      expect(longAddress.overflow, TextOverflow.ellipsis);
      expect(
        find.byWidgetPredicate((w) => w is Tooltip && w.message == ipv6),
        findsOneWidget,
      );
      expect(tester.takeException(), null);
      container
          .read(tailscaleProvider.notifier)
          .accept(
            TailscaleSnapshot(
              fixture(sequence: 4, session: 'loggedOut')
                ..['self'] = self
                ..['cached'] = true,
            ),
          );
      await tester.pumpAndSettle();
      expect(find.text('Not signed in'), findsOneWidget);
      expect(find.text('100.71.1.2'), findsNothing);
      container
          .read(tailscaleProvider.notifier)
          .accept(
            TailscaleSnapshot(
              fixture(sequence: 5, supported: false, session: 'loggedOut'),
            ),
          );
      await tester.pumpAndSettle();
      expect(find.text(AppLocalizations.current.tsUnsupported), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'failure recovery renders empty, filtered and unsupported states',
    (tester) async {
      final f = FakeBackend(fixture())..error = 'server_unreachable';
      final container = ProviderContainer(
        overrides: [tailscaleRequestProvider.overrideWithValue(f.request)],
      );
      addTearDown(container.dispose);
      globalState.container = container;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const TestApp(child: TailscalePage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Server connection failed'), findsOneWidget);
      expect(find.textContaining('server_unreachable'), findsNothing);
      f.error = null;
      f.snapshot['devices'] = [];
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsNothing);
      expect(find.text('No other devices visible'), findsOneWidget);
      f.snapshot = fixture(sequence: 2);
      await container.read(tailscaleProvider.notifier).refresh();
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'no-such-device');
      await tester.pumpAndSettle();
      expect(find.text('No matching devices'), findsOneWidget);
      f.snapshot = fixture(sequence: 3, supported: false, session: 'loggedOut');
      await container.read(tailscaleProvider.notifier).refresh();
      await tester.pumpAndSettle();
      expect(
        find.text('Tailscale is not enabled in this version'),
        findsOneWidget,
      );
      expect(find.text(AppLocalizations.current.tsBrowserLogin), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
