import 'package:flutter/material.dart';

/// Design tokens sampled from the approved StudyFlora mock-ups.
/// Light values come from the light screens, dark values from the DM-* screens.
@immutable
class SFColors extends ThemeExtension<SFColors> {
  final Color bg; // main tab background (soft mint-grey)
  final Color bgAuth; // auth / onboarding background (lavender white)
  final Color card;
  final Color cardAlt; // inner panels inside cards
  final Color border;
  final Color primary; // dark forest green buttons
  final Color primaryText; // text on primary
  final Color accent; // bright green used for progress/active (light: forest, dark: emerald)
  final Color heading; // deep green heading text
  final Color text; // near black body headings
  final Color textMuted;
  final Color textFaint;
  final Color mint; // pale mint chips / tiles
  final Color mintStrong; // nav active pill
  final Color mintText; // green text on mint chips
  final Color inputFill;
  final Color coinBg;
  final Color coinBorder;
  final Color coin;
  final Color danger;
  final Color dangerBg;
  final Color dangerBorder;
  final Color blueTint;
  final Color blue;
  final Color pinkTint;
  final Color amberTint;
  final Color amber;
  final Color track; // empty progress track
  final Color navBg;
  final Color shadow;

  const SFColors({
    required this.bg,
    required this.bgAuth,
    required this.card,
    required this.cardAlt,
    required this.border,
    required this.primary,
    required this.primaryText,
    required this.accent,
    required this.heading,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.mint,
    required this.mintStrong,
    required this.mintText,
    required this.inputFill,
    required this.coinBg,
    required this.coinBorder,
    required this.coin,
    required this.danger,
    required this.dangerBg,
    required this.dangerBorder,
    required this.blueTint,
    required this.blue,
    required this.pinkTint,
    required this.amberTint,
    required this.amber,
    required this.track,
    required this.navBg,
    required this.shadow,
  });

  static const light = SFColors(
    bg: Color(0xFFF2F6F3),
    bgAuth: Color(0xFFF9F9FF),
    card: Color(0xFFFFFFFF),
    cardAlt: Color(0xFFF1F6F2),
    border: Color(0xFFE3EBE6),
    primary: Color(0xFF1B4D3E),
    primaryText: Color(0xFFFFFFFF),
    accent: Color(0xFF1B5E3B),
    heading: Color(0xFF163B2C),
    text: Color(0xFF111827),
    textMuted: Color(0xFF6B7280),
    textFaint: Color(0xFF9CA3AF),
    mint: Color(0xFFDDF5E6),
    mintStrong: Color(0xFFB8EFCD),
    mintText: Color(0xFF1B6B3F),
    inputFill: Color(0xFFEFF2FF),
    coinBg: Color(0xFFFFF8E1),
    coinBorder: Color(0xFFFDEBB5),
    coin: Color(0xFFF59E0B),
    danger: Color(0xFFE11D48),
    dangerBg: Color(0xFFFFEEF0),
    dangerBorder: Color(0xFFFBC4CC),
    blueTint: Color(0xFFEAF3FE),
    blue: Color(0xFF2F80ED),
    pinkTint: Color(0xFFFEEFF1),
    amberTint: Color(0xFFFFF4DC),
    amber: Color(0xFFB7791F),
    track: Color(0xFFE2E8F0),
    navBg: Color(0xFFF7F8FD),
    shadow: Color(0x14000000),
  );

  static const dark = SFColors(
    bg: Color(0xFF07140F),
    bgAuth: Color(0xFF07140F),
    card: Color(0xFF10231B),
    cardAlt: Color(0xFF142B21),
    border: Color(0xFF1F3B2F),
    primary: Color(0xFF34D399),
    primaryText: Color(0xFF07140F),
    accent: Color(0xFF34D399),
    heading: Color(0xFFF1F5F3),
    text: Color(0xFFF1F5F3),
    textMuted: Color(0xFF97A59E),
    textFaint: Color(0xFF6B7C74),
    mint: Color(0xFF0F2E22),
    mintStrong: Color(0xFF1B4D3B),
    mintText: Color(0xFF34D399),
    inputFill: Color(0xFF142B21),
    coinBg: Color(0xFF2A2A12),
    coinBorder: Color(0xFF4A4520),
    coin: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    dangerBg: Color(0xFF2A1518),
    dangerBorder: Color(0xFF5C2228),
    blueTint: Color(0xFF13263A),
    blue: Color(0xFF60A5FA),
    pinkTint: Color(0xFF2A1518),
    amberTint: Color(0xFF2B2412),
    amber: Color(0xFFFBBF24),
    track: Color(0xFF1F3B2F),
    navBg: Color(0xFF0B1A14),
    shadow: Color(0x33000000),
  );

  bool get isDark => this == dark;

  @override
  SFColors copyWith() => this;

  @override
  SFColors lerp(ThemeExtension<SFColors>? other, double t) => (other is SFColors && t > .5) ? other : this;
}

extension SFColorsX on BuildContext {
  SFColors get c => Theme.of(this).extension<SFColors>() ?? SFColors.light;
}
