import 'package:av_design/av_design.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget Function(BuildContext) body) {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      CupertinoApp(
        builder: (context, child) =>
            AvTheme(colors: AvColors.light, child: child!),
        home: AvDensity.desktop(child: Builder(builder: body)),
      ),
    );
  }

  const actions = [AvAction('编辑'), AvAction('删除', destructive: true)];

  testWidgets('context menu dispatches the chosen action', (tester) async {
    int? chosen;
    await pump(
      tester,
      (context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTapUp: (d) async => chosen = await showAvItemMenu(
          context,
          actions: actions,
          cancel: '取消',
          position: d.globalPosition,
        ),
        child: const SizedBox.expand(),
      ),
    );
    await tester.tapAt(const Offset(100, 120), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(chosen, 1);
  });
}
