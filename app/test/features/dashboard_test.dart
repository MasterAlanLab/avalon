// The dashboard from its view model down to an in-memory database
// (PRODUCT_SPEC §3.1).
import 'package:av_core/av_core.dart';
import 'package:avalon/features/add/add_view_model.dart';
import 'package:avalon/features/dashboard/dashboard_state.dart';
import 'package:avalon/features/dashboard/dashboard_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _clash = '''
proxies:
  - {name: 香港 01, type: trojan, server: a.example.com, port: 443, password: fake-a}
  - {name: 日本 01, type: vless, server: b.example.com, port: 443, uuid: 00000000-0000-4000-8000-000000000001, tls: true}
proxy-groups:
  - {name: 节点选择, type: select, proxies: [自动选择, 香港 01, 日本 01]}
  - {name: 自动选择, type: url-test, proxies: [香港 01, 日本 01], url: "https://www.gstatic.com/generate_204", interval: 300}
rules:
  - MATCH,节点选择
''';

void main() {
  late Harness h;
  late ProviderContainer container;

  setUp(() async {
    h = await Harness.start()
      ..body = _clash;
    container = h.container;
    container.listen(dashboardStateProvider, (_, _) {});
    container.listen(addViewModelProvider, (_, _) {});
  });
  tearDown(() => h.stop());

  Future<DashboardState> page(bool Function(DashboardState s) ready) =>
      h.settle(
        () => container.read(dashboardStateProvider),
        (s) => !s.loading && ready(s),
      );

  test('without a configuration there is no exit', () async {
    final s = await page((s) => true);
    expect(s.hasConfiguration, isFalse);
    expect(s.exit, isNull);
    expect(s.connected, isFalse);
  });

  test('the exit follows the main selector into nested groups', () async {
    final form = container.read(addViewModelProvider.notifier)
      ..setUrl('${h.base}/sub');
    expect(await form.saveSubscription(defaultName: '新订阅'), isNotNull);

    // Nothing chosen: 节点选择 uses 自动选择, which picks by latency.
    var s = await page((s) => s.exit != null);
    expect(s.exit!.name, '自动选择');
    expect(s.exit!.kind, ExitKind.group);
    expect(s.exit!.groupType, 'URLTest');

    // A chosen node is the exit.
    final id = (await h.services.settings.device()).selectedConfigurationId!;
    await h.services.selections.select(
      id,
      'group:节点选择',
      MemberRef.source(configurationId: id, key: 'proxy:日本 01'),
    );
    s = await page((s) => s.exit?.name == '日本 01');
    expect(s.exit!.kind, ExitKind.node);
    expect(s.exit!.protocol, Protocol.vless);
  });

  test('mode and switches are saved', () async {
    final model = container.read(dashboardViewModelProvider);
    await model.setMode(OutboundMode.direct);
    await model.setTun(false);
    await model.setSystemProxy(true);
    final s = await page((s) => s.mode == OutboundMode.direct);
    expect(s.tunEnabled, isFalse);
    expect(s.systemProxy, isTrue);
    final saved = await h.services.settings.device();
    expect(saved.mode, OutboundMode.direct);
    expect(saved.tunEnabled, isFalse);
    expect(saved.systemProxy, isTrue);
  });
}
