import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../models/plant.dart';
import '../../providers/garden_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/pill.dart';
import 'garden_actions.dart';
import 'garden_board.dart';

class GardenScreen extends StatelessWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: const [
        GardenBoard(),
        SizedBox(height: 14),
        _ToolBar(),
        SizedBox(height: 14),
        _InfoCard(),
        SizedBox(height: 16),
        _StatsRow(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tool selector (Water / Fertilize / Shovel)
// ---------------------------------------------------------------------------

class _ToolBar extends StatelessWidget {
  const _ToolBar();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final g = context.watch<GardenProvider>();
    return Row(
      children: [
        Expanded(
          child: _ToolButton(
            label: 'Water',
            sub: '${g.charges}/${g.maxCharges} H2O',
            icon: Icons.water_drop_outlined,
            selected: g.tool == GardenTool.water,
            showSub: dark,
            onTap: () => g.setTool(GardenTool.water),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ToolButton(
            label: 'Fertilize',
            sub: '-50% Time',
            icon: Icons.spa_outlined,
            selected: g.tool == GardenTool.fertilize,
            showSub: dark,
            onTap: () => g.setTool(GardenTool.fertilize),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ToolButton(
            label: 'Shovel',
            sub: 'Dig Up',
            icon: Icons.handyman_outlined,
            selected: g.tool == GardenTool.shovel,
            showSub: dark,
            onTap: () => g.setTool(GardenTool.shovel),
          ),
        ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.label,
    required this.sub,
    required this.icon,
    required this.selected,
    required this.showSub,
    required this.onTap,
  });

  final String label;
  final String sub;
  final IconData icon;
  final bool selected;
  final bool showSub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    final Color bg;
    final Color fg;
    final Color border;
    if (selected) {
      bg = dark ? p.primarySoft : p.primary;
      fg = dark ? p.onPrimarySoft : p.onPrimary;
      border = dark ? p.onPrimarySoft : p.primary;
    } else {
      bg = dark ? p.surface : p.neutralChip;
      fg = p.text;
      border = p.border;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: selected && dark ? 1.8 : 1),
        boxShadow: selected && dark
            ? [BoxShadow(color: p.onPrimarySoft.withAlpha(70), blurRadius: 14)]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
            child: Column(
              children: [
                Icon(icon, color: fg, size: 26),
                const SizedBox(height: 8),
                Text(label,
                    style: TextStyle(color: fg, fontSize: 13.5, fontWeight: FontWeight.w700)),
                if (showSub) ...[
                  const SizedBox(height: 2),
                  Text(sub,
                      style: TextStyle(
                          color: fg.withAlpha(190), fontSize: 11.5, fontWeight: FontWeight.w500)),
                ] else
                  const SizedBox(height: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Selected pot details
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final g = context.watch<GardenProvider>();
    final sel = g.selected;
    final plant = g.selectedPlant;

    if (sel == null) {
      return _HintCard(
        icon: Icons.touch_app_outlined,
        title: 'Tap a pot',
        text: 'Plant a seed in an empty pot, or select a plant to water, fertilize or harvest it.',
      );
    }
    if (plant == null) {
      return AppCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                  color: p.neutralChip, borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.add_circle_outline, color: p.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Empty Pot ${sel + 1}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Plant a seed to start growing.',
                      style: TextStyle(color: p.textMuted, fontSize: 14)),
                ],
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: p.primary,
                foregroundColor: p.onPrimary,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onPressed: () => showPlantSheet(context, sel),
              child: const Text('Plant', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
    }
    return _PlantCard(pot: sel, plant: plant);
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(icon, color: p.primary, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(text, style: TextStyle(color: p.textMuted, fontSize: 14, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlantCard extends StatelessWidget {
  const _PlantCard({required this.pot, required this.plant});

  final int pot;
  final Plant plant;

  String _description(DateTime now) {
    if (plant.isReady(now)) {
      return 'Fully grown! Tap the plant or Claim to collect +${plant.type.xp} XP.';
    }
    if (plant.isThirsty(now)) return 'Growth paused. Tap Water to replenish moisture.';
    if (plant.needsWaterSoon(now)) return 'Needs hydration soon. Tap Water to replenish moisture.';
    if (plant.fertilized) return 'Fertilized and growing twice as fast.';
    return 'Healthy and growing. Keep it hydrated to stay on schedule.';
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final progress = plant.progressAt(now);
    final ready = progress >= 1;
    final thirsty = plant.isThirsty(now);
    final percent = (progress * 100).floor();
    final lvl = plant.stageAt(now);
    final lvlBg = dark ? const Color(0xFF3A3410) : const Color(0xFFEFE2C9);
    final lvlFg = dark ? const Color(0xFFE8C547) : const Color(0xFF8A6A2E);

    final timePillBg = dark ? p.primarySoft : p.primarySoft;
    final timeText = ready ? 'READY' : formatCountdown(plant.untilNextStage(now));
    final caption = ready
        ? 'TAP PLANT TO CLAIM'
        : thirsty
            ? 'GROWTH PAUSED'
            : 'UNTIL NEXT STAGE';

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 56,
                decoration: BoxDecoration(
                  color: p.neutralChip,
                  borderRadius: BorderRadius.circular(14),
                  border: dark ? Border.all(color: p.border) : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  plant.type.asset,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) => Icon(Icons.local_florist, color: p.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(plant.type.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 8),
                        Pill(
                          label: ready ? 'MAX' : 'Lv. $lvl',
                          background: lvlBg,
                          foreground: lvlFg,
                          fontSize: 11.5,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(_description(now),
                        style: TextStyle(color: p.textMuted, fontSize: 13.5, height: 1.35)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: timePillBg,
                      borderRadius: BorderRadius.circular(14),
                      border: dark ? Border.all(color: p.onPrimarySoft.withAlpha(120)) : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(ready ? Icons.star_rounded : Icons.schedule,
                            size: 16, color: p.onPrimarySoft),
                        const SizedBox(width: 5),
                        Text(timeText,
                            style: TextStyle(
                                color: p.onPrimarySoft,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 84,
                    child: Text(caption,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: p.textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.spa_outlined, size: 15, color: p.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Growth Progress',
                    style: TextStyle(
                        color: p.text, fontSize: 13.5, fontWeight: dark ? FontWeight.w700 : FontWeight.w500)),
              ),
              Text('$percent%',
                  style: TextStyle(
                      color: dark ? p.onPrimarySoft : p.primary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: p.border,
              valueColor: AlwaysStoppedAnimation(dark ? p.onPrimarySoft : p.primary),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: ready ? Icons.star_rounded : Icons.water_drop_outlined,
                  label: ready ? 'Claim XP' : 'Water',
                  bg: dark ? p.primarySoft : p.primary,
                  fg: dark ? p.onPrimarySoft : p.onPrimary,
                  border: dark ? p.onPrimarySoft.withAlpha(110) : null,
                  onTap: () => ready ? claimPot(context, pot) : waterPot(context, pot),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.spa_outlined,
                  label: 'Fertilize',
                  bg: dark ? const Color(0xFF2A2412) : const Color(0xFFD2A476),
                  fg: dark ? const Color(0xFFE8C547) : const Color(0xFF4A2F10),
                  border: dark ? const Color(0xFF6B5C22) : null,
                  onTap: () => fertilizePot(context, pot),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.handyman_outlined,
                  label: 'Shovel',
                  bg: p.neutralChip,
                  fg: p.text,
                  border: dark ? p.border : null,
                  onTap: () => digPot(context, pot),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
    this.border,
  });

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final Color? border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: border == null ? BorderSide.none : BorderSide(color: border!),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Footer stats
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final planted = context.select<GardenProvider, int>((g) => g.plantedCount);
    final boost = planted.clamp(0, 15);
    final accent = dark ? p.onPrimarySoft : p.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.eco_outlined, size: 17, color: p.primary),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(dark ? 'Botanical Garden\nBoost:' : 'Study Garden\nBoost:',
                style: TextStyle(color: p.text, fontSize: 13.5, height: 1.5)),
          ),
          Expanded(
            flex: 3,
            child: Text('+$boost% Focus\nEfficiency',
                style: TextStyle(
                    color: accent, fontSize: 13.5, fontWeight: FontWeight.w800, height: 1.5)),
          ),
          Icon(Icons.auto_awesome, size: 16, color: dark ? p.coin : p.warmText),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text('18 Pots\nActive',
                style: TextStyle(
                    color: dark ? p.coin : p.warmText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    height: 1.5)),
          ),
        ],
      ),
    );
  }
}
