import '../../services/release_updates.dart';

enum AboutFailure { check, browser }

final class AboutState {
  const AboutState({this.checking = false, this.update, this.failure});
  final bool checking;
  final ReleaseUpdate? update;
  final AboutFailure? failure;
}
