import 'dart:ffi';
import 'dart:io';

import 'package:avalon/runtime/host/windows_host.dart';
import 'package:avalon/runtime/host/windows_native.dart';
import 'package:avalon/runtime/host_protocol.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const native = WindowsNative();
  const helper = r'C:\Program Files\Avalon\avalon-host.exe';
  final invalidArguments = isA<WindowsNativeException>().having(
    (error) => error.code,
    'code',
    'invalidArguments',
  );

  test('rejects remote pipe endpoints and multiple request lines', () {
    expect(
      () => native.exchange(
        pipeName: r'\\another-computer\pipe\Avalon',
        line: '{}',
        expectedHelperPath: helper,
      ),
      throwsA(invalidArguments),
    );
    expect(
      () => native.exchange(
        pipeName: r'\\.\pipe\Avalon',
        line: '{}\n{}',
        expectedHelperPath: helper,
      ),
      throwsA(invalidArguments),
    );
  });

  test('rejects executable search and truncated UAC arguments', () {
    expect(
      () => native.elevate('avalon-host.exe', ['install']),
      throwsA(invalidArguments),
    );
    expect(
      () => native.elevate(helper, ['install\u0000uninstall']),
      throwsA(invalidArguments),
    );
  });

  test(
    'preserves permission and uncertain-delivery error categories',
    () async {
      final info = WindowsHostInfo.fromJson({
        'sid': 'S-1-5-21-1-2-3-1001',
        'userStateDir': r'C:\Users\User\Avalon',
        'serviceStateDir': r'C:\Users\User\Avalon\service',
        'userPipe': r'\\.\pipe\Avalon-user',
        'servicePipe': r'\\.\pipe\Avalon-service',
        'serviceName': 'AvalonHelper_S-1-5-21-1-2-3-1001',
        'executablePath': helper,
        'userExecutablePath': helper,
        'installed': true,
        'serviceRunning': false,
      });
      for (final (nativeError, expected) in [
        (
          const WindowsNativeException('timeout', 'No acknowledgment.'),
          HostErrorCode.timeout,
        ),
        (
          const WindowsNativeException('untrustedServer', 'Identity mismatch.'),
          HostErrorCode.permissionDenied,
        ),
        (
          const WindowsNativeException(
            'windowsApi',
            'Access denied.',
            win32Error: 5,
          ),
          HostErrorCode.permissionDenied,
        ),
        for (final code in [2, 3, 231])
          (
            WindowsNativeException(
              'windowsApi',
              'No endpoint.',
              win32Error: code,
            ),
            HostErrorCode.unreachable,
          ),
      ]) {
        final backend = WindowsProcessBackend(
          native: _FailingWindowsNative(nativeError),
          helperPath: helper,
        );
        await expectLater(
          backend.exchange(info, false, 'snapshot', const {}),
          throwsA(
            isA<HostException>().having(
              (error) => error.error.code,
              'host error category for ${nativeError.code}',
              expected,
            ),
          ),
        );
      }
    },
  );

  test(
    'UAC arguments round-trip through the Windows argument parser',
    () {
      final arguments = [
        helper,
        'install',
        '',
        'with spaces',
        '中文路径',
        'a"b',
        'one\\"two',
        'C:\\ending with slash\\',
        r'$HOME & echo unexpected | "quoted"',
      ];
      using((arena) {
        final parse = DynamicLibrary.open('shell32.dll')
            .lookupFunction<
              Pointer<Pointer<Utf16>> Function(Pointer<Utf16>, Pointer<Int32>),
              Pointer<Pointer<Utf16>> Function(Pointer<Utf16>, Pointer<Int32>)
            >('CommandLineToArgvW');
        final free = DynamicLibrary.open('kernel32.dll')
            .lookupFunction<
              Pointer<Void> Function(Pointer<Void>),
              Pointer<Void> Function(Pointer<Void>)
            >('LocalFree');
        final count = arena<Int32>();
        final parsed = parse(
          WindowsNative.commandLineArguments(
            arguments,
          ).toNativeUtf16(allocator: arena),
          count,
        );
        expect(parsed, isNot(nullptr));
        try {
          expect([
            for (var index = 0; index < count.value; index++)
              parsed[index].toDartString(),
          ], arguments);
        } finally {
          free(parsed.cast());
        }
      });
    },
    skip: !Platform.isWindows,
  );
}

class _FailingWindowsNative extends WindowsNative {
  const _FailingWindowsNative(this.error);

  final WindowsNativeException error;

  @override
  Future<String> exchange({
    required String pipeName,
    required String line,
    required String expectedHelperPath,
    String? serviceName,
    Duration timeout = const Duration(seconds: 45),
  }) async => throw error;
}
