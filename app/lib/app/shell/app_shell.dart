import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../layout.dart';
import 'desktop_shell.dart';
import 'mobile_shell.dart';

/// One set of routes, two presentations: tabs on phones, sidebar and
/// toolbar on wide windows.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => isWideLayout(context)
      ? DesktopShell(shell: shell)
      : MobileShell(shell: shell);
}
