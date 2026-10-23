import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

/// 「刚刚」「5 分钟前」「3 小时前」「2 天前」 for [time] seen at [now].
String relativeTime(AppLocalizations l, DateTime time, DateTime now) {
  final d = now.difference(time);
  if (d.inMinutes < 1) return l.justNow;
  if (d.inHours < 1) return l.minutesAgo(d.inMinutes);
  if (d.inDays < 1) return l.hoursAgo(d.inHours);
  return l.daysAgo(d.inDays);
}

/// Binary units, one decimal unless whole: `128.4 GB`, `500 GB`, `12 MB`.
String formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final rounded = (value * 10).round() / 10;
  final text = rounded == rounded.roundToDouble()
      ? rounded.round().toString()
      : rounded.toStringAsFixed(1);
  return '$text ${units[unit]}';
}

/// A transfer rate as the dashboard shows it: `0 KB/s`, `512 KB/s`,
/// `1.2 MB/s`.
String formatSpeed(int bytesPerSecond) {
  final kb = bytesPerSecond / 1024;
  return kb >= 1024
      ? '${(kb / 1024).toStringAsFixed(1)} MB/s'
      : '${kb.round()} KB/s';
}

/// `00:12:34`; hours keep counting past a day.
String formatElapsed(Duration elapsed) {
  String two(int n) => n.toString().padLeft(2, '0');
  final seconds = elapsed.isNegative ? 0 : elapsed.inSeconds;
  return '${two(seconds ~/ 3600)}:${two(seconds ~/ 60 % 60)}:${two(seconds % 60)}';
}

/// `2026-12-31` in local time.
String formatDate(DateTime date) =>
    DateFormat('yyyy-MM-dd').format(date.toLocal());
