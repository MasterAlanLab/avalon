import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:avalon/common/common.dart';
import 'package:avalon/l10n/l10n.dart';
import 'package:avalon/manager/hotkey_manager.dart';
import 'package:avalon/manager/manager.dart';
import 'package:avalon/plugins/app.dart';
import 'package:avalon/providers/providers.dart';
import 'package:avalon/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pages/pages.dart';

class Application extends ConsumerStatefulWidget {
  const Application({super.key});

  @override
  ConsumerState<Application> createState() => ApplicationState();
}

class ApplicationState extends ConsumerState<Application> {
  Timer? _autoUpdateProfilesTaskTimer;
  bool _preHasVpn = false;

  final _pageTransitionsTheme = const PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: commonSharedXPageTransitions,
      TargetPlatform.windows: commonSharedXPageTransitions,
      TargetPlatform.linux: commonSharedXPageTransitions,
      TargetPlatform.macOS: commonSharedXPageTransitions,
    },
  );

  @override
  void initState() {
    super.initState();
    SystemNavigator.setFrameworkHandlesBack(true);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      if (globalState.navigatorKey.currentContext != null) {
        await globalState.attach();
      } else {
        exit(0);
      }
      _autoUpdateProfilesTask();
      _initLink();
      app?.initShortcuts();
    });
  }

  void _initLink() {
    linkManager.initAppLinksListen((url) async {
      if (system.isDesktop) await window?.show();
      if (!mounted) return;
      final localizations = currentAppLocalizations;
      final primaryColor = context.colorScheme.primary;
      final isSubscription =
          url.startsWith('http://') || url.startsWith('https://');
      final res = await globalState.showMessage(
        title: isSubscription
            ? localizations.addProfile
            : localizations.importNode,
        message: TextSpan(
          children: [
            TextSpan(text: currentAppLocalizations.doYouWantToPass),
            TextSpan(
              text: ' $url ',
              style: TextStyle(
                color: primaryColor,
                decoration: TextDecoration.underline,
                decorationColor: primaryColor,
              ),
            ),
            TextSpan(
              text: isSubscription
                  ? localizations.createProfile
                  : localizations.importNode,
            ),
          ],
        ),
      );
      if (res != true) return;
      if (!mounted) return;
      final profileId = isSubscription
          ? null
          : ref.read(currentProfileIdProvider);
      await ref
          .read(profilesActionProvider.notifier)
          .importNodeText(url, profileId: profileId, bind: profileId != null);
    });
  }

  void _autoUpdateProfilesTask() {
    _autoUpdateProfilesTaskTimer = Timer(const Duration(minutes: 20), () async {
      await ref.read(profilesActionProvider.notifier).autoUpdateProfiles();
      _autoUpdateProfilesTask();
    });
  }

  Widget _buildPlatformState({required Widget child}) {
    if (system.isDesktop) {
      return WindowManager(
        child: TrayManager(
          child: HotKeyManager(child: ProxyManager(child: child)),
        ),
      );
    }
    return AndroidManager(child: TileManager(child: child));
  }

  Widget _buildState({required Widget child}) {
    return AppStateManager(
      child: CoreManager(
        child: ConnectivityManager(
          onConnectivityChanged: (results) async {
            commonPrint.log('connectivityChanged ${results.toString()}');
            ref.read(systemActionProvider.notifier).updateLocalIp();
            final hasVpn = results.contains(ConnectivityResult.vpn);
            if (_preHasVpn == hasVpn) {
              ref.read(checkIpNumProvider.notifier).add();
            }
            _preHasVpn = hasVpn;
          },
          child: child,
        ),
      ),
    );
  }

  Widget _buildPlatformApp({required Widget child}) {
    if (system.isDesktop) {
      return WindowHeaderContainer(child: child);
    }
    return VpnManager(child: child);
  }

  Widget _buildApp({required Widget child}) {
    return StatusManager(child: ThemeManager(child: child));
  }

  @override
  Widget build(context) {
    return Consumer(
      builder: (_, ref, child) {
        final locale = ref.watch(
          appSettingProvider.select((state) => state.locale),
        );
        final themeProps = ref.watch(themeSettingProvider);
        final lightColorScheme = ref.read(
          genColorSchemeProvider(Brightness.light),
        );
        final darkColorScheme = ref
            .read(genColorSchemeProvider(Brightness.dark))
            .toPureBlack(themeProps.pureBlack);
        final appBrightness = ref.watch(currentBrightnessProvider);
        final appBackgroundColor = appBrightness == Brightness.dark
            ? darkColorScheme.surface
            : lightColorScheme.surface;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: globalState.navigatorKey,
          onNavigationNotification: (_) => true,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          builder: (_, child) {
            return ColoredBox(
              // HomePage intentionally waits for its first measured view
              // size. Paint the resolved theme surface behind that short
              // initialization window so the native splash never reveals a
              // black Flutter surface when switching to the app.
              color: appBackgroundColor,
              child: AppEnvManager(
                child: ValueListenableBuilder<AppActivityState>(
                  valueListenable: appActivity,
                  builder: (_, activity, child) {
                    return TickerMode(
                      enabled: activity.isUiActive,
                      child: child!,
                    );
                  },
                  child: _buildApp(
                    child: _buildPlatformState(
                      child: _buildState(
                        child: _buildPlatformApp(child: child!),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          scrollBehavior: BaseScrollBehavior(),
          title: appName,
          locale: utils.getLocaleForString(locale),
          supportedLocales: AppLocalizations.delegate.supportedLocales,
          themeMode: themeProps.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            pageTransitionsTheme: _pageTransitionsTheme,
            colorScheme: lightColorScheme,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            pageTransitionsTheme: _pageTransitionsTheme,
            colorScheme: darkColorScheme,
          ),
          home: child!,
        );
      },
      child: const HomePage(),
    );
  }

  @override
  void dispose() {
    linkManager.destroy();
    _autoUpdateProfilesTaskTimer?.cancel();
    super.dispose();
  }
}
