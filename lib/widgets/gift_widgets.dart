import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/flower.dart';
import '../providers/feedback_bus.dart';
import '../providers/game_provider.dart';
import '../services/sound_service.dart';
import 'common.dart';
import 'plant_widgets.dart';

// =============================================================================
// Welcome gift — new users claim their 150 free coins from this screen.
// =============================================================================

Future<void> showWelcomeGift(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'welcome',
    barrierColor: Colors.black.withValues(alpha: 0.6),
    transitionDuration: const Duration(milliseconds: 520),
    pageBuilder: (_, __, ___) => const _WelcomeGiftDialog(),
    transitionBuilder: (_, a, __, child) => ScaleTransition(
      scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: a, child: child),
    ),
  );
}

class _WelcomeGiftDialog extends StatefulWidget {
  const _WelcomeGiftDialog();
  @override
  State<_WelcomeGiftDialog> createState() => _WelcomeGiftDialogState();
}

class _WelcomeGiftDialogState extends State<_WelcomeGiftDialog> with TickerProviderStateMixin {
  // Idle: glowing coin with slowly turning rays. Claim: coin burst + count-up.
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final AnimationController _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  bool _claimed = false;

  @override
  void dispose() {
    _idle.dispose();
    _burst.dispose();
    super.dispose();
  }

  Future<void> _claim() async {
    if (_claimed) return;
    setState(() => _claimed = true);
    SoundService.instance.play(Sfx.coin);
    context.read<GameProvider>().claimWelcome();
    await _burst.forward();
    await Future.delayed(const Duration(milliseconds: 650));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    return PopScope(
      canPop: _claimed, // the gift must be claimed (no accidental back-press)
      child: Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(30)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('WELCOME TO STUDY FLORA', style: context.tt.labelSmall?.copyWith(color: c.gold, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            SizedBox(
              width: 210,
              height: 190,
              child: AnimatedBuilder(
                animation: Listenable.merge([_idle, _burst]),
                builder: (_, __) => _CoinStage(idle: _idle.value, burst: _burst.value, claimed: _claimed),
              ),
            ),
            const SizedBox(height: 6),
            Text(_claimed ? 'Coins added!' : 'A gift for you!', style: context.tt.titleLarge),
            const SizedBox(height: 6),
            Text(
              _claimed
                  ? 'Spend them in the Shop on seeds and garden tools.'
                  : 'Here are ${GameRules.welcomeCoins} free coins to start your garden. Use them to buy seeds and tools.',
              style: context.tt.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _claimed ? 0.5 : 1,
              child: PrimaryButton(
                label: _claimed ? 'Claimed' : 'Claim ${GameRules.welcomeCoins} Coins',
                icon: _claimed ? Icons.check_rounded : Icons.redeem_rounded,
                color: c.danger,
                onTap: _claimed ? null : _claim,
              ),
            ),
          ]),
        ),
      ),
      ),
    );
  }
}

class _CoinStage extends StatelessWidget {
  const _CoinStage({required this.idle, required this.burst, required this.claimed});
  final double idle;
  final double burst;
  final bool claimed;

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final pulse = 1 + 0.05 * sin(idle * 2 * pi * 3);
    final count = (GameRules.welcomeCoins * Curves.easeOut.transform((burst * 1.3).clamp(0, 1))).round();
    return Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
      // Turning sun rays behind the coin.
      Transform.rotate(
        angle: idle * 2 * pi,
        child: CustomPaint(size: const Size(190, 190), painter: _RaysPainter(c.gold.withValues(alpha: 0.22))),
      ),
      Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: c.gold.withValues(alpha: 0.45), blurRadius: 34 * pulse, spreadRadius: 4)],
        ),
      ),
      Transform.scale(scale: pulse * (1 + 0.25 * sin(pi * burst)), child: const CoinIcon(size: 104)),
      // Coins bursting out on claim.
      if (claimed)
        for (var i = 0; i < 14; i++) _flyingCoin(i, burst),
      Positioned(
        bottom: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(color: c.goldSoft, borderRadius: BorderRadius.circular(99)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const CoinIcon(size: 18),
            const SizedBox(width: 6),
            Text(claimed ? '+$count' : '${GameRules.welcomeCoins}',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: c.ink)),
          ]),
        ),
      ),
    ]);
  }

  Widget _flyingCoin(int i, double t) {
    final angle = -pi / 2 + (i - 6.5) * 0.36;
    final dist = 30 + 95 * Curves.easeOut.transform(t);
    final dx = cos(angle) * dist;
    final dy = sin(angle) * dist + 60 * t * t; // a little gravity
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Opacity(
        opacity: (1 - t).clamp(0, 1),
        child: Transform.rotate(angle: t * 6 + i, child: CoinIcon(size: 16 + (i % 3) * 4.0)),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  _RaysPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    for (var i = 0; i < 12; i++) {
      final a = i * pi / 6;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + r * cos(a - 0.11), c.dy + r * sin(a - 0.11))
        ..lineTo(c.dx + r * cos(a + 0.11), c.dy + r * sin(a + 0.11))
        ..close();
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.color != color;
}

// =============================================================================
// Daily free flower — one random seed every day from 8:00 AM.
// =============================================================================

/// Home card: "Claim" when today's flower is ready, otherwise a countdown.
class DailyGiftCard extends StatelessWidget {
  const DailyGiftCard({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<ClockTicker>();
    final g = context.watch<GameProvider>();
    final c = context.sf;
    final ready = g.dailyGiftReady;
    final next = g.nextDailyGift;
    final wait = next.difference(DateTime.now());
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SfCard(
        onTap: ready ? () => claimDailyGift(context) : null,
        color: ready ? c.dangerSoft : null,
        border: ready ? c.danger.withValues(alpha: 0.35) : null,
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          IconTile(Icons.redeem_rounded, size: 44, color: ready ? c.danger : c.brand, bg: ready ? c.surface : null),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Free Flower of the Day', style: context.tt.titleSmall),
              Text(
                ready ? 'Your free random seed is ready!' : 'Next free flower in ${fmtDuration(wait)} • 8:00 AM',
                style: context.tt.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
          const SizedBox(width: 8),
          if (ready) ClaimPill(onTap: () => claimDailyGift(context)) else Icon(Icons.schedule_rounded, color: c.muted, size: 20),
        ]),
      ),
    );
  }
}

Future<void> claimDailyGift(BuildContext context) async {
  final id = context.read<GameProvider>().claimDailyGift();
  if (id == null) return;
  SoundService.instance.play(Sfx.badge);
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'daily flower',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 480),
    pageBuilder: (ctx, _, __) => _DailyFlowerDialog(flower: Flower.of(id)),
    transitionBuilder: (_, a, __, child) => ScaleTransition(
      scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: a, child: child),
    ),
  );
}

class _DailyFlowerDialog extends StatefulWidget {
  const _DailyFlowerDialog({required this.flower});
  final Flower flower;
  @override
  State<_DailyFlowerDialog> createState() => _DailyFlowerDialogState();
}

class _DailyFlowerDialogState extends State<_DailyFlowerDialog> with SingleTickerProviderStateMixin {
  // Gift box wiggles, pops, then the seed grows in.
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..forward();

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final f = widget.flower;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 310,
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(28)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('FREE FLOWER OF THE DAY', style: context.tt.labelSmall?.copyWith(color: c.danger, letterSpacing: 1.1)),
            const SizedBox(height: 12),
            SizedBox(
              width: 150,
              height: 150,
              child: AnimatedBuilder(
                animation: _a,
                builder: (_, __) {
                  final t = _a.value;
                  final box = (1 - Curves.easeIn.transform(((t - 0.35) / 0.2).clamp(0, 1)));
                  final wiggle = sin(t * 40) * 0.12 * (1 - (t / 0.35).clamp(0, 1));
                  final seed = Curves.elasticOut.transform(((t - 0.45) / 0.55).clamp(0, 1));
                  return Stack(alignment: Alignment.center, children: [
                    if (box > 0)
                      Opacity(
                        opacity: box,
                        child: Transform.rotate(
                          angle: wiggle,
                          child: Transform.scale(scale: 1 + 0.4 * (1 - box), child: Icon(Icons.redeem_rounded, size: 96, color: c.danger)),
                        ),
                      ),
                    Transform.scale(
                      scale: seed,
                      child: SeedArt(asset: f.seedAsset, tint: f.tint, size: 130),
                    ),
                  ]);
                },
              ),
            ),
            const SizedBox(height: 10),
            Text('${f.name} seed', style: context.tt.titleLarge),
            const SizedBox(height: 6),
            StatusBadge(f.rarity.label, tone: switch (f.rarity) { Rarity.common => Tone.green, Rarity.uncommon => Tone.blue, Rarity.rare => Tone.gold }),
            const SizedBox(height: 8),
            Text('Added to your inventory. Come back tomorrow at 8:00 AM for another free flower!',
                style: context.tt.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Awesome!', height: 48, onTap: () => Navigator.of(context).pop()),
          ]),
        ),
      ),
    );
  }
}
