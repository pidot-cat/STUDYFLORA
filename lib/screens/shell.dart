import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../models/cosmetics.dart';
import '../providers/feedback_bus.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/study_provider.dart';
import '../providers/sync_provider.dart';
import '../services/feedback_service.dart';
import '../services/garden_notifications.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../widgets/common.dart';
import '../widgets/gift_widgets.dart';
import '../widgets/profile_widgets.dart';
import 'garden/garden_screen.dart';
import 'home/home_screen.dart';
import 'settings/badges_screen.dart';
import 'settings/settings_screen.dart';
import 'shop/shop_screen.dart';
import 'study/study_screen.dart';

/// Bottom-navigation state (Home, Garden, Study, Shop, Settings — NFR 4.1).
class NavState extends ChangeNotifier {
  int index = 0;
  int shopTab = 0;
  void go(int i, {int? shopTab}) {
    index = i;
    if (shopTab != null) this.shopTab = shopTab;
    notifyListeners();
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  final _visited = <int>{0};
  GameProvider? _game;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final g = context.read<GameProvider>();
    if (_game != g) {
      _game?.removeListener(_maybeCelebrate);
      _game?.removeListener(_maybeWelcome);
      _game = g
        ..addListener(_maybeCelebrate)
        ..addListener(_maybeWelcome);
    }
    final s = context.read<SyncProvider>();
    if (_sync != s) {
      _sync?.removeListener(_maybeWelcome);
      _sync = s..addListener(_maybeWelcome);
    }
    _maybeWelcome();
  }

  SyncProvider? _sync;
  bool _welcomeShowing = false;

  /// New accounts claim their welcome coins from a celebration screen. On a
  /// new phone we wait for the first cloud sync so returning users (whose
  /// coins were claimed long ago) never see it.
  void _maybeWelcome() {
    final g = _game, s = _sync;
    if (_welcomeShowing || g == null || s == null || !g.loaded || !g.welcomePending) return;
    final waitForCloud = s.cloudEnabled && s.lastSyncedAt == 0 && s.status != SyncStatus.failed && s.status != SyncStatus.offline;
    if (waitForCloud) return;
    _welcomeShowing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted && g.welcomePending) await showWelcomeGift(context);
      _welcomeShowing = false;
    });
  }

  @override
  void initState() {
    super.initState();
    celebrationHold.addListener(_maybeCelebrate);
    WidgetsBinding.instance.addObserver(this);
    // Garden reminders only show while the app is closed.
    final notify = context.read<SettingsProvider>().notifications;
    GardenNotifications.instance.cancelAll().then((_) {
      if (notify) GardenNotifications.instance.requestPermission();
    });
    // Send any feedback that was written while offline.
    StorageService.create().then((s) => FeedbackService(s).flush()).catchError((_) => false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final g = _game;
      if (g != null) {
        GardenNotifications.instance.schedule(g, enabled: context.read<SettingsProvider>().notifications);
      }
    } else if (state == AppLifecycleState.resumed) {
      GardenNotifications.instance.cancelAll();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    GardenNotifications.instance.cancelAll(); // logged out / account deleted
    _game?.removeListener(_maybeCelebrate);
    _game?.removeListener(_maybeWelcome);
    _sync?.removeListener(_maybeWelcome);
    celebrationHold.removeListener(_maybeCelebrate);
    super.dispose();
  }

  bool _showing = false;
  void _maybeCelebrate() {
    if (_showing || celebrationHold.value > 0 || _game == null || _game!.celebrations.isEmpty) return;
    _showing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      while (mounted) {
        final id = _game!.takeCelebration();
        if (id == null) break;
        await showBadgeUnlocked(context, Badges.of(id));
      }
      _showing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavState>();
    _visited.add(nav.index);
    final pages = <Widget>[
      const HomeScreen(),
      const GardenScreen(),
      const StudyScreen(),
      ShopScreen(key: ValueKey('shop-${nav.shopTab}'), initialTab: nav.shopTab),
      const SettingsScreen(),
    ];
    return PopScope(
      canPop: nav.index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) nav.go(0);
      },
      child: Scaffold(
        body: Stack(children: [
          IndexedStack(
            index: nav.index,
            children: [
              for (var i = 0; i < pages.length; i++) _visited.contains(i) ? pages[i] : const SizedBox.shrink(),
            ],
          ),
          const RewardOverlay(),
        ]),
        bottomNavigationBar: _BottomNav(index: nav.index, onTap: (i) => nav.go(i)),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.yard_outlined, Icons.yard_rounded, 'Garden'),
    (Icons.menu_book_outlined, Icons.menu_book_rounded, 'Study'),
    (Icons.shopping_bag_outlined, Icons.shopping_bag_rounded, 'Shop'),
    (Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    context.watch<ClockTicker>(); // plants become ready / the daily gift unlocks over time
    final g = context.watch<GameProvider>();
    final now = GameClock.nowMs();
    // Red dot = something to claim on that tab.
    final dots = [
      g.homeClaims,
      g.readyCount(now),
      context.select<StudyProvider, int>((s) => s.pendingRewards),
      g.freeBordersToClaim,
      g.unclaimedBadges,
    ];
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.line)),
        boxShadow: [BoxShadow(color: c.shadow, blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (i != index) HapticFeedback.selectionClick();
                    onTap(i);
                  },
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      // Same width for every tab so labels never wrap on narrow phones.
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: i == index ? c.brandSoft : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Stack(clipBehavior: Clip.none, children: [
                          Icon(i == index ? _items[i].$2 : _items[i].$1, size: 22, color: i == index ? c.brand : c.muted),
                          if (dots[i] > 0)
                            Positioned(
                              right: dots[i] > 1 ? -9 : -4,
                              top: -4,
                              child: RedDot(count: dots[i], size: dots[i] > 1 ? 16 : 12),
                            ),
                        ]),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _items[i].$3,
                            maxLines: 1,
                            softWrap: false,
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                              color: i == index ? c.brand : c.muted,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Floating "+20 coins / +2h Hydration" chips (FR-4.10 visual feedback).
class RewardOverlay extends StatefulWidget {
  const RewardOverlay({super.key});
  @override
  State<RewardOverlay> createState() => _RewardOverlayState();
}

class _RewardOverlayState extends State<RewardOverlay> {
  final _items = <(int, RewardEvent)>[];
  int _seq = 0;
  StreamSubscription<RewardEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = FeedbackBus.instance.stream.listen((e) {
      final id = _seq++;
      setState(() => _items.add((id, e)));
      Future.delayed(const Duration(milliseconds: 3000), () {
        if (mounted) setState(() => _items.removeWhere((x) => x.$1 == id));
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 62,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Column(children: [
          for (final (id, e) in _items.take(3)) _RewardChip(key: ValueKey(id), event: e),
        ]),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({super.key, required this.event});
  final RewardEvent event;

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final (Widget lead, Color tint) = switch (event.kind) {
      RewardKind.coins => (const CoinIcon(size: 22), c.goldSoft),
      RewardKind.xp => (const XpIcon(size: 22), c.brandSoft),
      RewardKind.seed => (Icon(Icons.grass_rounded, color: c.brand, size: 20), c.brandSoft),
      RewardKind.water => (Icon(Icons.water_drop_rounded, color: c.info, size: 20), c.infoSoft),
      RewardKind.tool => (Icon(Icons.handyman_rounded, color: c.terracotta, size: 20), c.terracottaSoft),
      RewardKind.badge => (Icon(Icons.military_tech_rounded, color: c.gold, size: 20), c.goldSoft),
      RewardKind.info => (Icon(Icons.schedule_rounded, color: c.muted, size: 20), c.surface),
    };
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 2900),
      builder: (_, t, child) {
        final inT = (t / 0.11).clamp(0.0, 1.0);
        final outT = ((t - 0.86) / 0.14).clamp(0.0, 1.0);
        return Opacity(
          opacity: (inT * (1 - outT)).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - Curves.easeOutBack.transform(inT)) - 14 * outT),
            child: Transform.scale(scale: 0.85 + 0.15 * Curves.easeOutBack.transform(inT), child: child),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 6),
        padding: const EdgeInsets.fromLTRB(8, 7, 14, 7),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: c.line),
          boxShadow: [BoxShadow(color: c.shadow, blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          lead,
          const SizedBox(width: 8),
          Flexible(child: Text(event.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, color: c.ink, fontSize: 13.5, height: 1.25))),
        ]),
      ),
    );
  }
}

/// "Badge unlocked!" celebration dialog.
Future<void> showBadgeUnlocked(BuildContext context, BadgeDef badge) {
  SoundService.instance.play(Sfx.badge);
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'badge',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (ctx, _, __) {
      final c = ctx.sf;
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 310,
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(28)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('ACHIEVEMENT UNLOCKED', style: ctx.tt.labelSmall?.copyWith(color: c.gold)),
              const SizedBox(height: 16),
              BadgeMedal(badge: badge, size: 96),
              const SizedBox(height: 16),
              Text(badge.name, style: ctx.tt.titleLarge),
              const SizedBox(height: 4),
              Text(badge.description, style: ctx.tt.bodySmall, textAlign: TextAlign.center),
              if (badge.rewardCoins > 0 || badge.rewardXp > 0) ...[
                const SizedBox(height: 12),
                StatusBadge(
                  'Reward: ${badge.rewardCoins > 0 ? '${badge.rewardCoins} coins' : '${badge.rewardXp} XP'}',
                  tone: Tone.gold,
                  icon: Icons.card_giftcard_rounded,
                ),
              ],
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'Claim in Badges',
                height: 48,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BadgesScreen()));
                },
              ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Later', style: TextStyle(color: c.muted))),
            ]),
          ),
        ),
      );
    },
    transitionBuilder: (_, a, __, child) => ScaleTransition(
      scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: a, child: child),
    ),
  );
}
