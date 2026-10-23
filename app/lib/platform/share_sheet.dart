import 'dart:io';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// The system's share sheet (PRODUCT_SPEC §3.8 «分享»).
abstract interface class ShareSheet {
  /// Offers a text file to other apps; false when the user cancelled.
  Future<bool> shareFile({required String name, required Uint8List bytes});
}

final class SystemShareSheet implements ShareSheet {
  const SystemShareSheet();

  @override
  Future<bool> shareFile({
    required String name,
    required Uint8List bytes,
  }) async {
    // A real file: some apps refuse data without a name.
    final file = File('${Directory.systemTemp.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    try {
      final result = await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: 'text/plain')]),
      );
      return result.status != ShareResultStatus.dismissed;
    } finally {
      // The receiving app has copied it by now on Android and iOS.
      if (file.existsSync()) await file.delete();
    }
  }
}
