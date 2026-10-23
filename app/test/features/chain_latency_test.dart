import 'dart:io';

import 'package:av_core/av_core.dart';
import 'package:avalon/features/add/chain_options.dart';
import 'package:avalon/runtime/latency.dart';
import 'package:avalon/runtime/runtime_coordinator.dart';
import 'package:avalon/runtime/runtime_host.dart';
import 'package:flutter_test/flutter_test.dart';

import '../runtime/fake_host.dart';
import 'harness.dart';

void main() {
  test(
    'form observes the selected configuration tests, not a chain test',
    () async {
      final dir = Directory.systemTemp.createTempSync('avalon-chain-latency-');
      final host = FakeHost(dir.path);
      final h = await Harness.start(
        host: RuntimeHost(transport: host, system: host),
      );
      addTearDown(() async {
        await h.stop();
        dir.deleteSync(recursive: true);
      });
      h.container.listen(chainOptionsProvider, (_, _) {});
      await h.container.read(runtimeProvider.notifier).ready;
      final nodes = [
        for (final name in ['A', 'B'])
          await h.services.selfContent.addNode(
            SelfNode(
              id: '',
              name: name,
              server: '$name.example.com',
              port: 443,
              params: const NodeParams.trojan(
                password: Secret('fake-password'),
              ),
            ),
          ),
      ];
      await h.services.settings.updateDevice(
        (s) => s.copyWith(selectedConfigurationId: SelfSource.id),
      );
      final refs = [for (final node in nodes) MemberRef.selfNode(id: node.id)];
      final plan = await h.services.plans.compileSelected();
      host.latencies = {
        plan.tagOf(refs[0])!: {'delayMs': 82},
        plan.tagOf(refs[1])!: {'delayMs': 210},
      };
      await h.container.read(latencyProvider.notifier).test(refs);
      var options = await h.settle(
        () => h.container.read(chainOptionsProvider),
        (o) => o.hop(refs[1])?.latency?.ms == 210,
      );
      expect(options.hop(refs[0])!.latency!.ms, 82);
      expect(options.estimate(refs)!.ms, 292);

      // The same controller used by proxies can report a timeout while the
      // form is open; no new form-only measurement is made.
      host.latencies = {};
      await h.container.read(latencyProvider.notifier).test([refs[1]]);
      options = h.container.read(chainOptionsProvider);
      expect(options.estimate(refs)!.status, LatencyStatus.timedOut);
      expect(host.commands.where((c) => c.$1 == 'urlTest'), hasLength(2));
    },
  );
}
