import 'dart:io';

import 'package:avalon/platform/desktop/single_instance.dart';

/// A second process is required: POSIX file locks belong to the process.
Future<void> main(List<String> arguments) async {
  final instance = await SingleInstance.claim(arguments.single, onShow: () {});
  if (instance != null) {
    await instance.release();
    stderr.writeln('The second process acquired the first instance lock.');
    exit(1);
  }
}
