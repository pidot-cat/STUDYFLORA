import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../providers/garden_provider.dart';

/// One-shot effect over a pot: watering can + drops, fertilizer sparkles,
/// dirt puff when digging, planting ring, or floating "+XP" text.
class PotFx extends StatelessWidget {
  const PotFx({super.key, required this.fx, required this.boardWidth});

  final GardenFx fx;
  final double boardWidth;

  Duration get _duration => switch (fx.kind) {
        FxKind.water => const Duration(milliseconds: 1600),
        FxKind.fertilize => const Duration(milliseconds: 1300),
        FxKind.dig => const Duration(milliseconds: 800),
        FxKind.plant => const Duration(milliseconds: 900),
        FxKind.xp => const Duration(milliseconds: 1500),
      };

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(fx.id),
        tween: Tween(begin: 0, end: 1),
        duration: _duration,
        builder: (context, t, _) {
          if (t >= 1) return const SizedBox.shrink();
          return switch (fx.kind) {
            FxKind.water => _water(t),
            FxKind.fertilize => _sparkles(t),
            FxKind.dig => _dirt(t),
            FxKind.plant => _ring(t),
            FxKind.xp => _xp(t),
          };
        },
      ),
    );
  }

  // A zero-size box sitting on the pot's soil centre, so every Positioned
  // child below is an offset from that point.
  Widget _centred(List<Widget> children) => SizedBox(
        width: 0,
        height: 0,
        child: Stack(clipBehavior: Clip.none, children: children),
      );

  Widget _water(double t) {
    final w = boardWidth;
    final canIn = Curves.easeOut.transform((t / 0.2).clamp(0.0, 1.0));
    final canOut = Curves.easeIn.transform(((t - 0.8) / 0.2).clamp(0.0, 1.0));
    final canAlpha = (canIn * (1 - canOut)).clamp(0.0, 1.0);
    final tilt = -0.55 * Curves.easeInOut.transform(((t - 0.1) / 0.25).clamp(0.0, 1.0));
    final drops = <Widget>[];
    for (var k = 0; k < 7; k++) {
      final tk = ((t - 0.25 - k * 0.07) / 0.35).clamp(0.0, 1.0);
      if (tk <= 0 || tk >= 1) continue;
      final dx = (-0.036 + k * 0.012) * w;
      drops.add(Positioned(
        left: dx,
        top: -0.07 * w + tk * 0.1 * w,
        child: Opacity(
          opacity: math.sin(math.pi * tk),
          child: Icon(Icons.water_drop, size: w * 0.02, color: const Color(0xFF4FC3F7)),
        ),
      ));
    }
    return _centred([
      // moisture ripple on the soil
      Positioned(
        left: -w * 0.05,
        top: -w * 0.0275,
        width: w * 0.1,
        height: w * 0.055,
        child: Opacity(
          opacity: (math.sin(math.pi * ((t - 0.3) / 0.6).clamp(0.0, 1.0)) * 0.5).clamp(0.0, 1.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4FC3F7).withAlpha(120),
            ),
          ),
        ),
      ),
      Positioned(
        left: -0.01 * w + (1 - canIn) * 0.04 * w,
        top: -0.14 * w,
        child: Opacity(
          opacity: canAlpha,
          child: Transform.rotate(
            angle: tilt,
            alignment: Alignment.bottomRight,
            child: CustomPaint(size: Size(w * 0.1, w * 0.075), painter: _CanPainter()),
          ),
        ),
      ),
      ...drops,
    ]);
  }

  Widget _sparkles(double t) {
    final w = boardWidth;
    const xs = [-0.035, -0.015, 0.01, 0.03, -0.025, 0.02, 0.0, 0.04];
    const speeds = [0.9, 1.1, 0.8, 1.0, 1.2, 0.85, 1.05, 0.95];
    return _centred([
      for (var k = 0; k < xs.length; k++)
        Positioned(
          left: xs[k] * w,
          top: -t * 0.13 * w * speeds[k] - 0.02 * w,
          child: Opacity(
            opacity: (1 - t).clamp(0.0, 1.0),
            child: Icon(Icons.auto_awesome,
                size: w * (k.isEven ? 0.026 : 0.02),
                color: k.isEven ? const Color(0xFFFFD54F) : const Color(0xFF81C784)),
          ),
        ),
    ]);
  }

  Widget _dirt(double t) {
    final w = boardWidth;
    const angles = [-2.6, -2.1, -1.57, -1.0, -0.5, -1.8, -1.3];
    return _centred([
      for (var k = 0; k < angles.length; k++)
        Positioned(
          left: math.cos(angles[k]) * t * 0.06 * w,
          top: math.sin(angles[k]) * t * 0.08 * w + t * t * 0.05 * w,
          child: Opacity(
            opacity: (1 - t).clamp(0.0, 1.0),
            child: Container(
              width: w * 0.014,
              height: w * 0.014,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF5D4037)),
            ),
          ),
        ),
    ]);
  }

  Widget _ring(double t) {
    final w = boardWidth;
    return _centred([
      Positioned(
        left: -w * (0.02 + 0.05 * t),
        top: -w * (0.0125 + 0.03 * t),
        width: w * (0.04 + 0.1 * t),
        height: w * (0.025 + 0.06 * t),
        child: Opacity(
          opacity: (1 - t).clamp(0.0, 1.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF81C784), width: 2.5),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _xp(double t) {
    final w = boardWidth;
    final opacity = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3);
    return _centred([
      Positioned(
        left: -w * 0.12,
        width: w * 0.24,
        top: -0.08 * w - t * 0.1 * w,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Text(
            fx.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: w * 0.042,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFFFE066),
              shadows: const [
                Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                Shadow(color: Colors.black54, blurRadius: 8),
              ],
            ),
          ),
        ),
      ),
    ]);
  }
}

class _CanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = Paint()..color = const Color(0xFF90A4AE);
    final shade = Paint()..color = const Color(0xFF607D8B);

    // body
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.28, h * 0.3, w * 0.5, h * 0.65), Radius.circular(w * 0.06)),
      body,
    );
    // spout
    final spout = Path()
      ..moveTo(w * 0.28, h * 0.7)
      ..lineTo(w * 0.02, h * 0.28)
      ..lineTo(w * 0.1, h * 0.22)
      ..lineTo(w * 0.28, h * 0.5)
      ..close();
    canvas.drawPath(spout, shade);
    canvas.drawCircle(Offset(w * 0.06, h * 0.25), w * 0.06, shade);
    // handle
    final handle = Paint()
      ..color = shade.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05;
    canvas.drawArc(Rect.fromLTWH(w * 0.62, h * 0.2, w * 0.34, h * 0.55), -1.5, 3.1, false, handle);
    // lid highlight
    canvas.drawRect(Rect.fromLTWH(w * 0.28, h * 0.3, w * 0.5, h * 0.08), shade);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
