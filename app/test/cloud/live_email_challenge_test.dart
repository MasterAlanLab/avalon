// Opt-in 0.1.1 integration against the real loopback Cloud sandbox.
// The fixture expires only this test's challenge; no clock or quota is reset.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:avalon/cloud/api_client.dart';
import 'package:avalon/cloud/cloud_models.dart';
import 'package:flutter_test/flutter_test.dart';

final _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

void main() {
  final base = Platform.environment['AVALON_CLOUD_BASE_URL'];
  final mail = Platform.environment['AVALON_CLOUD_MAILBOX_DIR'];
  final fixture = Platform.environment['AVALON_CLOUD_CHALLENGE_FIXTURE'];
  final unconfigured = base == null && mail == null && fixture == null;
  test(
    'real Cloud 0.1.1: expiry, fifth attempt, terminal reasons and cleanup',
    () async {
      if (base != 'http://127.0.0.1:21323' || mail == null || fixture == null) {
        throw StateError('Configure the explicit local challenge sandbox.');
      }
      final fixtureFile = File(fixture);
      final mailbox = Directory(mail);
      if (!await fixtureFile.exists() || !await mailbox.exists()) {
        throw StateError('The local challenge fixture or mailbox is missing.');
      }
      final run = _ChallengeRun(
        ApiClient(
          baseUri: Uri.parse(base!),
          allowLoopbackHttp: true,
          timeout: const Duration(seconds: 5),
        ),
        mailbox,
        fixtureFile,
      );
      addTearDown(run.cleanup);
      await run.verifyIncrement();
    },
    skip: unconfigured
        ? 'Set the three explicit Cloud sandbox variables.'
        : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

final class _Challenge {
  const _Challenge(this.response, this.code);
  final EmailStartResponse response;
  final String code;
  String get id => response.challengeId;
  String get wrongCode => code == '000000' ? '000001' : '000000';
}

final class _ChallengeRun {
  _ChallengeRun(this.api, this.mailbox, this.fixture)
    : email = _temporaryEmail(),
      device = DeviceInput(
        installationId: _randomUuid(),
        name: 'Avalon challenge integration',
        os: DeviceOs.macos,
      );

  final ApiClient api;
  final Directory mailbox;
  final File fixture;
  final String email;
  final DeviceInput device;
  final challenges = <_Challenge>[];
  final issuedChallengeIds = <String>[];
  bool startRequested = false;
  String? accessToken;

  Future<_Challenge> start() async {
    final before = DateTime.now().toUtc();
    startRequested = true;
    final response = await api.emailStart(email: email);
    final after = DateTime.now().toUtc();
    if (!_uuid.hasMatch(response.challengeId)) {
      throw StateError('Invalid sandbox challenge identifier.');
    }
    // Track the server mutation before reading mail or asserting its contents.
    // A failed mailbox read must still participate in cleanup.
    issuedChallengeIds.add(response.challengeId);
    final record = await _mail(response.challengeId);
    final challenge = _Challenge(response, record.code);
    challenges.add(challenge);
    expect(response.expiresAt.isUtc, isTrue);
    expect(
      response.expiresAt.isBefore(
        before.add(const Duration(minutes: 10, seconds: -2)),
      ),
      isFalse,
    );
    expect(
      response.expiresAt.isAfter(
        after.add(const Duration(minutes: 10, seconds: 2)),
      ),
      isFalse,
    );
    expect(response.expiresAt == record.expiresAt, isTrue);
    return challenge;
  }

  Future<TokenResponse> verify(_Challenge challenge, String code) async {
    final result = await api.emailVerify(
      challengeId: challenge.id,
      code: code,
      device: device,
    );
    // Register cleanup before any assertions, never print these credentials.
    accessToken = result.accessToken;
    return result;
  }

  Future<void> rejected(
    String id,
    String code,
    EmailChallengeReason reason,
  ) async {
    try {
      final unexpected = await api.emailVerify(
        challengeId: id,
        code: code,
        device: device,
      );
      accessToken = unexpected.accessToken;
    } on CloudApiException catch (error) {
      expect(error.httpStatus, 400);
      expect(error.code, CloudErrorCode.validation);
      expect(error.reason, reason);
      return;
    }
    throw StateError('The sandbox accepted a challenge expected to fail.');
  }

  Future<void> verifyIncrement() async {
    // Challenge 1: the fifth attempt remains available for the correct code.
    final fifthCorrect = await start();
    for (var attempt = 1; attempt <= 4; attempt++) {
      await rejected(
        fifthCorrect.id,
        fifthCorrect.wrongCode,
        EmailChallengeReason.wrongCode,
      );
      await state(fifthCorrect.id, attempts: attempt, consumed: false);
    }
    await verify(fifthCorrect, fifthCorrect.code);
    await state(fifthCorrect.id, attempts: 5, consumed: true);

    // Challenge 2: a fifth wrong code exhausts it; later requests do not count.
    final exhausted = await start();
    for (var attempt = 1; attempt <= 5; attempt++) {
      await rejected(
        exhausted.id,
        exhausted.wrongCode,
        attempt == 5
            ? EmailChallengeReason.attemptsExceeded
            : EmailChallengeReason.wrongCode,
      );
    }
    await state(exhausted.id, attempts: 5, consumed: false);
    await rejected(
      exhausted.id,
      exhausted.code,
      EmailChallengeReason.attemptsExceeded,
    );
    await state(exhausted.id, attempts: 5, consumed: false);

    // Challenge 3: an explicit local fixture avoids waiting ten minutes.
    final expired = await start();
    await fixtureState(expired.id, action: 'expire');
    await rejected(expired.id, expired.code, EmailChallengeReason.expired);
    await rejected(expired.id, expired.wrongCode, EmailChallengeReason.expired);
    await state(expired.id, attempts: 0, consumed: false, expired: true);

    // Challenge 4 isolates consumed from attempt exhaustion.
    final consumed = await start();
    await verify(consumed, consumed.code);
    await rejected(consumed.id, consumed.code, EmailChallengeReason.consumed);
    await state(consumed.id, attempts: 1, consumed: true);
    final missing = _randomUuid();
    await rejected(missing, '000000', EmailChallengeReason.missing);
    final absent = await fixtureState(missing);
    expect(absent['missing'], isTrue);
  }

  Future<void> state(
    String id, {
    required int attempts,
    required bool consumed,
    bool expired = false,
  }) async {
    final value = await fixtureState(id);
    expect(value['missing'], isFalse);
    expect(value['attempts'], attempts);
    expect(value['consumed'], consumed);
    expect(value['expired'], expired);
  }

  Future<Map<String, Object?>> fixtureState(
    String id, {
    String action = 'state',
  }) async {
    if (!_uuid.hasMatch(id)) {
      throw StateError('Invalid local challenge fixture identifier.');
    }
    try {
      final result = await Process.run(
        'python3',
        [fixture.absolute.path, action, id],
        workingDirectory: fixture.parent.parent.path,
      ).timeout(const Duration(seconds: 35));
      final decoded = jsonDecode(result.stdout as String);
      if (decoded is! Map<String, Object?> ||
          decoded.length != 4 ||
          !decoded.keys.toSet().containsAll({
            'attempts',
            'consumed',
            'expired',
            'missing',
          }) ||
          decoded['missing'] is! bool ||
          result.exitCode != (decoded['missing'] == true ? 1 : 0)) {
        throw const FormatException();
      }
      return decoded;
    } on Object {
      // Child process output can contain configuration; never relay it.
      throw StateError('The local challenge fixture failed.');
    }
  }

  Future<({String code, DateTime expiresAt})> _mail(String id) async {
    final file = File('${mailbox.path}${Platform.pathSeparator}$id.json');
    final watch = Stopwatch()..start();
    while (watch.elapsed < const Duration(seconds: 5)) {
      try {
        if (await FileSystemEntity.isLink(file.path)) {
          throw StateError('Sandbox mail must be a regular file.');
        }
        if (await file.exists()) {
          if ((await file.stat()).size > 64 * 1024) {
            throw StateError('Sandbox mail exceeds its size limit.');
          }
          final decoded = jsonDecode(await file.readAsString());
          final code = decoded is Map<String, Object?> ? decoded['code'] : null;
          final rawExpiry = decoded is Map<String, Object?>
              ? decoded['expiresAt']
              : null;
          if (decoded is! Map<String, Object?> ||
              decoded['challengeId'] != id ||
              decoded['email'] != email ||
              code is! String ||
              !RegExp(r'^[0-9]{6}$').hasMatch(code) ||
              rawExpiry is! String) {
            throw const FormatException();
          }
          return (code: code, expiresAt: DateTime.parse(rawExpiry));
        }
      } on Object {
        throw StateError('Sandbox mail could not be read or validated.');
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw StateError('No sandbox mail arrived within five seconds.');
  }

  Future<void> cleanup() async {
    var failed = false;
    try {
      if (accessToken == null && issuedChallengeIds.isNotEmpty) {
        // Recover a cleanup proof if an assertion stopped before authentication.
        for (final challenge in challenges) {
          final value = await fixtureState(challenge.id);
          if (value['consumed'] == false &&
              value['expired'] == false &&
              value['attempts'] is int &&
              (value['attempts']! as int) < 5) {
            await verify(challenge, challenge.code);
            break;
          }
        }
        if (accessToken == null && issuedChallengeIds.length < 5) {
          final fresh = await start();
          await verify(fresh, fresh.code);
        }
      }
      if (issuedChallengeIds.isNotEmpty) {
        final token = accessToken;
        if (token == null) throw StateError('Cleanup proof is unavailable.');
        await api.deleteAccount(accessToken: token);
        for (final id in issuedChallengeIds) {
          final value = await fixtureState(id);
          if (value['missing'] != true) {
            throw StateError('Temporary challenges remain after cleanup.');
          }
        }
      } else if (startRequested) {
        // An invalid/lost start response may hide the server-side identifier.
        throw StateError('Challenge creation cleanup was not confirmed.');
      }
    } on Object {
      failed = true;
    } finally {
      for (final id in issuedChallengeIds) {
        try {
          final file = File('${mailbox.path}${Platform.pathSeparator}$id.json');
          if (await file.exists()) await file.delete();
        } on Object {
          failed = true;
        }
      }
      api.close();
    }
    if (failed) {
      throw StateError('Local challenge cleanup was not confirmed.');
    }
  }
}

String _temporaryEmail() =>
    'avalon-challenge-${DateTime.now().microsecondsSinceEpoch}-'
    '${_randomUuid()}@sandbox.invalid';

String _randomUuid() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((n) => n.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
