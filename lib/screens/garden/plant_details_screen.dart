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
import '../../widgets/common.dart';
import '../../widgets/plant_widgets.dart';
import '../../widgets/profile_widgets.dart';
import '../../widgets/sheets.dart';
import '../shop/purchase_sheet.dart';
import 'planting_sheets.dart';

/// Plant Details & Management (FR-4.4 … FR-4.8).
class PlantDetailsScreen extends StatelessWidget {
  const PlantDetailsScreen({super.key, required this.potNumber});
  final int potNumber;

  @override
  Widget build(BuildContext context) {
    context.watch<ClockTicker>();
    final g = context.watch<GameProvider>();
    final c = context.sf;
    final now = GameClock.nowMs();
    final pot = g.potByNumber(potNumber);

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          SfTopBar(
            leading: Pressable(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle, boxShadow: [BoxShadow(color: c.shadow, blurRadius: 10)]),
                child: Icon(Icons.chevron_left_rounded, color: c.ink),
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: pot.isEmpty
                  ? _EmptyPotView(key: const ValueKey('empty'), potNumber: potNumber)
                  : _PlantView(key: ValueKey('plant-${pot.plantedAt}'), pot: pot, now: now),
            ),
          ),
        ]),
      ),
    );
  }
}

class _EmptyPotView extends StatelessWidget {
  const _EmptyPotView({super.key, required this.potNumber});
  final int potNumber;
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 24), children: [
      Text('Pot is empty', style: context.tt.headlineMedium),
      const SizedBox(height: 6),
      Text('The plant was harvested or removed. Plant a new seed to keep your garden growing.', style: context.tt.bodySmall),
      const SizedBox(height: 24),
      Center(child: Image.asset('assets/plants/pot_empty.webp', height: 170)),
      const SizedBox(height: 24),
      PrimaryButton(label: 'Plant a Seed', icon: Icons.grass_rounded, onTap: () => showChooseFlowerSheet(context, potNumber)),
    ]);
  }
}

class _PlantView extends StatelessWidget {
  const _PlantView({super.key, required this.pot, required this.now});
  final Pot pot;
  final int now;

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final g = context.read<GameProvider>();
    final f = pot.flower!;
    final ready = pot.isReadyAt(now);
    final hydrated = pot.isHydratedAt(now);
    final progress = pot.progressAt(now);
    final stage = pot.stageAt(now);
    final charges = g.chargesAt(now);

    void act(ActionResult r) {
      if (!r.ok) showToast(context, r.message, error: true);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
      children: [
        Text('Plant Details', style: context.tt.headlineMedium),
        Text('Track your plant’s growth and care.', style: context.tt.bodySmall),
        const SizedBox(height: 14),

        // ---- hero card
        SfCard(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(color: ready ? c.goldSoft : (hydrated ? c.surfaceAlt : c.dangerSoft), borderRadius: BorderRadius.circular(20)),
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.only(bottom: 8),
              child: PlantImage(pot: pot, now: now, height: 108),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.name, style: context.tt.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                potStatusBadge(pot, now),
                const SizedBox(height: 10),
                _Line(
                  icon: Icons.water_drop_rounded,
                  color: hydrated || ready ? c.info : c.danger,
                  text: ready ? 'No water needed' : (hydrated ? 'Hydrated · ${fmtDuration(pot.hydrationLeftAt(now))}' : 'Dehydrated'),
                ),
                const SizedBox(height: 6),
                _Line(icon: Icons.schedule_rounded, color: c.ink, text: ready ? 'Ready!' : fmtDuration(pot.remainingAt(now)), bold: true),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(ready ? 'CLAIM YOUR XP' : (hydrated ? 'UNTIL HARVEST' : 'GROWTH PAUSED'),
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: c.muted, letterSpacing: 0.5)),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // ---- growth progress + stage timeline (FR-4.4)
        SfCard(
          child: Column(children: [
            Row(children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
                child: Icon(Icons.eco_rounded, size: 16, color: c.brand),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text('Growth Progress', style: context.tt.titleMedium)),
              Text('${(progress * 100).floor()}%', style: context.tt.titleMedium),
            ]),
            const SizedBox(height: 12),
            SfProgressBar(value: progress, height: 10, color: ready ? c.gold : c.accent),
            const SizedBox(height: 16),
            Row(children: [
              _StageDot(label: 'Seed', asset: f.seedAsset, active: stage == PlantStage.seed, done: progress > 0),
              _Connector(done: progress >= GameRules.sproutAt),
              _StageDot(label: 'Sprout', asset: f.sproutAsset, active: stage == PlantStage.sprout, done: progress >= GameRules.sproutAt),
              _Connector(done: ready),
              _StageDot(label: 'Bloom', asset: f.bloomAsset, active: stage == PlantStage.bloom, done: ready),
            ]),
            if (pot.fertilized) ...[
              const SizedBox(height: 12),
              const StatusBadge('Fertilized · 2× growth speed', tone: Tone.terracotta, icon: Icons.bolt_rounded),
            ],
          ]),
        ),
        const SizedBox(height: 12),

        if (!ready)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: c.infoSoft, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.info.withValues(alpha: 0.25))),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: c.info.withValues(alpha: 0.14), shape: BoxShape.circle),
                child: Icon(Icons.water_drop_rounded, color: c.info),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Keep it hydrated', style: context.tt.titleSmall),
                  Text('Each watering gives 2 hours of growth time. If it becomes dry, growth will pause.', style: context.tt.bodySmall),
                  const SizedBox(height: 8),
                  SfProgressBar(value: pot.hydrationAt(now), color: c.info, height: 7, background: c.info.withValues(alpha: 0.15)),
                ]),
              ),
            ]),
          ),

        if (ready) ...[
          PrimaryButton(
            label: 'Claim +${f.harvestXp} XP',
            icon: Icons.star_rounded,
            color: c.gold,
            onTap: () {
              g.harvest(pot.number);
              Navigator.of(context).maybePop();
            },
          ),
          const SizedBox(height: 8),
          Center(child: Text('Or leave it here — it stays displayed in your garden.', style: context.tt.bodySmall)),
        ],

        const CapsLabel('Garden tools'),
        Row(children: [
          Expanded(
            child: _ToolTile(
              tone: Tone.blue,
              asset: 'assets/tools/water.webp',
              title: 'Water',
              subtitle: '+2h hydration',
              count: '$charges charge${charges == 1 ? '' : 's'}',
              footnote: charges < GameRules.baseWaterCharges ? 'next ${fmtDuration(g.nextChargeIn(now))}' : null,
              enabled: !ready && pot.canWater(now),
              onTap: () {
                if (charges > 0) {
                  act(g.water(pot.number));
                } else {
                  _offerBuy(context, ToolKind.water);
                }
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ToolTile(
              tone: Tone.green,
              asset: 'assets/tools/fert.webp',
              title: 'Fertilize',
              // e.g. a fresh plant (6h left) → "Saves 3h" (SRS: halves the time left).
              subtitle: pot.fertilized
                  ? 'Already used'
                  : 'Saves ${fmtDuration(Duration(milliseconds: pot.remainingAt(now).inMilliseconds ~/ 2))} • 2× speed',
              count: 'x${g.fertilizers}',
              enabled: !ready && !pot.fertilized,
              onTap: () async {
                if (g.fertilizers <= 0) return _offerBuy(context, ToolKind.fertilizer);
                final ok = await confirmDialog(
                  context,
                  title: 'Use Fertilizer?',
                  message: 'Remaining time ${fmtDuration(pot.remainingAt(GameClock.nowMs()))} becomes '
                      '${fmtDuration(Duration(milliseconds: pot.remainingAt(GameClock.nowMs()).inMilliseconds ~/ 2))}. '
                      'Only once per plant.',
                  confirm: 'Fertilize',
                  image: 'assets/tools/fert.webp',
                );
                if (ok) act(g.fertilize(pot.number));
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ToolTile(
              tone: Tone.red,
              asset: 'assets/tools/shovel.webp',
              title: 'Shovel',
              subtitle: 'Remove plant & free the pot',
              count: 'x${g.shovels}',
              enabled: true,
              onTap: () async {
                if (g.shovels <= 0) return _offerBuy(context, ToolKind.shovel);
                final ok = await confirmDialog(
                  context,
                  title: 'Dig up ${f.name}?',
                  message: 'This removes the plant from its pot. Growth progress will be lost and no XP is given.',
                  confirm: 'Dig it up',
                  danger: true,
                  image: 'assets/tools/shovel.webp',
                );
                if (ok) act(g.shovel(pot.number));
              },
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(18), border: Border.all(color: c.brandSoft)),
          child: Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
              child: const Icon(Icons.star_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Harvest gives you +${f.harvestXp} XP!', style: context.tt.titleSmall),
                Text('${f.rarity.label} flower. When fully grown, claim it or keep it displayed.', style: context.tt.bodySmall),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.info_outline_rounded, size: 15, color: c.muted),
          const SizedBox(width: 6),
          Text('Planted ${fmtDate(DateTime.fromMillisecondsSinceEpoch(pot.plantedAt))}', style: context.tt.bodySmall),
        ]),
      ],
    );
  }

  Future<void> _offerBuy(BuildContext context, ToolKind kind) async {
    final t = ToolDef.of(kind);
    final ok = await confirmDialog(
      context,
      title: 'No ${t.name} left',
      message: kind == ToolKind.water
          ? 'Your watering can is empty. A charge restores every 10 minutes, or buy a can for ${t.price} coins.'
          : 'Buy a ${t.name} for ${t.price} coins?',
      confirm: 'Buy',
      image: t.asset,
    );
    if (ok && context.mounted) await showToolPurchaseSheet(context, kind);
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.color, required this.text, this.bold = false});
  final IconData icon;
  final Color color;
  final String text;
  final bool bold;
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 7),
        Expanded(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: bold ? 18 : 13.5, color: bold ? context.sf.ink : color)),
        ),
      ]);
}

class _StageDot extends StatelessWidget {
  const _StageDot({required this.label, required this.asset, required this.active, required this.done});
  final String label;
  final String asset;
  final bool active;
  final bool done;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return Column(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: active ? 62 : 50,
        height: active ? 62 : 50,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? c.brandSoft : c.surfaceAlt,
          border: Border.all(color: active ? c.accent : (done ? c.brandSoft : c.line), width: active ? 2.5 : 1.5),
        ),
        child: Opacity(opacity: done || active ? 1 : 0.4, child: Image.asset(asset, fit: BoxFit.contain)),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w800 : FontWeight.w600, color: active ? c.brand : c.muted)),
    ]);
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.done});
  final bool done;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          height: 3,
          margin: const EdgeInsets.only(bottom: 18, left: 4, right: 4),
          decoration: BoxDecoration(color: done ? context.sf.accent : context.sf.line, borderRadius: BorderRadius.circular(3)),
        ),
      );
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.tone,
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.enabled,
    required this.onTap,
    this.footnote,
  });
  final Tone tone;
  final String asset;
  final String title;
  final String subtitle;
  final String count;
  final String? footnote;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = toneColors(context, tone);
    final c = context.sf;
    return Pressable(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1 : 0.45,
        child: Container(
          height: 182,
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
          decoration: BoxDecoration(
            color: bg.withValues(alpha: context.isDark ? 1 : 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: fg.withValues(alpha: 0.18)),
          ),
          child: Column(children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle),
              padding: const EdgeInsets.all(5),
              child: Image.asset(asset, fit: BoxFit.contain),
            ),
            const SizedBox(height: 8),
            Text(title, style: context.tt.titleSmall),
            const SizedBox(height: 2),
            Text(subtitle, style: context.tt.bodySmall?.copyWith(fontSize: 10.5), textAlign: TextAlign.center, maxLines: 2),
            const Spacer(),
            Text(count, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: fg)),
            if (footnote != null) Text(footnote!, style: TextStyle(fontSize: 9.5, color: c.muted)),
          ]),
        ),
      ),
    );
  }
}
