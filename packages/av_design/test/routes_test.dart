import 'dart:async';

import 'package:av_design/av_design.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

const _a = Key('a');
const _b = Key('b');

Widget _page(Key key, String label) => ColoredBox(
  key: key,
  color: const Color(0xFFF2F2F7),
  child: Center(child: Text(label)),
);

Future<NavigatorState> _app(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final nav = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    CupertinoApp(
      navigatorKey: nav,
      onGenerateRoute: (s) => AvPageRoute<void>(builder: (_) => _page(_a, 'A')),
    ),
  );
  return nav.currentState!;
}

void main() {
  testWidgets('long back swipe returns to the previous page', (tester) async {
    final nav = await _app(tester);
    unawaited(nav.push(AvPageRoute<void>(builder: (_) => _page(_b, 'B'))));
    await tester.pumpAndSettle();

    final g = await tester.startGesture(const Offset(5, 400));
    await g.moveBy(const Offset(40, 0));
    await g.moveBy(const Offset(100, 0));
    await tester.pump();
    await g.moveBy(const Offset(100, 0));
    await tester.pump();

    await tester.pump(const Duration(seconds: 1)); // slow release
    await g.up();
    await tester.pumpAndSettle();
    expect(find.byKey(_b), findsNothing);
    expect(find.byKey(_a), findsOneWidget);
  });

  testWidgets('short swipe springs back', (tester) async {
    final nav = await _app(tester);
    unawaited(nav.push(AvPageRoute<void>(builder: (_) => _page(_b, 'B'))));
    await tester.pumpAndSettle();
    final g = await tester.startGesture(const Offset(5, 400));
    await g.moveBy(const Offset(40, 0));
    await g.moveBy(const Offset(40, 0));
    await tester.pump(const Duration(seconds: 1));
    await g.up();
    await tester.pumpAndSettle();
    expect(find.byKey(_b), findsOneWidget);
    expect(nav.canPop(), isTrue);
  });

  testWidgets('AvPage drives a Navigator declaratively', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    var pages = <Page<void>>[
      const AvPage(key: ValueKey('a'), child: Text('A')),
    ];
    late StateSetter setPages;
    await tester.pumpWidget(
      CupertinoApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            setPages = setState;
            return Navigator(
              pages: pages,
              onDidRemovePage: (page) =>
                  setState(() => pages = [...pages]..remove(page)),
            );
          },
        ),
      ),
    );
    setPages(
      () => pages = [
        ...pages,
        const AvPage(key: ValueKey('b'), child: Text('B')),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text('B'), findsOneWidget);
    // Updating the page in place updates the content.
    setPages(
      () => pages = [
        pages.first,
        const AvPage(key: ValueKey('b'), child: Text('B2')),
      ],
    );
    await tester.pump();
    expect(find.text('B2'), findsOneWidget);
  });
}
