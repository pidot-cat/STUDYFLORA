import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../garden/garden_screen.dart';
import '../home/home_screen.dart';
import '../settings/settings_screen.dart';
import '../shop/shop_screen.dart';
import '../study/study_review_screen.dart';

class ShellRequest {
  final int index;
  final bool reset;
  final int stamp;
  ShellRequest(this.index, this.reset) : stamp = DateTime.now().microsecondsSinceEpoch;
}

/// Hosts the five tabs. Each tab owns a nested Navigator so sub screens keep
/// the bottom navigation bar exactly as in the mock-ups.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static final controller = ValueNotifier<ShellRequest>(ShellRequest(0, false));

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _keys = List.generate(5, (_) => GlobalKey<NavigatorState>());

  static const _roots = <Widget>[
    HomeScreen(),
    GardenScreen(),
    StudyReviewScreen(),
    ShopScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _index = MainShell.controller.value.index;
    MainShell.controller.addListener(_onRequest);
  }

  @override
  void dispose() {
    MainShell.controller.removeListener(_onRequest);
    super.dispose();
  }

  void _onRequest() {
    final r = MainShell.controller.value;
    if (r.reset) _keys[r.index].currentState?.popUntil((route) => route.isFirst);
    if (mounted) setState(() => _index = r.index);
  }

  void _select(int i) {
    if (i == _index) {
      _keys[i].currentState?.popUntil((r) => r.isFirst);
    } else {
      setState(() => _index = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final nav = _keys[_index].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else if (_index != 0) {
          setState(() => _index = 0);
        } else {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        backgroundColor: c.bg,
        body: IndexedStack(
          index: _index,
          children: [
            for (var i = 0; i < 5; i++)
              Navigator(
                key: _keys[i],
                onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => _roots[i]),
              ),
          ],
        ),
        bottomNavigationBar: BottomNav(index: _index, onTap: _select),
      ),
    );
  }
}

class BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const BottomNav({super.key, required this.index, required this.onTap});

  static const items = [
    (Icons.home_outlined, 'Home'),
    (Icons.spa_outlined, 'Garden'),
    (Icons.menu_book_outlined, 'Study'),
    (Icons.shopping_bag_outlined, 'Shop'),
    (Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.navBg,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: Center(child: _NavItem(icon: items[i].$1, label: items[i].$2, active: i == index)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  const _NavItem({required this.icon, required this.label, required this.active});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (c.isDark) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
          decoration: BoxDecoration(
            color: active ? c.mintStrong : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: active ? Border.all(color: const Color(0xFF2B6B53)) : null,
          ),
          child: Icon(icon, size: 20, color: active ? c.accent : c.textMuted),
        ),
        const SizedBox(height: 3),
        Text(label, style: T.p(11, w: active ? FontWeight.w600 : FontWeight.w500, c: active ? c.accent : c.textMuted)),
      ]);
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 64,
      height: 52,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFB8EFCD) : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 20, color: const Color(0xFF1F3B30)),
        const SizedBox(height: 2),
        Text(label, style: T.p(11, w: FontWeight.w500, c: const Color(0xFF1F3B30))),
      ]),
    );
  }
}
