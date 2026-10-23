import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:av_core/av_core.dart';
import 'package:av_design/av_design.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path_provider/path_provider.dart';

import '../data/database/database.dart';
import '../l10n/app_localizations.dart';
import '../platform/desktop/desktop_window.dart';
import '../platform/desktop/global_hotkeys.dart';
import '../platform/desktop/login_item.dart';
import '../platform/desktop/single_instance.dart';
import '../platform/desktop/system_tray.dart';
import '../platform/launch_screen.dart';
import 'app_services_running.dart';
import 'avalon_app.dart';
import 'desktop_shell.dart';
import 'licenses.dart';
import 'log.dart';
import 'providers.dart';
import 'services.dart';
import 'startup_splash.dart';

/// Starts the UI at once with the startup animation, and opens local data
/// meanwhile; the app follows once both are done. When
/// the data cannot be opened the app says so and touches nothing
/// (PRODUCT_SPEC §8).
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerBundledLicenses();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  if (_desktop) {
    await _bootstrapDesktop();
    return;
  }
  runApp(StartupGate(startup: _start(), builder: _appFor));
}

bool get _desktop => switch (defaultTargetPlatform) {
  TargetPlatform.macOS ||
  TargetPlatform.linux ||
  TargetPlatform.windows => true,
  _ => false,
};

/// Desktop: one instance per user; local data opens before the window is
/// shown, which «静默启动» may skip, so the animation plays where it can
/// be seen (RUNTIME_HOST §9).
Future<void> _bootstrapDesktop() async {
  final window = WindowManagerWindow();
  final support = (await getApplicationSupportDirectory()).path;
  final instance = await SingleInstance.claim(
    support,
    onShow: () => unawaited(window.show()),
  );
  // Another Avalon runs and shows its window instead.
  if (instance == null) exit(0);
  final startup = await _start();
  switch (startup) {
    case Started(:final container, :final settings):
      final windows = defaultTargetPlatform == TargetPlatform.windows;
      final shell = DesktopShell(
        container: container,
        window: window,
        tray: TrayManagerTray(),
        hotkeys: GlobalHotkeys.host(),
        loginItem: LoginItem.host(),
        icons: windows
            ? (idle: 'assets/tray/idle.ico', running: 'assets/tray/running.ico')
            : (
                idle: 'assets/tray/idle.png',
                running: 'assets/tray/running.png',
              ),
        quitApp: () async {
          await instance.release();
          exit(0);
        },
      );
      await shell.start(silent: settings.silentStart);
    case StartFailed():
      await window.setup();
      await window.show();
  }
  runApp(StartupGate(startup: Future.value(startup), builder: _appFor));
}

Future<Startup> _start() async {
  try {
    final services = await AppServices.open(
      systemLocale: PlatformDispatcher.instance.locale,
    );
    final settings = await services.settings.device();
    final container = ProviderContainer(
      overrides: [servicesProvider.overrideWithValue(services)],
    );
    keepServicesRunning(container, cloud: true);
    // The next launch's system splash takes the app's appearance.
    container.listen(
      deviceSettingsProvider.select((s) => s.value?.appearance),
      (_, appearance) {
        if (appearance != null) {
          unawaited(const SystemLaunchScreen().rememberAppearance(appearance));
        }
      },
      fireImmediately: true,
    );
    return Started(container, settings);
  } on DatabaseTooNewException {
    return const StartFailed(databaseTooNew: true);
  } on Object catch (e, stack) {
    Log.error('start-up failed: $e\n$stack');
    return const StartFailed(databaseTooNew: false);
  }
}

Widget _appFor(Startup startup) => switch (startup) {
  Started(:final container, :final settings) => UncontrolledProviderScope(
    container: container,
    child: AvalonApp(initialSettings: settings),
  ),
  StartFailed(:final databaseTooNew) => StartupErrorApp(
    databaseTooNew: databaseTooNew,
  ),
};

/// What opening local data came to.
sealed class Startup {
  const Startup();
}

final class Started extends Startup {
  const Started(this.container, this.settings);

  final ProviderContainer container;

  /// Read before the first frame of the app (its appearance and language).
  final DeviceSettings settings;
}

final class StartFailed extends Startup {
  const StartFailed({required this.databaseTooNew});

  final bool databaseTooNew;
}

/// The startup animation until it has played and [startup] is done, then
/// what [builder] makes of it (UI_DESIGN_SYSTEM §5). The animation takes
/// the app's appearance as soon as the settings are read.
class StartupGate extends StatefulWidget {
  const StartupGate({
    super.key,
    required this.startup,
    required this.builder,
    this.launchScreen = const SystemLaunchScreen(),
  });

  final Future<Startup> startup;
  final Widget Function(Startup startup) builder;
  final LaunchScreen launchScreen;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  Startup? _startup;
  var _played = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      widget.startup.then((startup) {
        if (mounted) setState(() => _startup = startup);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startup = _startup;
    if (startup == null || !_played) {
      return StartupSplash(
        launchScreen: widget.launchScreen,
        brightness: switch (startup) {
          Started(:final settings) =>
            settings.appearance == Appearance.dark
                ? Brightness.dark
                : Brightness.light,
          _ => null,
        },
        onComplete: () {
          if (mounted) setState(() => _played = true);
        },
      );
    }
    return widget.builder(startup);
  }
}

/// Shown instead of the app when local data cannot be opened.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.databaseTooNew});

  final bool databaseTooNew;

  @override
  Widget build(BuildContext context) {
    const colors = AvColors.light;
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      supportedLocales: supportedAppLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => AvAppFrame(colors: colors, child: child!),
      home: Builder(
        builder: (context) {
          final l = AppLocalizations.of(context);
          return ColoredBox(
            color: colors.bg,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AvIcon(
                      databaseTooNew
                          ? Symbols.system_update_rounded
                          : Symbols.error_rounded,
                      size: 48,
                      color: databaseTooNew ? colors.tint : colors.bad,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      databaseTooNew ? l.databaseTooNew : l.startupFailed,
                      textAlign: TextAlign.center,
                      style: AvType.title3.copyWith(color: colors.l1),
                    ),
                    if (databaseTooNew) ...[
                      const SizedBox(height: 8),
                      Text(
                        l.databaseTooNewNote,
                        textAlign: TextAlign.center,
                        style: AvType.callout.copyWith(color: colors.l2),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
