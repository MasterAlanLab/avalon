// Shared set-up for view-model tests: the real services over an in-memory
// database and a local subscription server.
import 'dart:io';

import 'package:av_core/av_core.dart';
import 'package:avalon/app/app_services_running.dart';
import 'package:avalon/app/providers.dart';
import 'package:avalon/app/rule_set_updates.dart';
import 'package:avalon/app/services.dart';
import 'package:avalon/app/subscription_updates.dart';
import 'package:avalon/data/database/database.dart';
import 'package:avalon/data/vault/vault.dart';
import 'package:avalon/runtime/exit_ip_probe.dart';
import 'package:avalon/runtime/runtime_coordinator.dart';
import 'package:avalon/runtime/runtime_host.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

final class Harness {
  Harness._(this.server, this.services, this.container);

  final HttpServer server;
  final AppServices services;
  final ProviderContainer container;

  /// What the server answers next.
  int status = 200;
  String body = '';

  /// Answers for particular paths, instead of [body].
  final bodies = <String, String>{};

  /// Requests served so far, and their paths.
  int requests = 0;
  final paths = <String>[];

  String get base => 'http://127.0.0.1:${server.port}';

  /// [overrides] replace providers beyond the services (e.g. dialogs).
  /// [stateDir] is the host's directory, for tests that keep files there.
  /// Without a [host] nothing runs (tests run as Android, whose real host
  /// needs the platform).
  /// [exitIpPath] makes the local server the exit IP probe service, at
  /// that path; there is none by default.
  /// [platform] is what plans are compiled for.
  static Future<Harness> start({
    RuntimeHost? host,
    HostPlatform platform = HostPlatform.macos,
    String? exitIpPath,
    List<Override> overrides = const [],
    String stateDir = '/state',
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final services = await AppServices.open(
      database: AppDatabase(NativeDatabase.memory()),
      keyStore: MemoryKeyStore(),
      host: () async =>
          HostInfo(platform: platform, stateDir: stateDir, deviceName: 'test'),
      exitIpUrl: exitIpPath == null
          ? ''
          : 'http://127.0.0.1:${server.port}$exitIpPath',
    );
    final container = ProviderContainer(
      overrides: [
        servicesProvider.overrideWithValue(services),
        runtimeHostProvider.overrideWithValue(host),
        ...overrides,
      ],
    );
    // As the app does (bootstrap).
    keepServicesRunning(container);
    final harness = Harness._(server, services, container);
    server.listen((r) async {
      harness
        ..requests += 1
        ..paths.add(r.uri.path);
      r.response.statusCode = harness.status;
      r.response.write(harness.bodies[r.uri.path] ?? harness.body);
      await r.response.close();
    });
    return harness;
  }

  Future<void> stop() async {
    // What the services started in the background finishes before the
    // database closes; each can start work for another.
    for (var i = 0; i < 3; i++) {
      await container.read(runtimeProvider.notifier).idle();
      await container.read(ruleSetUpdaterProvider.notifier).idle();
      await container.read(subscriptionUpdaterProvider.notifier).idle();
      if (container.exists(exitIpProvider)) {
        await container.read(exitIpProvider.notifier).idle();
      }
    }
    container.dispose();
    await server.close(force: true);
    await services.close();
  }

  /// Polls [read] until [ready] holds; database watches arrive async.
  Future<T> settle<T>(T Function() read, bool Function(T value) ready) async {
    for (var i = 0; i < 200; i++) {
      final value = read();
      if (ready(value)) return value;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('state did not settle');
  }
}
