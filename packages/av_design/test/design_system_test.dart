import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {AvColors colors = AvColors.light}) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: const MediaQueryData(),
    child: AvTheme(
      colors: colors,
      child: Center(child: child),
    ),
  ),
);

void main() {
  testWidgets('switch applies the user change', (tester) async {
    var value = false;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => AvSwitch(
            value: value,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(AvSwitch));
    await tester.pumpAndSettle();
    expect(value, isTrue);
  });
}
