import 'package:av_core/av_core.dart';

/// Route locations. Features navigate by these and never import each other.
abstract final class Routes {
  static const dashboard = '/dashboard';
  static const proxies = '/proxies';
  static const configurations = '/configurations';
  static const tools = '/tools';

  /// A page of the tools tab: pushed on phones, shown in the right pane on
  /// desktop (PRODUCT_SPEC §2).
  static String tool(Tool tool) => '$tools/${tool.name}';

  /// Licences and notices, below About.
  static final licenses = '${tool(Tool.about)}/licenses';

  /// One package's licences.
  static String license(String package) =>
      '$licenses/${Uri.encodeComponent(package)}';

  /// The add form: a sheet on phones, a dialog on desktop, above whatever
  /// page opened it. Pops with an [AddResult] when something was saved.
  static const add = '/add';

  /// The same form editing one object (PRODUCT_SPEC §3.4); pops with
  /// nothing and leaves the page underneath as it was.
  static String edit(EditKind kind, String id) => '/edit/${kind.name}/$id';

  /// The JSON override editor (PRODUCT_SPEC §3.10), opened like a form.
  static const override = '/override';

  /// The compiled configuration, read-only.
  static const generated = '/generated';

  /// The proxies page showing 「自定义」, where new nodes and chains land.
  static final proxiesCustom = Uri(
    path: proxies,
    queryParameters: {proxiesGroup: ContentKeys.custom},
  ).toString();

  /// Query parameter of [proxies]: the group to show.
  static const proxiesGroup = 'group';
}

/// What the add form saved.
sealed class AddResult {
  const AddResult();
}

/// A subscription or file; [warnings] is what the import skipped or
/// approximated (D28, D29).
final class ConfigurationAdded extends AddResult {
  const ConfigurationAdded(this.warnings);

  final List<ImportWarning> warnings;
}

/// A self node or chain: the form returns to 「自定义」 on the proxies page
/// (PRODUCT_SPEC §3.6–3.7).
final class SelfContentAdded extends AddResult {
  const SelfContentAdded();
}

enum EditKind { configuration, node, chain }

/// What an edit form is editing.
final class EditTarget {
  const EditTarget(this.kind, this.id);

  final EditKind kind;
  final String id;
}

/// Cloud is registered only for an explicitly enabled development preview.
enum Tool {
  connections,
  logs,
  basic,
  advanced,
  apps,
  geo,
  tailscale,
  about,
  cloud,
}
