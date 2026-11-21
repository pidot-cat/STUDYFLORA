import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/cosmetics.dart';
import '../../models/flower.dart';
import '../../models/pot.dart';
import '../../providers/feedback_bus.dart';
import '../../providers/game_provider.dart';
import '../../providers/study_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/gift_widgets.dart';
import '../../widgets/plant_widgets.dart';
import '../../widgets/profile_widgets.dart';
import '../../widgets/sheets.dart';
import '../../widgets/streak_calendar.dart';
import '../garden/plant_details_screen.dart';
import '../shell.dart';
import '../study/module_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<ClockTicker>();
    final g = context.watch<GameProvider>();
    final study = context.watch<StudyProvider>();
    final now = GameClock.nowMs();
    final c = context.sf;
    final active = g.activePots()
      ..sort((a, b) {
        int rank(Pot p) => p.isReadyAt(now) ? 0 : (p.needsWaterAt(now) ? 1 : 2);
        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : a.remainingAt(now).compareTo(b.remainingAt(now));
      });
    final nav = context.read<NavState>();
    final modules = [...study.modules]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return SafeArea(
      bottom: false,
      child: Column(children: [
        const SfTopBar(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
            children: [
              const StreakCalendar(),
              const DailyGiftCard(),

              // ---- plants
              if (active.isNotEmpty) ...[
                SectionHeader('Your Plants', trailing: 'Inventory', onTrailing: () => showInventorySheet(context)),
                for (final p in active.take(3)) _ActivePlantTile(pot: p, now: now),
                if (active.length > 3)
                  Center(
                    child: TextButton(
                      onPressed: () => nav.go(1),
                      child: Text('View all ${active.length} plants in the garden',
                          style: TextStyle(color: c.brand, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _QuickRow(
                    icon: Icons.inventory_2_outlined,
                    title: 'Inventory',
                    subtitle: '${g.totalSeeds} seed${g.totalSeeds == 1 ? '' : 's'} • ${g.fertilizers} fertilizer • ${g.shovels} shovel',
                    onTap: () => showInventorySheet(context),
                  ),
                ),

              // ---- study
              SectionHeader('Continue Studying', trailing: modules.isEmpty ? null : 'See All', onTrailing: () => nav.go(2)),
              if (modules.isEmpty)
                _QuickRow(
                  icon: Icons.upload_file_rounded,
                  title: 'Upload your first module',
                  subtitle: 'Turn notes into key points and a quiz',
                  onTap: () => nav.go(2),
                )
              else
                for (final m in modules.take(2))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SfCard(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ModuleScreen(moduleId: m.id))),
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        IconTile(Icons.menu_book_rounded, size: 44),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(m.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleSmall),
                            const SizedBox(height: 6),
                            SfProgressBar(value: m.bestScore < 0 ? 0 : m.bestScore / 100, color: m.mastered ? c.accent : c.info, height: 6),
                            const SizedBox(height: 4),
                            Text(m.bestScore < 0 ? 'Not taken yet' : 'Best score ${m.bestScore}%${m.mastered ? ' • Mastered' : ''}',
                                style: context.tt.bodySmall),
                          ]),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.chevron_right_rounded, color: c.muted),
                      ]),
                    ),
                  ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _QuickRow extends StatelessWidget {
  const _QuickRow({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SfCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          IconTile(icon, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: context.tt.titleSmall),
              Text(subtitle, style: context.tt.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: context.sf.muted),
        ]),
      );
}

class _ActivePlantTile extends StatelessWidget {
  const _ActivePlantTile({required this.pot, required this.now});
  final Pot pot;
  final int now;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final f = pot.flower!;
    final thirsty = pot.needsWaterAt(now);
    final ready = pot.isReadyAt(now);
    final g = context.read<GameProvider>();
    final subtitle = ready
        ? 'Ready to harvest • +${f.harvestXp} XP'
        : thirsty
            ? 'Needs water • Growth paused'
            : '${fmtDuration(pot.remainingAt(now))} until harvest';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SfCard(
        color: thirsty ? c.dangerSoft : null,
        border: thirsty ? c.danger.withValues(alpha: 0.35) : null,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlantDetailsScreen(potNumber: pot.number))),
        child: Column(children: [
          Row(children: [
            TintedCircle(color: f.tint, size: 52, child: PlantImage(pot: pot, now: now, height: 40, showIndicators: false)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.name, style: context.tt.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: context.tt.bodySmall?.copyWith(color: thirsty ? c.danger : null), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            if (thirsty)
              _MiniButton(
                label: 'Water',
                icon: Icons.water_drop_rounded,
                onTap: () {
                  final r = g.water(pot.number);
                  if (!r.ok) showToast(context, r.message, error: true);
                },
              )
            else if (ready)
              _MiniButton(label: 'Claim', icon: Icons.star_rounded, gold: true, onTap: () => g.harvest(pot.number))
            else
              potStatusBadge(pot, now),
            Icon(Icons.chevron_right_rounded, color: c.muted, size: 20),
          ]),
          const SizedBox(height: 10),
          SfProgressBar(value: pot.progressAt(now), color: thirsty ? c.danger : (ready ? c.gold : c.accent)),
        ]),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.label, required this.icon, required this.onTap, this.gold = false});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool gold;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final bg = gold ? c.gold : c.brand;
    final fg = gold ? Colors.white : c.onBrand;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: fg, size: 15),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12.5)),
        ]),
      ),
    );
  }
}

class SeedTile extends StatelessWidget {
  const SeedTile({super.key, required this.flower, required this.count, this.onTap});
  final Flower flower;
  final int count;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return SfCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        TintedCircle(color: flower.tint, size: 52, child: Image.asset(flower.seedAsset)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${flower.name} Seeds', style: context.tt.titleSmall),
            Text('Plant in an empty pot to grow a ${flower.name}.', style: context.tt.bodySmall, maxLines: 2),
          ]),
        ),
        const SizedBox(width: 6),
        StatusBadge('x$count Seed${count == 1 ? '' : 's'}', tone: flower.rarity == Rarity.common ? Tone.green : Tone.blue, dense: true),
      ]),
    );
  }
}

/// Inventory "See All": seeds + tools.
void showInventorySheet(BuildContext context) {
  showSfSheet(
    context: context,
    builder: (ctx) {
      final g = ctx.watch<GameProvider>();
      final now = GameClock.nowMs();
      final seeds = g.seeds.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));
      return Column(mainAxisSize: MainAxisSize.min, children: [
        const SheetHeader(title: 'Inventory', icon: Icons.inventory_2_outlined),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              const CapsLabel('Garden tools', icon: Icons.handyman_outlined),
              for (final t in ToolDef.all)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SfCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.asset(t.asset, width: 52, height: 52)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t.name, style: ctx.tt.titleSmall),
                          Text(
                            t.kind == ToolKind.water && g.chargesAt(now) < GameRules.baseWaterCharges
                                ? 'Next charge in ${fmtDuration(g.nextChargeIn(now))}'
                                : t.effect,
                            style: ctx.tt.bodySmall,
                          ),
                        ]),
                      ),
                      StatusBadge(t.kind == ToolKind.water ? '${g.ownedTool(t.kind)} charges' : 'x${g.ownedTool(t.kind)}', dense: true),
                    ]),
                  ),
                ),
              CapsLabel('Seeds (${g.totalSeeds})', icon: Icons.grass_rounded),
              if (seeds.isEmpty) Text('No seeds yet — visit the Shop.', style: ctx.tt.bodySmall),
              for (final e in seeds)
                Padding(padding: const EdgeInsets.only(bottom: 10), child: SeedTile(flower: Flower.of(e.key), count: e.value)),
            ],
          ),
        ),
      ]);
    },
  );
}
