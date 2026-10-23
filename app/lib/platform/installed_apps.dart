import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// An app (Android) or program (desktop) the per-app list can name
/// (PRODUCT_SPEC §3.11).
@immutable
final class InstalledApp {
  const InstalledApp({
    required this.id,
    required this.name,
    this.system = false,
  });

  /// What the rules match: the package name on Android, the path on
  /// desktop (CONFIG_PIPELINE §6).
  final String id;
  final String name;

  /// Part of the system rather than installed by the user.
  final bool system;
}

/// The apps or programs found on this device.
abstract interface class InstalledApps {
  /// Empty where nothing can be listed; programs are then added by hand.
  Future<List<InstalledApp>> list();

  static InstalledApps host() => switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.windows => const ChannelInstalledApps(),
    TargetPlatform.macOS => MacInstalledApps(),
    TargetPlatform.linux => LinuxInstalledApps(),
    _ => const NoInstalledApps(),
  };
}

final class NoInstalledApps implements InstalledApps {
  const NoInstalledApps();

  @override
  Future<List<InstalledApp>> list() async => const [];
}

/// Native app lists: Android network-capable packages or Windows executables.
final class ChannelInstalledApps implements InstalledApps {
  const ChannelInstalledApps();

  static const _channel = MethodChannel('dev.avalon/apps');

  @override
  Future<List<InstalledApp>> list() async {
    final raw = await _channel.invokeListMethod<Map<Object?, Object?>>('list');
    return [
      for (final app in raw ?? const <Map<Object?, Object?>>[])
        InstalledApp(
          id: app['id']! as String,
          name: app['name']! as String,
          system: app['system'] == true,
        ),
    ];
  }
}

/// macOS: the app bundles in the application folders.
final class MacInstalledApps implements InstalledApps {
  MacInstalledApps({List<String>? roots, String? self})
    : roots = roots ?? _defaultRoots(),
      _self = self ?? Platform.resolvedExecutable;

  final List<String> roots;

  /// This app's own executable: its bundle is not offered.
  final String _self;

  /// Folders inside a root are searched this deep (Utilities, vendor
  /// folders); bundles themselves are never entered.
  static const _maxDepth = 1;

  static List<String> _defaultRoots() => [
    '/Applications',
    '/System/Applications',
    if (Platform.environment['HOME'] case final home?) '$home/Applications',
  ];

  @override
  Future<List<InstalledApp>> list() async {
    final found = <String, InstalledApp>{};
    for (final root in roots) {
      await _scan(Directory(root), 0, found);
    }
    return found.values.toList();
  }

  Future<void> _scan(
    Directory dir,
    int depth,
    Map<String, InstalledApp> found,
  ) async {
    final List<FileSystemEntity> entries;
    try {
      entries = await dir.list(followLinks: false).toList();
    } on FileSystemException {
      return; // Missing or unreadable: nothing to offer from here.
    }
    for (final entry in entries) {
      final name = entry.path.substring(entry.path.lastIndexOf('/') + 1);
      if (name.startsWith('.')) continue;
      if (!name.endsWith('.app')) {
        if (entry is Directory && depth < _maxDepth) {
          await _scan(entry, depth + 1, found);
        }
        continue;
      }
      // The rules see the real path: Safari, for one, is a link into the
      // system volume.
      final String path;
      try {
        path = await entry.resolveSymbolicLinks();
      } on FileSystemException {
        continue;
      }
      if (!await FileSystemEntity.isDirectory(path)) continue;
      if (_self.startsWith('$path/')) continue;
      found.putIfAbsent(
        path,
        () => InstalledApp(
          id: path,
          name: name.substring(0, name.length - '.app'.length),
          system: path.startsWith('/System/'),
        ),
      );
    }
  }
}

/// XDG desktop entries, with higher-priority user entries masking system ones.
/// Exec is parsed as data; listing never executes a desktop entry.
final class LinuxInstalledApps implements InstalledApps {
  LinuxInstalledApps({
    List<String>? roots,
    Map<String, String>? environment,
    String? self,
  }) : environment = environment ?? Platform.environment,
       roots = roots ?? _roots(environment ?? Platform.environment),
       self = self ?? Platform.resolvedExecutable;

  final List<String> roots;
  final Map<String, String> environment;
  final String self;

  static List<String> _roots(Map<String, String> env) {
    final home = env['XDG_DATA_HOME'];
    final dirs = env['XDG_DATA_DIRS'];
    return [
      '${home != null && home.startsWith('/') ? home : '${env['HOME']}/.local/share'}/applications',
      for (final dir
          in (dirs == null || dirs.isEmpty
                  ? '/usr/local/share:/usr/share'
                  : dirs)
              .split(':'))
        if (dir.startsWith('/')) '$dir/applications',
    ];
  }

  @override
  Future<List<InstalledApp>> list() async {
    final seen = <String>{};
    final found = <String, InstalledApp>{};
    for (final root in roots) {
      final List<FileSystemEntity> entries;
      try {
        entries = await Directory(
          root,
        ).list(recursive: true, followLinks: false).toList();
      } on FileSystemException {
        continue;
      }
      entries.sort((a, b) => a.path.compareTo(b.path));
      for (final entry in entries) {
        if (entry is Directory || !entry.path.endsWith('.desktop')) continue;
        final id = entry.path.substring(root.length + 1).replaceAll('/', '-');
        if (!seen.add(id)) continue;
        final Map<String, String> fields;
        try {
          fields = _desktopEntry(await File(entry.path).readAsLines());
        } on FileSystemException {
          continue;
        } on FormatException {
          continue;
        }
        if (fields['Type'] != 'Application' ||
            fields['Hidden'] == 'true' ||
            fields['NoDisplay'] == 'true') {
          continue;
        }
        final desktops = (environment['XDG_CURRENT_DESKTOP'] ?? '').split(':');
        if (fields['OnlyShowIn'] case final only?) {
          if (!only.split(';').any(desktops.contains)) continue;
        }
        if (fields['NotShowIn'] case final excluded?) {
          if (excluded.split(';').any(desktops.contains)) continue;
        }
        if (fields['TryExec'] case final tryExec?) {
          if (await _executable(tryExec) == null) continue;
        }
        final words = _execWords(fields['Exec'] ?? '');
        if (words == null || words.isEmpty) continue;
        var command = words.first;
        // Common env launchers: skip assignments, never evaluate expansions.
        if (command == 'env' || command == '/usr/bin/env') {
          final args = words.skip(1).toList();
          while (args.isNotEmpty &&
              (args.first.contains('=') || args.first == '--')) {
            args.removeAt(0);
          }
          if (args.isEmpty || args.first.startsWith('-')) continue;
          command = args.first;
        }
        final path = await _executable(command);
        if (path == null || path == self) continue;
        final locale =
            (environment['LC_ALL'] ??
                    environment['LC_MESSAGES'] ??
                    environment['LANG'] ??
                    '')
                .split('.')
                .first;
        final name =
            fields['Name[$locale]'] ??
            fields['Name[${locale.split('_').first}]'] ??
            fields['Name'];
        if (name == null || name.isEmpty) continue;
        found.putIfAbsent(path, () => InstalledApp(id: path, name: name));
      }
    }
    return found.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<String?> _executable(String name) async {
    if (name.isEmpty || name.contains('%') || name.contains('\u0000')) {
      return null;
    }
    final candidates = name.startsWith('/')
        ? [name]
        : name.contains('/')
        ? const <String>[]
        : [
            for (final dir in (environment['PATH'] ?? '/usr/bin:/bin').split(
              ':',
            ))
              if (dir.startsWith('/')) '$dir/$name',
          ];
    for (final candidate in candidates) {
      try {
        final file = File(candidate);
        final stat = await file.stat();
        if (stat.type != FileSystemEntityType.file || stat.mode & 0x49 == 0) {
          continue;
        }
        return await file.resolveSymbolicLinks();
      } on FileSystemException {
        continue;
      }
    }
    return null;
  }
}

Map<String, String> _desktopEntry(List<String> lines) {
  final result = <String, String>{};
  var application = false;
  for (final line in lines) {
    if (line.startsWith('[')) {
      application = line.trim() == '[Desktop Entry]';
      continue;
    }
    if (!application || line.startsWith('#')) continue;
    final equal = line.indexOf('=');
    if (equal <= 0) continue;
    result[line.substring(0, equal).trim()] = line
        .substring(equal + 1)
        .replaceAll(r'\s', ' ')
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\t', '\t')
        .replaceAll(r'\r', '\r')
        .replaceAll(r'\\', r'\');
  }
  return result;
}

List<String>? _execWords(String text) {
  final words = <String>[];
  var word = StringBuffer();
  var quoted = false;
  var escaped = false;
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    if (escaped) {
      word.write(char);
      escaped = false;
    } else if (char == r'\') {
      escaped = true;
    } else if (char == '"') {
      quoted = !quoted;
    } else if (!quoted && (char == ' ' || char == '\t' || char == '\n')) {
      if (word.isNotEmpty) {
        words.add(word.toString());
        word = StringBuffer();
      }
    } else {
      word.write(char);
    }
  }
  if (quoted || escaped) return null;
  if (word.isNotEmpty) words.add(word.toString());
  return words;
}
