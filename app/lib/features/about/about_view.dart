import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';

import '../../app/app_info.dart';
import '../../app/layout.dart';
import '../../l10n/app_localizations.dart';
import '../../services/release_updates.dart';
import 'about_state.dart';

/// About (PRODUCT_SPEC §3.15; V3 «关于»). Pure.
class AboutView extends StatelessWidget {
  const AboutView({
    super.key,
    required this.platform,
    required this.masterKeyInFile,
    required this.onLicenses,
    this.coreVersion = '',
    this.installedVersion = '$appVersion ($appBuild)',
    this.state = const AboutState(),
    this.onCheckUpdates,
    this.onOpenUpdate,
    this.onSource,
    this.onReleases,
    this.onPrivacy,
    this.showCheckUpdates = true,
  });

  final AppPlatform platform;
  final bool masterKeyInFile;

  /// The sing-box version the host reports; empty while unknown or where
  /// there is no host yet (shown as «—»).
  final String coreVersion;
  final VoidCallback onLicenses;
  final String installedVersion;
  final AboutState state;
  final VoidCallback? onCheckUpdates;
  final VoidCallback? onOpenUpdate;
  final VoidCallback? onSource;
  final VoidCallback? onReleases;
  final VoidCallback? onPrivacy;
  final bool showCheckUpdates;

  static String _osName(AppPlatform p) => switch (p) {
    AppPlatform.android => 'Android',
    AppPlatform.ios => 'iOS',
    AppPlatform.mac => 'macOS',
    AppPlatform.windows => 'Windows',
    AppPlatform.linux => 'Linux',
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.av;
    final desktop = AvDensity.isDesktop(context);
    final version = l.aboutVersionLine(installedVersion);
    // The app icon (D90).
    Widget icon(double size) => DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.225),
        boxShadow: AvShadows.appIcon,
      ),
      child: AvBrandMark.avalon(size: size),
    );
    final value = desktop ? AvType.s(14).copyWith(color: c.l2) : null;
    final double? rowHeight = desktop ? 44 : null;
    final rows = AvGroup(
      children: [
        AvRow(
          title: l.aboutCore,
          value: coreVersion.isEmpty ? '—' : 'sing-box $coreVersion',
          valueStyle: value,
          minHeight: rowHeight,
        ),
        if (showCheckUpdates)
          AvRow(
            title: l.aboutCheckUpdates,
            value: state.checking
                ? l.aboutCheckingUpdates
                : switch (state.update?.kind) {
                    UpdateResultKind.available => l.aboutUpdateAvailable(
                      state.update!.version!,
                    ),
                    UpdateResultKind.current => l.aboutUpToDate,
                    UpdateResultKind.noRelease => l.aboutNoRelease,
                    null => null,
                  },
            valueStyle: value,
            minHeight: rowHeight,
            chevron: !desktop,
            onTap: state.checking
                ? null
                : state.update?.kind == UpdateResultKind.available
                ? onOpenUpdate
                : onCheckUpdates,
          ),
        AvRow(
          title: l.aboutLicense,
          value: 'AGPL-3.0',
          valueStyle: value,
          minHeight: rowHeight,
          chevron: !desktop,
          onTap: onLicenses,
        ),
        AvRow(
          title: l.aboutSource,
          chevron: !desktop,
          minHeight: rowHeight,
          onTap: onSource,
        ),
        AvRow(
          title: l.aboutChangelog,
          chevron: !desktop,
          minHeight: rowHeight,
          onTap: onReleases,
        ),
        AvRow(
          title: l.aboutPrivacy,
          chevron: !desktop,
          minHeight: rowHeight,
          onTap: onPrivacy,
        ),
        if (masterKeyInFile)
          AvRow(
            title: l.keyStorage,
            value: l.keyStorageFile,
            valueStyle: value,
            minHeight: rowHeight,
          ),
      ],
    );
    final error = state.failure == null
        ? null
        : AvBanner(
            title: state.failure == AboutFailure.check
                ? l.aboutUpdateFailed
                : l.aboutBrowserFailed,
          );

    if (desktop) {
      return ColoredBox(
        color: c.bg,
        child: AvDesktopPage(
          maxWidth: 640,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 20),
                child: Row(
                  children: [
                    icon(72),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Avalon',
                          style: AvType.title2.copyWith(color: c.l1),
                        ),
                        Text(
                          '$version · ${_osName(platform)}',
                          style: AvType.footnote.copyWith(color: c.l2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              rows,
              ?error,
              AvSectionFooter(l.aboutThanks),
            ],
          ),
        ),
      );
    }
    return AvPushedPage(
      title: l.toolAboutShort,
      backLabel: l.tabTools,
      topPadding: 12,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            children: [
              icon(96),
              const SizedBox(height: 14),
              Text('Avalon', style: AvType.title2.copyWith(color: c.l1)),
              const SizedBox(height: 4),
              Text(version, style: AvType.footnote.copyWith(color: c.l2)),
            ],
          ),
        ),
        rows,
        ?error,
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
          child: Text(
            l.aboutThanks,
            textAlign: TextAlign.center,
            style: AvType.footnote.copyWith(color: c.l2),
          ),
        ),
      ],
    );
  }
}
