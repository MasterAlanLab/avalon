import 'package:av_design/av_design.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';

void main() {
  const channel = MethodChannel('avalon/window');
  final calls = <String>[];
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return null;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  Widget host(AvDesktopPlatform platform) => Directionality(
    textDirection: TextDirection.ltr,
    child: AvTheme(
      colors: AvColors.light,
      child: Center(child: AvWindowTitleBar(platform: platform)),
    ),
  );

  testWidgets(
    'Windows title buttons call native minimize, maximize and close',
    (tester) async {
      await tester.pumpWidget(host(AvDesktopPlatform.windows));
      await tester.tap(find.byIcon(Symbols.remove_rounded));
      await tester.tap(find.byIcon(Symbols.crop_square_rounded));
      await tester.tap(find.byIcon(Symbols.close_rounded));
      await tester.pumpAndSettle();
      expect(calls, ['minimize', 'maximize', 'close']);
    },
  );

  testWidgets('Linux title buttons call native minimize and close', (
    tester,
  ) async {
    await tester.pumpWidget(host(AvDesktopPlatform.linux));
    await tester.tap(find.byIcon(Symbols.remove_rounded));
    await tester.tap(find.byIcon(Symbols.close_rounded));
    await tester.pumpAndSettle();
    expect(calls, ['minimize', 'close']);
  });

  testWidgets('empty title chrome initiates native dragging', (tester) async {
    await tester.pumpWidget(host(AvDesktopPlatform.windows));
    await tester.drag(find.text('Avalon'), const Offset(60, 0));
    await tester.pumpAndSettle();
    expect(calls, contains('startDrag'));
  });
}
