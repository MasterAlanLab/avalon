import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../platform/file_dialogs.dart';
import '../add_state.dart';

/// V3 3d: link and name, then the auto-update switch.
class SubscriptionForm extends StatelessWidget {
  const SubscriptionForm({
    super.key,
    required this.state,
    required this.urlController,
    required this.nameController,
    required this.onAutoUpdate,
    required this.onMethod,
    required this.onPickFile,
    required this.onClearFile,
    this.scanAvailable = false,
    this.scanner,
  });

  final AddState state;
  final TextEditingController urlController;
  final TextEditingController nameController;
  final ValueChanged<bool> onAutoUpdate;
  final ValueChanged<SubscriptionMethod> onMethod;
  final VoidCallback onPickFile;
  final VoidCallback onClearFile;

  /// Phones with a camera offer «扫描二维码» (PRODUCT_SPEC §6).
  final bool scanAvailable;

  /// The camera view shown while scanning (the screen builds it, so the
  /// form stays free of platform code).
  final Widget? scanner;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.av;
    final desktop = AvDensity.isDesktop(context);
    final error = state.error;
    final nameRow = AvFieldRow(
      label: l.name,
      placeholder: l.nameAuto,
      inputSize: desktop ? 14 : 17,
      controller: nameController,
    );
    // A local file configuration: only its name can change.
    if (state.fileOnly) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AvGroup(children: [nameRow]),
          if (error != null) AvFormNote(error.message(l), color: c.bad),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AvGroup(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                vertical: desktop ? 10 : 11,
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.sep, width: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.subscriptionUrl,
                    style: (desktop ? AvType.caption : AvType.footnote)
                        .copyWith(color: c.l2),
                  ),
                  const SizedBox(height: 4),
                  // V3 `<textarea>` with min-height 64 (60 on desktop) sits
                  // on the text line's baseline, so the line's descent adds
                  // below it.
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: desktop ? 63 : 68),
                    child: AvInput(
                      controller: urlController,
                      placeholder: l.subscriptionUrlHint,
                      maxLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      keyboardType: TextInputType.url,
                      style: desktop ? AvType.s(14) : null,
                    ),
                  ),
                ],
              ),
            ),
            nameRow,
          ],
        ),
        if (error != null) AvFormNote(error.message(l), color: c.bad),
        // Editing keeps the source; a file cannot replace a subscription.
        if (desktop && state.editing == null) ...[
          const SizedBox(height: 12),
          _FileBox(
            file: state.file,
            desktop: true,
            onTap: onPickFile,
            onClear: onClearFile,
          ),
        ] else if (state.editing == null) ...[
          const SizedBox(height: 24),
          AvGroup(
            children: [
              if (scanAvailable)
                _MethodRow(
                  icon: Symbols.qr_code_scanner_rounded,
                  label: l.scanQr,
                  on: state.method == SubscriptionMethod.scan,
                  onTap: () => onMethod(SubscriptionMethod.scan),
                ),
              _MethodRow(
                icon: Symbols.folder_open_rounded,
                label: l.importFile,
                on: state.importsFile,
                onTap: () => onMethod(SubscriptionMethod.file),
              ),
            ],
          ),
          if (state.method == SubscriptionMethod.scan && scanner != null)
            AvDropIn(
              key: const ValueKey('scan'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: scanner,
              ),
            ),
          if (state.importsFile)
            AvDropIn(
              key: const ValueKey('file'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _FileBox(
                  file: state.file,
                  desktop: false,
                  onTap: onPickFile,
                  onClear: null,
                ),
              ),
            ),
        ],
        SizedBox(height: desktop ? 16 : 24),
        // A local file is not updated (PRODUCT_SPEC §3.5).
        if (state.importsFile)
          AvFormNote(l.fileImportNote)
        else ...[
          AvGroup(
            children: [
              AvRow(
                title: l.autoUpdate,
                subtitle: desktop ? l.autoUpdateSubtitle : null,
                trailing: AvSwitch(
                  value: state.autoUpdate,
                  onChanged: onAutoUpdate,
                ),
              ),
            ],
          ),
          AvFormNote(desktop ? l.localOnlyNote : l.autoUpdateLocalOnlyNote),
        ],
      ],
    );
  }
}

/// «扫描二维码» / «从文件导入» (V3 3d): accent title, check when chosen.
class _MethodRow extends StatelessWidget {
  const _MethodRow({
    required this.icon,
    required this.label,
    required this.on,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    return AvRow(
      leading: AvIcon(icon, size: 22, color: c.tint),
      title: label,
      titleColor: c.tint,
      onTap: onTap,
      trailing: AnimatedOpacity(
        opacity: on ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: AvIcon(Symbols.check_rounded, size: 20, color: c.tint),
      ),
    );
  }
}

/// The dashed file box: «选择 .json 或 .yaml» on phones, «或拖入配置文件»
/// on desktop (V3 3d, 3p); once a file is chosen it shows that file.
class _FileBox extends StatelessWidget {
  const _FileBox({
    required this.file,
    required this.desktop,
    required this.onTap,
    required this.onClear,
  });

  final PickedFile? file;
  final bool desktop;
  final VoidCallback onTap;

  /// Desktop: back to the link.
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.av;
    final file = this.file;
    final title = file?.name ?? (desktop ? l.dropFile : l.fileChoose);
    final note = file == null
        ? (desktop ? l.dropFileNote : l.fileChooseNote)
        : '${formatBytes(file.bytes.length)} · ${l.fileReplace}';
    final titleStyle = (desktop ? AvType.subheadStrong : AvType.calloutStrong)
        .copyWith(color: c.l1);
    final noteStyle = (desktop ? AvType.caption : AvType.footnote).copyWith(
      color: c.l2,
    );
    final icon = AvIcon(
      file == null
          ? (desktop
                ? Symbols.upload_file_rounded
                : Symbols.description_rounded)
          : Symbols.description_rounded,
      size: desktop ? 28 : 36,
      color: c.tint,
    );
    final Widget content;
    if (desktop) {
      content = Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                  Text(note, style: noteStyle),
                ],
              ),
            ),
            if (file != null && onClear != null)
              AvPressable(
                onTap: onClear,
                pressedOpacity: 0.4,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: AvIcon(Symbols.close_rounded, size: 18, color: c.l3),
                ),
              ),
          ],
        ),
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            icon,
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: titleStyle,
            ),
            Text(note, style: noteStyle),
          ],
        ),
      );
    }
    return AvPressable(
      onTap: onTap,
      scale: 0.98,
      child: CustomPaint(
        painter: AvDashedBorder(color: c.l3, radius: desktop ? 12 : 16),
        child: content,
      ),
    );
  }
}
