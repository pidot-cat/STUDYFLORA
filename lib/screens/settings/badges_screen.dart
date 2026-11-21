import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/cosmetics.dart';
import '../../providers/game_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/profile_widgets.dart';

/// Badges: border badges (from XP border purchases) + achievements
/// (study/garden milestones with a claimable reward). One badge can be
/// showcased on the profile.
class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameProvider>();
    final c = context.sf;
    return Scaffold(
      appBar: AppBar(backgroundColor: c.bg, surfaceTintColor: Colors.transparent, title: Text('Badges & Achievements', style: context.tt.titleMedium)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          SfCard(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const MyAvatar(size: 72),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${g.badges.length} / ${Badges.all.length} unlocked', style: context.tt.titleMedium),
                  const SizedBox(height: 6),
                  SfProgressBar(value: g.badges.length / Badges.all.length),
                  const SizedBox(height: 6),
                  Text('Tap an unlocked badge to show it on your avatar border. Tap it again to go back to the border’s own badge.', style: context.tt.bodySmall),
                ]),
              ),
            ]),
          ),
          const CapsLabel('Achievements', icon: Icons.emoji_events_outlined),
          _Grid(badges: Badges.achievements),
          const CapsLabel('Border badges', icon: Icons.blur_circular_rounded),
          _Grid(badges: Badges.borderBadges),
          const SizedBox(height: 8),
          Text('Border badges are unlocked when you buy the matching avatar border with XP. Each border shows its own badge unless you pick another one here.',
              style: context.tt.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.badges});
  final List<BadgeDef> badges;
  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameProvider>();
    final c = context.sf;
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.66,
      children: [
        for (final b in badges)
          Builder(builder: (context) {
            final unlocked = g.hasBadge(b.id);
            final claimable = unlocked && !g.isClaimed(b.id);
            final showcased = g.showcaseBadge == b.id;
            return Pressable(
              onTap: () {
                if (claimable) {
                  g.claimBadge(b.id);
                } else if (unlocked) {
                  g.setShowcaseBadge(showcased ? null : b.id);
                } else {
                  showToast(context, b.description);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
                decoration: BoxDecoration(
                  color: showcased ? c.brandSoft : c.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: claimable ? c.danger : (showcased ? c.accent : c.line), width: claimable || showcased ? 2 : 1.2),
                  boxShadow: [BoxShadow(color: c.shadow, blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(children: [
                  BadgeMedal(badge: b, size: 58, locked: !unlocked),
                  const SizedBox(height: 8),
                  Text(b.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Text(b.description, style: context.tt.bodySmall?.copyWith(fontSize: 10.5), textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis),
                  ),
                  if (claimable)
                    ClaimPill(label: b.rewardCoins > 0 ? 'Claim ${b.rewardCoins} coins' : 'Claim ${b.rewardXp} XP', dense: true)
                  else if (showcased)
                    const StatusBadge('Showcased', dense: true)
                  else if (!unlocked && (b.rewardCoins > 0 || b.rewardXp > 0))
                    StatusBadge(b.rewardCoins > 0 ? '${b.rewardCoins} coins' : '${b.rewardXp} XP', tone: Tone.neutral, dense: true),
                ]),
              ),
            );
          }),
      ],
    );
  }
}
