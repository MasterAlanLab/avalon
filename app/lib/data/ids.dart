import 'dart:math';

final _random = Random.secure();

/// A random UUID v4.
String newId() {
  final b = List<int>.generate(16, (_) => _random.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = [for (final x in b) x.toRadixString(16).padLeft(2, '0')].join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}

/// UTC milliseconds, as stored.
int nowMs() => DateTime.now().toUtc().millisecondsSinceEpoch;

DateTime? fromMs(int? ms) =>
    ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

/// The object changed since the form opened it (another window, or sync):
/// the form reloads instead of overwriting.
final class EditConflictException implements Exception {
  const EditConflictException();
}

/// Throws [EditConflictException] unless the row is as the editor saw it.
void checkUnchanged(int rowEditedAt, DateTime? ifEditedAt) {
  if (ifEditedAt != null &&
      ifEditedAt.toUtc().millisecondsSinceEpoch != rowEditedAt) {
    throw const EditConflictException();
  }
}
