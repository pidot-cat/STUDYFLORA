import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/plant.dart';

/// Draws one plant: a seed sprout first, then the adult flower art growing
/// in size, going grey when thirsty and glowing when ready to claim.
class PlantSprite extends StatefulWidget {
  const PlantSprite({super.key, required this.plant, required this.now, required this.height});

  final Plant plant;
  final DateTime now;
  final double height;

  @override
  State<PlantSprite> createState() => _PlantSpriteState();
}

class _PlantSpriteState extends State<PlantSprite> with SingleTickerProviderStateMixin {
  late final AnimationController _bob =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  static const _grey = ColorFilter.matrix(<double>[
    0.55, 0.30, 0.10, 0, 0,
    0.20, 0.65, 0.10, 0, 0,
    0.20, 0.30, 0.45, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;
    final now = widget.now;
    final h = widget.height;
    final p = plant.progressAt(now);
    final ready = p >= 1;
    final thirsty = plant.isThirsty(now);

    if (p < 1 / 3) {
      return SizedBox(
        height: h,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: CustomPaint(
            size: Size(h * 0.36, h * 0.36),
            painter: _SproutPainter(thirsty: thirsty),
          ),
        ),
      );
    }

    final scale = ready ? 1.0 : 0.5 + 0.5 * ((p - 1 / 3) / (2 / 3)).clamp(0.0, 1.0);
    Widget flower = Image.asset(
      plant.type.asset,
      height: h * scale,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.local_florist, size: h * scale * 0.6, color: Colors.green),
    );
    if (thirsty) {
      flower = ColorFiltered(
        colorFilter: _grey,
        child: Transform.rotate(angle: 0.07, alignment: Alignment.bottomCenter, child: flower),
      );
    }

    if (!ready) {
      return SizedBox(height: h, child: Align(alignment: Alignment.bottomCenter, child: flower));
    }

    return SizedBox(
      height: h,
      child: AnimatedBuilder(
        animation: _bob,
        builder: (_, child) {
          final t = Curves.easeInOut.transform(_bob.value);
          return Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                bottom: h * 0.1,
                child: Container(
                  width: h * 0.7,
                  height: h * 0.7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFE066).withAlpha((90 + 70 * t).round()),
                        blurRadius: h * 0.35,
                        spreadRadius: h * 0.05,
                      ),
                    ],
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, -h * 0.04 * t),
                child: child,
              ),
              Positioned(
                top: -h * 0.02 - h * 0.04 * t,
                right: 0,
                child: Icon(Icons.star_rounded, size: h * 0.3, color: const Color(0xFFFFC107)),
              ),
            ],
          );
        },
        child: flower,
      ),
    );
  }
}

class _SproutPainter extends CustomPainter {
  _SproutPainter({required this.thirsty});

  final bool thirsty;

  @override
  void paint(Canvas canvas, Size size) {
    final leaf = Paint()..color = thirsty ? const Color(0xFF9AA58E) : const Color(0xFF4CAF50);
    final dark = Paint()..color = thirsty ? const Color(0xFF7C876F) : const Color(0xFF2E7D32);
    final w = size.width;
    final h = size.height;
    final base = Offset(w / 2, h);

    final stem = Paint()
      ..color = dark.color
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(base, Offset(w / 2, h * 0.45), stem);

    Path leafPath(double dir) {
      final p = Path()..moveTo(w / 2, h * 0.5);
      p.quadraticBezierTo(w / 2 + dir * w * 0.55, h * 0.1, w / 2 + dir * w * 0.5, h * 0.32);
      p.quadraticBezierTo(w / 2 + dir * w * 0.3, h * 0.55, w / 2, h * 0.5);
      return p;
    }

    canvas.drawPath(leafPath(-1), leaf);
    canvas.drawPath(leafPath(1), leaf);

    final seed = Paint()..color = const Color(0xFF6D4C41);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.97), width: w * 0.32, height: h * 0.14),
      seed,
    );
    // little highlight so the sprout reads on the dark soil
    canvas.drawCircle(Offset(w / 2 - w * 0.12, h * 0.3), math.max(1.0, w * 0.03),
        Paint()..color = Colors.white.withAlpha(120));
  }

  @override
  bool shouldRepaint(covariant _SproutPainter old) => old.thirsty != thirsty;
}
