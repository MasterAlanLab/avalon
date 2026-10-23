import 'package:av_core/av_core.dart';
import 'package:av_design/av_design.dart';
import 'package:avalon/app/avalon_app.dart';
import 'package:avalon/features/tailscale/tailscale_state.dart';
import 'package:avalon/features/tailscale/tailscale_view.dart';
import 'package:avalon/l10n/app_localizations.dart';
import 'package:avalon/runtime/host_protocol.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

const _peer = HostTailnetPeer(
  id: 'fixture-peer',
  name: 'Fixture NAS',
  os: 'linux',
  ips: ['100.64.0.3'],
  online: true,
  exitCapable: true,
);

void main() {
  Future<void> show(
    WidgetTester tester,
    TailscaleState state, {
    ValueChanged<HostTailnetPeer?>? exit,
    ValueChanged<bool>? advertise,
  }) async {
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) =>
            AvAppFrame(colors: AvColors.light, child: child!),
        home: TailscaleView(
          state: state,
          onExit: exit,
          onAdvertiseExit: advertise,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('unverified exits show the limitation and cannot be selected', (
    tester,
  ) async {
    var actions = 0;
    await show(
      tester,
      const TailscaleState(
        settings: TailnetSettings(enabled: true),
        status: HostTailnetStatus(
          state: 'Running',
          tailnet: 'fixture',
          peers: [_peer],
        ),
      ),
      exit: (_) => actions++,
    );
    final peer = find
        .byWidgetPredicate((w) => w is AvRow && w.title == _peer.name)
        .first;
    await tester.ensureVisible(peer);
    await tester.tap(peer);
    await tester.pumpAndSettle();
    expect(actions, 0);
    expect(find.textContaining('出口节点功能待开放'), findsOneWidget);
    final advertise = tester.widget<AvRow>(
      find.byWidgetPredicate((w) => w is AvRow && w.title == '将本机作为出口节点'),
    );
    expect((advertise.trailing! as AvSwitch).onChanged, isNull);
  });

  testWidgets('an old exit choice can be explicitly cleared', (tester) async {
    HostTailnetPeer? selected = _peer;
    await show(
      tester,
      const TailscaleState(
        settings: TailnetSettings(
          enabled: true,
          exit: TailnetExitRef(
            tailnet: 'fixture',
            nodeStableId: 'fixture-peer',
            name: 'Fixture NAS',
          ),
        ),
        status: HostTailnetStatus(
          state: 'Running',
          tailnet: 'fixture',
          peers: [_peer],
        ),
      ),
      exit: (value) => selected = value,
    );
    final none = find.byWidgetPredicate((w) => w is AvRow && w.title == '无');
    await tester.ensureVisible(none);
    await tester.tap(none);
    await tester.pumpAndSettle();
    expect(selected, isNull);
  });
}
