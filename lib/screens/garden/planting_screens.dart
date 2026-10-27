import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../nav.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'garden_screen.dart';

Widget _potPill(BuildContext context, int pot, {bool coral = true}) {
  final c = context.c;
  final fg = coral ? const Color(0xFFC2410C) : c.mintText;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: coral
          ? (c.isDark ? const Color(0xFF3A2015) : const Color(0xFFFFEFE6))
          : (c.isDark ? c.mint : const Color(0xFFE3F5EA)),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: coral ? const Color(0xFFFBD3BD) : const Color(0xFFBFE6CE)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: coral ? const Color(0xFFEA6A3C) : c.mintText, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text('Pot $pot', style: T.p(12.5, w: FontWeight.w600, c: fg)),
    ]),
  );
}

class ChooseFlowerScreen extends StatefulWidget {
  final int pot;
  const ChooseFlowerScreen({super.key, required this.pot});
  @override
  State<ChooseFlowerScreen> createState() => _ChooseFlowerScreenState();
}

class _ChooseFlowerScreenState extends State<ChooseFlowerScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = context.c;
    final owned = s.ownedSeedIds.map(Flowers.byId).toList();
    return Scaffold(
      backgroundColor: c.isDark ? c.bg : const Color(0xFFF3F8F4),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Row(children: [
              const CircleBackButton(size: 36, outlined: true),
              Expanded(
                child: Text('Choose a Flower',
                    textAlign: TextAlign.center, style: T.p(18, w: FontWeight.w700, c: c.heading)),
              ),
              _potPill(context, widget.pot),
            ]),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              Expanded(
                child: RichText(
                  text: TextSpan(children: [
                    TextSpan(text: 'Planting target: ', style: T.p(13.5, c: c.textMuted)),
                    TextSpan(
                        text: 'Empty Ceramic Pot ${widget.pot}', style: T.p(13.5, w: FontWeight.w700, c: c.heading)),
                  ]),
                ),
              ),
              Pill('${s.totalSeeds} Seeds',
                  icon: Icons.yard_outlined,
                  fontSize: 11,
                  bg: c.isDark ? c.mint : const Color(0xFFE3F5EA),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
            ]),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: GridView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 140),
              children: [
                for (final f in owned)
                  _FlowerChoice(
                    flower: f,
                    count: s.seedCount(f.id),
                    selected: _selected == f.id,
                    onTap: () async {
                      setState(() => _selected = f.id);
                      await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ConfirmPlantingScreen(pot: widget.pot, flowerId: f.id)));
                      if (mounted) setState(() => _selected = null);
                    },
                  ),
                _BuyMoreCard(onTap: () => goTab(context, 3)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
            child: OutlineButtonSF('Cancel',
                height: 52, fontSize: 15.5, weight: FontWeight.w700, onTap: () => Navigator.of(context).pop()),
          ),
        ]),
      ),
    );
  }
}

class _FlowerChoice extends StatelessWidget {
  final Flower flower;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  const _FlowerChoice({required this.flower, required this.count, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SFCard(
      onTap: onTap,
      radius: 16,
      borderColor: selected ? const Color(0xFF2E7D57) : null,
      borderWidth: selected ? 2 : 1,
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
      child: Column(children: [
        Align(
          alignment: Alignment.topRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: c.isDark ? c.cardAlt : const Color(0xFFEEF1F4), borderRadius: BorderRadius.circular(10)),
            child: Text('x$count', style: T.p(10.5, w: FontWeight.w700, c: c.text)),
          ),
        ),
        FlowerIcon(flower, size: 44, useEmoji: true),
        const SizedBox(height: 6),
        Text(flower.name, style: T.p(13.5, w: FontWeight.w700, c: c.heading)),
        const SizedBox(height: 4),
        Pill('Plant',
            dot: true,
            fontSize: 10.5,
            bg: c.isDark ? c.mint : const Color(0xFFE3F5EA),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
      ]),
    );
  }
}

class _BuyMoreCard extends StatelessWidget {
  final VoidCallback onTap;
  const _BuyMoreCard({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: CustomPaint(
        painter: _DashedRRect(color: c.isDark ? c.border : const Color(0xFFCBD5E1)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: c.isDark ? c.cardAlt : const Color(0xFFEEF1F6), shape: BoxShape.circle),
            child: Icon(Icons.add_circle_outline, color: c.textMuted, size: 22),
          ),
          const SizedBox(height: 10),
          Text('Buy more seeds', style: T.p(11, w: FontWeight.w600, c: c.textMuted)),
        ]),
      ),
    );
  }
}

class _DashedRRect extends CustomPainter {
  final Color color;
  _DashedRRect({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)));
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 5), p);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRect old) => old.color != color;
}

class ConfirmPlantingScreen extends StatelessWidget {
  final int pot;
  final String flowerId;
  const ConfirmPlantingScreen({super.key, required this.pot, required this.flowerId});

  void _plant(BuildContext context) {
    final s = context.read<AppState>();
    if (!s.plant(pot, flowerId)) {
      showSnack(context, 'Unable to plant: pot is taken or no seeds left.');
      return;
    }
    GardenScreen.selection.value = pot;
    goTab(context, 1);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final f = Flowers.byId(flowerId);
    return Scaffold(
      backgroundColor: c.isDark ? c.bg : Colors.white,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: Row(children: [
              const CircleBackButton(size: 36, outlined: true),
              Expanded(
                  child: Text('Confirm Planting',
                      textAlign: TextAlign.center, style: T.p(17, w: FontWeight.w700, c: c.heading))),
              _potPill(context, pot, coral: false),
            ]),
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 16), children: [
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: c.isDark ? c.cardAlt : const Color(0xFFF6F2DC)),
                  alignment: Alignment.center,
                  child: Container(
                    width: 168,
                    height: 168,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.isDark ? c.card : const Color(0xFFFBF7E3),
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: ClipOval(
                      child: flowerId == 'daisy'
                          ? Image.asset('assets/images/daisy_large.png', fit: BoxFit.cover)
                          : Image.asset(f.asset, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(child: Text(f.name, style: T.p(28, w: FontWeight.w700, c: c.heading))),
              const SizedBox(height: 8),
              Text(f.description, textAlign: TextAlign.center, style: T.p(13.5, c: c.textMuted, h: 1.55)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.isDark ? c.card : const Color(0xFFF2F8F4),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: c.isDark ? c.border : const Color(0xFFDCEDE2)),
                ),
                child: Column(children: [
                  Row(children: [
                    Text('PLANTING DESTINATION', style: T.p(11.5, w: FontWeight.w600, c: c.textMuted, ls: .5)),
                    const Spacer(),
                    Pill('Ready',
                        icon: Icons.check_circle_outline,
                        fontSize: 11,
                        weight: FontWeight.w500,
                        bg: c.isDark ? c.mint : const Color(0xFFDDF3E5),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3)),
                  ]),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: c.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.border)),
                    child: Row(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration:
                            BoxDecoration(color: const Color(0xFFFFEDE4), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.local_drink, size: 18, color: Color(0xFFDE7F50)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Pot $pot', style: T.p(15, w: FontWeight.w600, c: c.heading)),
                          Text('Empty pot • Ready to plant', style: T.p(12, c: c.textMuted)),
                        ]),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.isDark ? c.mint : const Color(0xFFE3F5EA),
                            border: Border.all(color: const Color(0xFFBFE6CE))),
                        child: Icon(Icons.check, size: 16, color: c.mintText),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: _InfoBox(
                        icon: Icons.schedule,
                        label: 'BLOOM TIME',
                        value: '6h 0m',
                        bg: c.isDark ? c.mint : const Color(0xFFE3F2E8),
                        border: const Color(0xFFCDE6D6),
                        labelColor: c.textMuted,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoBox(
                        icon: Icons.emoji_events_outlined,
                        label: 'HARVEST REWARD',
                        value: '+${f.rewardXp} XP • ${f.rewardCoins}',
                        coin: true,
                        bg: c.isDark ? c.amberTint : const Color(0xFFFFF6DD),
                        border: const Color(0xFFF7E3A8),
                        labelColor: c.amber,
                      ),
                    ),
                  ]),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Row(children: [
              Expanded(
                child: OutlineButtonSF('Cancel',
                    icon: Icons.close, height: 46, weight: FontWeight.w600, onTap: () => Navigator.of(context).pop()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton('Plant Flower',
                    icon: Icons.yard_outlined,
                    height: 46,
                    color: c.isDark ? c.primary : const Color(0xFF1F4D3A),
                    onTap: () => _plant(context)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color bg, border, labelColor;
  final bool coin;
  const _InfoBox(
      {required this.icon,
      required this.label,
      required this.value,
      required this.bg,
      required this.border,
      required this.labelColor,
      this.coin = false});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Row(children: [
        Icon(icon, size: 16, color: labelColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: T.p(9, w: FontWeight.w700, c: labelColor, ls: .4)),
                Row(children: [
                  Flexible(
                      child: Text(value,
                          overflow: TextOverflow.ellipsis, style: T.p(12.5, w: FontWeight.w700, c: c.heading))),
                  if (coin) ...[
                    const SizedBox(width: 3),
                    Container(
                        width: 11,
                        height: 11,
                        decoration: const BoxDecoration(color: Color(0xFF6B7280), shape: BoxShape.circle)),
                  ],
                ]),
              ]),
        ),
      ]),
    );
  }
}
