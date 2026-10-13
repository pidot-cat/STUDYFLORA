import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/nav_provider.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_header.dart';
import 'home/home_screen.dart';
import 'garden/garden_screen.dart';
import 'settings/settings_screen.dart';
import 'shop/shop_screen.dart';
import 'study/study_screen.dart';

/// Header + bottom navigation + the five tabs.
/// IndexedStack keeps each tab's scroll position and state alive.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final index = context.watch<NavProvider>().index;
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: IndexedStack(
              index: index,
              children: const [
                HomeScreen(),
                GardenScreen(),
                StudyScreen(),
                ShopScreen(),
                SettingsScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }
}
