// Settings pages: the view model down to the database, and the pages'
// wiring per platform (PRODUCT_SPEC §3.9–3.10, §6).
import 'package:av_core/av_core.dart';
import 'package:av_design/av_design.dart';
import 'package:avalon/app/avalon_app.dart';
import 'package:avalon/app/layout.dart';
import 'package:avalon/features/settings/basic_settings.dart';
import 'package:avalon/features/settings/settings_view_model.dart';
import 'package:avalon/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Pumps a settings page built by [sections] over a mutable settings value.
Future<void> _pump(
  WidgetTester tester,
  List<AvSettingsSection> Function(AppLocalizations l) sections, {
  bool desktop = false,
}) async {
  tester.view.physicalSize = desktop
      ? const Size(1000, 1600)
      : const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    CupertinoApp(
      locale: const Locale('zh', 'CN'),
      supportedLocales: supportedAppLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) =>
          AvAppFrame(colors: AvColors.light, child: child!),
      home: StatefulBuilder(
        builder: (context, _) {
          final page = AvSettingsPage(
            title: 't',
            backLabel: 'b',
            sections: sections(AppLocalizations.of(context)),
          );
          return desktop ? AvDensity.desktop(child: page) : page;
        },
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('view model', () {
    late Harness h;
    setUp(() async => h = await Harness.start());
    tearDown(() => h.stop());

    test('changes and typed values are saved at once', () async {
      final model = h.container.read(settingsViewModelProvider);
      await model.change((s) => s.copyWith(allowLan: true));
      await model.edit(SettingField.mixedPort, '1080');
      final s = await h.services.settings.device();
      expect(s.allowLan, isTrue);
      expect(s.mixedPort, 1080);
      await expectLater(
        model.edit(SettingField.mtu, '99'),
        throwsA(isA<SettingException>()),
      );
      expect((await h.services.settings.device()).mtu, 9000);
    });

    test('reset keeps the key; regenerating replaces it', () async {
      final model = h.container.read(settingsViewModelProvider);
      final key = (await h.services.settings.device()).clashApiSecret!;
      await model.change(
        (s) => s.copyWith(ipv6: true, mtu: 1400, mixedPort: 1080),
      );
      await model.resetAdvanced();
      var s = await h.services.settings.device();
      expect(s.ipv6, isFalse);
      expect(s.mtu, 9000);
      expect(s.mixedPort, 1080);
      expect(s.clashApiSecret, key);

      await model.regenerateClashSecret();
      s = await h.services.settings.device();
      expect(s.clashApiSecret, isNot(key));
      expect(s.clashApiSecret!.value, isNotEmpty);
    });
  });

  group('basic page', () {
    BasicSettingsActions actions({
      void Function(DeviceSettings Function(DeviceSettings))? change,
      void Function(SettingField)? edit,
    }) => BasicSettingsActions(
      change: change ?? (_) {},
      edit: edit ?? (_) {},
      chooseLanguage: () {},
      exportBackup: () {},
      restoreBackup: () {},
    );

    testWidgets('switches and value rows report what changed', (tester) async {
      var s = const DeviceSettings();
      SettingField? edited;
      await _pump(
        tester,
        (l) => basicSettingsSections(
          l: l,
          s: s,
          platform: AppPlatform.android,
          on: actions(change: (f) => s = f(s), edit: (f) => edited = f),
        ),
      );
      await tester.tap(
        find.descendant(
          of: find.ancestor(
            of: find.text('允许局域网连接'),
            matching: find.byType(AvRow),
          ),
          matching: find.byType(AvSwitch),
        ),
      );
      expect(s.allowLan, isTrue);
      await tester.tap(find.text('混合端口'));
      expect(edited, SettingField.mixedPort);
      await tester.tap(find.text('深色'));
      await tester.pump(const Duration(seconds: 1));
      expect(s.appearance, Appearance.dark);
    });
  });
}
