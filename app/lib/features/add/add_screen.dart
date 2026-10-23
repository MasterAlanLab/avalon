import 'package:av_core/av_core.dart';
import 'package:av_design/av_design.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_error.dart';
import '../../app/layout.dart';
import '../../app/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/file_dialogs.dart';
import '../../platform/qr_scanner.dart';
import '../../services/import_service.dart';
import 'add_state.dart';
import 'add_view.dart';
import 'add_view_model.dart';
import 'chain_options.dart';

/// The add form connected to its view model. Pops with an [AddResult] once
/// something was saved.
class AddScreen extends ConsumerStatefulWidget {
  const AddScreen({super.key, this.edit, this.scrollController});

  /// The object to edit (PRODUCT_SPEC §3.4); null adds something new.
  final EditTarget? edit;
  final ScrollController? scrollController;

  @override
  ConsumerState<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends ConsumerState<AddScreen> {
  final _url = TextEditingController();
  final _name = TextEditingController();
  final _link = TextEditingController();
  final _chainName = TextEditingController();
  final _node = <NodeField, TextEditingController>{};

  AddViewModel get _model => ref.read(addViewModelProvider.notifier);

  @override
  void initState() {
    super.initState();
    _url.addListener(() => _model.setUrl(_url.text));
    _name.addListener(() => _model.setName(_name.text));
    _link.addListener(() => _model.setLink(_link.text));
    _chainName.addListener(() => _model.setChainName(_chainName.text));
    final edit = widget.edit;
    if (edit != null) {
      // Providers may not change while the tree builds.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _model.beginEdit(edit);
      });
    }
  }

  @override
  void dispose() {
    _url.dispose();
    _name.dispose();
    _link.dispose();
    _chainName.dispose();
    for (final c in _node.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// One controller per node field, made when the field first shows.
  TextEditingController _nodeController(NodeField field) => _node.putIfAbsent(
    field,
    () {
      final controller = TextEditingController(
        text: ref.read(addViewModelProvider).node[field],
      );
      controller.addListener(() => _model.setNodeField(field, controller.text));
      return controller;
    },
  );

  /// After the state changed by itself (a parsed link, an object loaded for
  /// editing), the fields follow.
  void _syncFields(AddState state) {
    void sync(TextEditingController controller, String text) {
      if (controller.text != text) controller.text = text;
    }

    sync(_url, state.url);
    sync(_name, state.name);
    sync(_link, state.link);
    sync(_chainName, state.chain.name);
    for (final MapEntry(key: field, value: controller) in _node.entries) {
      sync(controller, state.node[field]);
    }
  }

  /// Closes the form: an edit just returns to the page underneath.
  void _done(AddResult added) =>
      context.pop<AddResult>(widget.edit == null ? added : null);

  Future<void> _save() async {
    final state = ref.read(addViewModelProvider);
    switch (state.segment) {
      case AddSegment.subscription:
        final warnings = await _model.saveSubscription(
          defaultName: AppLocalizations.of(context).defaultSubscriptionName,
        );
        if (warnings != null && mounted) _done(ConfigurationAdded(warnings));
      case AddSegment.node:
        if (await _model.saveNode() && mounted) _done(const SelfContentAdded());
      case AddSegment.chain:
        if (await _model.saveChain() && mounted) {
          _done(const SelfContentAdded());
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(addViewModelProvider, (_, state) => _syncFields(state));
    final state = ref.watch(addViewModelProvider);
    final l = AppLocalizations.of(context);
    final view = AddView(
      state: state,
      urlController: _url,
      nameController: _name,
      scrollController: widget.scrollController,
      onCancel: () => context.pop(),
      onSave: _save,
      onSegment: _model.setSegment,
      onAutoUpdate: _model.setAutoUpdate,
      onMethod: _model.toggleMethod,
      onPickFile: _model.pickFile,
      onClearFile: _model.clearFile,
      // Phones scan; desktops take dropped files (PRODUCT_SPEC §6).
      scanAvailable:
          AppPlatform.host == AppPlatform.android ||
          AppPlatform.host == AppPlatform.ios,
      scanner: state.method == SubscriptionMethod.scan
          ? QrScanner(
              onCode: _scanned,
              prompt: l.scanPrompt,
              problemText: (p) => switch (p) {
                ScannerProblem.denied => l.scanDenied,
                ScannerProblem.unavailable => l.scanUnavailable,
              },
            )
          : null,
      linkController: _link,
      nodeController: _nodeController,
      onParseLink: _model.parseLink,
      onProtocol: _model.setProtocol,
      onTransport: _model.setTransport,
      onSecurity: _model.setSecurity,
      chainOptions: ref.watch(chainOptionsProvider),
      chainNameController: _chainName,
      onToggleHopPicker: _model.toggleHopPicker,
      onAddHop: _model.addHop,
      onRemoveHop: _model.removeHop,
      onMoveHop: _model.moveHop,
      onToggleChainGroup: _model.toggleChainGroup,
    );
    // Desktop: a configuration file dropped anywhere on the form is
    // imported as a subscription (PRODUCT_SPEC §3.5).
    if (!AvDensity.isDesktop(context) ||
        state.segment != AddSegment.subscription ||
        state.editing != null) {
      return view;
    }
    return DropTarget(onDragDone: _dropped, child: view);
  }

  void _scanned(String text) {
    if (_model.scanned(text)) {
      HapticFeedback.selectionClick();
      showAvToast(context, AppLocalizations.of(context).scanned);
    }
  }

  Future<void> _dropped(DropDoneDetails details) async {
    if (details.files.isEmpty) return;
    final result = await attempt(
      () => readDroppedFile(
        details.files.first,
        maxBytes: ImportService.maxFileBytes,
      ),
    );
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        _model.setFile(value);
      case Err(:final error):
        _model.showError(error);
    }
  }
}
