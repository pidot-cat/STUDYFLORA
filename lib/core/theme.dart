import 'package:flutter/material.dart';

/// Design tokens taken from the Study Flora mockups (light + "DM" dark screens).
/// Every widget reads colours through `context.sf` so Dark Mode (FR-5.4)
/// switches the whole app at once.
@immutable
class SfColors extends ThemeExtension<SfColors> {
  final Color bg;
  final Color surface;
  final Color surfaceAlt; // mint-tinted card
  final Color ink;
  final Color muted;
  final Color line;
  final Color brand; // primary dark-green buttons (light) / mint (dark)
  final Color onBrand;
  final Color brandSoft; // chips, selected nav pill
  final Color accent; // progress bars
  final Color terracotta;
  final Color terracottaSoft;
  final Color gold;
  final Color goldSoft;
  final Color danger;
  final Color dangerSoft;
  final Color info;
  final Color infoSoft;
  final Color shadow;

  const SfColors({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.ink,
    required this.muted,
    required this.line,
    required this.brand,
    required this.onBrand,
    required this.brandSoft,
    required this.accent,
    required this.terracotta,
    required this.terracottaSoft,
    required this.gold,
    required this.goldSoft,
    required this.danger,
    required this.dangerSoft,
    required this.info,
    required this.infoSoft,
    required this.shadow,
  });

  static const light = SfColors(
    bg: Color(0xFFF5F5F5),
    surface: Colors.white,
    surfaceAlt: Color(0xFFEAF6EE),
    ink: Color(0xFF12261C),
    muted: Color(0xFF6B7A72),
    line: Color(0xFFE4EAE6),
    brand: Color(0xFF1E4D3A),
    onBrand: Colors.white,
    brandSoft: Color(0xFFCDEFD9),
    accent: Color(0xFF1F8F5F),
    terracotta: Color(0xFFD2643A),
    terracottaSoft: Color(0xFFFBE7DE),
    gold: Color(0xFFF2A516),
    goldSoft: Color(0xFFFFF4D9),
    danger: Color(0xFFE5484D),
    dangerSoft: Color(0xFFFDECEC),
    info: Color(0xFF2B7BD6),
    infoSoft: Color(0xFFE8F2FD),
    shadow: Color(0x14102A1E),
  );

  static const dark = SfColors(
    bg: Color(0xFF0B1A14),
    surface: Color(0xFF12251C),
    surfaceAlt: Color(0xFF173026),
    ink: Color(0xFFEAF4EE),
    muted: Color(0xFF8FA79A),
    line: Color(0xFF23392E),
    brand: Color(0xFF34D58D),
    onBrand: Color(0xFF07140E),
    brandSoft: Color(0xFF1C3A2D),
    accent: Color(0xFF34D58D),
    terracotta: Color(0xFFE5794E),
    terracottaSoft: Color(0xFF3A2219),
    gold: Color(0xFFF5B83A),
    goldSoft: Color(0xFF33290F),
    danger: Color(0xFFFF6B6B),
    dangerSoft: Color(0xFF3A1A1C),
    info: Color(0xFF6BB0FF),
    infoSoft: Color(0xFF162A40),
    shadow: Color(0x66000000),
  );

  @override
  SfColors copyWith() => this;

  @override
  SfColors lerp(ThemeExtension<SfColors>? other, double t) {
    if (other is! SfColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return SfColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      ink: l(ink, other.ink),
      muted: l(muted, other.muted),
      line: l(line, other.line),
      brand: l(brand, other.brand),
      onBrand: l(onBrand, other.onBrand),
      brandSoft: l(brandSoft, other.brandSoft),
      accent: l(accent, other.accent),
      terracotta: l(terracotta, other.terracotta),
      terracottaSoft: l(terracottaSoft, other.terracottaSoft),
      gold: l(gold, other.gold),
      goldSoft: l(goldSoft, other.goldSoft),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      info: l(info, other.info),
      infoSoft: l(infoSoft, other.infoSoft),
      shadow: l(shadow, other.shadow),
    );
  }
}

extension SfThemeX on BuildContext {
  SfColors get sf => Theme.of(this).extension<SfColors>()!;
  TextTheme get tt => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

class AppTheme {
  static const radius = 20.0;

  static ThemeData build(Brightness b) {
    final c = b == Brightness.dark ? SfColors.dark : SfColors.light;
    final base = ThemeData(
      useMaterial3: true,
      brightness: b,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: c.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1E4D3A),
        brightness: b,
        primary: c.brand,
        onPrimary: c.onBrand,
        surface: c.surface,
        error: c.danger,
      ),
      extensions: [c],
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      }),
    );
    final t = base.textTheme.apply(bodyColor: c.ink, displayColor: c.ink);
    return base.copyWith(
      textTheme: t.copyWith(
        headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.5),
        titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 19),
        titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 15.5),
        titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 13.5),
        bodyMedium: t.bodyMedium?.copyWith(fontSize: 13.5, height: 1.4),
        bodySmall: t.bodySmall?.copyWith(fontSize: 12, color: c.muted, height: 1.35),
        labelSmall: t.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: TextStyle(color: c.muted, fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.brand, width: 1.6)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.danger)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.danger, width: 1.6)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.ink,
        contentTextStyle: TextStyle(color: c.bg, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.accent : c.line),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: c.surface, surfaceTintColor: Colors.transparent),
      dialogTheme: DialogThemeData(backgroundColor: c.surface, surfaceTintColor: Colors.transparent),
    );
  }
}
