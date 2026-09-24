import 'dart:async';
import 'dart:io';

import 'package:avalon/pages/error.dart';
import 'package:avalon/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rust_api/rust_api.dart';

import 'application.dart';
import 'common/common.dart';
import 'providers/providers.dart';
import 'widgets/startup_splash.dart';

Future<void> main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  linkManager.setStartupArguments(arguments);
  runApp(_BootstrapApp(initialization: _initialize()));
}

Future<_InitializationResult> _initialize() async {
  try {
    if (system.isDesktop) {
      await RustLib.init();
    }
    final version = await system.init();
    final container = await globalState.init(version);
    HttpOverrides.global = AvalonHttpOverrides();
    return _InitializationResult.success(container);
  } catch (e, s) {
    return _InitializationResult.failure(e, s);
  }
}

class _InitializationResult {
  final ProviderContainer? container;
  final Object? error;
  final StackTrace? stack;

  const _InitializationResult._({this.container, this.error, this.stack});

  const _InitializationResult.success(ProviderContainer container)
    : this._(container: container);

  const _InitializationResult.failure(Object error, StackTrace stack)
    : this._(error: error, stack: stack);
}

class _BootstrapApp extends StatefulWidget {
  final Future<_InitializationResult> initialization;

  const _BootstrapApp({required this.initialization});

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  bool _splashComplete = false;

  void _handleSplashComplete() {
    if (!mounted || _splashComplete) return;
    setState(() => _splashComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_InitializationResult>(
      future: widget.initialization,
      builder: (context, snapshot) {
        final result = snapshot.data;
        if (result == null || !_splashComplete) {
          // The persisted theme is available once initialization finishes;
          // keep the splash on that resolved brightness instead of falling
          // back to the platform brightness for an explicitly selected mode.
          final brightness = result?.container?.read(currentBrightnessProvider);
          return StartupSplash(
            onComplete: _handleSplashComplete,
            brightness: brightness,
          );
        }

        if (result.error != null || result.container == null) {
          return MaterialApp(
            home: InitErrorScreen(
              error:
                  result.error ?? StateError('Startup initialization failed'),
              stack: result.stack ?? StackTrace.current,
            ),
          );
        }

        return UncontrolledProviderScope(
          container: result.container!,
          child: const Application(),
        );
      },
    );
  }
}
