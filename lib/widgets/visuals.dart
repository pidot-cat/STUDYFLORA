import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Avatar with its equipped border, teal inner ring and gold star badge
/// (Settings, Profile, Log Out, Border preview).
class AvatarRing extends StatelessWidget {
  final String avatarAsset;
  final BorderStyleKind border;
  final double size;
  final bool star;
  final bool showOuter;
  const AvatarRing(
      {super.key,
      required this.avatarAsset,
      required this.border,
      this.size = 120,
      this.star = true,
      this.showOuter = true});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final inner = size * (showOuter ? .74 : 1);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        if (showOuter) CustomPaint(size: Size.square(size), painter: BorderPainter(border)),
        Container(
          width: inner,
          height: inner,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.isDark ? c.cardAlt : const Color(0xFFDDF5E6),
            border: Border.all(color: const Color(0xFF5EE0C2), width: inner * .045),
          ),
          padding: EdgeInsets.all(inner * .14),
          child: ClipOval(child: Image.asset(avatarAsset, fit: BoxFit.cover)),
        ),
        if (star)
          Positioned(
            right: size * (showOuter ? .08 : 0),
            bottom: size * (showOuter ? .08 : 0),
            child: Container(
              width: size * .22,
              height: size * .22,
              decoration: BoxDecoration(
                color: showOuter ? const Color(0xFF1B3A2E) : const Color(0xFFF5B416),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child:
                  Icon(Icons.star_rounded, size: size * .14, color: showOuter ? const Color(0xFFFACC15) : Colors.white),
            ),
          ),
      ]),
    );
  }
}

/// Paints the five avatar border styles.
class BorderPainter extends CustomPainter {
  final BorderStyleKind kind;
  final bool muted;
  BorderPainter(this.kind, {this.muted = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2 - 2;
    final p = Paint()..style = PaintingStyle.stroke;
    Color col(Color c) => muted ? c.withValues(alpha: .55) : c;
    switch (kind) {
      case BorderStyleKind.starter:
        p
          ..color = col(const Color(0xFF2F5D4A))
          ..strokeWidth = math.max(1.5, size.width * .015);
        _dashed(canvas, center, r, p, 36);
        break;
      case BorderStyleKind.leaf:
        p
          ..color = col(const Color(0xFF6CC28A))
          ..strokeWidth = 1;
        canvas.drawCircle(center, r * .92, p..color = col(const Color(0xFFBFE6CC)));
        final leaf = Paint()..color = col(const Color(0xFF4CAF74));
        for (var i = 0; i < 14; i++) {
          final a = i * 2 * math.pi / 14;
          final o = center + Offset(math.cos(a), math.sin(a)) * r * .92;
          canvas.save();
          canvas.translate(o.dx, o.dy);
          canvas.rotate(a + math.pi / 2);
          canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: r * .1, height: r * .2), leaf);
          canvas.restore();
        }
        break;
      case BorderStyleKind.flower:
        p
          ..color = col(const Color(0xFFF1A48A))
          ..strokeWidth = math.max(1.0, size.width * .012);
        canvas.drawCircle(center, r * .9, p);
        final dot = Paint()..color = col(const Color(0xFFFBD5C8));
        final ring = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = col(const Color(0xFFE9825F));
        for (var i = 0; i < 8; i++) {
          final a = i * 2 * math.pi / 8 - math.pi / 2;
          final o = center + Offset(math.cos(a), math.sin(a)) * r * .9;
          canvas.drawCircle(o, r * .09, dot);
          canvas.drawCircle(o, r * .09, ring);
        }
        break;
      case BorderStyleKind.vine:
        p
          ..color = col(const Color(0xFF2E7D57))
          ..strokeWidth = size.width * .06;
        canvas.drawCircle(center, r * .86, p);
        final d = Paint()..color = col(const Color(0xFF2E7D57));
        for (var i = 0; i < 4; i++) {
          final a = i * math.pi / 2 - math.pi / 2;
          canvas.drawCircle(center + Offset(math.cos(a), math.sin(a)) * r * .99, r * .07, d);
        }
        break;
      case BorderStyleKind.golden:
        p
          ..color = col(const Color(0xFFE2A95A))
          ..strokeWidth = math.max(1.5, size.width * .018);
        canvas.drawCircle(center, r * .95, p);
        canvas.drawCircle(center, r * .8, p..strokeWidth = math.max(1.0, size.width * .01));
        canvas.drawCircle(center + Offset(0, -r * .95), r * .06, Paint()..color = col(const Color(0xFFE2A95A)));
        break;
    }
  }

  void _dashed(Canvas canvas, Offset c, double r, Paint p, int dashes) {
    final step = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), i * step, step * .55, false, p);
    }
  }

  @override
  bool shouldRepaint(covariant BorderPainter old) => old.kind != kind || old.muted != muted;
}

/// Small border swatch with a placeholder person inside (Shop & border lists).
class BorderSwatch extends StatelessWidget {
  final BorderStyleKind kind;
  final double size;
  final bool locked;
  final bool active;
  const BorderSwatch(this.kind, {super.key, this.size = 58, this.locked = false, this.active = false});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Color bg;
    switch (kind) {
      case BorderStyleKind.flower:
        bg = const Color(0xFFFFF4EF);
        break;
      case BorderStyleKind.golden:
        bg = const Color(0xFFFFF9EC);
        break;
      default:
        bg = c.isDark ? c.cardAlt : const Color(0xFFEFF6F1);
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: active ? Colors.white : bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      padding: EdgeInsets.all(size * .14),
      child: Stack(alignment: Alignment.center, children: [
        CustomPaint(size: Size.square(size * .72), painter: BorderPainter(kind, muted: locked)),
        Container(
          width: size * .36,
          height: size * .36,
          decoration:
              BoxDecoration(color: active ? const Color(0xFFD1FAE5) : const Color(0xFFE5E7EB), shape: BoxShape.circle),
          child:
              Icon(Icons.person, size: size * .26, color: active ? const Color(0xFF15803D) : const Color(0xFFB8BEC6)),
        ),
      ]),
    );
  }
}

/// Terracotta pot drawn with paths (garden grid & empty states).
class PotPainter extends CustomPainter {
  final int? number;
  final bool dark;
  PotPainter({this.number, this.dark = false});

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final rim = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h * .26), Radius.circular(h * .06));
    canvas.drawRRect(rim, Paint()..color = const Color(0xFFDE7F50));
    final body = Path()
      ..moveTo(w * .08, h * .26)
      ..lineTo(w * .92, h * .26)
      ..lineTo(w * .84, h)
      ..lineTo(w * .16, h)
      ..close();
    canvas.drawPath(
        body,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFC8643B), Color(0xFFB4532E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, 0, w, h)));
    if (number != null) {
      final cr = h * .28;
      final cc = Offset(w / 2, h * .62);
      canvas.drawCircle(cc, cr, Paint()..color = const Color(0xFFFDF4EC));
      final tp = TextPainter(
        text: TextSpan(text: '$number', style: T.p(cr * 1.05, w: FontWeight.w700, c: const Color(0xFF7A3A1D))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, cc - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant PotPainter old) => old.number != number;
}

/// Simple terracotta pot used inside illustrations (empty pot state).
class PotIllustration extends StatelessWidget {
  final double size;
  final bool sprout;
  const PotIllustration({super.key, this.size = 90, this.sprout = false});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.isDark ? c.cardAlt : const Color(0xFFD7F0E0), shape: BoxShape.circle),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (sprout) Icon(Icons.spa, size: size * .28, color: const Color(0xFF3E8E5E)),
        SizedBox(
          width: size * .5,
          height: size * .38,
          child: CustomPaint(painter: PotPainter()),
        ),
      ]),
    );
  }
}
