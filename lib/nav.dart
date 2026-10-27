import 'package:flutter/material.dart';

import 'screens/shell/main_shell.dart';

/// Push inside the current tab (bottom navigation stays visible).
Future<T?> pushTab<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

/// Push full-screen above the shell (no bottom navigation) – used for
/// screens whose mock-ups have no tab bar.
Future<T?> pushRoot<T>(BuildContext context, Widget page) =>
    Navigator.of(context, rootNavigator: true).push<T>(MaterialPageRoute(builder: (_) => page));

/// Replace the whole app stack (auth → shell, logout → sign in).
void goRoot(BuildContext context, Widget page) => Navigator.of(context, rootNavigator: true)
    .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => page), (_) => false);

/// Jump to a bottom-nav tab (0 Home, 1 Garden, 2 Study, 3 Shop, 4 Settings).
void goTab(BuildContext context, int index, {bool resetStack = true}) {
  final nav = Navigator.of(context, rootNavigator: true);
  nav.popUntil((r) => r.isFirst);
  MainShell.controller.value = ShellRequest(index, resetStack);
}
