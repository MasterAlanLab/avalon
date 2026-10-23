import 'dart:async';

import 'package:tray_manager/tray_manager.dart';

/// One entry of the tray menu (D31).
final class TrayItem {
  const TrayItem(
    this.key,
    this.label, {
    this.checked,
    this.enabled = true,
    this.children = const [],
  });

  const TrayItem.separator()
    : key = '',
      label = '',
      checked = null,
      enabled = true,
      children = const [];

  final String key;
  final String label;

  /// Null for an entry without a check mark.
  final bool? checked;
  final bool enabled;
  final List<TrayItem> children;

  bool get isSeparator => key.isEmpty;
}

/// The menu bar (macOS) or system tray icon and its menu.
abstract interface class SystemTray {
  /// Shows the icon; false where there is no tray (some Linux desktops).
  Future<bool> show(String icon);

  Future<void> setIcon(String icon);
  Future<void> setMenu(List<TrayItem> items);

  /// The key of the menu entry chosen.
  Stream<String> get choices;
}

final class TrayManagerTray with TrayListener implements SystemTray {
  final _choices = StreamController<String>.broadcast();

  @override
  Stream<String> get choices => _choices.stream;

  @override
  Future<bool> show(String icon) async {
    try {
      await trayManager.setIcon(icon);
    } on Object {
      return false;
    }
    trayManager.addListener(this);
    return true;
  }

  @override
  Future<void> setIcon(String icon) => trayManager.setIcon(icon);

  @override
  Future<void> setMenu(List<TrayItem> items) => trayManager.setContextMenu(
    Menu(items: [for (final i in items) _item(i)]),
  );

  static MenuItem _item(TrayItem i) {
    if (i.isSeparator) return MenuItem.separator();
    if (i.children.isNotEmpty) {
      return MenuItem.submenu(
        key: i.key,
        label: i.label,
        submenu: Menu(items: [for (final c in i.children) _item(c)]),
      );
    }
    if (i.checked != null) {
      return MenuItem.checkbox(
        key: i.key,
        label: i.label,
        checked: i.checked,
        disabled: !i.enabled,
      );
    }
    return MenuItem(key: i.key, label: i.label, disabled: !i.enabled);
  }

  // Either click opens the menu, as menu bar items do.
  @override
  void onTrayIconMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final key = menuItem.key;
    if (key != null) _choices.add(key);
  }
}
