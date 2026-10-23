// Compiling the selected configuration, checking and saving the JSON
// override, and the texts for what can go wrong (PRODUCT_SPEC §3.10).
import 'dart:convert';

import 'package:av_core/av_core.dart';
import 'package:avalon/features/override/override_view_model.dart';
import 'package:avalon/services/plan_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _clash = '''
proxies:
  - {name: 香港 01, type: trojan, server: a.example.com, port: 443, password: fake-a}
  - {name: 日本 01, type: trojan, server: b.example.com, port: 443, password: fake-b}
proxy-groups:
  - {name: 节点选择, type: select, proxies: [香港 01, 日本 01]}
rules:
  - MATCH,节点选择
''';

const _self = SelfNode(
  id: '',
  name: '自建 VPS',
  server: 'vps.example.com',
  port: 443,
  params: NodeParams.trojan(password: Secret('fake-self')),
);

Matcher _compileError(CompileErrorCode code) =>
    throwsA(isA<CompileException>().having((e) => e.code, 'code', code));

void main() {
  late Harness h;
  setUp(
    () async => h = await Harness.start()
      ..body = _clash,
  );
  tearDown(() => h.stop());

  PlanService plans() => h.services.plans;

  Future<void> addSubscription() async {
    final added = await h.services.imports.addSubscription(
      url: '${h.base}/sub',
      defaultName: '新订阅',
    );
    await h.services.settings.updateDevice(
      (s) => s.copyWith(selectedConfigurationId: added.configurationId),
    );
  }

  group('compiling', () {
    test('needs a selected configuration', () async {
      await expectLater(
        plans().compileSelected(),
        throwsA(
          isA<PlanUnavailableException>().having(
            (e) => e.reason,
            'reason',
            PlanUnavailable.nothingSelected,
          ),
        ),
      );
    });

    test('a subscription compiles; what is shown hides the secrets', () async {
      await addSubscription();
      final plan = await plans().compileSelected();
      final shown = jsonEncode(plan.redacted());
      expect(shown, contains('a.example.com'));
      expect(shown, isNot(contains('fake-')));
      expect(shown, contains('••••'));
      expect(jsonEncode(plan.toJson()), contains('fake-a'));
      // Same content, same hash: the key is derived, not random per call.
      expect((await plans().compileSelected()).planHash, plan.planHash);
    });

    test('「自建节点」 compiles from the self nodes', () async {
      await h.services.selfService.addNode(_self);
      final plan = await plans().compileSelected();
      expect(jsonEncode(plan.redacted()), contains('vps.example.com'));
    });
  });

  group('checking an override', () {
    test('without a configuration only the text itself is checked', () async {
      await plans().checkOverride('');
      await plans().checkOverride('{"route": {"final": "不存在"}}');
      await expectLater(
        plans().checkOverride('{"route": '),
        _compileError(CompileErrorCode.overrideInvalid),
      );
      await expectLater(
        plans().checkOverride('{"inbounds": []}'),
        _compileError(CompileErrorCode.overrideInvalid),
      );
    });

    test('names are resolved against the selected configuration', () async {
      await addSubscription();
      await plans().checkOverride(
        '{"route": {"rules": [{"domain_suffix": ["example.com"], '
        '"outbound": "日本 01"}], "final": "节点选择"}}',
      );
      await expectLater(
        plans().checkOverride('{"route": {"final": "不存在"}}'),
        _compileError(CompileErrorCode.overrideReference),
      );
    });
  });

  group('the editor', () {
    OverrideViewModel model() =>
        h.container.read(overrideViewModelProvider.notifier);

    setUp(() => h.container.listen(overrideViewModelProvider, (_, _) {}));

    test('loads, refuses what is wrong, saves what is right', () async {
      await addSubscription();
      await model().load();
      var s = h.container.read(overrideViewModelProvider);
      expect(s.loading, isFalse);
      expect(s.text, '');
      expect(s.canSave, isFalse);

      model().setText('{"route": {"final": "不存在"}}');
      expect(h.container.read(overrideViewModelProvider).canSave, isTrue);
      expect(await model().save(), isFalse);
      s = h.container.read(overrideViewModelProvider);
      expect(s.invalid!.code, CompileErrorCode.overrideReference);
      expect((await h.services.settings.policy()).jsonOverride, isNull);

      // Editing clears the complaint.
      const good = '{"route": {"final": "日本 01"}}';
      model().setText(good);
      expect(h.container.read(overrideViewModelProvider).invalid, isNull);
      expect(await model().save(), isTrue);
      expect(
        (await h.services.settings.policy()).jsonOverride,
        const Secret(good),
      );
      expect(h.container.read(overrideViewModelProvider).canSave, isFalse);
      // The plan now ends in that node.
      final plan = await plans().compileSelected();
      final route = plan.toJson()['route']! as Map<String, Object?>;
      expect(plan.tags[route['final']]!.name, '日本 01');

      // Emptying the editor removes the override.
      model().setText('  ');
      expect(await model().save(), isTrue);
      expect((await h.services.settings.policy()).jsonOverride, isNull);
    });
  });
}
