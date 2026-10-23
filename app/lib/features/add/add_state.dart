import 'package:av_core/av_core.dart';

import '../../app/app_error.dart';
import '../../app/routes.dart';
import '../../platform/file_dialogs.dart';

enum AddSegment { subscription, node, chain }

/// Where a subscription comes from (V3 3d): a link, a QR code that fills
/// in the link, or a local file.
enum SubscriptionMethod { link, scan, file }

/// State of the add form (PRODUCT_SPEC §3.5–3.7).
final class AddState {
  const AddState({
    this.segment = AddSegment.subscription,
    this.url = '',
    this.name = '',
    this.autoUpdate = true,
    this.method = SubscriptionMethod.link,
    this.file,
    this.node = const NodeDraft(),
    this.link = '',
    this.linkError,
    this.nodeError,
    this.chain = const ChainDraft(),
    this.hopPicker = false,
    this.editing,
    this.loading = false,
    this.editedAt,
    this.fileOnly = false,
    this.savedSecrets = const {},
    this.saving = false,
    this.error,
  });

  final AddSegment segment;

  // 订阅
  final String url;
  final String name;
  final bool autoUpdate;
  final SubscriptionMethod method;

  /// The chosen local file.
  final PickedFile? file;

  /// Saving imports [file] rather than downloading the link.
  bool get importsFile => method == SubscriptionMethod.file;

  // 独立节点
  final NodeDraft node;

  /// The share link box above the form.
  final String link;

  /// Why the pasted link could not be read.
  final AppError? linkError;

  /// The first field that keeps the node from being saved.
  final NodeDraftException? nodeError;

  // 代理链
  final ChainDraft chain;

  /// The «添加一跳» list is open.
  final bool hopPicker;

  // 编辑（PRODUCT_SPEC §3.4）

  /// The object being edited; null when adding.
  final EditTarget? editing;

  /// The object is being read into the form.
  final bool loading;

  /// When the edited object was last changed, as the form read it.
  final DateTime? editedAt;

  /// Editing a local file configuration: only the name can change.
  final bool fileOnly;

  /// Secret fields of the edited node that have a saved value; left empty
  /// they stay as they are.
  final Set<NodeField> savedSecrets;

  /// A download or save is running; «取消» stops a download.
  final bool saving;

  /// Shown inside the form; what was typed stays.
  final AppError? error;

  bool get canSave {
    if (saving || loading || error?.code == 'edit.missing') return false;
    return switch (segment) {
      AddSegment.subscription =>
        fileOnly || (importsFile ? file != null : url.trim().isNotEmpty),
      AddSegment.node => true,
      AddSegment.chain => chain.canSave,
    };
  }

  AddState copyWith({
    AddSegment? segment,
    String? url,
    String? name,
    bool? autoUpdate,
    SubscriptionMethod? method,
    PickedFile? Function()? file,
    NodeDraft? node,
    String? link,
    AppError? Function()? linkError,
    NodeDraftException? Function()? nodeError,
    ChainDraft? chain,
    bool? hopPicker,
    EditTarget? editing,
    bool? loading,
    DateTime? editedAt,
    bool? fileOnly,
    Set<NodeField>? savedSecrets,
    bool? saving,
    AppError? Function()? error,
  }) => AddState(
    segment: segment ?? this.segment,
    url: url ?? this.url,
    name: name ?? this.name,
    autoUpdate: autoUpdate ?? this.autoUpdate,
    method: method ?? this.method,
    file: file == null ? this.file : file(),
    node: node ?? this.node,
    link: link ?? this.link,
    linkError: linkError == null ? this.linkError : linkError(),
    nodeError: nodeError == null ? this.nodeError : nodeError(),
    chain: chain ?? this.chain,
    hopPicker: hopPicker ?? this.hopPicker,
    editing: editing ?? this.editing,
    loading: loading ?? this.loading,
    editedAt: editedAt ?? this.editedAt,
    fileOnly: fileOnly ?? this.fileOnly,
    savedSecrets: savedSecrets ?? this.savedSecrets,
    saving: saving ?? this.saving,
    error: error == null ? this.error : error(),
  );
}
