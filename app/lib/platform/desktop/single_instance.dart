import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// One app per user (PRODUCT_SPEC §7): the first instance holds a lock file
/// and listens on a loopback port it writes down; a second one finds the
/// lock taken, asks the first to show its window and exits.
final class SingleInstance {
  SingleInstance._(this._lock, this._server);

  final RandomAccessFile _lock;
  final ServerSocket _server;

  static const _show = 'show';

  /// The lock in [dir]; null when another instance has it (it has been
  /// asked to show itself). [onShow] runs when a later one asks.
  static Future<SingleInstance?> claim(
    String dir, {
    required void Function() onShow,
  }) async {
    await Directory(dir).create(recursive: true);
    final lock = await File('$dir/instance.lock').open(mode: FileMode.append);
    try {
      await lock.lock(FileLock.exclusive);
    } on FileSystemException {
      await lock.close();
      await _askToShow(dir);
      return null;
    }
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    await File('$dir/instance.port').writeAsString('${server.port}');
    server.listen((client) {
      client
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              if (line == _show) onShow();
              client.destroy();
            },
            onError: (_) => client.destroy(),
            onDone: client.destroy,
          );
    });
    return SingleInstance._(lock, server);
  }

  static Future<void> _askToShow(String dir) async {
    Socket? socket;
    try {
      final port = int.parse(await File('$dir/instance.port').readAsString());
      socket = await Socket.connect(
        InternetAddress.loopbackIPv4,
        port,
        timeout: const Duration(seconds: 2),
      );
      socket.writeln(_show);
      await socket.flush();
      await socket.close().timeout(const Duration(seconds: 2));
    } on Object {
      // The other one is going away; nothing to show.
    } finally {
      socket?.destroy();
    }
  }

  Future<void> release() async {
    await _server.close();
    await _lock.unlock();
    await _lock.close();
  }
}
