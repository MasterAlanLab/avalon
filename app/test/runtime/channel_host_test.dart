import 'dart:convert';

import 'package:avalon/runtime/host/channel_host.dart';
import 'package:avalon/runtime/host_protocol.dart';
import 'package:avalon/runtime/runtime_host.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dev.avalon/host');
  const host = ChannelHost();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  final methods = <String, Future<dynamic> Function()>{
    'call': () => host.call('start', '{}'),
    'facts': host.facts,
    'prepare': () => host.prepare(tun: true),
    'configure': () => host.configure(
      const HostOptions(speedNotification: false, startAtBoot: false),
    ),
    'release': host.release,
  };
  for (final entry in methods.entries) {
    test('${entry.key} preserves native UNSUPPORTED and its reason', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, entry.key);
        throw PlatformException(
          code: 'UNSUPPORTED',
          message: 'Packet Tunnel requires a device',
          details: 'simulator',
        );
      });
      await expectLater(
        entry.value(),
        throwsA(
          isA<HostException>()
              .having((e) => e.error.code, 'code', HostErrorCode.unsupported)
              .having(
                (e) => e.error.message,
                'message',
                'Packet Tunnel requires a device',
              )
              .having((e) => e.error.detail, 'detail', 'simulator'),
        ),
      );
    });
  }

  test(
    'prepare refusal stays a refusal and options preserve their JSON',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'prepare') {
          expect(call.arguments, {'tun': true});
          return false;
        }
        expect(call.method, 'configure');
        expect(jsonDecode(call.arguments as String), {
          'speedNotification': true,
          'startAtBoot': false,
          'systemProxy': false,
          'mixedPort': 7890,
          'language': 'zh',
        });
        return null;
      });
      expect(await host.prepare(tun: true), isFalse);
      await host.configure(
        const HostOptions(
          speedNotification: true,
          startAtBoot: false,
          language: 'zh',
        ),
      );
    },
  );

  test('unknown transport errors are unreachable', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(
        code: 'native-unavailable',
        message: 'not connected',
      );
    });
    await expectLater(
      host.facts(),
      throwsA(
        isA<HostException>().having(
          (e) => e.error.code,
          'code',
          HostErrorCode.unreachable,
        ),
      ),
    );
  });

  test('missing native registration is reported as unreachable', () async {
    await expectLater(
      host.prepare(tun: true),
      throwsA(
        isA<HostException>().having(
          (e) => e.error.code,
          'code',
          HostErrorCode.unreachable,
        ),
      ),
    );
  });
}
