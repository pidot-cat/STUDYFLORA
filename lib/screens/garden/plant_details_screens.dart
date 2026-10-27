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
import 'garden_widgets.dart';
import 'harvest_screens.dart';
import 'tool_screens.dart';

Scaffold _shell(BuildContext context, List<Widget> children) {
  final c = context.c;
  return Scaffold(
    backgroundColor: c.isDark ? c.bg : const Color(0xFFF3F7F4),
    body: SafeArea(
      bottom: false,
      child: Column(children: [
        const AppHeader(back: true),
        Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(20, 6, 20, 24), children: children)),
      ]),
    ),
  );
}

/// Compact "Plant Details" (thumbnail + tools grid).
class PlantDetailsScreen extends StatelessWidget {
  final int pot;
  const PlantDetailsScreen({super.key, required this.pot});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final p = context.watch<AppState>().plantAt(pot);
    if (p == null) return const Scaffold();
    final pct = (p.progress * 100).round();
    return _shell(context, [
      Text('Plant Details', style: T.p(25, w: FontWeight.w700, c: c.text)),
      Text("Track your plant's growth and care.", style: T.p(13, c: c.textMuted)),
      const SizedBox(height: 18),
      SFCard(
        radius: 22,
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
                color: c.isDark ? c.cardAlt : const Color(0xFFE6F4EA), borderRadius: BorderRadius.circular(18)),
            padding: const EdgeInsets.all(8),
            child: PlantArt(p.flowerId, size: 112),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(p.flower.name, style: T.p(18, w: FontWeight.w700, c: c.text))),
                const Spacer(),
                Pill(p.ready ? 'Ready' : 'Growing',
                    fontSize: 11.5, bg: c.isDark ? c.mint : const Color(0xFFD4F5E2), fg: const Color(0xFF15803D)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.water_drop, size: 16, color: p.needsWater ? c.danger : const Color(0xFF2F80ED)),
                const SizedBox(width: 6),
                Text(p.needsWater ? 'Thirsty' : 'Hydrated',
                    style: T.p(14, w: FontWeight.w600, c: p.needsWater ? c.danger : const Color(0xFF1D7FD8))),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.schedule, size: 16, color: c.text),
                const SizedBox(width: 6),
                Text(p.ready ? 'Ready!' : fmtHm(p.remaining), style: T.p(15, w: FontWeight.w700, c: c.text)),
              ]),
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: Text('UNTIL HARVEST', style: T.p(9.5, w: FontWeight.w600, c: c.textMuted, ls: .4)),
              ),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      SFCard(
        radius: 18,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(children: [
          Row(children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: c.isDark ? c.mint : const Color(0xFFD4F5E2), shape: BoxShape.circle),
              child: const Icon(Icons.colorize, size: 14, color: Color(0xFF15803D)),
            ),
            const SizedBox(width: 10),
            Text('Growth Progress', style: T.p(14.5, w: FontWeight.w600, c: c.text)),
            const Spacer(),
            Text('$pct%', style: T.p(15, w: FontWeight.w700, c: c.text)),
          ]),
          const SizedBox(height: 12),
          SFProgress(
              value: p.progress,
              height: 9,
              color: const Color(0xFF15924F),
              track: c.isDark ? c.border : const Color(0xFFEFF2F7)),
        ]),
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.isDark ? c.blueTint : const Color(0xFFEAF3FE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.isDark ? c.border : const Color(0xFFCFE3FB)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: c.isDark ? c.card : const Color(0xFFD6E9FC), shape: BoxShape.circle),
            child: const Icon(Icons.water_drop, size: 18, color: Color(0xFF1D7FD8)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Keep it hydrated', style: T.p(13.5, w: FontWeight.w700, c: c.text)),
              Text('Your plant grows while hydrated. If it becomes dry, growth will pause.',
                  style: T.p(12.5, c: c.textMuted, h: 1.4)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 22),
      Text('TOOLS', style: T.p(11.5, w: FontWeight.w600, c: c.textMuted, ls: .6)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
            child: _BigTool(
                'Water',
                'Keep it hydrated to keep growing.',
                Icons.water_drop,
                const Color(0xFF1D7FD8),
                c.isDark ? c.blueTint : const Color(0xFFEAF3FE),
                const Color(0xFFD6E9FC),
                () => pushTab(context, WaterPlantScreen(pot: pot)))),
        const SizedBox(width: 10),
        Expanded(
            child: _BigTool(
                'Fertilize',
                '2x growth speed (1 use per plant).',
                Icons.lock,
                const Color(0xFF15803D),
                c.isDark ? c.cardAlt : const Color(0xFFEFF8F2),
                const Color(0xFFD4F5E2),
                () => pushTab(context, FertilizeScreen(pot: pot)))),
        const SizedBox(width: 10),
        Expanded(
            child: _BigTool(
                'Shovel',
                'Remove plant and free the pot.',
                Icons.colorize,
                const Color(0xFFE11D48),
                c.isDark ? c.pinkTint : const Color(0xFFFEEFF1),
                const Color(0xFFFCD9DF),
                () => pushTab(context, ShovelScreen(pot: pot)))),
      ]),
      const SizedBox(height: 18),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.info_outline, size: 15, color: c.textMuted),
        const SizedBox(width: 6),
        Text('The plant will pause growing if it is not hydrated.', style: T.p(12.5, c: c.textMuted)),
      ]),
    ]);
  }
}

class _BigTool extends StatelessWidget {
  final String title, body;
  final IconData icon;
  final Color fg, bg, circle;
  final VoidCallback onTap;
  const _BigTool(this.title, this.body, this.icon, this.fg, this.bg, this.circle, this.onTap);
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 164,
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: circle)),
          child: Column(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: c.isDark ? c.card : circle, shape: BoxShape.circle),
              child: Icon(icon, size: 19, color: fg),
            ),
            const SizedBox(height: 12),
            Text(title, style: T.p(14, w: FontWeight.w700, c: c.text)),
            const SizedBox(height: 4),
            Text(body, textAlign: TextAlign.center, style: T.p(11, c: c.textMuted, h: 1.3)),
          ]),
        ),
      ),
    );
  }
}

/// Full plant view: hero, needs, rewards, info and shovel row. Also covers the
/// "Active Boost" and "Ready to Harvest" variants.
class PlantOverviewScreen extends StatelessWidget {
  final int pot;
  const PlantOverviewScreen({super.key, required this.pot});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.watch<AppState>();
    final p = s.plantAt(pot);
    if (p == null) return const Scaffold();
    final f = p.flower;
    final pct = (p.progress * 100).round();
    return _shell(context, [
      if (p.fertilized && !p.ready) ...[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.isDark ? c.mint : const Color(0xFFDDF8E9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFA7E9C3)),
          ),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: const Color(0xFF22B573), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.bolt, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: const Color(0xFFB9F0D0), borderRadius: BorderRadius.circular(4)),
                    child: Text('ACTIVE BOOST', style: T.p(11, w: FontWeight.w700, c: const Color(0xFF14532D))),
                  ),
                  const SizedBox(width: 8),
                  Text('x2 Speed', style: T.p(11, w: FontWeight.w700, c: const Color(0xFF15803D))),
                ]),
                Text('Fertilizer applied! Plant growth rate is currently doubled.',
                    style: T.p(12, c: c.isDark ? c.text : const Color(0xFF14532D), h: 1.35)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
      ],
      SFCard(
        radius: 24,
        padding: EdgeInsets.zero,
        child: Column(children: [
          const SizedBox(height: 22),
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                p.fertilized ? const Color(0xFFFFF5CC) : const Color(0xFFE7F6EC),
                c.card,
              ]),
            ),
            child: PlantArt(f.id, size: 150, large: true),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(f.name, style: T.p(21, w: FontWeight.w700, c: c.text)),
                  Pill(p.ready ? 'Ready to Harvest' : 'Growing',
                      dot: p.fertilized || p.ready,
                      fontSize: 11.5,
                      bg: c.isDark ? c.mint : const Color(0xFFD4F5E2),
                      fg: const Color(0xFF15803D)),
                  if (p.fertilized)
                    Pill('⚡ x2 Speed', fontSize: 11.5, bg: const Color(0xFFFFF1C2), fg: const Color(0xFF92400E)),
                ]),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Text(f.description, textAlign: TextAlign.center, style: T.p(11.5, c: c.textMuted, h: 1.6)),
          ),
          const SizedBox(height: 16),
          if (p.ready)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
              child: Column(children: [
                Divider(color: c.border),
                const SizedBox(height: 8),
                Row(children: [
                  Text('Time to Harvest', style: T.p(12, c: c.textMuted)),
                  const Spacer(),
                  Text('Growth Progress', style: T.p(12, c: c.textMuted)),
                ]),
                Row(children: [
                  Icon(Icons.schedule, size: 16, color: const Color(0xFF15924F)),
                  const SizedBox(width: 6),
                  Text('Ready!', style: T.p(14.5, w: FontWeight.w700, c: const Color(0xFF15924F))),
                  const Spacer(),
                  Text('100%', style: T.p(14.5, w: FontWeight.w700, c: c.text)),
                ]),
                const SizedBox(height: 10),
                const SFProgress(
                    value: 1, height: 6, gradient: LinearGradient(colors: [Color(0xFF14532D), Color(0xFF34D399)])),
                const SizedBox(height: 22),
                PrimaryButton('Harvest',
                    icon: Icons.spa,
                    trailingIcon: Icons.chevron_right,
                    radius: 16,
                    color: c.isDark ? c.primary : const Color(0xFF1B4D3E),
                    onTap: () => pushTab(context, ReadyToHarvestScreen(pot: pot))),
              ]),
            )
          else
            Container(
              margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.border),
              ),
              child: Row(children: [
                IconTile(Icons.schedule,
                    size: 32, iconSize: 16, circle: true, bg: c.isDark ? c.mint : const Color(0xFFE6F4EA)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('TIME TO HARVEST', style: T.p(9.5, w: FontWeight.w600, c: c.textMuted, ls: .4)),
                    Row(children: [
                      Text(fmtHm(p.remaining), style: T.p(13, w: FontWeight.w700, c: c.text)),
                      if (p.fertilized) ...[
                        const SizedBox(width: 6),
                        Pill('(was ${fmtHm(p.remainingNoBoost)})',
                            fontSize: 8.5,
                            bg: const Color(0xFFE3F5EA),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1)),
                      ],
                    ]),
                  ]),
                ),
                Container(width: 1, height: 34, color: c.border),
                const SizedBox(width: 10),
                IconTile(Icons.trending_up,
                    size: 32, iconSize: 16, circle: true, bg: c.isDark ? c.mint : const Color(0xFFE6F4EA)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('GROWTH PROGRESS', style: T.p(9.5, w: FontWeight.w600, c: c.textMuted, ls: .4)),
                    Row(children: [
                      Text('$pct%', style: T.p(13, w: FontWeight.w700, c: c.text)),
                      const SizedBox(width: 6),
                      Expanded(child: SFProgress(value: p.progress, height: 7, color: const Color(0xFF1B3A2E))),
                    ]),
                  ]),
                ),
              ]),
            ),
        ]),
      ),
      const SizedBox(height: 20),
      Row(children: [
        Text('Plant Needs', style: T.p(15, w: FontWeight.w600, c: c.text)),
        const Spacer(),
        if (!p.needsWater && p.fertilized)
          Pill('All Needs Met',
              fontSize: 11, bg: c.isDark ? c.mint : const Color(0xFFE3F5EA), fg: const Color(0xFF15803D)),
      ]),
      const SizedBox(height: 10),
      _NeedRow(
        icon: Icons.water_drop,
        iconBg: const Color(0xFFE3F0FD),
        iconFg: const Color(0xFF2F80ED),
        title: 'Water',
        subtitle: p.needsWater
            ? 'Needs water now'
            : (p.hydration >= 99
                ? 'Hydrated • Next in ${p.hydrationLeft.inHours}h'
                : 'Needs water in ${p.hydrationLeft.inHours}h'),
        action: p.hydration >= 99
            ? const _DoneChip('Hydrated')
            : _ActionChip('Water', dark: true, onTap: () => pushTab(context, WaterPlantScreen(pot: pot))),
      ),
      const SizedBox(height: 10),
      _NeedRow(
        icon: Icons.inventory_2_outlined,
        iconBg: const Color(0xFFE6F4EA),
        iconFg: c.text,
        title: 'Fertilizer',
        badge: p.fertilized ? 'x2 Active' : null,
        subtitle: p.fertilized ? 'Boost active until harvest' : 'Available (one-time)',
        action: p.fertilized
            ? const _DoneChip('Applied')
            : _ActionChip('Fertilize', onTap: () => pushTab(context, FertilizeScreen(pot: pot))),
      ),
      const SizedBox(height: 18),
      Text(p.ready ? 'Reward' : 'Rewards', style: T.p(15, w: FontWeight.w600, c: c.text)),
      const SizedBox(height: 10),
      SFCard(
        radius: 16,
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const _XpDot(),
          const SizedBox(width: 12),
          Text('+${f.rewardXp} XP', style: T.p(15, w: FontWeight.w700, c: c.text)),
        ]),
      ),
      const SizedBox(height: 18),
      Text('Plant Info', style: T.p(15, w: FontWeight.w600, c: c.text)),
      const SizedBox(height: 10),
      SFCard(
        radius: 16,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        child: Column(children: [
          _InfoRow(Icons.layers_outlined, 'Type', 'Flower'),
          Divider(color: c.border, height: 1),
          _InfoRow(Icons.circle_outlined, 'Pot', '$pot / ${GardenRules.potCount}'),
        ]),
      ),
      const SizedBox(height: 20),
      Material(
        color: c.isDark ? c.pinkTint : const Color(0xFFFFF4F5),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => pushTab(context, ShovelScreen(pot: pot)),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFBC4CC))),
            child: Row(children: [
              const Icon(Icons.colorize, color: Color(0xFFE11D48), size: 18),
              const SizedBox(width: 12),
              Expanded(child: Text('Shovel Plant', style: T.p(13.5, w: FontWeight.w700, c: const Color(0xFFB91C1C)))),
              const Icon(Icons.chevron_right, color: Color(0xFFE11D48)),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _XpDot extends StatelessWidget {
  const _XpDot();
  @override
  Widget build(BuildContext context) => Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(color: Color(0xFFD1FAE5), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text('XP', style: T.p(11, w: FontWeight.w700, c: const Color(0xFF14532D))),
      );
}

class _NeedRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconFg;
  final String title, subtitle;
  final String? badge;
  final Widget action;
  const _NeedRow(
      {required this.icon,
      required this.iconBg,
      required this.iconFg,
      required this.title,
      required this.subtitle,
      required this.action,
      this.badge});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SFCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: c.isDark ? c.cardAlt : iconBg, borderRadius: BorderRadius.circular(19)),
          child: Icon(icon, size: 19, color: iconFg),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(title, style: T.p(14.5, w: FontWeight.w600, c: c.text)),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: const Color(0xFFD4F5E2), borderRadius: BorderRadius.circular(4)),
                  child: Text(badge!, style: T.p(10, w: FontWeight.w700, c: const Color(0xFF14532D))),
                ),
              ],
            ]),
            Text(subtitle, style: T.p(12, c: c.textMuted)),
          ]),
        ),
        action,
      ]),
    );
  }
}

class _DoneChip extends StatelessWidget {
  final String label;
  const _DoneChip(this.label);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFFD4F5E2), borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check, size: 15, color: Color(0xFF14532D)),
          const SizedBox(width: 6),
          Text(label, style: T.p(12.5, w: FontWeight.w600, c: const Color(0xFF14532D))),
        ]),
      );
}

class _ActionChip extends StatelessWidget {
  final String label;
  final bool dark;
  final VoidCallback onTap;
  const _ActionChip(this.label, {required this.onTap, this.dark = false});
  @override
  Widget build(BuildContext context) => Material(
        color: dark ? const Color(0xFF1B3A2E) : const Color(0xFFD4F5E2),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            child: Text(label, style: T.p(12.5, w: FontWeight.w500, c: dark ? Colors.white : const Color(0xFF14532D))),
          ),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(icon, size: 17, color: const Color(0xFF15803D)),
        const SizedBox(width: 10),
        Text(label, style: T.p(13, c: c.textMuted)),
        const Spacer(),
        Text(value, style: T.p(13, w: FontWeight.w600, c: c.text)),
      ]),
    );
  }
}
