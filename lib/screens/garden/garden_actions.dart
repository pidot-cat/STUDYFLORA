import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/garden_catalog.dart';
import '../../core/theme/app_palette.dart';
import '../../models/plant_type.dart';
import '../../providers/garden_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/nav_provider.dart';
import '../../providers/user_provider.dart';

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Friendly message for a failed garden action (null when it worked).
String? messageFor(GardenResult r) => switch (r) {
      GardenResult.ok => null,
      GardenResult.emptyPot => 'This pot is empty. Plant a seed first.',
      GardenResult.occupied => 'Something is already growing here.',
      GardenResult.alreadyWatered => 'This plant is already well watered.',
      GardenResult.alreadyFertilized => 'This plant is already fertilized.',
      GardenResult.alreadyGrown => 'Fully grown! Tap it to claim your XP.',
      GardenResult.notReady => 'Not fully grown yet.',
      GardenResult.noWater => 'Watering can is empty. It refills 1 charge every 10 minutes.',
      GardenResult.noFertilizer => 'No Fertilizer left. Buy some in the Shop (Tools).',
      GardenResult.noShovel => 'No Shovel left. Buy one in the Shop (Tools).',
      GardenResult.noCoins => 'Not enough coins.',
    };

/// Tap on a pot: plant into an empty one, claim a ready plant, or use the
/// selected tool.
Future<void> onPotTapped(BuildContext context, int pot) async {
  final g = context.read<GardenProvider>();
  final plant = g.pots[pot];
  g.select(pot);

  if (plant == null) {
    await showPlantSheet(context, pot);
    return;
  }

  final now = DateTime.now();
  if (plant.isReady(now) && g.tool != GardenTool.shovel) {
    claimPot(context, pot);
    return;
  }

  switch (g.tool) {
    case GardenTool.water:
      waterPot(context, pot);
    case GardenTool.fertilize:
      fertilizePot(context, pot);
    case GardenTool.shovel:
      await digPot(context, pot);
  }
}

void waterPot(BuildContext context, int pot) {
  final msg = messageFor(context.read<GardenProvider>().water(pot));
  if (msg != null) _toast(context, msg);
}

void fertilizePot(BuildContext context, int pot) {
  final g = context.read<GardenProvider>();
  final msg = messageFor(g.fertilize(pot));
  if (msg != null) {
    _toast(context, msg);
  } else {
    _toast(context, 'Fertilized! Growth time cut in half.');
  }
}

void claimPot(BuildContext context, int pot) {
  final g = context.read<GardenProvider>();
  final name = g.pots[pot]?.type.name ?? 'Plant';
  final xp = g.claim(pot);
  if (xp > 0) _toast(context, '$name harvested: +$xp XP');
}

Future<void> digPot(BuildContext context, int pot) async {
  final g = context.read<GardenProvider>();
  final plant = g.pots[pot];
  if (plant == null) {
    _toast(context, messageFor(GardenResult.emptyPot)!);
    return;
  }
  final p = AppPalette.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Dig up ${plant.type.name}?'),
      content: const Text('The plant and its growth progress will be removed. This uses 1 Shovel.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('Dig Up', style: TextStyle(color: p.dangerText)),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final msg = messageFor(g.dig(pot));
  if (msg != null) _toast(context, msg);
}

/// Bottom sheet listing all six flowers. Seeds you own plant for free;
/// the rest can be bought on the spot with coins.
Future<void> showPlantSheet(BuildContext context, int pot) {
  final p = AppPalette.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: p.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheetCtx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (_, controller) => _PlantSheet(
        controller: controller,
        onPick: (type, owned) {
          final g = context.read<GardenProvider>();
          final res = g.plant(pot, type, buyIfNeeded: true);
          Navigator.pop(sheetCtx);
          final msg = messageFor(res);
          _toast(context, msg ?? '${type.name} planted! Ready in 6 hours.');
        },
      ),
    ),
  );
}

class _PlantSheet extends StatelessWidget {
  const _PlantSheet({required this.controller, required this.onPick});

  final ScrollController controller;
  final void Function(PlantType type, bool owned) onPick;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final inv = context.watch<InventoryProvider>();
    final coins = context.select<UserProvider, int>((u) => u.coins);

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Text('Plant a Seed', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('Every flower takes 6 hours to grow. Seeds you own plant for free.',
            style: TextStyle(color: p.textMuted, fontSize: 14, height: 1.4)),
        const SizedBox(height: 14),
        for (final type in GardenCatalog.types) ...[
          _SeedRow(
            type: type,
            owned: inv.count(type.seedId),
            canAfford: coins >= type.seedPrice,
            onTap: () => onPick(type, inv.count(type.seedId) > 0),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SeedRow extends StatelessWidget {
  const _SeedRow({
    required this.type,
    required this.owned,
    required this.canAfford,
    required this.onTap,
  });

  final PlantType type;
  final int owned;
  final bool canAfford;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final hasSeed = owned > 0;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.neutralChip.withAlpha(150),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 56,
              height: 56,
              color: p.primarySoft,
              child: Image.asset(
                type.asset,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => Icon(Icons.local_florist, color: p.onPrimarySoft),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('6h growth • +${type.xp} XP • Owned: $owned',
                    style: TextStyle(color: p.textMuted, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: hasSeed || canAfford ? p.primary : p.neutralChip,
              foregroundColor: hasSeed || canAfford ? p.onPrimary : p.textMuted,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onTap,
            child: Text(hasSeed ? 'Plant' : 'Buy ¢${type.seedPrice}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

/// Used by the Home dashboard to jump to the Garden tab.
void openGarden(BuildContext context) =>
    context.read<NavProvider>().go(NavProvider.garden);
