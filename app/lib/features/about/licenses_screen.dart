import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/licenses.dart';
import '../../app/routes.dart';
import '../../l10n/app_localizations.dart';

/// Every licence, grouped by package; read once per visit.
final licensesProvider = FutureProvider.autoDispose<List<PackageLicenses>>(
  (ref) => collectLicenses(),
);

/// «许可与第三方声明»: the packages, then one package's texts.
class LicensesScreen extends ConsumerWidget {
  const LicensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final desktop = AvDensity.isDesktop(context);
    final packages = ref.watch(licensesProvider).value ?? const [];
    return AvPushedPage(
      title: l.licensesTitle,
      backLabel: l.toolAboutShort,
      tabBar: !desktop,
      children: [
        AvSectionFooter(l.licensesNote),
        const SizedBox(height: 8),
        if (packages.isNotEmpty)
          AvGroup(
            children: [
              for (final p in packages)
                AvRow(
                  title: p.package,
                  value: l.licenseCount(p.texts.length),
                  chevron: true,
                  onTap: () => context.push(Routes.license(p.package)),
                ),
            ],
          ),
      ],
    );
  }
}

class LicenseScreen extends ConsumerWidget {
  const LicenseScreen({super.key, required this.package});

  final String package;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.av;
    final desktop = AvDensity.isDesktop(context);
    final texts =
        ref
            .watch(licensesProvider)
            .value
            ?.where((p) => p.package == package)
            .firstOrNull
            ?.texts ??
        const <String>[];
    return AvPushedPage(
      title: package,
      backLabel: l.licensesTitle,
      tabBar: !desktop,
      children: [
        for (final (i, text) in texts.indexed)
          Padding(
            padding: EdgeInsets.fromLTRB(16, i == 0 ? 8 : 16, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.cell,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                text,
                style: AvType.mono(12, height: 1.45).copyWith(color: c.l1),
              ),
            ),
          ),
      ],
    );
  }
}
