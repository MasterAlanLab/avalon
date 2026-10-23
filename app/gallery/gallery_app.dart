// DEVELOPMENT ONLY: V3 replica used to verify the design system on devices.
import 'dart:async';

import 'package:av_design/av_design.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:window_manager/window_manager.dart';

import 'desktop/desktop_shell.dart';
import 'dev_remote.dart';
import 'gallery_state.dart';
import 'pages_main.dart';

void runGallery() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // macOS starts the window hidden (the app's «静默启动»); show it.
  if (defaultTargetPlatform == TargetPlatform.macOS) {
    unawaited(
      windowManager.ensureInitialized().then((_) => windowManager.show()),
    );
  }
  runApp(const GalleryApp());
}

class GalleryApp extends StatefulWidget {
  const GalleryApp({
    super.key,
    this.state,
    this.desktopPlatform,
    this.fontFamily,
    this.fontFamilyFallback,
  });

  /// Injected by golden tests; otherwise the app owns a live state.
  final GalleryState? state;

  /// Overrides `--dart-define=AV_DESKTOP` (golden tests render all three).
  final AvDesktopPlatform? desktopPlatform;

  /// Golden tests only: the app itself never names a font (D62); tests have
  /// no system font, so they pass the host's fonts registered under these.
  final String? fontFamily;
  final List<String>? fontFamilyFallback;

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  late final GalleryState _state = widget.state ?? GalleryState();

  @override
  void initState() {
    super.initState();
    if (widget.state == null) {
      DevRemote.maybeStart(
        commands: {
          'dark': (a) => _state.set(() => _state.dark = a[1] == '1'),
          'account': (a) => _state.set(() => _state.account = a[1]),
        },
      );
    }
  }

  @override
  void dispose() {
    if (widget.state == null) _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GalleryScope(
      state: _state,
      child: ListenableBuilder(
        listenable: _state,
        builder: (context, _) {
          final colors = _state.dark ? AvColors.dark : AvColors.light;
          return CupertinoApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('zh', 'CN'),
            supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: CupertinoThemeData(
              brightness: colors.brightness,
              primaryColor: colors.tint,
              scaffoldBackgroundColor: colors.bg,
            ),
            builder: (context, child) => AvTheme(
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
                    fontFamily: widget.fontFamily,
                    fontFamilyFallback: widget.fontFamilyFallback,
                  ),
                  child: child!,
                ),
              ),
            ),
            // Wide windows get the V3 desktop layout (3p/3q/3r).
            home: LayoutBuilder(
              builder: (context, box) => box.maxWidth >= 900
                  ? DesktopShell(
                      spec: AvDesktopSpec.of(
                        widget.desktopPlatform ?? galleryDesktopPlatform(),
                      ),
                    )
                  : const GalleryShell(),
            ),
          );
        },
      ),
    );
  }
}

const _tabs = [
  AvTabItem(Symbols.speed_rounded, '仪表盘'),
  AvTabItem(Symbols.public_rounded, '代理'),
  AvTabItem(Symbols.folder_rounded, '配置'),
  AvTabItem(Symbols.handyman_rounded, '工具'),
];

/// Four tabs, each with its own navigator so pushed pages keep the tab bar
/// (as in V3), and a fade/zoom when switching tabs (`ios-fade .32s`).
class GalleryShell extends StatefulWidget {
  const GalleryShell({super.key});

  @override
  State<GalleryShell> createState() => GalleryShellState();
}

class GalleryShellState extends State<GalleryShell> {
  int _tab = 0;
  final _navs = List.generate(4, (_) => GlobalKey<NavigatorState>());

  void select(int i) {
    if (i == _tab) {
      _navs[i].currentState?.popUntil((r) => r.isFirst);
      return;
    }
    setState(() => _tab = i);
  }

  /// Switch to the tools tab and push [page] there (V3 shows Cloud under 工具).
  void openInTools(Widget page) {
    setState(() => _tab = 3);
    final nav = _navs[3].currentState;
    nav?.popUntil((r) => r.isFirst);
    nav?.push(AvPageRoute<void>(builder: (_) => page));
  }

  static GalleryShellState of(BuildContext context) =>
      context.findAncestorStateOfType<GalleryShellState>()!;

  Widget _root(int i) => switch (i) {
    0 => const DashboardPage(),
    1 => const ProxiesPage(),
    2 => const ProfilesPage(),
    _ => const ToolsPage(),
  };

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _navs[_tab].currentState?.maybePop();
      },
      child: ColoredBox(
        color: c.bg,
        child: Stack(
          children: [
            Positioned.fill(
              child: AvFadeSwap(
                token: _tab,
                child: IndexedStack(
                  index: _tab,
                  children: [
                    for (var i = 0; i < 4; i++)
                      Navigator(
                        key: _navs[i],
                        onGenerateRoute: (s) => AvPageRoute<void>(
                          builder: (_) => _root(i),
                          settings: s,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AvTabBar(items: _tabs, index: _tab, onTap: select),
            ),
          ],
        ),
      ),
    );
  }
}

void pushPage(BuildContext context, Widget page) {
  Navigator.of(context).push(AvPageRoute<void>(builder: (_) => page));
}
