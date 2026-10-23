// Renders the gallery on the V3 reference canvas:
// 390x873 at 1x (the deck screenshots show 873 pt of screen, while V3's CSS
// frame is 844), with V3's 58 pt status bar and 34 pt home indicator. Skipped
// unless requested:
//
//   flutter test --update-goldens --dart-define=AV_DECK=true tool/fidelity/deck_canvas.dart
//
// Output goes to tool/fidelity/deck/ (git-ignored); it is not a golden.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../gallery/gallery_app.dart';
import '../../gallery/gallery_state.dart';
import 'flutter_test_config.dart';

const _enabled = bool.fromEnvironment('AV_DECK');

Future<void> _render(
  WidgetTester tester,
  String id,
  Future<void> Function(WidgetTester tester)? go,
) async {
  tester.view.physicalSize = const Size(390, 873);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 58, bottom: 34);
  tester.view.viewPadding = const FakeViewPadding(top: 58, bottom: 34);
  addTearDown(tester.view.reset);
  final state = GalleryState(live: false, random: math.Random(1));
  addTearDown(state.dispose);
  await tester.pumpWidget(
    GalleryApp(
      state: state,
      fontFamily: goldenTextFamily,
      fontFamilyFallback: const [goldenCjkFamily],
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
  if (go != null) await go(tester);
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump(const Duration(milliseconds: 600));
  await expectLater(find.byType(GalleryApp), matchesGoldenFile('deck/$id.png'));
}

Future<void> _tap(WidgetTester t, Finder f) async {
  await t.tap(f);
  await t.pump();
  await t.pump(const Duration(milliseconds: 700));
}

Future<void> _openAdd(WidgetTester t, [String? segment]) async {
  await _tap(t, find.text('配置'));
  await t.tapAt(const Offset(357, 90));
  await t.pump();
  await t.pump(const Duration(milliseconds: 700));
  if (segment != null) await _tap(t, find.text(segment));
}

void main() {
  final pages = <String, Future<void> Function(WidgetTester)?>{
    '3a': null,
    '3b': (t) => _tap(t, find.text('代理')),
    '3c': (t) => _tap(t, find.text('配置')),
    '3d': (t) => _openAdd(t),
    '3e': (t) => _openAdd(t, '独立节点'),
    '3f': (t) => _openAdd(t, '代理链'),
    '3g': (t) => _tap(t, find.text('工具')),
    '3h': (t) async {
      await _tap(t, find.text('工具'));
      await _tap(t, find.text('连接'));
    },
    '3i': (t) async {
      await _tap(t, find.text('工具'));
      await _tap(t, find.text('日志'));
    },
  };
  for (final MapEntry(key: id, value: go) in pages.entries) {
    testWidgets(
      id,
      (t) => _render(t, id, go),
      skip: !_enabled || !goldenFontsAvailable,
    );
  }
}
