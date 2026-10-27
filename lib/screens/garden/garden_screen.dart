import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../nav.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_header.dart';
import '../../widgets/common.dart';
import '../../widgets/visuals.dart';
import 'garden_widgets.dart';
import 'harvest_screens.dart';
import 'plant_details_screens.dart';
import 'planting_screens.dart';
import 'tool_screens.dart';

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  /// Selected pot (1-based). Other screens set this before switching to the tab.
  static final selection = ValueNotifier<int?>(-1); // -1 = not initialised yet

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  @override
  void initState() {
    super.initState();
    if (GardenScreen.selection.value == -1) {
      final plants = context.read<AppState>().plants;
      final first = plants.isEmpty ? null : (plants.map((p) => p.pot).toList()..sort()).first;
      GardenScreen.selection.value = first;
    }
    GardenScreen.selection.addListener(_onSel);
  }

  @override
  void dispose() {
    GardenScreen.selection.removeListener(_onSel);
    super.dispose();
  }

  void _onSel() {
    if (mounted) setState(() {});
  }

  void _tap(int pot) {
    GardenScreen.selection.value = GardenScreen.selection.value == pot ? null : pot;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = context.c;
    final sel = GardenScreen.selection.value;
    final selected = (sel == null || sel < 1) ? null : sel;
    final plant = selected == null ? null : s.plantAt(selected);
    return Scaffold(
      backgroundColor: c.isDark ? c.bg : const Color(0xFFEFF6F2),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const AppHeader(),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 24), children: [
              const _GardenBanner(),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.isDark ? c.card : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: c.border),
                  boxShadow: c.isDark ? null : [BoxShadow(color: c.shadow, blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: GardenRules.potCount,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: .62,
                  ),
                  itemBuilder: (_, i) => PotTile(
                    number: i + 1,
                    plant: s.plantAt(i + 1),
                    selected: selected == i + 1,
                    onTap: () => _tap(i + 1),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (selected == null)
                const Padding(padding: EdgeInsets.only(top: 60), child: _NoPlantSelected())
              else if (plant == null)
                Padding(padding: const EdgeInsets.only(top: 60), child: _EmptyPotPanel(pot: selected))
              else
                _PlantPanel(plant: plant),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _GardenBanner extends StatelessWidget {
  const _GardenBanner();
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      height: 82,
      decoration: BoxDecoration(
        gradient: c.isDark
            ? const LinearGradient(colors: [Color(0xFF10231B), Color(0xFF143326)])
            : const LinearGradient(colors: [Color(0xFFD9F2E3), Color(0xFFCDEEDB)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.isDark ? c.border : const Color(0xFFBFE6CE)),
      ),
      child: Stack(children: [
        Positioned(
          right: -6,
          top: -4,
          child: Transform.rotate(
            angle: -.5,
            child: Icon(Icons.eco, size: 90, color: c.isDark ? const Color(0xFF1E4A38) : const Color(0xFF9CD6B2)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            IconTile(Icons.spa_outlined,
                size: 48, iconSize: 24, radius: 12, bg: c.isDark ? c.cardAlt : const Color(0xFFBFE8CF), fg: c.mintText),
            const SizedBox(width: 14),
            Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Garden',
                      style: T.p(19, w: FontWeight.w600, c: c.isDark ? c.text : const Color(0xFF0F2B20))),
                  Text('18 pots • Grow, study, earn XP!',
                      style: T.p(12, c: c.isDark ? c.textMuted : const Color(0xFF2F4F3F))),
                ]),
          ]),
        ),
      ]),
    );
  }
}

class _NoPlantSelected extends StatelessWidget {
  const _NoPlantSelected();
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SFCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 50),
      child: Column(children: [
        Stack(alignment: Alignment.center, children: [
          const SizedBox(width: 120, height: 84),
          const PotIllustration(size: 80, sprout: true),
          for (final o in const [Offset(-50, -14), Offset(50, -14), Offset(-44, 18), Offset(44, 18)])
            Transform.translate(
              offset: o,
              child: Container(
                  width: o.dy < 0 ? 8 : 4,
                  height: o.dy < 0 ? 2 : 4,
                  decoration: BoxDecoration(color: const Color(0xFF8FCBA5), borderRadius: BorderRadius.circular(2))),
            ),
        ]),
        const SizedBox(height: 16),
        Text('No Plant Selected', style: T.p(16, w: FontWeight.w700, c: c.heading)),
        const SizedBox(height: 10),
        Text('Select a planted flower to view its details, growth progress, and available actions.',
            textAlign: TextAlign.center, style: T.p(13, c: c.textMuted, h: 1.55)),
      ]),
    );
  }
}

class _EmptyPotPanel extends StatelessWidget {
  final int pot;
  const _EmptyPotPanel({required this.pot});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SFCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Transform.rotate(
              angle: .3,
              child: Icon(Icons.drag_handle, color: const Color(0xFF8FCBA5).withValues(alpha: .7), size: 16)),
          const SizedBox(width: 12),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: c.isDark ? c.cardAlt : const Color(0xFFD7F0E0), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: SizedBox(width: 50, height: 42, child: CustomPaint(painter: PotPainter())),
          ),
          const SizedBox(width: 12),
          Transform.rotate(
              angle: -.3,
              child: Icon(Icons.drag_handle, color: const Color(0xFF8FCBA5).withValues(alpha: .7), size: 16)),
        ]),
        const SizedBox(height: 14),
        Text('Empty Pot', style: T.p(18, w: FontWeight.w700, c: c.heading)),
        const SizedBox(height: 4),
        Text('No flower planted here yet.\nChoose a seed to start growing!',
            textAlign: TextAlign.center, style: T.p(13, c: c.textMuted, h: 1.5)),
        const SizedBox(height: 18),
        PrimaryButton('Plant a Flower',
            icon: Icons.yard_outlined,
            radius: 14,
            color: c.isDark ? c.primary : const Color(0xFF14533C),
            onTap: () => pushRoot(context, ChooseFlowerScreen(pot: pot))),
        const SizedBox(height: 14),
        Text('Tap again or cancel to close this panel.', style: T.p(11, c: c.textMuted)),
      ]),
    );
  }
}

class _PlantPanel extends StatelessWidget {
  final Plant plant;
  const _PlantPanel({required this.plant});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final f = plant.flower;
    final pct = (plant.progress * 100).round();
    return SFCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: () => pushTab(context, PlantDetailsScreen(pot: plant.pot)),
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: c.isDark ? c.cardAlt : const Color(0xFFE6F4EA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.border),
              ),
              padding: const EdgeInsets.all(6),
              child: PlantArt(f.id, size: 64),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(f.name, style: T.p(17, w: FontWeight.w700, c: c.heading))),
                const SizedBox(width: 8),
                Pill(plant.ready ? 'Ready' : (plant.needsWater ? 'Thirsty' : 'Growing'),
                    fontSize: 11,
                    bg: c.isDark ? Colors.transparent : const Color(0xFFD7F2E0),
                    borderColor: c.isDark ? const Color(0xFF2B6B53) : const Color(0xFFBFE6CE),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
              ]),
              const SizedBox(height: 4),
              Text(f.description, style: T.p(12, c: c.textMuted, h: 1.45)),
            ]),
          ),
          const SizedBox(width: 6),
          Container(
            width: 96,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: c.isDark ? Colors.transparent : const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.isDark ? c.border : const Color(0xFFCDEBD8)),
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.schedule, size: 14, color: c.mintText),
                const SizedBox(width: 4),
                Text(plant.ready ? 'Ready' : fmtHm(plant.remaining), style: T.p(14, w: FontWeight.w700, c: c.heading)),
              ]),
              Text('UNTIL\nHARVEST',
                  textAlign: TextAlign.center, style: T.p(8.5, w: FontWeight.w600, c: c.textMuted, ls: .5, h: 1.3)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Icon(Icons.flag, size: 16, color: c.isDark ? c.accent : const Color(0xFF2E9E64)),
          const SizedBox(width: 6),
          Text('Growth Progress', style: T.p(13, w: FontWeight.w600, c: c.heading)),
          const Spacer(),
          Text('$pct%', style: T.p(13, w: FontWeight.w700, c: c.heading)),
        ]),
        const SizedBox(height: 8),
        SFProgress(
            value: plant.progress,
            height: 10,
            color: c.isDark ? c.accent : const Color(0xFF2E9E64),
            track: c.isDark ? c.border : const Color(0xFFE2EFE7)),
        const SizedBox(height: 16),
        IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
              child: _ToolTile(
                  title: 'Water',
                  body: 'Keep it hydrated to keep it growing.',
                  icon: Icons.water_drop,
                  bg: c.isDark ? c.cardAlt : const Color(0xFFEAF3FE),
                  border: c.isDark ? c.border : const Color(0xFFCFE3FB),
                  iconColor: const Color(0xFF2F80ED),
                  titleColor: c.heading,
                  onTap: () => pushTab(context, WaterPlantScreen(pot: plant.pot)))),
          const SizedBox(width: 10),
          Expanded(
              child: _ToolTile(
                  title: 'Fertilize',
                  body: '2× growth speed (1 use per plant).',
                  icon: Icons.medication_liquid,
                  bg: c.isDark ? c.cardAlt : const Color(0xFFEAF6EE),
                  border: c.isDark ? c.border : const Color(0xFFCDEBD8),
                  iconColor: const Color(0xFF2E9E64),
                  titleColor: c.heading,
                  onTap: () => pushTab(context, FertilizeScreen(pot: plant.pot)))),
          const SizedBox(width: 10),
          Expanded(
              child: _ToolTile(
                  title: 'Shovel',
                  body: 'Remove plant and free the pot.',
                  icon: Icons.colorize,
                  bg: c.isDark ? const Color(0xFF2A1518) : const Color(0xFFFEEFF1),
                  border: c.isDark ? const Color(0xFF5C2228) : const Color(0xFFFBD0D8),
                  iconColor: const Color(0xFFE5486B),
                  titleColor: c.isDark ? const Color(0xFFF87171) : const Color(0xFF7F1D1D),
                  onTap: () => pushTab(context, ShovelScreen(pot: plant.pot)))),
        ])),
        const SizedBox(height: 14),
        Material(
          color: c.isDark ? c.cardAlt : const Color(0xFFE6F4EA),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => pushTab(
                context, plant.ready ? ReadyToHarvestScreen(pot: plant.pot) : PlantOverviewScreen(pot: plant.pot)),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.isDark ? c.border : const Color(0xFFCDEBD8))),
              child: Row(children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: c.isDark ? Colors.transparent : const Color(0xFF2E9E64),
                      shape: BoxShape.circle,
                      border: c.isDark ? Border.all(color: c.border) : null),
                  child: Icon(Icons.star_rounded, size: 18, color: c.isDark ? c.accent : Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Harvest gives you XP!', style: T.p(13.5, w: FontWeight.w700, c: c.heading)),
                    Text('When the plant is fully grown, you can claim your XP.', style: T.p(11, c: c.textMuted)),
                  ]),
                ),
                Icon(Icons.chevron_right, color: c.textMuted),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final String title, body;
  final IconData icon;
  final Color bg, border, iconColor, titleColor;
  final VoidCallback onTap;
  const _ToolTile(
      {required this.title,
      required this.body,
      required this.icon,
      required this.bg,
      required this.border,
      required this.iconColor,
      required this.titleColor,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 112),
          padding: const EdgeInsets.fromLTRB(10, 14, 8, 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(height: 10),
            Text(title, style: T.p(13, w: FontWeight.w700, c: titleColor)),
            Text(body, style: T.p(10.5, c: c.textMuted, h: 1.3)),
          ]),
        ),
      ),
    );
  }
}
