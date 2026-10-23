import 'package:av_core/av_core.dart';
import 'package:av_design/av_design.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../cloud/cloud_revocation_retry.dart';
import '../l10n/app_localizations.dart';
import '../runtime/runtime_coordinator.dart';
import 'providers.dart';
import 'router.dart';
import 'routes.dart';

/// The supported languages. zh carries the region so text uses Simplified
/// Chinese glyphs (D62).
const supportedAppLocales = [Locale('zh', 'CN'), Locale('en')];

Locale appLocale(String? code) =>
    code == 'en' ? const Locale('en') : const Locale('zh', 'CN');

/// Root widget: theme, language and routes, driven by the device settings.
class AvalonApp extends ConsumerStatefulWidget {
  const AvalonApp({
    super.key,
    required this.initialSettings,
    this.initialLocation = Routes.dashboard,
    this.fontFamily,
    this.fontFamilyFallback,
  });

  /// Settings read before the first frame, so the app never flashes the
  /// wrong appearance or language.
  final DeviceSettings initialSettings;
  final String initialLocation;

  /// Golden tests only: the app itself never names a font (D62); tests have
  /// no system font, so they pass the host's fonts registered under these.
  final String? fontFamily;
  final List<String>? fontFamilyFallback;

  @override
  ConsumerState<AvalonApp> createState() => _AvalonAppState();
}

class _AvalonAppState extends ConsumerState<AvalonApp> {
  late final CloudRevocationRetryController? _revocations = ref.read(
    cloudRevocationRetryProvider,
  );
  late final GoRouter _router = buildRouter(
    initialLocation: widget.initialLocation,
    cloudEnabled: ref.read(cloudAuthServiceProvider) != null,
  );

  // The host is asked for its state only while the app is in view
  // (RUNTIME_HOST §6); the proxy itself does not care.
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onStateChange: (state) {
      final visible = state == AppLifecycleState.resumed;
      ref.read(cloudSyncEngineProvider)?.foreground(visible);
      ref.read(runtimeProvider.notifier).setVisible(visible);
      if (visible) {
        _revocations?.resume();
      } else {
        _revocations?.pause();
      }
    },
  );

  @override
  void initState() {
    super.initState();
    _lifecycle; // Created with the app, released with it.
    _revocations?.resume();
    ref.read(cloudSyncEngineProvider)?.start();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _revocations?.pause();
    ref.read(cloudSyncEngineProvider)?.foreground(false);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(deviceSettingsProvider).value ?? widget.initialSettings;
    final colors = settings.appearance == Appearance.dark
        ? AvColors.dark
        : AvColors.light;
    return CupertinoApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      locale: appLocale(settings.locale),
      supportedLocales: supportedAppLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      onGenerateTitle: (context) => 'Avalon',
      theme: CupertinoThemeData(
        brightness: colors.brightness,
        primaryColor: colors.tint,
        scaffoldBackgroundColor: colors.bg,
      ),
      builder: (context, child) => AvAppFrame(
        colors: colors,
        fontFamily: widget.fontFamily,
        fontFamilyFallback: widget.fontFamilyFallback,
        child: child!,
      ),
    );
  }
}

/// What every screen sits in: the V3 colours, transparent system bars with
/// matching icon brightness, and the default text style.
class AvAppFrame extends StatelessWidget {
  const AvAppFrame({
    super.key,
    required this.colors,
    required this.child,
    this.fontFamily,
    this.fontFamilyFallback,
  });

  final AvColors colors;
  final Widget child;
  final String? fontFamily;
  final List<String>? fontFamilyFallback;

  @override
  Widget build(BuildContext context) => AvTheme(
    colors: colors,
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          (colors.isDark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark)
              .copyWith(
                statusBarColor: const Color(0x00000000),
                systemNavigationBarColor: const Color(0x00000000),
                systemNavigationBarContrastEnforced: false,
              ),
      child: DefaultTextStyle(
        style: AvType.body.copyWith(
          color: colors.l1,
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
        ),
        child: child,
      ),
    ),
  );
}
