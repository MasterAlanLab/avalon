// Adding a configuration from a local file (PRODUCT_SPEC §3.5).
import 'dart:convert';
import 'dart:typed_data';

import 'package:av_core/av_core.dart';
import 'package:avalon/app/providers.dart';
import 'package:avalon/features/add/add_state.dart';
import 'package:avalon/features/add/add_view_model.dart';
import 'package:avalon/platform/file_dialogs.dart';
import 'package:avalon/services/import_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _links = '''
trojan://fake-password-a@a.example.com:443#A
trojan://fake-password-b@b.example.com:443#B
''';

/// Hands out whatever the test puts in [next].
final class _Dialogs implements FileDialogs {
  Object? next;

  @override
  Future<PickedFile?> open({
    List<String>? extensions,
    required int maxBytes,
  }) async {
    final value = next;
    if (value is Exception) throw value;
    return value as PickedFile?;
  }

  @override
  Future<bool> save({required String name, required Uint8List bytes}) async =>
      true;

  @override
  Future<String?> pickProgram() async => null;
}

PickedFile _file(String name, String text) =>
    PickedFile(name, Uint8List.fromList(utf8.encode(text)));

void main() {
  late Harness h;
  late ProviderContainer container;
  late _Dialogs dialogs;

  setUp(() async {
    dialogs = _Dialogs();
    h = await Harness.start(
      overrides: [fileDialogsProvider.overrideWithValue(dialogs)],
    );
    container = h.container;
    container.listen(addViewModelProvider, (_, _) {});
  });
  tearDown(() => h.stop());

  AddViewModel form() => container.read(addViewModelProvider.notifier);
  AddState state() => container.read(addViewModelProvider);

  test('a picked file is imported, named after it and selected', () async {
    form().toggleMethod(SubscriptionMethod.file);
    expect(state().importsFile, isTrue);
    expect(state().canSave, isFalse);

    dialogs.next = _file('home.yaml', _links);
    await form().pickFile();
    expect(state().file!.name, 'home.yaml');
    expect(state().canSave, isTrue);

    final before = h.requests;
    expect(await form().saveSubscription(defaultName: '新订阅'), isNotNull);
    expect(h.requests, before);
    final c = (await h.services.configurations.watchAll().first).firstWhere(
      (c) => c.kind == ConfigurationKind.file,
    );
    expect(c.name, 'home');
    expect(c.autoUpdate, isFalse);
    expect((await h.services.settings.device()).selectedConfigurationId, c.id);
  });

  test('the link is used again once the file method is off', () async {
    dialogs.next = _file('home.yaml', _links);
    await form().pickFile();
    form().toggleMethod(SubscriptionMethod.file);
    expect(state().importsFile, isFalse);
    expect(state().canSave, isFalse); // No link typed.
    form().clearFile();
    expect(state().file, isNull);
  });

  test('cancelling the dialog changes nothing', () async {
    dialogs.next = null;
    await form().pickFile();
    expect(state().file, isNull);
    expect(state().error, isNull);
  });

  test('a file that is too large or not text says so', () async {
    dialogs.next = const FileTooLargeException();
    await form().pickFile();
    expect(state().error!.code, 'fetch.tooLarge');

    form().setFile(PickedFile('x.yaml', Uint8List.fromList([0xC3, 0x28])));
    expect(await form().saveSubscription(defaultName: '新订阅'), isNull);
    expect(state().error!.code, 'import.malformed');

    form().setFile(_file('x.yaml', 'not a configuration'));
    expect(await form().saveSubscription(defaultName: '新订阅'), isNull);
    expect(state().error!.code, 'import.unknownFormat');
  });

  test('a scanned subscription link fills the link and stops scanning', () {
    form().toggleMethod(SubscriptionMethod.scan);
    expect(state().method, SubscriptionMethod.scan);

    // A share link is not a subscription: reported, scanning goes on.
    expect(form().scanned('vless://00000000@a.example.com:443#A'), isFalse);
    expect(state().error!.code, 'scan.notSubscription');
    expect(state().method, SubscriptionMethod.scan);

    expect(form().scanned(' https://sub.example.com/s?token=fake '), isTrue);
    expect(state().url, 'https://sub.example.com/s?token=fake');
    expect(state().method, SubscriptionMethod.link);
    expect(state().error, isNull);
    expect(state().canSave, isTrue);
  });

  test('text: UTF-8, with or without a byte-order mark', () {
    expect(ImportService.decodeText(utf8.encode('中文')), '中文');
    expect(
      ImportService.decodeText([0xEF, 0xBB, 0xBF, ...utf8.encode('a')]),
      'a',
    );
    expect(
      () => ImportService.decodeText([0xFF]),
      throwsA(isA<ImportException>()),
    );
  });
}
