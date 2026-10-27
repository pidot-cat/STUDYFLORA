import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../nav.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_header.dart';
import '../../widgets/common.dart';
import '../garden/garden_screen.dart';
import 'inventory_screen.dart';
import 'subject_screens.dart';

IconData plantGlyph(String flowerId) {
  switch (flowerId) {
    case 'sunflower':
      return Icons.wb_sunny_outlined;
    case 'lavender':
      return Icons.grass;
    case 'rose':
      return Icons.filter_vintage_outlined;
    case 'daisy':
      return Icons.local_florist_outlined;
    default:
      return Icons.local_florist_outlined;
  }
}

IconData moduleGlyph(String key) {
  switch (key) {
    case 'microscope':
      return Icons.biotech_outlined;
    case 'sun':
      return Icons.wb_sunny_outlined;
    case 'gauge':
      return Icons.speed;
    case 'phone':
      return Icons.crop_portrait;
    case 'genetics':
      return Icons.block;
    case 'cloud':
      return Icons.cloud_upload_outlined;
    case 'flask':
      return Icons.science_outlined;
    default:
      return Icons.description_outlined;
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = context.c;
    final plants = [...s.plants]..sort((a, b) => a.pot.compareTo(b.pot));
    final seedIds = s.ownedSeedIds;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const AppHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                _GreetingCard(),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _StatCard(label: 'COINS', value: '${s.coins}', coin: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(label: 'XP', value: '${s.xp}', suffix: 'XP')),
                ]),
                const SizedBox(height: 22),
                SectionHeader('Active Plants',
                    trailing: Pill('${s.plants.length} / ${GardenRules.potCount} pots',
                        bg: c.isDark ? Colors.transparent : const Color(0xFFE8ECFB),
                        fg: c.isDark ? c.textMuted : const Color(0xFF334155),
                        borderColor: c.isDark ? c.border : null,
                        weight: FontWeight.w500,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5))),
                const SizedBox(height: 12),
                if (plants.isEmpty)
                  SFCard(
                    onTap: () => _openGarden(context, null),
                    child: Text('No active plants yet. Plant a seed in your garden!', style: T.p(13, c: c.textMuted)),
                  ),
                for (final p in plants.take(3)) ...[
                  _PlantCard(plant: p),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 10),
                SectionHeader('Inventory',
                    action: 'See All ›', onAction: () => pushTab(context, const InventoryScreen())),
                const SizedBox(height: 12),
                if (seedIds.isEmpty)
                  SFCard(child: Text('No seeds yet. Visit the Shop to buy some.', style: T.p(13, c: c.textMuted))),
                for (var i = 0; i < seedIds.length && i < 2; i++) ...[
                  _SeedRow(flower: Flowers.byId(seedIds[i]), count: s.seedCount(seedIds[i]), alt: i.isOdd),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 10),
                SectionHeader('Study Progress',
                    action: 'See All ›', onAction: () => pushRoot(context, const SubjectsListScreen())),
                const SizedBox(height: 12),
                for (final m in s.modules.where((m) => m.bestScore >= 0).take(3)) ...[
                  _StudyRow(module: m),
                  const SizedBox(height: 12),
                ],
                SFCard(
                  onTap: () => goTab(context, 1),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: Row(children: [
                    IconTile(Icons.contrast,
                        circle: !c.isDark,
                        size: c.isDark ? 44 : 48,
                        bg: c.isDark ? c.cardAlt : const Color(0xFFD7F2E0)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Harvest XP', style: T.p(16, w: FontWeight.w700, c: c.heading)),
                        const SizedBox(height: 2),
                        Text('Earn XP by harvesting fully grown plants.', style: T.p(12.5, c: c.textMuted)),
                      ]),
                    ),
                    Icon(c.isDark ? Icons.arrow_upward : Icons.spa, size: 16, color: c.mintText),
                  ]),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

void _openGarden(BuildContext context, int? pot) {
  GardenScreen.selection.value = pot;
  goTab(context, 1);
}

class _GreetingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final h = DateTime.now().hour;
    final greet = h < 12 ? 'Good morning!' : (h < 18 ? 'Good day!' : 'Good evening!');
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: c.isDark ? c.card : null,
        gradient: c.isDark ? null : const LinearGradient(colors: [Color(0xFFADEDC8), Color(0xFFC2F2D6)]),
        borderRadius: BorderRadius.circular(18),
        border: c.isDark ? Border.all(color: c.border) : null,
      ),
      child: Row(children: [
        c.isDark
            ? IconTile(Icons.yard_outlined, size: 44, bg: c.cardAlt, fg: c.accent)
            : Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.yard_outlined, color: Color(0xFF145630), size: 22),
              ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(greet, style: T.p(17, w: FontWeight.w700, c: c.isDark ? c.text : const Color(0xFF0F2B20))),
            Text('Keep studying and grow your garden!',
                style: T.p(12.5, c: c.isDark ? c.textMuted : const Color(0xFF1F3B30))),
          ]),
        ),
        Icon(Icons.lightbulb_outline, color: c.isDark ? c.accent : const Color(0xFF3E8E64), size: 24),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool coin;
  final String? suffix;
  const _StatCard({required this.label, required this.value, this.coin = false, this.suffix});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      height: 88,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: c.isDark ? c.card : const Color(0xFFE4F8EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.isDark ? c.border : const Color(0xFFCDEFD9)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (coin)
            const CoinGlyph(size: 16)
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                  color: c.isDark ? Colors.transparent : Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Text('XP', style: T.p(9.5, w: FontWeight.w700, c: c.isDark ? c.accent : c.textMuted)),
            ),
          if (coin) ...[
            const SizedBox(width: 6),
            Text(label, style: T.p(11, w: FontWeight.w600, c: c.textMuted, ls: .5)),
          ],
        ]),
        const Spacer(),
        RichText(
          text: TextSpan(children: [
            TextSpan(text: value, style: T.p(22, w: FontWeight.w700, c: c.isDark ? c.text : const Color(0xFF0F2B20))),
            if (suffix != null)
              TextSpan(
                  text: suffix,
                  style: T.p(c.isDark ? 18 : 16,
                      w: c.isDark ? FontWeight.w400 : FontWeight.w700,
                      c: c.isDark ? c.textMuted : const Color(0xFF0F2B20))),
          ]),
        ),
      ]),
    );
  }
}

class _PlantCard extends StatelessWidget {
  final Plant plant;
  const _PlantCard({required this.plant});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.read<AppState>();
    final dry = plant.needsWater;
    final ready = plant.ready;
    final f = plant.flower;
    final title = dry && c.isDark ? '${f.name} needs water! 💧' : f.name;
    final subtitle = ready
        ? 'Ready to harvest'
        : (dry
            ? (c.isDark ? 'Hydration low • Growth paused' : 'Needs water • Growth paused')
            : '${fmtHm(plant.remaining)} until harvest');
    final darkDry = c.isDark && dry;
    return SFCard(
      onTap: () => _openGarden(context, plant.pot),
      color: darkDry ? const Color(0xFF3A1519) : null,
      borderColor: darkDry ? const Color(0xFF7A2A30) : null,
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      child: Column(children: [
        Row(children: [
          IconTile(
            darkDry ? Icons.shield_outlined : plantGlyph(f.id),
            circle: !c.isDark,
            size: c.isDark ? 44 : 46,
            bg: c.isDark
                ? (darkDry ? const Color(0xFF4A1A20) : c.cardAlt)
                : (dry ? const Color(0xFFE3E8FB) : const Color(0xFFE2F5E9)),
            fg: darkDry
                ? const Color(0xFFF87171)
                : (c.isDark
                    ? (f.id == 'rose' ? c.coin : c.accent)
                    : (dry ? const Color(0xFF3346A8) : const Color(0xFF145630))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: T.p(15, w: FontWeight.w700, c: c.isDark ? c.text : const Color(0xFF0F2B20))),
              Text(subtitle,
                  style:
                      T.p(12, c: dry ? (c.isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)) : c.textMuted)),
            ]),
          ),
          if (dry)
            Material(
              color: c.isDark ? const Color(0xFF6EE7B7) : const Color(0xFF145630),
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () {
                  if (!s.water(plant.pot)) showSnack(context, 'No watering can charges left.');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(c.isDark ? Icons.water_drop_outlined : Icons.water_drop,
                        size: 14, color: c.isDark ? const Color(0xFF07140F) : Colors.white),
                    const SizedBox(width: 6),
                    Text('Water',
                        style: T.p(12.5, w: FontWeight.w600, c: c.isDark ? const Color(0xFF07140F) : Colors.white)),
                  ]),
                ),
              ),
            )
          else
            Pill(
              ready ? (c.isDark ? 'READY' : 'Ready') : (c.isDark ? 'GROWING' : 'Growing'),
              bg: c.isDark ? Colors.transparent : const Color(0xFFCDEFD9),
              fg: c.isDark ? c.accent : const Color(0xFF145630),
              borderColor: c.isDark ? const Color(0xFF2B6B53) : null,
              fontSize: c.isDark ? 11 : 12,
              weight: FontWeight.w700,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: c.textMuted, size: 20),
        ]),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: SFProgress(
            value: plant.progress,
            height: 7,
            color: darkDry ? const Color(0xFFF87171) : (c.isDark ? c.accent : const Color(0xFF145630)),
            track: c.isDark ? c.border : const Color(0xFFE2E8F0),
          ),
        ),
      ]),
    );
  }
}

class _SeedRow extends StatelessWidget {
  final Flower flower;
  final int count;
  final bool alt;
  const _SeedRow({required this.flower, required this.count, required this.alt});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SFCard(
      onTap: () => pushTab(context, const InventoryScreen()),
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      child: Row(children: [
        c.isDark
            ? Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: c.cardAlt, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.border)),
                alignment: Alignment.center,
                child: Text(flower.emoji, style: const TextStyle(fontSize: 20)),
              )
            : FlowerIcon(flower, size: 44, useEmoji: true),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${flower.name} Seeds',
                style: T.p(14.5, w: FontWeight.w700, c: c.isDark ? c.text : const Color(0xFF0F2B20))),
            Text('Plant in an empty pot to grow a ${flower.name}.', style: T.p(12, c: c.textMuted, h: 1.35)),
          ]),
        ),
        const SizedBox(width: 6),
        Container(
          padding: EdgeInsets.symmetric(horizontal: c.isDark ? 10 : 12, vertical: c.isDark ? 4 : 6),
          decoration: BoxDecoration(
            color: c.isDark ? Colors.transparent : (alt ? const Color(0xFFDDE3FB) : const Color(0xFFCDEFD9)),
            borderRadius: BorderRadius.circular(16),
            border: c.isDark ? Border.all(color: alt ? const Color(0xFF2B4B6B) : const Color(0xFF2B6B53)) : null,
          ),
          child: Text(c.isDark ? 'x$count Seeds' : 'x$count\nSeeds',
              textAlign: TextAlign.center,
              style: T.p(11.5,
                  w: FontWeight.w700,
                  c: c.isDark
                      ? (alt ? const Color(0xFF7DD3FC) : c.accent)
                      : (alt ? const Color(0xFF283593) : const Color(0xFF145630)),
                  h: 1.25)),
        ),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right, color: c.textMuted, size: 20),
      ]),
    );
  }
}

class _StudyRow extends StatelessWidget {
  final StudyModule module;
  const _StudyRow({required this.module});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final m = module.mastered;
    return SFCard(
      onTap: () => pushRoot(context, SubjectProgressScreen(moduleId: module.id)),
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      child: Column(children: [
        Row(children: [
          IconTile(moduleGlyph(module.iconKey),
              circle: !c.isDark,
              size: c.isDark ? 44 : 46,
              bg: c.isDark ? c.cardAlt : (m ? const Color(0xFFE2F5E9) : const Color(0xFFE3E8FB)),
              fg: c.isDark ? c.accent : (m ? const Color(0xFF145630) : const Color(0xFF3346A8))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(module.title, style: T.p(14.5, w: FontWeight.w700, c: c.isDark ? c.text : const Color(0xFF0F2B20))),
              Text('Best Score: ${module.bestScore}%', style: T.p(12, c: c.textMuted)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: c.isDark ? Colors.transparent : (m ? const Color(0xFFCDEFD9) : const Color(0xFFDDE3FB)),
              borderRadius: BorderRadius.circular(16),
              border: c.isDark ? Border.all(color: m ? const Color(0xFF2B6B53) : c.border) : null,
            ),
            child: Text(
              c.isDark ? (m ? 'MASTERED' : 'NOT\nMASTERED') : (m ? 'Mastered' : 'Not\nMastered'),
              textAlign: TextAlign.center,
              style: T.p(c.isDark ? 11 : 12,
                  w: FontWeight.w700,
                  c: c.isDark ? (m ? c.accent : c.textMuted) : (m ? const Color(0xFF145630) : const Color(0xFF283593)),
                  h: 1.25),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: c.textMuted, size: 20),
        ]),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: SFProgress(
            value: module.bestScore / 100,
            height: 7,
            color: c.isDark
                ? (m ? c.accent : const Color(0xFF3F5E50))
                : (m ? const Color(0xFF145630) : const Color(0xFF5B6B63)),
          ),
        ),
      ]),
    );
  }
}
