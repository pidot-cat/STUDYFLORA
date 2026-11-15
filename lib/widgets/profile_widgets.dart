import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/cosmetics.dart';
import '../providers/game_provider.dart';
import 'common.dart';

/// Avatar inside the equipped border, with the border's themed badge in the
/// corner. The badge is always drawn so the old badge baked into the border
/// art never shows. With no border equipped, a plain round avatar is shown.
class AvatarWithBorder extends StatelessWidget {
  const AvatarWithBorder({super.key, required this.avatarId, required this.borderId, this.size = 64, this.badgeId});
  final String avatarId;
  final String borderId;
  final double size;

  /// Achievement shown on the border's corner (e.g. First Sprout, Bookworm).
  /// Falls back to the border's own badge when the user has none yet.
  final String? badgeId;

  @override
  Widget build(BuildContext context) {
    final border = BorderDef.maybe(borderId);
    if (border == null) {
      final c = context.sf;
      final d = size * 0.84;
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Container(
            width: d,
            height: d,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.brandSoft,
              border: Border.all(color: c.line, width: size < 50 ? 1.5 : 2.5),
            ),
            child: ClipOval(child: Image.asset(Avatar.of(avatarId).asset, fit: BoxFit.cover)),
          ),
        ),
      );
    }
    final badge = Badges.of(badgeId ?? border.badgeId);
    final d = size * border.innerRadius * 2;
    final m = size * border.badgeSize;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(child: Image.asset(border.asset, fit: BoxFit.contain)),
        // Avatar sits exactly in the border's inner circle (art is re-centred).
        Positioned(
          left: size * border.cx - d / 2,
          top: size * border.cy - d / 2,
          width: d,
          height: d,
          child: ClipOval(child: Image.asset(Avatar.of(avatarId).asset, fit: BoxFit.cover)),
        ),
        // Themed badge covers the corner badge drawn in the border art.
        Positioned(
            left: size * border.badgeX - m / 2,
            top: size * border.badgeY - m / 2,
            child: BadgeMedal(badge: badge, size: m, ring: true),
          ),
      ]),
    );
  }
}

/// The user's own avatar (reads GameProvider).
class MyAvatar extends StatelessWidget {
  const MyAvatar({super.key, this.size = 40});
  final double size;
  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameProvider>();
    return AvatarWithBorder(avatarId: g.avatarId, borderId: g.equippedBorder, size: size, badgeId: g.avatarBadge);
  }
}

class BadgeMedal extends StatelessWidget {
  const BadgeMedal({super.key, required this.badge, this.size = 56, this.locked = false, this.ring = false});
  final BadgeDef badge;
  final double size;
  final bool locked;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final colors = locked ? [c.line, c.muted.withValues(alpha: 0.5)] : badge.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: ring ? Border.all(color: Colors.white, width: size * 0.08) : null,
        boxShadow: locked ? null : [BoxShadow(color: colors.last.withValues(alpha: 0.35), blurRadius: size * 0.25, offset: Offset(0, size * 0.08))],
      ),
      child: Icon(locked ? Icons.lock_rounded : badge.icon, color: Colors.white, size: size * 0.5),
    );
  }
}

/// Header used on Home/Garden/Shop/Settings: logo, wordmark, coins (+XP), avatar.
class SfTopBar extends StatelessWidget {
  const SfTopBar({super.key, this.showXp = true, this.leading});
  final bool showXp;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.sf;
    final g = context.watch<GameProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(children: [
        if (leading != null) ...[leading!, const SizedBox(width: 8)],
        Image.asset('assets/images/logo_mark.webp', width: 34, height: 30, fit: BoxFit.contain),
        const SizedBox(width: 8),
        Expanded(
          child: Text('StudyFlora',
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(fontFamily: 'DMSerif', fontSize: 21, color: context.isDark ? c.ink : c.brand)),
        ),
        _Pill(tint: c.goldSoft, child: Row(children: [
          const CoinIcon(size: 18),
          const SizedBox(width: 5),
          AnimatedCount(g.coins, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: c.ink)),
        ])),
        if (showXp) ...[
          const SizedBox(width: 6),
          _Pill(tint: c.brandSoft, child: Row(children: [
            const XpIcon(size: 18),
            const SizedBox(width: 5),
            AnimatedCount(g.xp, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: c.ink)),
          ])),
        ],
        const SizedBox(width: 8),
        const MyAvatar(size: 38),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child, required this.tint});
  final Widget child;
  final Color tint;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: context.sf.line.withValues(alpha: 0.6)),
        ),
        child: child,
      );
}

String levelLabel(GameProvider g) => 'Lv. ${g.level}';
String xpLabel(GameProvider g) => '${fmtNumber(g.xpIntoLevel)} / 200 XP';
