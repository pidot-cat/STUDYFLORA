import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/flower.dart';
import '../../providers/game_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/sheets.dart';
import '../shell.dart';

/// "Choose a Flower" (mockup) — owned seeds first; unowned seeds can be
/// bought with coins right here (FR-4.2).
Future<void> showChooseFlowerSheet(BuildContext context, int potNumber) async {
  final picked = await showSfSheet<String>(
    context: context,
    builder: (ctx) {
      final c = ctx.sf;
      final g = ctx.watch<GameProvider>();
      final owned = Flower.all.where((f) => g.seedCount(f.id) > 0).toList();
      final others = Flower.all.where((f) => g.seedCount(f.id) == 0).toList();
      return Column(mainAxisSize: MainAxisSize.min, children: [
        const SheetHeader(title: 'Choose a Flower'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
          child: Row(children: [
            Expanded(
              child: Text.rich(TextSpan(style: ctx.tt.bodySmall, children: [
                const TextSpan(text: 'Planting target: '),
                TextSpan(text: 'Empty ceramic pot', style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
              ])),
            ),
            StatusBadge('${g.totalSeeds} Seeds', icon: Icons.grass_rounded, dense: true),
          ]),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            children: [
              if (owned.isNotEmpty) _grid(ctx, owned, (f) => _SeedCard(flower: f, count: g.seedCount(f.id), onTap: () => Navigator.pop(ctx, f.id))),
              if (owned.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('You have no seeds yet. Buy one below and plant it right away.', style: ctx.tt.bodySmall),
                ),
              const CapsLabel('Buy & plant with coins', icon: Icons.storefront_outlined),
              _grid(ctx, others, (f) => _SeedCard(flower: f, price: f.seedPrice, affordable: g.coins >= f.seedPrice, onTap: () => Navigator.pop(ctx, f.id))),
              const SizedBox(height: 8),
              Pressable(
                onTap: () {
                  Navigator.pop(ctx);
                  ctx.read<NavState>().go(3, shopTab: 0);
                },
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: c.line, width: 1.5),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_circle_outline_rounded, color: c.muted),
                    const SizedBox(width: 8),
                    Text('Buy more seeds (bundles save 20%)', style: TextStyle(color: c.muted, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
          child: SecondaryButton(label: 'Cancel', onTap: () => Navigator.pop(ctx)),
        ),
      ]);
    },
  );
  if (picked == null || !context.mounted) return;
  await showConfirmPlantingSheet(context, potNumber, picked);
}

Widget _grid(BuildContext ctx, List<Flower> flowers, Widget Function(Flower) item) {
  return GridView.count(
    crossAxisCount: 3,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 0.8,
    children: [for (final f in flowers) item(f)],
  );
}

class _SeedCard extends StatelessWidget {
  const _SeedCard({required this.flower, this.count, this.price, this.affordable = true, required this.onTap});
  final Flower flower;
  final int? count;
  final int? price;
  final bool affordable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final buying = price != null;
    return Pressable(
      onTap: onTap,
      child: Opacity(
        opacity: buying && !affordable ? 0.55 : 1,
        child: Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.line, width: 1.3),
            boxShadow: [BoxShadow(color: c.shadow, blurRadius: 10, offset: const Offset(0, 4))],
          ),
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
          child: Stack(children: [
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              TintedCircle(color: flower.tint, size: 54, child: Image.asset(flower.seedAsset)),
              const SizedBox(height: 6),
              Text(flower.name, style: context.tt.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              buying
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      const CoinIcon(size: 14),
                      const SizedBox(width: 3),
                      Text('${flower.seedPrice}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ])
                  : const StatusBadge('Plant', icon: Icons.yard_outlined, dense: true),
            ]),
            if (count != null)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(9)),
                  child: Text('x$count', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: c.muted)),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

/// "Confirm Planting" (mockup).
Future<void> showConfirmPlantingSheet(BuildContext context, int potNumber, String flowerId) {
  final f = Flower.of(flowerId);
  return showSfSheet(
    context: context,
    builder: (ctx) {
      final c = ctx.sf;
      final g = ctx.watch<GameProvider>();
      final owned = g.seedCount(flowerId) > 0;
      final canAfford = g.coins >= f.seedPrice;
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SheetHeader(title: 'Confirm Planting'),
          const SizedBox(height: 6),
          Container(
            width: 196,
            height: 196,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.surfaceAlt,
              border: Border.all(color: c.brandSoft, width: 14),
            ),
            alignment: Alignment.center,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Image.asset(f.seedAsset, height: 130),
            ),
          ),
          const SizedBox(height: 12),
          Text(f.name, style: ctx.tt.headlineMedium),
          const SizedBox(height: 4),
          Text(f.blurb, style: ctx.tt.bodyMedium?.copyWith(color: c.muted), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.surfaceAlt.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.brandSoft),
            ),
            child: Column(children: [
              Row(children: [
                Text('PLANTING DESTINATION', style: ctx.tt.labelSmall?.copyWith(color: c.muted)),
                const Spacer(),
                const StatusBadge('Ready', icon: Icons.check_circle_outline_rounded, dense: true),
              ]),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.line)),
                child: Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: c.terracottaSoft, borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.all(6),
                    child: Image.asset('assets/plants/pot_empty.webp'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Selected pot', style: ctx.tt.titleMedium),
                      Text('Empty pot • Ready to plant', style: ctx.tt.bodySmall),
                    ]),
                  ),
                  Icon(Icons.check_circle_rounded, color: c.accent),
                ]),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _InfoBox(icon: Icons.schedule_rounded, label: 'BLOOM TIME', value: fmtDuration(GameRules.growDuration), tint: c.brandSoft)),
                const SizedBox(width: 10),
                Expanded(child: _InfoBox(icon: Icons.emoji_events_outlined, label: 'HARVEST REWARD', value: '+${f.harvestXp} XP', tint: c.goldSoft)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.water_drop_outlined, size: 15, color: c.info),
                const SizedBox(width: 6),
                Expanded(child: Text('Water it after planting — growth only happens while hydrated.', style: ctx.tt.bodySmall)),
              ]),
            ]),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: SecondaryButton(label: 'Cancel', icon: Icons.close_rounded, onTap: () => Navigator.pop(ctx))),
            const SizedBox(width: 10),
            Expanded(
              flex: owned ? 1 : 2,
              child: PrimaryButton(
                label: owned ? 'Plant Flower' : (canAfford ? 'Buy & Plant • ${f.seedPrice}' : 'Need ${f.seedPrice - g.coins} coins'),
                icon: owned ? Icons.yard_outlined : Icons.shopping_cart_outlined,
                onTap: owned || canAfford
                    ? () {
                        final r = owned ? g.plant(potNumber, flowerId) : g.buyAndPlant(potNumber, flowerId);
                        Navigator.pop(ctx);
                        if (!r.ok) showToast(context, r.message, error: true);
                      }
                    : null,
              ),
            ),
          ]),
        ]),
      );
    },
  );
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.label, required this.value, required this.tint});
  final IconData icon;
  final String label;
  final String value;
  final Color tint;
  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(icon, size: 18, color: c.ink),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: c.muted, letterSpacing: 0.4)),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.ink)),
          ]),
        ),
      ]),
    );
  }
}
