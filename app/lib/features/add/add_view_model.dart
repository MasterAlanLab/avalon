import 'package:av_core/av_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_error.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../platform/file_dialogs.dart';
import '../../services/download/fetcher.dart';
import '../../services/import_service.dart';
import 'add_state.dart';
import 'chain_options.dart';

final addViewModelProvider =
    NotifierProvider.autoDispose<AddViewModel, AddState>(AddViewModel.new);

class AddViewModel extends Notifier<AddState> {
  FetchCancel? _cancel;

  @override
  AddState build() {
    // Closing the form stops a running download or parse; nothing is saved
    // (PRODUCT_SPEC §3.5).
    ref.onDispose(() => _cancel?.cancel());
    return const AddState();
  }

  void setSegment(AddSegment segment) =>
      state = state.copyWith(segment: segment, error: () => null);

  // ---------------------------------------------------------------- 编辑

  /// The node being edited: its secrets fill the fields left empty.
  SelfNode? _editedNode;

  /// Reads the object into the form (PRODUCT_SPEC §3.4). The form then
  /// shows only that object's segment, and saving keeps its id.
  Future<void> beginEdit(EditTarget target) async {
    state = AddState(
      editing: target,
      loading: true,
      segment: switch (target.kind) {
        EditKind.configuration => AddSegment.subscription,
        EditKind.node => AddSegment.node,
        EditKind.chain => AddSegment.chain,
      },
    );
    final loaded = await attempt(() => _load(target));
    if (!ref.mounted) return;
    state = switch (loaded) {
      Ok(:final value?) => value,
      Ok() => state.copyWith(error: () => const AppError('edit.missing')),
      Err(:final error) => state.copyWith(error: () => error),
    };
  }

  Future<AddState?> _load(EditTarget target) async {
    final base = state.copyWith(loading: false);
    switch (target.kind) {
      case EditKind.configuration:
        final configurations = ref.read(configurationRepositoryProvider);
        final c = await configurations.get(target.id);
        if (c == null || c.kind == ConfigurationKind.self) return null;
        final source = await configurations.source(target.id);
        return base.copyWith(
          name: c.name,
          url: source?.url.value ?? '',
          autoUpdate: c.autoUpdate,
          fileOnly: c.kind == ConfigurationKind.file,
          editedAt: c.editedAt,
        );
      case EditKind.node:
        final found = await ref
            .read(selfContentRepositoryProvider)
            .node(target.id);
        if (found == null) return null;
        final node = _editedNode = found.node;
        final draft = NodeDraft.fromNode(
          name: node.name,
          server: node.server,
          port: node.port,
          params: node.params,
          withSecrets: false,
        );
        return base.copyWith(
          node: draft,
          savedSecrets: _savedSecretsOf(node),
          editedAt: found.editedAt,
        );
      case EditKind.chain:
        final repository = ref.read(selfContentRepositoryProvider);
        final found = await repository.chain(target.id);
        if (found == null) return null;
        final selected = (await ref.read(settingsRepositoryProvider).device())
            .selectedConfigurationId;
        final memberships = await repository.watchMemberships().first;
        return base.copyWith(
          chain: ChainDraft(
            name: found.chain.name ?? '',
            hops: found.chain.hops,
            // What it is in now, not the default for a new chain.
            groups: {
              for (final m in memberships)
                if (m.ownerKind == MemberOwner.chain &&
                    m.ownerId == target.id &&
                    m.configurationId == selected)
                  m.groupKey,
            },
          ),
          editedAt: found.editedAt,
        );
    }
  }

  /// The secret fields [node] has a value for.
  static Set<NodeField> _savedSecretsOf(SelfNode node) {
    final all = NodeDraft.fromNode(
      name: node.name,
      server: node.server,
      port: node.port,
      params: node.params,
    );
    return {
      for (final f in NodeField.values)
        if (NodeDraft.isSecret(f) && all[f].isNotEmpty) f,
    };
  }

  /// After a failed save: a conflict reloads the object and says so;
  /// anything else stays in the form.
  Future<void> _saveFailed(AppError error) async {
    final target = state.editing;
    if (target != null && error.code == 'edit.conflict') {
      await beginEdit(target);
      if (ref.mounted) state = state.copyWith(error: () => error);
      return;
    }
    state = state.copyWith(
      saving: false,
      error: () => error.cancelled ? null : error,
    );
  }

  void setUrl(String url) {
    if (url != state.url) state = state.copyWith(url: url, error: () => null);
  }

  void setName(String name) {
    if (name != state.name) state = state.copyWith(name: name);
  }

  void setAutoUpdate(bool on) => state = state.copyWith(autoUpdate: on);

  /// The method rows toggle: tapping the current one returns to the link.
  void toggleMethod(SubscriptionMethod method) => state = state.copyWith(
    method: state.method == method ? SubscriptionMethod.link : method,
    error: () => null,
  );

  /// A QR code read while scanning: a subscription link fills the link
  /// field and scanning stops; anything else is reported and scanning goes
  /// on. True when the link was taken.
  bool scanned(String text) {
    final link = text.trim();
    final uri = Uri.tryParse(link);
    final ok =
        uri != null &&
        (uri.isScheme('http') || uri.isScheme('https')) &&
        uri.host.isNotEmpty;
    if (!ok) {
      if (state.error?.code != 'scan.notSubscription') {
        state = state.copyWith(
          error: () => const AppError('scan.notSubscription'),
        );
      }
      return false;
    }
    state = state.copyWith(
      url: link,
      method: SubscriptionMethod.link,
      error: () => null,
    );
    return true;
  }

  /// A file chosen in the open dialog or dropped on the window.
  void setFile(PickedFile file) => state = state.copyWith(
    method: SubscriptionMethod.file,
    file: () => file,
    error: () => null,
  );

  /// Back to the link (desktop's clear button).
  void clearFile() => state = state.copyWith(
    method: SubscriptionMethod.link,
    file: () => null,
    error: () => null,
  );

  /// Opens the system's open dialog (PRODUCT_SPEC §3.5).
  Future<void> pickFile() async {
    final dialogs = ref.read(fileDialogsProvider);
    final result = await attempt(
      () => dialogs.open(maxBytes: ImportService.maxFileBytes),
    );
    if (!ref.mounted) return;
    switch (result) {
      case Ok(value: final file?):
        setFile(file);
      case Ok():
        break; // Cancelled.
      case Err(:final error):
        state = state.copyWith(error: () => error);
    }
  }

  /// Shows an error that happened outside the view model (a dropped file
  /// that could not be read).
  void showError(AppError error) => state = state.copyWith(error: () => error);

  /// Downloads, validates and saves the subscription. Returns what the
  /// import skipped, or null when it failed (see [AddState.error]) or the
  /// form was closed meanwhile.
  Future<List<ImportWarning>?> saveSubscription({
    required String defaultName,
  }) async {
    if (state.segment != AddSegment.subscription || !state.canSave) {
      return null;
    }
    final cancel = _cancel = FetchCancel();
    final imports = ref.read(importServiceProvider);
    final settings = ref.read(settingsRepositoryProvider);
    final configurations = ref.read(configurationRepositoryProvider);
    final url = state.url;
    final name = state.name.trim();
    final autoUpdate = state.autoUpdate;
    final editing = state.editing;
    final editedAt = state.editedAt;
    final fileOnly = state.fileOnly;
    final file = state.importsFile ? state.file : null;
    state = state.copyWith(saving: true, error: () => null);
    final result = await attempt(() async {
      if (editing != null) {
        // An emptied name keeps the old one.
        final newName = name.isEmpty ? null : name;
        if (fileOnly) {
          await configurations.update(
            editing.id,
            name: newName,
            ifEditedAt: editedAt,
          );
        } else {
          await imports.updateSubscription(
            editing.id,
            url: url,
            name: newName,
            autoUpdate: autoUpdate,
            ifEditedAt: editedAt,
            cancel: cancel,
          );
        }
        return const <ImportWarning>[];
      }
      final saved = file != null
          ? await imports.addFile(
              text: ImportService.decodeText(file.bytes),
              defaultName: defaultName,
              name: name.isEmpty ? null : name,
              fileName: file.name,
              cancel: cancel,
            )
          : await imports.addSubscription(
              url: url,
              defaultName: defaultName,
              name: name.isEmpty ? null : name,
              autoUpdate: autoUpdate,
              cancel: cancel,
            );
      // The first configuration becomes the selected one (D26).
      await settings.updateDevice(
        (s) => s.selectedConfigurationId == null
            ? s.copyWith(selectedConfigurationId: saved.configurationId)
            : s,
      );
      return saved.warnings;
    });
    if (!ref.mounted) return null;
    switch (result) {
      case Ok(:final value):
        state = state.copyWith(saving: false);
        return value;
      case Err(:final error):
        await _saveFailed(error);
        return null;
    }
  }

  // ------------------------------------------------------------ 独立节点

  void setLink(String link) {
    if (link != state.link) {
      state = state.copyWith(link: link, linkError: () => null);
    }
  }

  /// Fills the form from the pasted share link; nothing is saved. An
  /// unknown scheme is an error, never a guess (PRODUCT_SPEC §3.6).
  void parseLink() {
    final text = state.link.trim();
    if (text.isEmpty) return;
    try {
      state = state.copyWith(
        node: NodeDraft.fromLink(parseShareLink(text)),
        linkError: () => null,
        nodeError: () => null,
      );
    } on ImportException catch (e) {
      state = state.copyWith(linkError: () => AppError.from(e));
    }
  }

  void setNodeField(NodeField field, String value) {
    if (value == state.node[field]) return;
    final failed = state.nodeError?.field == field;
    state = state.copyWith(
      node: state.node.set(field, value),
      nodeError: failed ? () => null : null,
    );
  }

  void setProtocol(Protocol protocol) {
    final edited = _editedNode;
    state = state.copyWith(
      node: state.node.copyWith(protocol: protocol),
      nodeError: () => null,
      // Saved secrets belong to the protocol they were saved for.
      savedSecrets: edited == null
          ? null
          : (edited.params.protocol == protocol
                ? _savedSecretsOf(edited)
                : const {}),
    );
  }

  void setTransport(TransportKind transport) => state = state.copyWith(
    node: state.node.copyWith(transport: transport),
    nodeError: () => null,
  );

  void setSecurity(NodeSecurity security) => state = state.copyWith(
    node: state.node.copyWith(security: security),
    nodeError: () => null,
  );

  /// Validates and saves the node into 「自建节点」. False when a field is
  /// wrong (see [AddState.nodeError]) or saving failed ([AddState.error]).
  Future<bool> saveNode() async {
    if (state.segment != AddSegment.node || !state.canSave) return false;
    final editing = state.editing;
    final editedAt = state.editedAt;
    final SelfNode node;
    try {
      node = state.node.build(existing: editing == null ? null : _editedNode);
    } on NodeDraftException catch (e) {
      state = state.copyWith(nodeError: () => e);
      return false;
    }
    state = state.copyWith(
      saving: true,
      nodeError: () => null,
      error: () => null,
    );
    final result = await attempt(
      () async => editing == null
          ? await ref.read(selfContentServiceProvider).addNode(node)
          : await ref
                .read(selfContentRepositoryProvider)
                .updateNode(node, ifEditedAt: editedAt),
    );
    if (!ref.mounted) return false;
    switch (result) {
      case Ok():
        state = state.copyWith(saving: false);
        return true;
      case Err(:final error):
        await _saveFailed(error);
        return false;
    }
  }

  // -------------------------------------------------------------- 代理链

  void setChainName(String name) {
    if (name != state.chain.name) {
      state = state.copyWith(chain: state.chain.withName(name));
    }
  }

  void toggleHopPicker() => state = state.copyWith(hopPicker: !state.hopPicker);

  void addHop(MemberRef hop) =>
      state = state.copyWith(chain: state.chain.add(hop));

  void removeHop(int index) =>
      state = state.copyWith(chain: state.chain.removeAt(index));

  void moveHop(int index, int delta) =>
      state = state.copyWith(chain: state.chain.move(index, delta));

  void toggleChainGroup(String key) => state = state.copyWith(
    chain: state.chain.toggleGroup(
      key,
      defaults: ref.read(chainOptionsProvider).defaultGroups,
    ),
  );

  /// Saves the chain into 「自建节点」 and adds it to the ticked groups.
  /// False when it cannot be saved (see [AddState.error]).
  Future<bool> saveChain() async {
    if (state.segment != AddSegment.chain || !state.canSave) return false;
    final options = ref.read(chainOptionsProvider);
    final Chain chain;
    try {
      chain = state.chain.build();
    } on ChainDraftException {
      // The form cannot produce these; treat as a failed save.
      state = state.copyWith(error: () => const AppError('unknown'));
      return false;
    }
    // Only groups that still exist can be joined.
    final groups = state.chain.groupsOr(options.defaultGroups).intersection({
      for (final g in options.groups) g.key,
    });
    final editing = state.editing;
    final editedAt = state.editedAt;
    state = state.copyWith(saving: true, error: () => null);
    final service = ref.read(selfContentServiceProvider);
    final result = await attempt(
      () async => editing == null
          ? await service.addChain(chain, groupKeys: groups)
          : await service.updateChain(
              chain.copyWith(id: editing.id),
              groupKeys: groups,
              ifEditedAt: editedAt,
            ),
    );
    if (!ref.mounted) return false;
    switch (result) {
      case Ok():
        state = state.copyWith(saving: false);
        return true;
      case Err(:final error):
        await _saveFailed(error);
        return false;
    }
  }
}
