import 'package:av_core/av_core.dart';
import 'package:av_design/av_design.dart';
import 'package:avalon/app/avalon_app.dart';
import 'package:avalon/app/routes.dart';
import 'package:avalon/features/configurations/configurations_screen.dart';
import 'package:avalon/features/configurations/configurations_state.dart';
import 'package:avalon/features/configurations/configurations_view_model.dart';
import 'package:avalon/features/configurations/self_content_management_state.dart';
import 'package:avalon/features/configurations/self_content_management_view.dart';
import 'package:avalon/features/configurations/self_content_management_view_model.dart';
import 'package:avalon/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _self = ConfigurationCard(
  id: 'self',
  kind: ConfigurationKind.self,
  name: '自建节点',
  nodeCount: 1,
  chainCount: 1,
);
const _node = SelfContentManagementItem(
  ref: MemberRef.selfNode(id: 'node-id'),
  name: '我的节点',
  protocol: Protocol.trojan,
);
const _chain = SelfContentManagementItem(
  ref: MemberRef.chain(id: 'chain-id'),
  name: '我的代理链',
  hops: 2,
);
const _content = SelfContentManagementState(nodes: [_node], chains: [_chain]);

Widget _frame(BuildContext context, Widget? child) =>
    AvAppFrame(colors: AvColors.light, child: child!);

void main() {
  for (final kind in [EditKind.node, EditKind.chain]) {
    for (final desktop in [false, true]) {
      testWidgets(
        '$kind opens the existing edit route from ${desktop ? 'desktop dialog' : 'phone sheet'}',
        (tester) async {
          tester.view.physicalSize = desktop
              ? const Size(1200, 900)
              : const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final router = GoRouter(
            initialLocation: Routes.configurations,
            routes: [
              GoRoute(
                path: Routes.configurations,
                builder: (_, _) => desktop
                    ? const AvDensity.desktop(child: ConfigurationsScreen())
                    : const ConfigurationsScreen(),
              ),
              GoRoute(
                path: '/edit/:kind/:id',
                builder: (_, state) => Text(
                  '${state.pathParameters['kind']}:${state.pathParameters['id']}',
                ),
              ),
            ],
          );
          addTearDown(router.dispose);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                configurationsStateProvider.overrideWithValue(
                  const ConfigurationsState(cards: [_self]),
                ),
                selfContentManagementStateProvider.overrideWithValue(_content),
              ],
              child: CupertinoApp.router(
                locale: const Locale('zh', 'CN'),
                supportedLocales: supportedAppLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                builder: _frame,
                routerConfig: router,
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('管理'));
          await tester.pumpAndSettle();
          expect(find.byType(SelfContentManagementView), findsOneWidget);
          final item = kind == EditKind.node ? _node : _chain;
          await tester.tap(find.text(item.name));
          await tester.pumpAndSettle();
          expect(
            find.text(
              '${kind.name}:${kind == EditKind.node ? 'node-id' : 'chain-id'}',
            ),
            findsOneWidget,
          );
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
}
