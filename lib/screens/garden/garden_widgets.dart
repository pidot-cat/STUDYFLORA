import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/visuals.dart';

/// Flower-in-pot illustration. Uses the illustrated art from the mock-ups for
/// sunflower & daisy and composes pot + flower badge for the others.
class PlantArt extends StatelessWidget {
  final String flowerId;
  final double size;
  final bool large;
  const PlantArt(this.flowerId, {super.key, this.size = 90, this.large = false});

  @override
  Widget build(BuildContext context) {
    if (flowerId == 'sunflower') {
      return Image.asset(large ? 'assets/images/sunflower_pot_large.png' : 'assets/images/sunflower_pot_card.png',
          width: size, height: size, fit: BoxFit.contain);
    }
    if (flowerId == 'daisy') {
      return Image.asset('assets/images/daisy_pot_card.png', width: size, height: size, fit: BoxFit.contain);
    }
    final f = Flowers.byId(flowerId);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.topCenter, children: [
        Positioned(
          top: size * .06,
          child: ClipOval(child: Image.asset(f.asset, width: size * .56, height: size * .56, fit: BoxFit.cover)),
        ),
        Positioned(
          top: size * .56,
          child: Container(width: 3, height: size * .08, color: const Color(0xFF3E9A5C)),
        ),
        Positioned(
          bottom: size * .06,
          child: SizedBox(width: size * .42, height: size * .3, child: CustomPaint(painter: PotPainter())),
        ),
      ]),
    );
  }
}

/// One cell of the 6×3 garden grid.
class PotTile extends StatelessWidget {
  final int number;
  final Plant? plant;
  final bool selected;
  final VoidCallback onTap;
  const PotTile({super.key, required this.number, this.plant, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final p = plant;
    return GestureDetector(
      onTap: onTap,
      child: Stack(clipBehavior: Clip.none, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: c.isDark ? const Color(0xFF0B1A14) : const Color(0xFFF3F8F5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? (c.isDark ? const Color(0xFF34D399) : const Color(0xFF1B6B3F)) : c.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: LayoutBuilder(builder: (_, box) {
            final w = box.maxWidth;
            return Stack(alignment: Alignment.bottomCenter, children: [
              if (p != null)
                Positioned(
                  top: box.maxHeight * .12,
                  child: p.flower.sprite != null
                      ? Image.asset(p.flower.sprite!, height: box.maxHeight * .48, fit: BoxFit.contain)
                      : Column(children: [
                          ClipOval(
                              child: Image.asset(p.flower.asset, width: w * .38, height: w * .38, fit: BoxFit.cover)),
                          Container(width: 2, height: box.maxHeight * .1, color: const Color(0xFF3E9A5C)),
                        ]),
                ),
              Positioned(
                bottom: box.maxHeight * .06,
                child: SizedBox(
                  width: w * .68,
                  height: box.maxHeight * .32,
                  child: CustomPaint(painter: PotPainter(number: number)),
                ),
              ),
            ]);
          }),
        ),
        if (p != null && p.needsWater)
          Positioned(
            right: -4,
            top: -6,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                  color: const Color(0xFF3B9BF0),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5)),
              child: const Icon(Icons.water_drop, size: 9, color: Colors.white),
            ),
          ),
        if (p != null && p.ready)
          Positioned(
            right: -4,
            top: -6,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                  color: const Color(0xFFF5B416),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5)),
              child: const Icon(Icons.star_rounded, size: 10, color: Colors.white),
            ),
          ),
      ]),
    );
  }
}
