import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../nav.dart';
import '../screens/settings/profile_screen.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Mint circle with the sprout glyph + "StudyFlora" wordmark.
class BrandMark extends StatelessWidget {
  final double logo;
  final double fontSize;
  const BrandMark({super.key, this.logo = 36, this.fontSize = 22});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: logo,
        height: logo,
        decoration: BoxDecoration(
          color: c.isDark ? c.card : const Color(0xFFCDEBD8),
          shape: BoxShape.circle,
          border: c.isDark ? Border.all(color: c.border) : null,
        ),
        child: Icon(Icons.eco_outlined, size: logo * .5, color: c.isDark ? c.accent : const Color(0xFF1B4D3E)),
      ),
      const SizedBox(width: 10),
      Text('StudyFlora',
          style: c.isDark
              ? T.p(fontSize * .92, w: FontWeight.w700, c: c.text)
              : T.serif(fontSize, c: const Color(0xFF1B4D3E))),
    ]);
  }
}

class CoinPill extends StatelessWidget {
  final int amount;
  const CoinPill(this.amount, {super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
      decoration: BoxDecoration(
        color: c.coinBg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: c.coinBorder),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const CoinGlyph(size: 20),
        const SizedBox(width: 7),
        Text('$amount', style: T.p(14, w: FontWeight.w700, c: c.isDark ? c.coin : const Color(0xFF1F2937))),
      ]),
    );
  }
}

class XpPill extends StatelessWidget {
  final int amount;
  const XpPill(this.amount, {super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
      decoration: BoxDecoration(
        color: c.isDark ? c.mint : const Color(0xFFF0FBF4),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: c.isDark ? c.border : const Color(0xFFCDEFD9)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
              color: c.isDark ? Colors.transparent : const Color(0xFFCDF5DD), borderRadius: BorderRadius.circular(6)),
          child: Text('XP', style: T.p(11, w: FontWeight.w700, c: c.mintText)),
        ),
        const SizedBox(width: 6),
        Text('$amount', style: T.p(14, w: FontWeight.w700, c: c.isDark ? c.mintText : const Color(0xFF1F2937))),
      ]),
    );
  }
}

class ProfileButton extends StatelessWidget {
  final double size;
  const ProfileButton({super.key, this.size = 40});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.isDark ? c.card : const Color(0xFF145A3E),
      shape: CircleBorder(side: c.isDark ? BorderSide(color: c.border) : BorderSide.none),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => pushTab(context, const ProfileScreen()),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(Icons.person, size: size * .5, color: c.isDark ? c.textMuted : Colors.white),
        ),
      ),
    );
  }
}

/// The top app bar used by the main tabs and most sub screens.
class AppHeader extends StatelessWidget {
  final bool back;
  final bool showXp;
  final bool showProfile;
  final bool showCoins;
  final bool divider;
  final VoidCallback? onBack;
  const AppHeader({
    super.key,
    this.back = false,
    this.showXp = false,
    this.showProfile = true,
    this.showCoins = true,
    this.divider = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = context.c;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      decoration: BoxDecoration(
        border: (divider || c.isDark) ? Border(bottom: BorderSide(color: c.border)) : null,
      ),
      child: Row(children: [
        if (back) ...[CircleBackButton(onTap: onBack), const SizedBox(width: 14)],
        BrandMark(fontSize: back ? 21 : 22),
        const Spacer(),
        if (showCoins) CoinPill(s.coins),
        if (showXp) ...[const SizedBox(width: 6), XpPill(s.xp)],
        if (showProfile && !showXp) ...[const SizedBox(width: 10), const ProfileButton()],
      ]),
    );
  }
}

/// Centered title bar with a back circle (Study Material, Summary, Privacy...).
class TitleBar extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final bool back;
  final bool jakarta;
  final double fontSize;
  final bool divider;
  const TitleBar(this.title,
      {super.key, this.trailing, this.back = true, this.jakarta = false, this.fontSize = 18, this.divider = false});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(border: divider ? Border(bottom: BorderSide(color: c.border)) : null),
      child: Row(children: [
        SizedBox(
            width: 44,
            child: back
                ? const Align(alignment: Alignment.centerLeft, child: CircleBackButton(size: 36, outlined: true))
                : null),
        Expanded(
          child: Text(title,
              textAlign: TextAlign.center,
              style: jakarta
                  ? T.j(fontSize, w: FontWeight.w700, c: c.heading)
                  : T.p(fontSize, w: FontWeight.w700, c: c.heading)),
        ),
        SizedBox(width: 44, child: trailing == null ? null : Align(alignment: Alignment.centerRight, child: trailing)),
      ]),
    );
  }
}
