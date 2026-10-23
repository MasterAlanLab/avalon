// The add form and the configurations page, view models down to an
// in-memory database, against a local server.
import 'package:av_core/av_core.dart';
import 'package:avalon/features/add/add_view_model.dart';
import 'package:avalon/features/configurations/configurations_state.dart';
import 'package:avalon/features/configurations/configurations_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _links = '''
trojan://fake-password@a.example.com:443#A
trojan://fake-password@b.example.com:443?allowInsecure=1#B
''';

void main() {
  late Harness h;
  late ProviderContainer container;

  setUp(() async {
    h = await Harness.start()
      ..body = _links;
    container = h.container;
    // Keep the page and the form alive, as their screens would.
    container.listen(configurationsStateProvider, (_, _) {});
    container.listen(addViewModelProvider, (_, _) {});
  });
  tearDown(() => h.stop());

  /// The page state once [ready] holds.
  Future<ConfigurationsState> page(
    bool Function(ConfigurationsState s) ready,
  ) => h.settle(
    () => container.read(configurationsStateProvider),
    (s) => !s.loading && ready(s),
  );

  Future<List<ImportWarning>?> add(String url, {String name = ''}) {
    final form = container.read(addViewModelProvider.notifier)
      ..setUrl(url)
      ..setName(name);
    return form.saveSubscription(defaultName: '新订阅');
  }

  test('starts empty; the form cannot save without a link', () async {
    final s = await page((s) => true);
    expect(s.cards, isEmpty);
    expect(s.selectedId, isNull);
    expect(container.read(addViewModelProvider).canSave, isFalse);
    expect(await add('  '), isNull);
  });

  test(
    'adding shows a card, selects the first one and reports warnings',
    () async {
      final warnings = await add('${h.base}/sub', name: '我的订阅');
      expect(warnings!.map((w) => w.kind), contains(WarningKind.insecureTls));
      final s = await page((s) => s.cards.isNotEmpty && s.selectedId != null);
      final card = s.cards.single;
      expect(card.name, '我的订阅');
      expect(card.kind, ConfigurationKind.subscription);
      expect(card.nodeCount, 2);
      expect(card.canRefresh, isTrue);
      expect(s.selectedId, card.id);
      expect(s.canRefreshAll, isTrue);

      // A second configuration does not take the selection away (D26).
      container.invalidate(addViewModelProvider);
      await add('${h.base}/other');
      final two = await page((s) => s.cards.length == 2);
      expect(two.selectedId, card.id);
    },
  );

  test('a failed import stays in the form with its reason', () async {
    h.status = 404;
    expect(await add('${h.base}/sub'), isNull);
    final form = container.read(addViewModelProvider);
    expect(form.saving, isFalse);
    expect(form.error!.code, 'fetch.httpStatus.404');
    expect(form.url, '${h.base}/sub');
    expect((await page((s) => true)).cards, isEmpty);

    // Editing the link clears the error.
    container.read(addViewModelProvider.notifier).setUrl('${h.base}/sub2');
    expect(container.read(addViewModelProvider).error, isNull);
  });

  test('closing the form cancels the import', () async {
    final pending = add('${h.base}/sub');
    container.invalidate(addViewModelProvider);
    expect(await pending, isNull);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect((await page((s) => true)).cards, isEmpty);
  });

  test('a failed refresh keeps the content and marks the card', () async {
    await add('${h.base}/sub');
    final id = (await page((s) => s.cards.isNotEmpty)).cards.single.id;
    final model = container.read(configurationsViewModelProvider.notifier);

    h.status = 500;
    await model.refresh(id);
    final failed = await page((s) => s.cards.single.errorCode != null);
    expect(failed.cards.single.errorCode, 'fetch.httpStatus.500');
    expect(failed.cards.single.nodeCount, 2);
    expect(failed.cards.single.refreshing, isFalse);

    h.status = 200;
    h.body = 'trojan://fake-password@c.example.com:443#C\n';
    await model.refreshAll();
    final ok = await page((s) => s.cards.single.errorCode == null);
    expect(ok.cards.single.nodeCount, 1);
    expect(ok.refreshingAll, isFalse);
  });

  test('selecting and deleting', () async {
    await add('${h.base}/a', name: 'A');
    container.invalidate(addViewModelProvider);
    await add('${h.base}/b', name: 'B');
    final s = await page((s) => s.cards.length == 2);
    final a = s.cards.firstWhere((c) => c.name == 'A');
    final b = s.cards.firstWhere((c) => c.name == 'B');
    final model = container.read(configurationsViewModelProvider.notifier);

    await model.select(b.id);
    expect((await page((s) => s.selectedId == b.id)).selectedId, b.id);

    // Deleting the selected configuration clears the selection.
    await model.delete(b.id);
    final left = await page((s) => s.cards.length == 1);
    expect(
      (await h.services.settings.device()).selectedConfigurationId,
      isNull,
    );
    expect(left.cards.single.id, a.id);
    expect(left.selectedId, isNull);
  });

  test('「自建节点」 shows once it has content, after the imported ones', () async {
    await add('${h.base}/sub', name: 'A');
    expect((await page((s) => s.cards.isNotEmpty)).cards, hasLength(1));
    await h.services.selfService.addNode(
      const SelfNode(
        id: '',
        name: '自建 VPS',
        server: 'vps.example.com',
        port: 443,
        params: NodeParams.trojan(password: Secret('fake-self')),
      ),
    );
    final s = await page((s) => s.cards.length == 2);
    expect(
      [for (final c in s.cards) c.kind],
      [ConfigurationKind.subscription, ConfigurationKind.self],
    );
    expect(s.cards.last.nodeCount, 1);
    expect(s.cards.last.hasMenu, isFalse);
  });
}
