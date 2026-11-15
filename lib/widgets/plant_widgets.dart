import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/pot.dart';
import 'common.dart';

/// Renders a pot at its current stage (seed → sprout → bloom, or wilted when
/// dry) with a soft cross-fade whenever the stage changes.
class PlantImage extends StatelessWidget {
  const PlantImage({super.key, required this.pot, required this.now, this.height = 64, this.showIndicators = true});
  final Pot pot;
  final int now;
  final double height;
  final bool showIndicators;

  @override
  Widget build(BuildContext context) {
    final asset = pot.imageAt(now);
    final ready = pot.isReadyAt(now);
    final thirsty = pot.needsWaterAt(now);
    final dimSeed = thirsty && pot.stageAt(now) == PlantStage.seed;

    Widget img = AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(a), alignment: Alignment.bottomCenter, child: child),
      ),
      child: Image.asset(
        asset,
        key: ValueKey(asset),
        height: height,
        fit: BoxFit.fitHeight,
        alignment: Alignment.bottomCenter,
        color: dimSeed ? Colors.brown.withValues(alpha: 0.18) : null,
        colorBlendMode: dimSeed ? BlendMode.srcATop : null,
      ),
    );

    if (ready) img = _ReadyGlow(height: height, child: img);

    return SizedBox(
      height: height,
      width: height * 0.95,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
        img,
        if (showIndicators && thirsty)
          Positioned(top: -height * 0.06, right: -height * 0.02, child: _Bob(child: _Indicator(icon: Icons.water_drop_rounded, color: context.sf.info, size: height * 0.3))),
        if (showIndicators && ready)
          Positioned(top: -height * 0.06, right: -height * 0.02, child: _Bob(child: _Indicator(icon: Icons.star_rounded, color: context.sf.gold, size: height * 0.3))),
      ]),
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({required this.icon, required this.color, required this.size});
  final IconData icon;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: math.max(18, size),
        height: math.max(18, size),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)],
        ),
        child: Icon(icon, color: color, size: math.max(12, size * 0.66)),
      );
}

/// Gentle up/down bob for indicators.
class _Bob extends StatefulWidget {
  const _Bob({required this.child});
  final Widget child;
  @override
  State<_Bob> createState() => _BobState();
}

class _BobState extends State<_Bob> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Transform.translate(offset: Offset(0, -3 * Curves.easeInOut.transform(_c.value)), child: child),
        child: widget.child,
      );
}

/// Pulsing golden halo behind a plant that's ready to harvest.
class _ReadyGlow extends StatefulWidget {
  const _ReadyGlow({required this.child, required this.height});
  final Widget child;
  final double height;
  @override
  State<_ReadyGlow> createState() => _ReadyGlowState();
}

class _ReadyGlowState extends State<_ReadyGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
      AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Container(
          width: widget.height * (0.7 + 0.1 * _c.value),
          height: widget.height * (0.7 + 0.1 * _c.value),
          decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
            BoxShadow(color: const Color(0xFFFFD45C).withValues(alpha: 0.35 + 0.25 * _c.value), blurRadius: widget.height * 0.35, spreadRadius: 2),
          ]),
        ),
      ),
      widget.child,
    ]);
  }
}

/// Small status badge for a pot.
StatusBadge potStatusBadge(Pot p, int now, {bool dense = true}) {
  if (p.isEmpty) return StatusBadge('Empty', tone: Tone.neutral, dense: dense);
  if (p.isReadyAt(now)) return StatusBadge('Ready to Harvest', tone: Tone.gold, icon: Icons.star_rounded, dense: dense);
  if (p.needsWaterAt(now)) {
    return StatusBadge(p.growthAt(now) > 0 ? 'Wilted' : 'Needs water', tone: Tone.red, icon: Icons.water_drop_outlined, dense: dense);
  }
  return StatusBadge(p.stageAt(now) == PlantStage.seed ? 'Seed' : 'Sprouting', tone: Tone.green, dense: dense);
}

String stageLabel(PlantStage s) => switch (s) {
      PlantStage.empty => 'Empty pot',
      PlantStage.seed => 'Stage 1 · Seed',
      PlantStage.sprout => 'Stage 2 · Sprout',
      PlantStage.bloom => 'Stage 3 · Full bloom',
    };

/// Seed artwork for the Shop: a single seed pot, or — for a bundle — a fanned
/// trio of pots with a "×5" tag so packs never look like single seeds.
class SeedArt extends StatelessWidget {
  const SeedArt({super.key, required this.asset, required this.tint, this.bundle = false, this.size = 72});
  final String asset;
  final Color tint;
  final bool bundle;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final bg = context.isDark ? Color.alphaBlend(tint.withValues(alpha: 0.18), c.surfaceAlt) : tint;
    if (!bundle) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          Container(decoration: BoxDecoration(color: bg, shape: BoxShape.circle)),
          Padding(padding: EdgeInsets.all(size * 0.12), child: Image.asset(asset)),
        ]),
      );
    }

    // Bundle: five pots lined up on a tray — the middle one in front, the
    // outer ones a little smaller behind it — with a clear "×5" tag.
    final w = size * 1.72;
    final pot = size * 0.62; // height of the front pot
    final step = size * 0.285; // distance between pot centres
    Widget potAt(int i) {
      final d = (i - 2).abs(); // 0 = centre, 2 = outer
      final h = pot * (1 - d * 0.11);
      return Positioned(
        left: w / 2 + (i - 2) * step - h * 0.5,
        bottom: size * 0.17 + d * size * 0.035,
        child: _SeedPot(asset: asset, height: h),
      );
    }

    return SizedBox(
      width: w,
      height: size,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(
          child: DecoratedBox(decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * 0.3))),
        ),
        // Soft shelf under the pots.
        Positioned(
          left: size * 0.14,
          right: size * 0.14,
          bottom: size * 0.12,
          height: size * 0.12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: context.isDark ? 0.22 : 0.07),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        // Outer pots first so the centre pot is drawn on top.
        for (final i in const [0, 4, 1, 3, 2]) potAt(i),
        Positioned(
          right: -size * 0.05,
          top: -size * 0.06,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: size * 0.1, vertical: size * 0.03),
            decoration: BoxDecoration(
              color: c.terracotta,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: c.surface, width: 2),
            ),
            child: Text('×5', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.17, height: 1.15)),
          ),
        ),
      ]),
    );
  }
}

/// A seed pot without the empty space around it in the artwork (the pot only
/// fills the lower-middle part of the image), so pots can sit close together.
class _SeedPot extends StatelessWidget {
  const _SeedPot({required this.asset, required this.height});
  final String asset;
  final double height;

  // Where the pot sits inside the artwork (fractions of the image).
  static const _left = 0.185, _top = 0.43, _right = 0.81;

  @override
  Widget build(BuildContext context) {
    const imgAspect = 215 / 240; // artwork width / height
    final fullH = height / (1 - _top);
    final fullW = fullH * imgAspect;
    final width = fullW * (_right - _left);
    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: fullW,
          maxWidth: fullW,
          minHeight: fullH,
          maxHeight: fullH,
          child: Transform.translate(
            offset: Offset(-fullW * _left, -fullH * _top),
            child: Image.asset(asset, width: fullW, height: fullH, fit: BoxFit.fill),
          ),
        ),
      ),
    );
  }
}
