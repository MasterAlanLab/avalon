import 'package:av_design/av_design.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('each visible code slot selects its digit for correction', (
    tester,
  ) async {
    final email = TextEditingController();
    final code = TextEditingController(text: '012345');
    addTearDown(email.dispose);
    addTearDown(code.dispose);
    var submissions = 0;
    await tester.pumpWidget(
      CupertinoApp(
        home: AvTheme(
          colors: AvColors.light,
          child: Center(
            child: SizedBox(
              width: 390,
              child: SingleChildScrollView(
                child: AvLoginForm(
                  title: 'Check your inbox',
                  subtitle: 'We sent a verification code to',
                  emailLabel: 'Email address',
                  emailPlaceholder: 'name@example.com',
                  codeLabel: '6-digit verification code',
                  submitLabel: 'Sign in',
                  helper: 'Valid for 10 minutes.',
                  emailController: email,
                  codeController: code,
                  showCode: true,
                  submitEnabled: true,
                  busy: false,
                  onSubmit: () => submissions++,
                  onChanged: () {},
                  codeKey: const ValueKey('code'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final field = find.byKey(const ValueKey('code'));
    final box = tester.getRect(field);
    final pitch = (box.width + 8) / 6;
    final slotWidth = pitch - 8;
    for (final slot in [0, 2, 5]) {
      await tester.tapAt(
        Offset(box.left + slot * pitch + slotWidth / 2, box.center.dy),
      );
      await tester.pump();
      expect(
        code.selection,
        TextSelection(baseOffset: slot, extentOffset: slot + 1),
      );
    }

    // The keyboard replaces the selected last digit, including when all six
    // slots are already occupied. Leading zero and explicit submit survive.
    tester.testTextInput.updateEditingValue(
      code.value.copyWith(
        text:
            '${code.selection.textBefore(code.text)}9${code.selection.textAfter(code.text)}',
        selection: const TextSelection.collapsed(offset: 6),
      ),
    );
    await tester.pump();
    expect(code.text, '012349');

    await tester.tapAt(
      Offset(box.left + 2 * pitch + slotWidth / 2, box.center.dy),
    );
    await tester.pump();
    expect(code.selection, const TextSelection(baseOffset: 2, extentOffset: 3));
    tester.testTextInput.updateEditingValue(
      code.value.copyWith(
        text:
            '${code.selection.textBefore(code.text)}987654${code.selection.textAfter(code.text)}',
        selection: const TextSelection.collapsed(offset: 8),
      ),
    );
    await tester.pump();
    expect(code.text, '987654');
    expect(submissions, 0);
    expect(find.byType(CupertinoTextField), findsOneWidget);
  });
}
