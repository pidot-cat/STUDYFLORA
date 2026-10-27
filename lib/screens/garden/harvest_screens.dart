import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/common.dart';
import 'garden_screen.dart';
import 'garden_widgets.dart';

Widget _frame(BuildContext context, Widget card, {Widget? below}) {
  final c = context.c;
  return Scaffold(
    backgroundColor: c.isDark ? c.bg : const Color(0xFFF1F5F2),
    body: SafeArea(
      bottom: false,
      child: Column(children: [
        const AppHeader(back: true),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 24), children: [
            card,
            if (below != null) ...[const SizedBox(height: 46), below],
          ]),
        ),
      ]),
    ),
  );
}

BoxDecoration _cardDeco(BuildContext context) => BoxDecoration(
      color: context.c.card,
      borderRadius: BorderRadius.circular(30),
      boxShadow:
          context.c.isDark ? null : const [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 6))],
      border: context.c.isDark ? Border.all(color: context.c.border) : null,
    );

Widget _rewardBox(BuildContext context, int xp, {bool upperLabel = false}) {
  final c = context.c;
  return Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
    decoration: BoxDecoration(
      color: c.isDark ? c.cardAlt : const Color(0xFFF0F7F2),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: c.isDark ? c.border : const Color(0xFFDCEDE2)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(upperLabel ? 'REWARD' : 'Reward',
          style: T.p(11.5, w: FontWeight.w600, c: upperLabel ? c.textMuted : c.mintText, ls: upperLabel ? .6 : 0)),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(mainAxisAlignment: upperLabel ? MainAxisAlignment.start : MainAxisAlignment.center, children: [
            if (upperLabel) const SizedBox(width: 40),
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(color: Color(0xFFD1FAE5), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text('XP', style: T.p(10.5, w: FontWeight.w700, c: const Color(0xFF14532D))),
            ),
            const SizedBox(width: 10),
            Text('+$xp XP', style: T.p(15, w: FontWeight.w700, c: c.text)),
          ]),
        ),
      ),
    ]),
  );
}

class ReadyToHarvestScreen extends StatelessWidget {
  final int pot;
  const ReadyToHarvestScreen({super.key, required this.pot});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final p = context.watch<AppState>().plantAt(pot);
    if (p == null) return const Scaffold();
    final f = p.flower;
    return _frame(
      context,
      Container(
        decoration: _cardDeco(context),
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 26),
        child: Column(children: [
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(color: c.isDark ? c.cardAlt : const Color(0xFFEFF7F1), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: PlantArt(f.id, size: 130, large: true),
          ),
          const SizedBox(height: 18),
          Text('Ready to Harvest!', style: T.p(25, w: FontWeight.w700, c: c.heading)),
          const SizedBox(height: 10),
          Text('Your ${f.name.toLowerCase()} is ready to harvest.\nGreat job for keeping your plant happy and healthy!',
              textAlign: TextAlign.center, style: T.p(13.5, c: c.textMuted, h: 1.55)),
          const SizedBox(height: 22),
          _rewardBox(context, f.rewardXp),
          const SizedBox(height: 30),
          PrimaryButton('Harvest',
              icon: Icons.spa_outlined,
              trailingIcon: Icons.chevron_right,
              color: c.isDark ? c.primary : const Color(0xFF268556),
              fontSize: 16,
              onTap: p.ready
                  ? () => Navigator.of(context)
                      .pushReplacement(MaterialPageRoute(builder: (_) => HarvestingScreen(pot: pot, flowerId: f.id)))
                  : null),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: T.p(14, c: c.textMuted)),
          ),
        ]),
      ),
    );
  }
}

class HarvestingScreen extends StatefulWidget {
  final int pot;
  final String flowerId;
  const HarvestingScreen({super.key, required this.pot, required this.flowerId});
  @override
  State<HarvestingScreen> createState() => _HarvestingScreenState();
}

class _HarvestingScreenState extends State<HarvestingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      final xp = context.read<AppState>().harvest(widget.pot);
      GardenScreen.selection.value = widget.pot;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => HarvestCompleteScreen(
              flowerId: widget.flowerId, xp: xp == 0 ? Flowers.byId(widget.flowerId).rewardXp : xp)));
    });
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return _frame(
      context,
      Container(
        height: 520,
        decoration: _cardDeco(context),
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 26),
        child: Column(children: [
          SizedBox(
            width: 210,
            height: 210,
            child: Stack(alignment: Alignment.center, children: [
              Container(
                  decoration:
                      BoxDecoration(color: c.isDark ? c.cardAlt : const Color(0xFFEFF7F1), shape: BoxShape.circle)),
              RotationTransition(
                turns: _ac,
                child: CustomPaint(size: const Size.square(140), painter: _DashedCircle()),
              ),
              PlantArt(widget.flowerId, size: 110, large: true),
            ]),
          ),
          const SizedBox(height: 50),
          Text('Harvesting...', style: T.p(22, w: FontWeight.w700, c: c.heading)),
          const SizedBox(height: 10),
          Text('Claiming your rewards, please wait.', style: T.p(13.5, c: c.textMuted)),
        ]),
      ),
    );
  }
}

class _DashedCircle extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF7FD4A0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const n = 22;
    for (var i = 0; i < n; i++) {
      final a = i * 2 * math.pi / n;
      canvas.drawArc(Offset.zero & size, a, 2 * math.pi / n * .55, false, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HarvestCompleteScreen extends StatelessWidget {
  final String flowerId;
  final int xp;
  const HarvestCompleteScreen({super.key, required this.flowerId, required this.xp});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final f = Flowers.byId(flowerId);
    return _frame(
      context,
      Container(
        decoration: _cardDeco(context),
        padding: const EdgeInsets.fromLTRB(10, 36, 10, 50),
        child: Column(children: [
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(color: c.isDark ? c.cardAlt : const Color(0xFFEFF7F1), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Stack(alignment: Alignment.center, children: [
              Icon(Icons.spa_outlined, size: 140, color: const Color(0xFFA5DDB9).withValues(alpha: .9)),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(color: Color(0xFF3AAA68), shape: BoxShape.circle),
                child: const Icon(Icons.star_rounded, color: Colors.white, size: 42),
              ),
            ]),
          ),
          const SizedBox(height: 26),
          Text('Harvest Complete!', style: T.p(24, w: FontWeight.w700, c: c.heading)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
                'Your ${f.name.toLowerCase()} has been harvested. Great job for keeping your plant happy and healthy!',
                textAlign: TextAlign.center,
                style: T.p(13.5, c: c.textMuted, h: 1.55)),
          ),
          const SizedBox(height: 22),
          _rewardBox(context, xp, upperLabel: true),
        ]),
      ),
      below: OutlineButtonSF('Back to Garden',
          height: 62,
          radius: 18,
          fg: c.textMuted,
          weight: FontWeight.w500,
          onTap: () => Navigator.of(context).popUntil((r) => r.isFirst)),
    );
  }
}
