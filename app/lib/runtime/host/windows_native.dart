import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

/// No request contents or Windows-formatted error text are retained in errors.
final class WindowsNativeException implements Exception {
  const WindowsNativeException(this.code, this.message, {this.win32Error});

  final String code;
  final String message;
  final int? win32Error;

  @override
  String toString() => 'WindowsNativeException($code, $win32Error): $message';
}

/// Win32 transport only. The helper owns the engine and privileged operations.
/// DLLs and native allocations live in a worker isolate, including UAC waits.
class WindowsNative {
  const WindowsNative();

  Future<String> currentUserSid() {
    _requireWindows();
    return Isolate.run(() => _Win32().currentUserSid());
  }

  /// Each connection carries exactly one newline-delimited JSON exchange.
  /// Identity is checked on the connected handle before sending any bytes.
  Future<String> exchange({
    required String pipeName,
    required String line,
    required String expectedHelperPath,
    String? serviceName,
    Duration timeout = const Duration(seconds: 45),
  }) {
    if (!pipeName.startsWith(r'\\.\pipe\') ||
        pipeName.substring(9).isEmpty ||
        pipeName.contains('\u0000') ||
        line.contains('\n') ||
        line.contains('\r') ||
        line.isEmpty ||
        expectedHelperPath.contains('\u0000') ||
        !_isAbsoluteWindowsPath(expectedHelperPath) ||
        (serviceName != null &&
            (serviceName.isEmpty || serviceName.contains('\u0000'))) ||
        timeout <= Duration.zero) {
      throw const WindowsNativeException(
        'invalidArguments',
        'Invalid Windows helper connection parameters.',
      );
    }
    _requireWindows();
    return Isolate.run(
      () => _Win32().exchange(
        pipeName: pipeName,
        line: line,
        expectedHelperPath: expectedHelperPath,
        serviceName: serviceName,
        timeout: timeout,
      ),
    );
  }

  /// Launch a fixed helper executable through ShellExecuteExW's runas verb.
  /// Arguments go directly to the executable; no command shell is involved.
  Future<int> elevate(
    String executable,
    List<String> arguments, {
    Duration timeout = const Duration(minutes: 2),
  }) {
    if (!_isAbsoluteWindowsPath(executable) ||
        executable.contains('\u0000') ||
        timeout <= Duration.zero) {
      throw const WindowsNativeException(
        'invalidArguments',
        'Invalid Windows helper elevation parameters.',
      );
    }
    final parameters = commandLineArguments(arguments);
    _requireWindows();
    return Isolate.run(() => _Win32().elevate(executable, parameters, timeout));
  }

  /// Windows CommandLineToArgvW/CRT escaping, including empty arguments,
  /// embedded quotes, and backslashes immediately before a closing quote.
  static String commandLineArguments(List<String> arguments) {
    return arguments
        .map((argument) {
          if (argument.contains('\u0000')) {
            throw const WindowsNativeException(
              'invalidArguments',
              'A Windows helper argument contains a null character.',
            );
          }
          final result = StringBuffer('"');
          var slashes = 0;
          for (final unit in argument.codeUnits) {
            if (unit == 92) {
              slashes++;
              continue;
            }
            result.write('\\' * (unit == 34 ? slashes * 2 + 1 : slashes));
            slashes = 0;
            result.writeCharCode(unit);
          }
          result.write('\\' * (slashes * 2));
          result.write('"');
          return result.toString();
        })
        .join(' ');
  }
}

bool _isAbsoluteWindowsPath(String path) =>
    RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(path) || path.startsWith(r'\\');

void _requireWindows() {
  if (!Platform.isWindows) {
    throw const WindowsNativeException(
      'unsupportedPlatform',
      'The Windows helper transport requires Windows.',
    );
  }
}

const _maxMessageBytes = 64 * 1024 * 1024;
const _errorIoPending = 997;
const _waitTimeout = 258;

final class _Overlapped extends Struct {
  @UintPtr()
  external int internal;
  @UintPtr()
  external int internalHigh;
  @Uint32()
  external int offset;
  @Uint32()
  external int offsetHigh;
  @IntPtr()
  external int event;
}

final class _ShellExecuteInfo extends Struct {
  @Uint32()
  external int size;
  @Uint32()
  external int mask;
  @IntPtr()
  external int window;
  external Pointer<Utf16> verb;
  external Pointer<Utf16> file;
  external Pointer<Utf16> parameters;
  external Pointer<Utf16> directory;
  @Int32()
  external int show;
  @IntPtr()
  external int instance;
  external Pointer<Void> idList;
  external Pointer<Utf16> className;
  @IntPtr()
  external int classKey;
  @Uint32()
  external int hotKey;
  @IntPtr()
  external int iconOrMonitor;
  @IntPtr()
  external int process;
}

final class _ServiceStatus extends Struct {
  @Uint32()
  external int type;
  @Uint32()
  external int state;
  @Uint32()
  external int controls;
  @Uint32()
  external int win32ExitCode;
  @Uint32()
  external int serviceExitCode;
  @Uint32()
  external int checkpoint;
  @Uint32()
  external int waitHint;
  @Uint32()
  external int processId;
  @Uint32()
  external int flags;
}

final class _ServiceConfig extends Struct {
  @Uint32()
  external int type;
  @Uint32()
  external int startType;
  @Uint32()
  external int errorControl;
  external Pointer<Utf16> binaryPath;
  external Pointer<Utf16> loadOrderGroup;
  @Uint32()
  external int tagId;
  external Pointer<Utf16> dependencies;
  external Pointer<Utf16> account;
  external Pointer<Utf16> displayName;
}

class _Win32 {
  final _kernel = DynamicLibrary.open('kernel32.dll');
  final _advapi = DynamicLibrary.open('advapi32.dll');

  late final _lastError = _kernel
      .lookupFunction<Uint32 Function(), int Function()>('GetLastError');
  late final _close = _kernel
      .lookupFunction<Int32 Function(IntPtr), int Function(int)>('CloseHandle');
  late final _wait = _kernel
      .lookupFunction<Uint32 Function(IntPtr, Uint32), int Function(int, int)>(
        'WaitForSingleObject',
      );
  late final _openFile = _kernel
      .lookupFunction<
        IntPtr Function(
          Pointer<Utf16>,
          Uint32,
          Uint32,
          Pointer<Void>,
          Uint32,
          Uint32,
          IntPtr,
        ),
        int Function(Pointer<Utf16>, int, int, Pointer<Void>, int, int, int)
      >('CreateFileW');
  late final _waitPipe = _kernel
      .lookupFunction<
        Int32 Function(Pointer<Utf16>, Uint32),
        int Function(Pointer<Utf16>, int)
      >('WaitNamedPipeW');
  late final _pipeServerPid = _kernel
      .lookupFunction<
        Int32 Function(IntPtr, Pointer<Uint32>),
        int Function(int, Pointer<Uint32>)
      >('GetNamedPipeServerProcessId');
  late final _openProcess = _kernel
      .lookupFunction<
        IntPtr Function(Uint32, Int32, Uint32),
        int Function(int, int, int)
      >('OpenProcess');
  late final _imageName = _kernel
      .lookupFunction<
        Int32 Function(IntPtr, Uint32, Pointer<Utf16>, Pointer<Uint32>),
        int Function(int, int, Pointer<Utf16>, Pointer<Uint32>)
      >('QueryFullProcessImageNameW');
  late final _openToken = _advapi
      .lookupFunction<
        Int32 Function(IntPtr, Uint32, Pointer<IntPtr>),
        int Function(int, int, Pointer<IntPtr>)
      >('OpenProcessToken');
  late final _tokenInformation = _advapi
      .lookupFunction<
        Int32 Function(IntPtr, Int32, Pointer<Void>, Uint32, Pointer<Uint32>),
        int Function(int, int, Pointer<Void>, int, Pointer<Uint32>)
      >('GetTokenInformation');
  late final _sidString = _advapi
      .lookupFunction<
        Int32 Function(Pointer<Void>, Pointer<Pointer<Utf16>>),
        int Function(Pointer<Void>, Pointer<Pointer<Utf16>>)
      >('ConvertSidToStringSidW');
  late final _localFree = _kernel
      .lookupFunction<
        Pointer<Void> Function(Pointer<Void>),
        Pointer<Void> Function(Pointer<Void>)
      >('LocalFree');
  late final _createEvent = _kernel
      .lookupFunction<
        IntPtr Function(Pointer<Void>, Int32, Int32, Pointer<Utf16>),
        int Function(Pointer<Void>, int, int, Pointer<Utf16>)
      >('CreateEventW');
  late final _read = _kernel
      .lookupFunction<
        Int32 Function(
          IntPtr,
          Pointer<Uint8>,
          Uint32,
          Pointer<Uint32>,
          Pointer<_Overlapped>,
        ),
        int Function(
          int,
          Pointer<Uint8>,
          int,
          Pointer<Uint32>,
          Pointer<_Overlapped>,
        )
      >('ReadFile');
  late final _write = _kernel
      .lookupFunction<
        Int32 Function(
          IntPtr,
          Pointer<Uint8>,
          Uint32,
          Pointer<Uint32>,
          Pointer<_Overlapped>,
        ),
        int Function(
          int,
          Pointer<Uint8>,
          int,
          Pointer<Uint32>,
          Pointer<_Overlapped>,
        )
      >('WriteFile');
  late final _overlappedResult = _kernel
      .lookupFunction<
        Int32 Function(IntPtr, Pointer<_Overlapped>, Pointer<Uint32>, Int32),
        int Function(int, Pointer<_Overlapped>, Pointer<Uint32>, int)
      >('GetOverlappedResult');
  late final _cancel = _kernel
      .lookupFunction<
        Int32 Function(IntPtr, Pointer<_Overlapped>),
        int Function(int, Pointer<_Overlapped>)
      >('CancelIoEx');

  Never _fail(String operation, [int? error]) => throw WindowsNativeException(
    'windowsApi',
    'Windows helper $operation failed.',
    win32Error: error ?? _lastError(),
  );

  String currentUserSid() =>
      _processSid(-1); // GetCurrentProcess pseudo-handle.

  String _processSid(int process) => using((arena) {
    final token = arena<IntPtr>();
    if (_openToken(process, 0x0008, token) == 0) _fail('token access');
    try {
      final needed = arena<Uint32>();
      _tokenInformation(token.value, 1, nullptr, 0, needed); // TokenUser.
      if (needed.value == 0 || needed.value > 65536) _fail('token sizing');
      final information = arena<Uint8>(needed.value);
      if (_tokenInformation(
            token.value,
            1,
            information.cast(),
            needed.value,
            needed,
          ) ==
          0) {
        _fail('token query');
      }
      final sid = information.cast<Pointer<Void>>().value;
      final result = arena<Pointer<Utf16>>();
      if (_sidString(sid, result) == 0) _fail('SID conversion');
      try {
        return result.value.toDartString();
      } finally {
        _localFree(result.value.cast());
      }
    } finally {
      _close(token.value);
    }
  });

  String exchange({
    required String pipeName,
    required String line,
    required String expectedHelperPath,
    required String? serviceName,
    required Duration timeout,
  }) => using((arena) {
    final bytes = utf8.encode('$line\n');
    if (bytes.length > _maxMessageBytes) {
      throw const WindowsNativeException(
        'messageTooLarge',
        'Windows helper request exceeds the message limit.',
      );
    }
    final clock = Stopwatch()..start();
    final pipePath = pipeName.toNativeUtf16(allocator: arena);
    var pipe = -1;
    while (pipe == -1) {
      _remaining(clock, timeout);
      // FILE_READ_DATA | FILE_WRITE_DATA | FILE_READ_ATTRIBUTES | SYNCHRONIZE.
      // GENERIC_WRITE also permits FILE_CREATE_PIPE_INSTANCE: never request it.
      // SECURITY_SQOS_PRESENT | SECURITY_IDENTIFICATION forbids impersonation.
      pipe = _openFile(
        pipePath,
        0x00100083,
        0,
        nullptr,
        3, // OPEN_EXISTING.
        0x40110000, // FILE_FLAG_OVERLAPPED + SQOS flags.
        0,
      );
      if (pipe != -1) break;
      final error = _lastError();
      // A missing endpoint is an unreachable host, not an uncertain command
      // timeout: no request was sent. The coordinator can start its helper.
      if (error != 231) _fail('pipe connection', error);
      if (_waitPipe(pipePath, math.min(100, _remaining(clock, timeout))) == 0) {
        final waitError = _lastError();
        if (waitError != 2 && waitError != 121 && waitError != 231) {
          _fail('pipe availability', waitError);
        }
        // WaitNamedPipe returns immediately if the last instance disappears.
        if (waitError == 2) _fail('pipe connection', waitError);
        sleep(Duration(milliseconds: math.min(20, _remaining(clock, timeout))));
      }
    }
    try {
      _verifyServer(pipe, expectedHelperPath, serviceName, arena);
      final request = arena<Uint8>(bytes.length);
      request.asTypedList(bytes.length).setAll(0, bytes);
      var sent = 0;
      while (sent < bytes.length) {
        final count = _transfer(
          pipe,
          request + sent,
          bytes.length - sent,
          false,
          clock,
          timeout,
        );
        if (count == 0) _ioFailure('request write', 109);
        sent += count;
      }
      final response = BytesBuilder(copy: false);
      final buffer = arena<Uint8>(65536);
      while (true) {
        final count = _transfer(pipe, buffer, 65536, true, clock, timeout);
        if (count == 0) _ioFailure('response read', 109);
        final chunk = buffer.asTypedList(count);
        final newline = chunk.indexOf(10);
        final length = newline < 0 ? count : newline;
        if (response.length + length > _maxMessageBytes) {
          throw const WindowsNativeException(
            'messageTooLarge',
            'Windows helper response exceeds the message limit.',
          );
        }
        // The native buffer is reused, so BytesBuilder must own a copy.
        response.add(chunk.sublist(0, length));
        if (newline >= 0) {
          try {
            return utf8.decode(response.takeBytes());
          } on FormatException {
            throw const WindowsNativeException(
              'invalidResponse',
              'Windows helper response is not valid UTF-8.',
            );
          }
        }
      }
    } finally {
      _close(pipe);
    }
  });

  void _verifyServer(
    int pipe,
    String helperPath,
    String? serviceName,
    Arena arena,
  ) {
    final pid = arena<Uint32>();
    if (_pipeServerPid(pipe, pid) == 0) _fail('server identity');
    final process = _openProcess(0x1000, 0, pid.value);
    if (process == 0) _fail('server process access');
    try {
      if (serviceName == null && _processSid(process) != currentUserSid()) {
        _untrustedServer();
      }
      final capacity = arena<Uint32>()..value = 32768;
      final path = arena<Uint16>(capacity.value).cast<Utf16>();
      if (_imageName(process, 0, path, capacity) == 0) {
        _fail('server executable query');
      }
      if (_normalizedPath(path.toDartString(length: capacity.value)) !=
          _normalizedPath(helperPath)) {
        _untrustedServer();
      }
      if (serviceName != null &&
          _serviceProcessId(serviceName, helperPath, arena) != pid.value) {
        _untrustedServer();
      }
    } finally {
      _close(process);
    }
  }

  int _serviceProcessId(String serviceName, String helperPath, Arena arena) {
    final ownerSid = currentUserSid();
    if (serviceName != 'AvalonHelper_$ownerSid') _untrustedServer();
    final openManager = _advapi
        .lookupFunction<
          IntPtr Function(Pointer<Utf16>, Pointer<Utf16>, Uint32),
          int Function(Pointer<Utf16>, Pointer<Utf16>, int)
        >('OpenSCManagerW');
    final openService = _advapi
        .lookupFunction<
          IntPtr Function(IntPtr, Pointer<Utf16>, Uint32),
          int Function(int, Pointer<Utf16>, int)
        >('OpenServiceW');
    final query = _advapi
        .lookupFunction<
          Int32 Function(
            IntPtr,
            Int32,
            Pointer<Uint8>,
            Uint32,
            Pointer<Uint32>,
          ),
          int Function(int, int, Pointer<Uint8>, int, Pointer<Uint32>)
        >('QueryServiceStatusEx');
    final queryConfig = _advapi
        .lookupFunction<
          Int32 Function(
            IntPtr,
            Pointer<_ServiceConfig>,
            Uint32,
            Pointer<Uint32>,
          ),
          int Function(int, Pointer<_ServiceConfig>, int, Pointer<Uint32>)
        >('QueryServiceConfigW');
    final closeService = _advapi
        .lookupFunction<Int32 Function(IntPtr), int Function(int)>(
          'CloseServiceHandle',
        );
    final manager = openManager(nullptr, nullptr, 0x0001);
    if (manager == 0) _fail('service manager access');
    try {
      final service = openService(
        manager,
        serviceName.toNativeUtf16(allocator: arena),
        0x0005, // SERVICE_QUERY_STATUS | SERVICE_QUERY_CONFIG.
      );
      if (service == 0) _fail('service access');
      try {
        final status = arena<_ServiceStatus>();
        final needed = arena<Uint32>();
        queryConfig(service, nullptr, 0, needed);
        if (needed.value == 0 || needed.value > 8192) {
          _fail('service configuration sizing');
        }
        final config = arena<Uint8>(needed.value).cast<_ServiceConfig>();
        if (queryConfig(service, config, needed.value, needed) == 0) {
          _fail('service configuration query');
        }
        final account = config.ref.account.toDartString().toLowerCase();
        if (config.ref.type != 0x0010 ||
            (account != 'localsystem' && account != r'nt authority\system')) {
          _untrustedServer();
        }
        _verifyServiceCommand(
          config.ref.binaryPath.toDartString(),
          helperPath,
          ownerSid,
        );
        if (query(
              service,
              0,
              status.cast(),
              sizeOf<_ServiceStatus>(),
              needed,
            ) ==
            0) {
          _fail('service status query');
        }
        // The service PID is reliable only in these active states.
        if (![4, 5, 6, 7].contains(status.ref.state)) _untrustedServer();
        return status.ref.processId;
      } finally {
        closeService(service);
      }
    } finally {
      closeService(manager);
    }
  }

  void _verifyServiceCommand(
    String command,
    String helperPath,
    String ownerSid,
  ) {
    final parse = DynamicLibrary.open('shell32.dll')
        .lookupFunction<
          Pointer<Pointer<Utf16>> Function(Pointer<Utf16>, Pointer<Int32>),
          Pointer<Pointer<Utf16>> Function(Pointer<Utf16>, Pointer<Int32>)
        >('CommandLineToArgvW');
    using((arena) {
      final count = arena<Int32>();
      final arguments = parse(command.toNativeUtf16(allocator: arena), count);
      if (arguments == nullptr) _fail('service command parsing');
      try {
        if (count.value != 5 ||
            _normalizedPath(arguments[0].toDartString()) !=
                _normalizedPath(helperPath) ||
            arguments[1].toDartString() != '-windows-action' ||
            arguments[2].toDartString() != 'serve-service' ||
            arguments[3].toDartString() != '-sid' ||
            arguments[4].toDartString() != ownerSid) {
          _untrustedServer();
        }
      } finally {
        _localFree(arguments.cast());
      }
    });
  }

  Never _untrustedServer() => throw const WindowsNativeException(
    'untrustedServer',
    'The Windows helper identity could not be verified.',
  );

  int _transfer(
    int pipe,
    Pointer<Uint8> buffer,
    int length,
    bool reading,
    Stopwatch clock,
    Duration timeout,
  ) => using((arena) {
    _remaining(clock, timeout);
    final overlapped = arena<_Overlapped>();
    final transferred = arena<Uint32>();
    final event = _createEvent(nullptr, 1, 0, nullptr);
    if (event == 0) _fail('I/O event creation');
    overlapped.ref.event = event;
    try {
      final completed = (reading ? _read : _write)(
        pipe,
        buffer,
        length,
        transferred,
        overlapped,
      );
      if (completed != 0) return transferred.value;
      final error = _lastError();
      if (error != _errorIoPending) {
        _ioFailure(reading ? 'response read' : 'request write', error);
      }
      var waitResult = _waitTimeout;
      try {
        waitResult = _wait(event, _remaining(clock, timeout));
      } on WindowsNativeException {
        // Cancellation below also handles a deadline reached between calls.
      }
      if (waitResult != 0) {
        final waitError = waitResult == _waitTimeout ? null : _lastError();
        _cancel(pipe, overlapped);
        // CancelIoEx is asynchronous. Keep buffer/OVERLAPPED alive until the
        // kernel completes cancellation before freeing either allocation.
        _overlappedResult(pipe, overlapped, transferred, 1);
        if (waitResult == _waitTimeout) _timedOut();
        _fail('I/O wait', waitError);
      }
      if (_overlappedResult(pipe, overlapped, transferred, 0) == 0) {
        _ioFailure(reading ? 'response read' : 'request write');
      }
      return transferred.value;
    } finally {
      _close(event);
    }
  });

  Never _ioFailure(String operation, [int? code]) {
    final error = code ?? _lastError();
    // Once WriteFile has been issued, a disconnect cannot prove rejection.
    // Preserve the original requestId's recovery path in HostGateway.
    if (error == 109 || error == 232 || error == 233) {
      throw WindowsNativeException(
        'timeout',
        'The Windows helper disconnected before confirming the command.',
        win32Error: error,
      );
    }
    _fail(operation, error);
  }

  int elevate(String executable, String parameters, Duration timeout) =>
      using((arena) {
        final ole = DynamicLibrary.open('ole32.dll');
        final initialize = ole
            .lookupFunction<
              Int32 Function(Pointer<Void>, Uint32),
              int Function(Pointer<Void>, int)
            >('CoInitializeEx');
        final uninitialize = ole
            .lookupFunction<Void Function(), void Function()>('CoUninitialize');
        final initialized = initialize(nullptr, 0x0006) >= 0;
        try {
          final execute = DynamicLibrary.open('shell32.dll')
              .lookupFunction<
                Int32 Function(Pointer<_ShellExecuteInfo>),
                int Function(Pointer<_ShellExecuteInfo>)
              >('ShellExecuteExW');
          final info = arena<_ShellExecuteInfo>();
          info.ref
            ..size = sizeOf<_ShellExecuteInfo>()
            ..mask =
                0x00000140 // SEE_MASK_NOCLOSEPROCESS | SEE_MASK_NOASYNC.
            ..verb = 'runas'.toNativeUtf16(allocator: arena)
            ..file = executable.toNativeUtf16(allocator: arena)
            ..parameters = parameters.toNativeUtf16(allocator: arena)
            ..show = 0;
          if (execute(info) == 0) {
            final error = _lastError();
            if (error == 1223) {
              throw const WindowsNativeException(
                'permissionDenied',
                'Windows administrator permission was not granted.',
                win32Error: 1223,
              );
            }
            _fail('elevation', error);
          }
          final process = info.ref.process;
          if (process == 0) _fail('elevated process access');
          try {
            final result = _wait(process, _boundedMilliseconds(timeout));
            if (result == _waitTimeout) _timedOut();
            if (result != 0) _fail('elevated process wait');
            final exitCode = arena<Uint32>();
            final getExitCode = _kernel
                .lookupFunction<
                  Int32 Function(IntPtr, Pointer<Uint32>),
                  int Function(int, Pointer<Uint32>)
                >('GetExitCodeProcess');
            if (getExitCode(process, exitCode) == 0) {
              _fail('elevated process result');
            }
            return exitCode.value;
          } finally {
            _close(process);
          }
        } finally {
          if (initialized) uninitialize();
        }
      });
}

String _normalizedPath(String path) {
  var normalized = path.replaceAll('/', '\\').toLowerCase();
  if (normalized.startsWith(r'\\?\unc\')) {
    normalized = r'\\' + normalized.substring(8);
  } else if (normalized.startsWith(r'\\?\')) {
    normalized = normalized.substring(4);
  }
  return normalized;
}

int _remaining(Stopwatch clock, Duration timeout) {
  final remaining = timeout - clock.elapsed;
  if (remaining <= Duration.zero) _timedOut();
  return _boundedMilliseconds(remaining);
}

int _boundedMilliseconds(Duration duration) =>
    math.min(0xfffffffe, math.max(1, (duration.inMicroseconds + 999) ~/ 1000));

Never _timedOut() => throw const WindowsNativeException(
  'timeout',
  'The Windows helper operation timed out.',
);
