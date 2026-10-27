import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_header.dart';
import '../../widgets/common.dart';
import 'garden_screen.dart';

/// Shared scaffold for the Water / Fertilizer / Shovel screens.
class _ToolScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  const _ToolScaffold({required this.title, required this.subtitle, required this.children});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.isDark ? c.bg : const Color(0xFFF3F7F4),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          const AppHeader(back: true),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
              Row(children: [
                Pill('ACTIVE GARDEN',
                    dot: true,
                    fontSize: 11,
                    bg: c.isDark ? c.mint : const Color(0xFFDDF5E6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                const Spacer(),
                Icon(Icons.more_horiz, color: c.textFaint),
              ]),
              const SizedBox(height: 8),
              Text(title, style: T.p(25, w: FontWeight.w700, c: c.heading)),
              Text(subtitle, style: T.p(12.5, c: c.textMuted)),
              const SizedBox(height: 16),
              ...children,
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ToolHeroCard extends StatelessWidget {
  final String asset;
  final String name;
  final String status;
  final Color statusDot;
  final String description;
  final List<String> bullets;
  const _ToolHeroCard(
      {required this.asset,
      required this.name,
      required this.status,
      required this.statusDot,
      required this.description,
      required this.bullets});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SFCard(
      radius: 22,
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(clipBehavior: Clip.none, children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(asset, width: 76, height: 76, fit: BoxFit.cover)),
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                      color: statusDot.withValues(alpha: .35),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2))),
            ),
          ]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: T.p(16, w: FontWeight.w600, c: c.text)),
              const SizedBox(height: 4),
              Pill(status,
                  dot: true,
                  fontSize: 11,
                  weight: FontWeight.w500,
                  bg: statusDot == const Color(0xFF2F80ED) ? const Color(0xFFE3F0FD) : const Color(0xFFDDF5E6),
                  fg: statusDot == const Color(0xFF2F80ED) ? const Color(0xFF1D4ED8) : const Color(0xFF15803D),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3)),
              const SizedBox(height: 8),
              Text(description, style: T.p(12.5, c: c.textMuted, h: 1.5)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: c.isDark ? c.cardAlt : const Color(0xFFEFF6F1), borderRadius: BorderRadius.circular(14)),
          child: Column(children: [for (final b in bullets) CheckLine(b)]),
        ),
      ]),
    );
  }
}

class _ConfirmCard extends StatelessWidget {
  final String title;
  final String body;
  final Widget button;
  final Widget? leading;
  final Widget? footer;
  const _ConfirmCard({required this.title, required this.body, required this.button, this.leading, this.footer});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SFCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(children: [
        if (leading == null) ...[
          Text(title, style: T.p(16.5, w: FontWeight.w600, c: c.text)),
          const SizedBox(height: 6),
          Text(body, textAlign: TextAlign.center, style: T.p(12.5, c: c.textMuted, h: 1.45)),
        ] else
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            leading!,
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: T.p(16, w: FontWeight.w700, c: c.text)),
                const SizedBox(height: 4),
                Text(body, style: T.p(12.5, c: c.textMuted, h: 1.45)),
              ]),
            ),
          ]),
        const SizedBox(height: 16),
        button,
        if (footer != null) ...[const SizedBox(height: 12), footer!],
      ]),
    );
  }
}

Plant? _plant(BuildContext context, int pot) => context.watch<AppState>().plantAt(pot);

void _done(BuildContext context, String msg) {
  showSnack(context, msg);
  Navigator.of(context).pop();
}

class WaterPlantScreen extends StatelessWidget {
  final int pot;
  const WaterPlantScreen({super.key, required this.pot});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.watch<AppState>();
    final p = _plant(context, pot);
    if (p == null) return const Scaffold();
    final cur = p.hydration.round().clamp(0, 100).toInt();
    final charges = s.toolCount(ToolType.wateringCan);
    final name = p.flower.name;
    return _ToolScaffold(
      title: 'Water Plant',
      subtitle: 'Keep your plant hydrated to ensure continuous growth.',
      children: [
        _ToolHeroCard(
          asset: 'assets/tools/watering_can.png',
          name: 'Spring Watering Can',
          status: charges > 0 ? 'Ready to Water' : 'Recharging',
          statusDot: const Color(0xFF2F80ED),
          description:
              'Essential hydration for steady growth. Hydrated plants flourish at 100% normal speed without pause.',
          bullets: const [
            'Restores moisture level back to 100%.',
            'Lasts for 6 hours of continuous growth.',
            'Prevents wilting and pauses in your focus journey.',
          ],
        ),
        const SizedBox(height: 18),
        SFCard(
          radius: 22,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _Gauge(
                  icon: Icons.water_drop,
                  iconColor: const Color(0xFFF59E0B),
                  bg: const Color(0xFFFFF4DC),
                  label: 'CURRENT',
                  value: '$cur% Moisture',
                  valueColor: c.text),
              Column(children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: c.isDark ? c.mint : const Color(0xFFE3F5EA),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFBFE6CE))),
                  child: Icon(Icons.arrow_forward, size: 16, color: c.mintText),
                ),
                const SizedBox(height: 4),
                Text('Refill', style: T.p(10.5, c: c.textMuted)),
              ]),
              _Gauge(
                  icon: Icons.water_drop,
                  iconColor: const Color(0xFF2F80ED),
                  bg: const Color(0xFFE3F0FD),
                  label: 'AFTER WATER',
                  value: '100% Hydrated',
                  valueColor: c.mintText),
            ]),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.isDark ? c.cardAlt : const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.border),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Hydration Gauge', style: T.p(12.5, w: FontWeight.w500, c: c.text)),
                  const Spacer(),
                  Text('After water: 100%', style: T.p(12.5, w: FontWeight.w600, c: const Color(0xFF2F80ED))),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 10,
                    color: const Color(0xFF38BDF8),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: cur / 100,
                      heightFactor: 1,
                      child: Container(color: const Color(0xFFFBBF24)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Current ($cur%)', style: T.p(11.5, c: c.textMuted)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 18),
        _ConfirmCard(
          title: 'Water $name?',
          body: 'Your ${name.toLowerCase()} needs water. Restore its hydration to allow growth to continue.',
          button: PrimaryButton(
            charges > 0 ? 'Confirm & Water Plant' : 'No charges • 1 restores every 10 min',
            icon: Icons.water_drop,
            radius: 14,
            fontSize: 14.5,
            color: c.isDark ? c.primary : const Color(0xFF1B4D3E),
            onTap: charges > 0
                ? () {
                    if (s.water(pot)) _done(context, '$name watered! Hydration restored to 100%.');
                  }
                : null,
          ),
        ),
        const SizedBox(height: 18),
        const InfoBanner('Plant growth pauses when moisture runs out and resumes when the plant is hydrated.'),
      ],
    );
  }
}

class _Gauge extends StatelessWidget {
  final IconData icon;
  final Color iconColor, bg, valueColor;
  final String label, value;
  const _Gauge(
      {required this.icon,
      required this.iconColor,
      required this.bg,
      required this.label,
      required this.value,
      required this.valueColor});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: c.isDark ? c.cardAlt : bg, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      const SizedBox(height: 8),
      Text(label, style: T.p(10.5, w: FontWeight.w600, c: c.textMuted, ls: .4)),
      Text(value, style: T.p(14, w: FontWeight.w600, c: valueColor)),
    ]);
  }
}

class FertilizeScreen extends StatelessWidget {
  final int pot;
  const FertilizeScreen({super.key, required this.pot});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.watch<AppState>();
    final p = _plant(context, pot);
    if (p == null) return const Scaffold();
    final name = p.flower.name;
    final count = s.toolCount(ToolType.fertilizer);
    final can = !p.fertilized && count > 0 && !p.ready;
    final now = p.fertilized ? p.remainingNoBoost : p.remaining;
    final boosted = Duration(milliseconds: now.inMilliseconds ~/ 2);
    return _ToolScaffold(
      title: 'Use Fertilizer',
      subtitle: "Double your plant's growth speed.",
      children: [
        _ToolHeroCard(
          asset: 'assets/tools/fertilizer.png',
          name: 'Fertilizer',
          status: count > 0 ? 'Available' : 'Out of stock',
          statusDot: const Color(0xFF22C55E),
          description: 'Organic growth accelerator for all botanical species.',
          bullets: const [
            'Can be applied once per plant.',
            'Doubles growth speed.',
            'Reduces total growth time from 6 hours to 3 hours.',
          ],
        ),
        const SizedBox(height: 18),
        SFCard(
          radius: 22,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _Gauge(
                icon: Icons.schedule,
                iconColor: const Color(0xFFF59E0B),
                bg: const Color(0xFFFFF4DC),
                label: 'CURRENT TIME',
                value: fmtHmSpaced(now),
                valueColor: c.text),
            Pill('→ 2× Boost',
                fontSize: 11.5,
                bg: c.isDark ? c.mint : const Color(0xFFDDF5E6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
            _Gauge(
                icon: Icons.watch_later,
                iconColor: const Color(0xFF1B4D3E),
                bg: const Color(0xFFDDF0E4),
                label: 'WITH FERTILIZER',
                value: fmtHm(boosted),
                valueColor: c.mintText),
          ]),
        ),
        const SizedBox(height: 28),
        _ConfirmCard(
          title: 'Fertilize $name?',
          body: 'Your ${name.toLowerCase()} needs fertilizer. Boost its growth and reduced its remaining growth time.',
          button: PrimaryButton(
            p.fertilized
                ? 'Already applied to this plant'
                : (count > 0 ? 'Confirm & Apply Fertilizer' : 'No fertilizer left'),
            icon: Icons.auto_awesome,
            radius: 14,
            fontSize: 14.5,
            color: c.isDark ? c.primary : const Color(0xFF1B4D3E),
            onTap: can
                ? () {
                    if (s.fertilize(pot)) _done(context, 'Fertilizer applied! $name now grows 2× faster.');
                  }
                : null,
          ),
        ),
        const SizedBox(height: 28),
        const InfoBanner(
            'Plant growth speeds up when fertilizer is applied and returns to its normal rate when the fertilizer boost ends.'),
      ],
    );
  }
}

class ShovelScreen extends StatelessWidget {
  final int pot;
  const ShovelScreen({super.key, required this.pot});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.watch<AppState>();
    final p = _plant(context, pot);
    if (p == null) return const Scaffold();
    final name = p.flower.name;
    final count = s.toolCount(ToolType.shovel);
    return _ToolScaffold(
      title: 'Use Shovel',
      subtitle: "Remove a plant and free it's pot for replanting.",
      children: [
        _ToolHeroCard(
          asset: 'assets/tools/shovel.png',
          name: 'Shovel',
          status: count > 0 ? 'Available' : 'Out of stock',
          statusDot: const Color(0xFF22C55E),
          description: 'Tool used to remove a selected plant from your garden after confirmation.',
          bullets: const [
            'Removes the selected plant from the garden.',
            'Frees the pot for replanting.',
            'The plant cannot be restored after removal.',
          ],
        ),
        const SizedBox(height: 22),
        _ConfirmCard(
          title: 'Remove $name?',
          body: 'Are you sure you want to remove your ${name.toLowerCase()}? This will free the pot for a new plant.',
          leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset('assets/tools/shovel.png', width: 64, height: 64, fit: BoxFit.cover)),
          button: PrimaryButton(
            count > 0 ? 'Confirm & Remove Plant' : 'No shovel left',
            icon: Icons.colorize,
            radius: 30,
            fontSize: 14.5,
            color: c.isDark ? c.primary : const Color(0xFF14533C),
            onTap: count > 0
                ? () {
                    if (s.shovel(pot)) {
                      GardenScreen.selection.value = pot;
                      _done(context, '$name removed. Pot $pot is free for replanting.');
                    }
                  }
                : null,
          ),
          footer: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: T.p(12.5, w: FontWeight.w600, c: c.textMuted)),
          ),
        ),
        const SizedBox(height: 40),
        const InfoBanner('Removing a plant frees its pot so you can plant a new flower'),
      ],
    );
  }
}
