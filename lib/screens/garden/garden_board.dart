import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/garden_catalog.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/garden_provider.dart';
import 'garden_actions.dart';
import 'plant_sprite.dart';
import 'pot_fx.dart';

/// The greenhouse picture with 18 tappable pots drawn on top of it.
class GardenBoard extends StatelessWidget {
  const GardenBoard({super.key});

  static const _imageAspect = 1600 / 1015;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final garden = context.watch<GardenProvider>();
    final now = DateTime.now();

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = w / _imageAspect;
        final plantH = w * 0.17;

        return Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: p.shadow, blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: Image.asset(
                    AppAssets.gardenBackground,
                    fit: BoxFit.fill,
                    errorBuilder: (_, __, ___) => Container(color: p.primarySoft),
                  ),
                ),
                for (var i = 0; i < GardenCatalog.potCount; i++)
                  _PotSlot(
                    index: i,
                    centre: GardenCatalog.potCentres[i],
                    boardWidth: w,
                    boardHeight: h,
                    plantHeight: plantH,
                    now: now,
                    garden: garden,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PotSlot extends StatelessWidget {
  const _PotSlot({
    required this.index,
    required this.centre,
    required this.boardWidth,
    required this.boardHeight,
    required this.plantHeight,
    required this.now,
    required this.garden,
  });

  final int index;
  final (double, double) centre;
  final double boardWidth;
  final double boardHeight;
  final double plantHeight;
  final DateTime now;
  final GardenProvider garden;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final cx = centre.$1 * boardWidth;
    final cy = centre.$2 * boardHeight;
    final slotW = boardWidth * 0.14;
    final slotH = boardWidth * 0.24;
    final plant = garden.pots[index];
    final selected = garden.selected == index;
    final fx = garden.lastFx;
    final showFx = fx != null && fx.pot == index;

    // Slot box: bottom edge sits just under the soil centre.
    final bottomY = cy + boardWidth * 0.03;

    return Positioned(
      left: cx - slotW / 2,
      top: bottomY - slotH,
      width: slotW,
      height: slotH,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onPotTapped(context, index),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            if (selected)
              Positioned(
                bottom: boardWidth * 0.0,
                child: Container(
                  width: boardWidth * 0.12,
                  height: boardWidth * 0.07,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(boardWidth),
                    border: Border.all(color: p.brand, width: 2.2),
                    boxShadow: [BoxShadow(color: p.brand.withAlpha(120), blurRadius: 10)],
                  ),
                ),
              ),
            if (plant != null)
              Positioned(
                bottom: boardWidth * 0.012,
                child: PlantSprite(plant: plant, now: now, height: plantHeight),
              ),
            if (showFx)
              Positioned(
                // The soil centre is 0.03w above the slot's bottom edge.
                left: slotW / 2,
                bottom: boardWidth * 0.03,
                child: PotFx(fx: fx, boardWidth: boardWidth),
              ),
          ],
        ),
      ),
    );
  }
}
