import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';

/// A file the user picked.
final class PickedFile {
  const PickedFile(this.name, this.bytes);

  final String name;
  final Uint8List bytes;
}

/// The picked file is larger than the caller accepts.
final class FileTooLargeException implements Exception {
  const FileTooLargeException();
}

/// The system's open and save dialogs (PRODUCT_SPEC §5, §3.5).
abstract interface class FileDialogs {
  /// Lets the user pick one file, with [extensions] (without dots) when
  /// given; null when cancelled. Throws [FileTooLargeException] beyond
  /// [maxBytes], before reading the file.
  Future<PickedFile?> open({List<String>? extensions, required int maxBytes});

  /// Lets the user choose where to save [bytes]; false when cancelled.
  Future<bool> save({required String name, required Uint8List bytes});

  /// Lets the user pick a program on desktop (PRODUCT_SPEC §3.11): its
  /// path as the system reports the running process, or null when cancelled.
  Future<String?> pickProgram();
}

final class SystemFileDialogs implements FileDialogs {
  const SystemFileDialogs();

  @override
  Future<PickedFile?> open({
    List<String>? extensions,
    required int maxBytes,
  }) async {
    final file = await FilePicker.pickFile(
      type: extensions == null ? FileType.any : FileType.custom,
      allowedExtensions: extensions,
    );
    if (file == null) return null;
    if (await file.xFile.length() > maxBytes) {
      throw const FileTooLargeException();
    }
    return PickedFile(file.name, await file.xFile.readAsBytes());
  }

  @override
  Future<bool> save({required String name, required Uint8List bytes}) async =>
      await FilePicker.saveFile(fileName: name, bytes: bytes) != null;

  @override
  Future<String?> pickProgram() async {
    final file = await FilePicker.pickFile(
      // macOS apps are bundles and command-line tools have no extension,
      // so only Windows can filter.
      type: Platform.isWindows ? FileType.custom : FileType.any,
      allowedExtensions: Platform.isWindows ? const ['exe'] : null,
      initialDirectory: Platform.isMacOS ? '/Applications' : null,
    );
    final path = file?.path;
    if (path == null) return null;
    // A link (Homebrew's, say) is not what the process is seen running as.
    try {
      return await File(path).resolveSymbolicLinks();
    } on FileSystemException {
      return path;
    }
  }
}

/// Reads a file dropped on the window (desktop), refusing it beyond
/// [maxBytes] before reading.
Future<PickedFile> readDroppedFile(XFile file, {required int maxBytes}) async {
  if (await file.length() > maxBytes) throw const FileTooLargeException();
  return PickedFile(file.name, await file.readAsBytes());
}
