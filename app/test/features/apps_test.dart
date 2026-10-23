// 分应用代理 (PRODUCT_SPEC §3.11): the rows, and the view model down to the
// database.
import 'dart:typed_data';

import 'package:av_core/av_core.dart';
import 'package:av_design/av_design.dart';
import 'package:avalon/app/avalon_app.dart';
import 'package:avalon/app/layout.dart';
import 'package:avalon/app/providers.dart';
import 'package:avalon/features/settings/apps_state.dart';
import 'package:avalon/features/settings/apps_view.dart';
import 'package:avalon/features/settings/apps_view_model.dart';
import 'package:avalon/l10n/app_localizations.dart';
import 'package:avalon/platform/file_dialogs.dart';
import 'package:avalon/platform/installed_apps.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

final class _Apps implements InstalledApps {
  _Apps(this.apps);

  List<InstalledApp> apps;
  bool fail = false;

  @override
  Future<List<InstalledApp>> list() async =>
      fail ? throw Exception('unreadable') : apps;
}

final class _Dialogs implements FileDialogs {
  String? program;

  @override
  Future<String?> pickProgram() async => program;

  @override
  Future<PickedFile?> open({
    List<String>? extensions,
    required int maxBytes,
  }) async => null;

  @override
  Future<bool> save({required String name, required Uint8List bytes}) async =>
      false;
}

const _installed = [
  InstalledApp(id: 'com.android.chrome', name: 'Chrome', system: true),
  InstalledApp(id: 'org.telegram.messenger', name: 'Telegram'),
  InstalledApp(id: 'com.tencent.mm', name: '微信'),
  InstalledApp(id: 'com.spotify.music', name: 'Spotify'),
];

List<String> _names(AppsState s) => [for (final r in s.rows) r.name];

void main() {
  group('rows', () {
    AppsState of({
      List<String> pinned = const [],
      List<String> added = const [],
      List<String> on = const [],
      List<InstalledApp> installed = _installed,
    }) => AppsState.of(
      installed: installed,
      pinned: pinned,
      added: added,
      settings: DeviceSettings(perAppList: on),
    );

    test('a saved package that is gone stays listed, marked', () {
      final s = of(pinned: ['com.gone.app'], on: ['com.gone.app']);
      final row = s.rows.first;
      expect(
        (row.id, row.name, row.on, row.missing),
        ('com.gone.app', 'com.gone.app', true, true),
      );
      // Also when it arrived after the page opened (a restored backup).
      expect(of(on: ['com.late.app']).rows.first.missing, isTrue);
    });

    test('an allow list with no app installed is pointed out', () {
      AppsState state(
        List<String> on, {
        PerAppMode mode = PerAppMode.whitelist,
      }) => AppsState.of(
        installed: _installed,
        pinned: on,
        added: const [],
        settings: DeviceSettings(perAppList: on, perAppMode: mode),
      );
      expect(state(['com.example.gone']).noneInstalled, isTrue);
      expect(
        state(['com.example.gone', 'com.tencent.mm']).noneInstalled,
        isFalse,
      );
      // A block list of absent apps excludes nothing, which is what it says.
      expect(
        state(['com.example.gone'], mode: PerAppMode.blacklist).noneInstalled,
        isFalse,
      );
      expect(state([]).noneInstalled, isFalse);
    });
  });

  group('page', () {
    final calls = <String>[];
    setUp(calls.clear);

    Future<void> pump(
      WidgetTester tester,
      AppsState state, {
      AppPlatform platform = AppPlatform.android,
    }) async {
      final desktop = platform.isDesktop;
      tester.view.physicalSize = desktop
          ? const Size(1000, 800)
          : const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final view = AppsView(
        state: state,
        platform: platform,
        onMode: (mode) => calls.add('mode ${mode.name}'),
        onToggle: (id, on) => calls.add('toggle $id $on'),
        onAdd: () => calls.add('add'),
        onEnableFindProcess: () => calls.add('find'),
      );
      await tester.pumpWidget(
        CupertinoApp(
          locale: const Locale('zh', 'CN'),
          supportedLocales: supportedAppLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) =>
              AvAppFrame(colors: AvColors.light, child: child!),
          home: desktop ? AvDensity.desktop(child: view) : view,
        ),
      );
      await tester.pump();
    }

    AppsState state({
      List<String> on = const [],
      PerAppMode mode = PerAppMode.whitelist,
      bool findProcess = true,
      List<InstalledApp> installed = _installed,
    }) => AppsState.of(
      installed: installed,
      pinned: on,
      added: const [],
      settings: DeviceSettings(
        perAppList: on,
        perAppMode: mode,
        findProcess: findProcess,
      ),
    );

    testWidgets('switches, the mode and search', (tester) async {
      await pump(tester, state());
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('org.telegram.messenger')),
          matching: find.byType(AvSwitch),
        ),
      );
      await tester.tap(find.text('黑名单'));
      expect(calls, ['toggle org.telegram.messenger true', 'mode blacklist']);

      await tester.enterText(find.byType(CupertinoTextField), 'tencent');
      await tester.pump();
      expect(find.text('微信'), findsOneWidget);
      expect(find.text('Telegram'), findsNothing);

      await tester.enterText(find.byType(CupertinoTextField), 'zzz');
      await tester.pump();
      expect(find.text('没有匹配的应用'), findsOneWidget);
      // Phones have nothing to add by hand.
      expect(find.text('添加程序'), findsNothing);
    });

    testWidgets('desktop: add a program, and the find-process notice', (
      tester,
    ) async {
      await pump(
        tester,
        state(installed: const [], on: ['/usr/bin/git'], findProcess: false),
        platform: AppPlatform.mac,
      );
      expect(find.text('git'), findsOneWidget);
      expect(find.text('/usr/bin/git'), findsOneWidget);
      await tester.tap(find.text('添加程序'));
      await tester.tap(find.text('开启'));
      expect(calls, ['add', 'find']);

      // With find process on there is nothing to warn about.
      await pump(
        tester,
        state(installed: const [], on: ['/usr/bin/git']),
        platform: AppPlatform.mac,
      );
      expect(find.text('开启'), findsNothing);
      // Nothing listed and nothing saved: say how to start.
      await pump(
        tester,
        state(installed: const []),
        platform: AppPlatform.windows,
      );
      expect(find.textContaining('还没有程序'), findsOneWidget);
    });
  });

  group('view model', () {
    late Harness h;
    late _Apps apps;
    late _Dialogs dialogs;

    setUp(() async {
      apps = _Apps(_installed);
      dialogs = _Dialogs();
      h = await Harness.start(
        overrides: [
          installedAppsProvider.overrideWithValue(apps),
          fileDialogsProvider.overrideWithValue(dialogs),
        ],
      );
    });
    tearDown(() => h.stop());

    Future<AppsState> ready() {
      // Keeps the page's providers alive, as the page would.
      h.container.listen(appsStateProvider, (_, _) {});
      return h.settle(
        () => h.container.read(appsStateProvider),
        (s) => !s.loading,
      );
    }

    AppsViewModel model() => h.container.read(appsViewModelProvider.notifier);

    test('switches and the mode are saved at once', () async {
      expect((await ready()).anyOn, isFalse);

      await model().toggle('org.telegram.messenger', on: true);
      await model().toggle('com.tencent.mm', on: true);
      await model().toggle('org.telegram.messenger', on: true); // Once only.
      await model().setMode(PerAppMode.blacklist);
      var saved = await h.services.settings.device();
      expect(saved.perAppList, ['com.tencent.mm', 'org.telegram.messenger']);
      expect(saved.perAppMode, PerAppMode.blacklist);

      await model().toggle('com.tencent.mm', on: false);
      saved = await h.services.settings.device();
      expect(saved.perAppList, ['org.telegram.messenger']);

      final s = await h.settle(
        () => h.container.read(appsStateProvider),
        (s) => s.rows.where((r) => r.on).length == 1,
      );
      expect(s.mode, PerAppMode.blacklist);
      expect(s.rows.singleWhere((r) => r.on).name, 'Telegram');
    });

    test('the list as saved is on top when the page opens', () async {
      await h.services.settings.updateDevice(
        (s) => s.copyWith(perAppList: ['com.android.chrome']),
      );
      final s = await ready();
      expect(_names(s).first, 'Chrome');
      // Turned off, it keeps its place for this visit.
      await model().toggle('com.android.chrome', on: false);
      final off = await h.settle(
        () => h.container.read(appsStateProvider),
        (s) => !s.anyOn,
      );
      expect(_names(off).first, 'Chrome');
    });

    test('adding a program turns it on and lists it first', () async {
      apps.apps = const [
        InstalledApp(id: '/Applications/Safari.app', name: 'Safari'),
      ];
      await ready();

      dialogs.program = null; // Cancelled.
      expect(await model().addProgram(), isFalse);
      expect((await h.services.settings.device()).perAppList, isEmpty);

      dialogs.program = '/usr/local/bin/curl';
      expect(await model().addProgram(), isTrue);
      expect((await h.services.settings.device()).perAppList, [
        '/usr/local/bin/curl',
      ]);
      var s = await h.settle(
        () => h.container.read(appsStateProvider),
        (s) => s.anyOn,
      );
      expect(_names(s), ['curl', 'Safari']);

      // Turned off it is still there to turn back on.
      await model().toggle('/usr/local/bin/curl', on: false);
      s = await h.settle(
        () => h.container.read(appsStateProvider),
        (s) => !s.anyOn,
      );
      expect(_names(s), ['curl', 'Safari']);
    });

    test('«开启» turns on find process', () async {
      await h.services.settings.updateDevice(
        (s) => s.copyWith(perAppList: ['/usr/bin/git'], findProcess: false),
      );
      expect((await ready()).needsFindProcess(desktop: true), isTrue);
      await model().enableFindProcess();
      final s = await h.settle(
        () => h.container.read(appsStateProvider),
        (s) => s.findProcess,
      );
      expect(s.needsFindProcess(desktop: true), isFalse);
    });

    test('when the device cannot be read the saved list still shows', () async {
      apps.fail = true;
      await h.services.settings.updateDevice(
        (s) => s.copyWith(perAppList: ['com.tencent.mm']),
      );
      final s = await ready();
      expect(s.listFailed, isTrue);
      expect(
        [for (final r in s.rows) (r.id, r.on)],
        [('com.tencent.mm', true)],
      );
    });
  });
}
