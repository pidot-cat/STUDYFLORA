import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../models/plant.dart';
import '../../providers/garden_provider.dart';
import '../../providers/nav_provider.dart';
import '../../providers/study_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/pill.dart';
import '../../widgets/section_header.dart';
import '../garden/garden_actions.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final garden = context.watch<GardenProvider>();
    final now = DateTime.now();
    final thirsty = garden.thirstiest(now);
    final entries = garden
        .plantEntries(now)
        .where((e) => thirsty == null || e.key != thirsty.key)
        .toList();
    final growingCount = entries.where((e) => !e.value.isReady(now)).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const _StreakCard(),
        const SizedBox(height: 16),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: thirsty == null
                ? const SizedBox(key: ValueKey('none'), width: double.infinity)
                : Padding(
                    key: ValueKey('thirsty_${thirsty.key}'),
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _ThirstyCard(plant: thirsty.value, now: now),
                  ),
          ),
        ),
        SectionHeader(
          title: 'Active Crops & Harvest',
          trailing: '$growingCount GROWING',
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty && thirsty == null)
          const _NoCropsCard()
        else
          for (final e in entries) ...[
            _CropTile(plant: e.value, now: now, index: e.key),
            const SizedBox(height: 12),
          ],
        const SizedBox(height: 8),
        const SectionHeader(title: 'Quick Shortcuts', trailing: 'NAVIGATION'),
        const SizedBox(height: 12),
        const _Shortcuts(),
      ],
    );
  }
}

class _NoCropsCard extends StatelessWidget {
  const _NoCropsCard();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return AppCard(
      onTap: () => openGarden(context),
      child: Row(
        children: [
          Icon(Icons.yard_outlined, color: p.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nothing is growing yet. Open the Zen Garden to plant your first seed.',
              style: TextStyle(color: p.textMuted, fontSize: 14.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final streak = context.select<UserProvider, int>((u) => u.streak);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: p.warmSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.local_fire_department_outlined,
                color: p.warmText, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$streak Day Study Streak',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Study daily to boost nursery growth',
                    style: TextStyle(color: p.textMuted, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Pill(
            label: 'Active',
            background: p.warmSoft,
            foreground: p.warmText,
            fontSize: 11.5,
            borderColor: p.warmText.withAlpha(60),
          ),
        ],
      ),
    );
  }
}

class _ThirstyCard extends StatelessWidget {
  const _ThirstyCard({required this.plant, required this.now});

  final Plant plant;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final paused = plant.isThirsty(now);
    return AppCard(
      color: p.alertBg,
      borderColor: p.alertBorder,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(Icons.water_drop_outlined, color: p.alertMuted, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${plant.type.name} needs water!',
                    style: TextStyle(
                        color: p.alertTitle, fontSize: 19, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(paused ? 'Hydration low • Growth paused' : 'Hydration low • Water soon',
                    style: TextStyle(color: p.alertMuted, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: p.primary,
              foregroundColor: p.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            onPressed: () {
              final msg = messageFor(context.read<GardenProvider>().waterThirstiest());
              if (msg != null) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(msg)));
              }
            },
            icon: const Icon(Icons.water_drop_outlined, size: 18),
            label: const Text('Water', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _CropTile extends StatelessWidget {
  const _CropTile({required this.plant, required this.now, required this.index});

  final Plant plant;
  final DateTime now;
  final int index;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ready = plant.isReady(now);
    final warm = index.isOdd;
    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () {
        context.read<GardenProvider>().select(index);
        openGarden(context);
      },
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: warm ? p.warmSoft : p.primarySoft,
              borderRadius: BorderRadius.circular(14),
              border: isDark ? Border.all(color: p.border) : null,
            ),
            child: Icon(warm ? Icons.yard_outlined : Icons.eco_outlined,
                color: warm ? p.warmText : p.onPrimarySoft),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plant.type.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(ready ? Icons.star_rounded : Icons.schedule,
                        size: 15, color: p.onPrimarySoft),
                    const SizedBox(width: 5),
                    Text(
                        ready
                            ? 'Ready to claim +${plant.type.xp} XP'
                            : '${formatCountdown(plant.untilReady(now))} until harvest',
                        style: TextStyle(
                            color: p.onPrimarySoft,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Pill(
            label: ready ? 'READY' : 'GROWING',
            background: ready ? p.warmSoft : p.primarySoft,
            foreground: ready ? p.warmText : p.onPrimarySoft,
            fontSize: 11,
            borderColor: isDark ? (ready ? p.warmText : p.onPrimarySoft).withAlpha(90) : null,
          ),
        ],
      ),
    );
  }
}

class _Shortcuts extends StatelessWidget {
  const _Shortcuts();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final nav = context.read<NavProvider>();
    final items = <_Shortcut>[
      _Shortcut('Zen Garden', Icons.yard_outlined, p.primarySoft, p.onPrimarySoft,
          NavProvider.garden),
      _Shortcut('AI Hub', Icons.quiz_outlined, p.warmSoft, p.warmText, NavProvider.study),
      _Shortcut(
          'Shop',
          Icons.storefront_outlined,
          Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2E1A1C)
              : const Color(0xFFB7D3C4),
          Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFE5736A)
              : p.primary,
          NavProvider.shop),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: AppCard(
              onTap: () {
                if (items[i].label == 'AI Hub') {
                  context.read<StudyProvider>().showAiHub();
                }
                nav.go(items[i].tab);
              },
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
              child: Column(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: items[i].bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(items[i].icon, color: items[i].fg, size: 24),
                  ),
                  const SizedBox(height: 10),
                  Text(items[i].label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Shortcut {
  const _Shortcut(this.label, this.icon, this.bg, this.fg, this.tab);
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  final int tab;
}
