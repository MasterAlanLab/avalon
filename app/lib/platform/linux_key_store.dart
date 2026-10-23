import 'dart:io';

import 'package:flutter/services.dart';

import '../data/vault/vault.dart';

/// Keep a Linux installation on its original backend. A file fallback is
/// selected only after the native host confirms Secret Service is unavailable;
/// an existing vault still forbids key creation in AppServices.open.
Future<MasterKeyStore> linuxKeyStore({
  Map<String, String>? environment,
  Future<bool> Function()? secretServiceAvailable,
}) async {
  final env = environment ?? Platform.environment;
  final dataHome = env['XDG_DATA_HOME'];
  final home = env['HOME'];
  if ((dataHome == null || !dataHome.startsWith('/')) &&
      (home == null || !home.startsWith('/'))) {
    throw const MasterKeyUnavailableException();
  }
  final root = dataHome != null && dataHome.startsWith('/')
      ? dataHome
      : '$home/.local/share';
  final file = File('$root/avalon/master.key');
  if (await file.exists()) return FileKeyStore(file);
  final available = await (secretServiceAvailable ?? _secretServiceAvailable)();
  return available ? const SecureStorageKeyStore() : FileKeyStore(file);
}

Future<bool> _secretServiceAvailable() async {
  try {
    final available = await const MethodChannel(
      'avalon/secure-storage',
    ).invokeMethod<bool>('secretServiceAvailable');
    if (available == null) throw const MasterKeyUnavailableException();
    return available;
  } on PlatformException {
    throw const MasterKeyUnavailableException();
  } on MissingPluginException {
    throw const MasterKeyUnavailableException();
  }
}
